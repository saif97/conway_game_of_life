import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/block.dart';
import '../saved_blocks.dart';
import '../worker/transport.dart';
import '../worker/worker_factory.dart';

class ModelBoard extends ChangeNotifier {
  ModelBoard({SimulationTransport Function()? workerFactory, bool demo = true})
    : _factory = workerFactory ?? createWorker {
    _worker = _factory();
    ready = demo
        ? loadPattern(listBlocks.last)
        : _enqueue({'command': 'frame'});
  }

  final SimulationTransport Function() _factory;
  late SimulationTransport _worker;
  late final Future<void> ready;
  final _queue = Queue<(Map<String, Object?>, Completer<void>)>();
  Timer? _timer;
  bool _disposed = false, _inFlight = false, _playing = false;
  int _epoch = 0, _viewRevision = 0, _drawnRevision = -1;
  int _jumpExponent = 0, _seedExponent = 5;
  List<num> _view = [-8, -8, 100, 80, 1];
  Block? _insertedBlock;
  Float64List cells = Float64List(0);
  int generation = 0, population = 0, elapsedUs = 0, detail = 1;
  String? error;
  String title = 'Untitled world';
  bool get isPlaying => _playing;
  bool get isBusy => _inFlight || _queue.isNotEmpty;
  int get jumpExponent => _jumpExponent;
  int get seedExponent => _seedExponent;
  Block? get insertedBlock => _insertedBlock;
  int cameraReset = 0;
  List<num> bounds = [0, 0, 32];

  set jumpExponent(int value) {
    RangeError.checkValueInInterval(value, 0, 20);
    _jumpExponent = value;
    notifyListeners();
  }

  set seedExponent(int value) {
    RangeError.checkValueInInterval(value, 3, 9);
    _seedExponent = value;
    notifyListeners();
  }

  void setViewport(List<num> value) {
    if (listEquals(value, _view)) return;
    _view = value;
    _viewRevision++;
    _pump();
  }

  Future<void> _enqueue(Map<String, Object?> command) {
    if (_disposed || error != null) return Future.value();
    final done = Completer<void>();
    _queue.add((command, done));
    _pump();
    return done.future;
  }

  Future<void> _pump() async {
    if (_disposed || _inFlight || error != null) return;
    Map<String, Object?> command;
    Completer<void>? done;
    if (_queue.isNotEmpty) {
      (command, done) = _queue.removeFirst();
    } else if (_drawnRevision != _viewRevision) {
      command = {'command': 'frame'};
    } else {
      return;
    }
    final epoch = _epoch, revision = _viewRevision;
    _inFlight = true;
    notifyListeners();
    try {
      final reply = await _worker.request({...command, 'view': _view});
      if (_disposed || epoch != _epoch) return;
      cells = reply['cells'] as Float64List;
      bounds = (reply['bounds'] as List).cast<num>();
      generation = reply['generation'] as int;
      population = reply['population'] as int;
      if (command['command'] != 'frame') elapsedUs = reply['elapsedUs'] as int;
      detail = reply['detail'] as int;
      _drawnRevision = revision;
    } on WorkerStopped {
      // Clear/dispose invalidates the entire worker session.
    } catch (failure) {
      if (!_disposed && epoch == _epoch) {
        error = failure.toString();
        _playing = false;
        _timer?.cancel();
        while (_queue.isNotEmpty) {
          _queue.removeFirst().$2.complete();
        }
      }
    } finally {
      done?.complete();
      if (!_disposed && epoch == _epoch) {
        _inFlight = false;
        notifyListeners();
        _pump();
      }
    }
  }

  Future<void> step() => _enqueue({'command': 'advance', 'exponent': 0});
  Future<void> advance() =>
      _enqueue({'command': 'advance', 'exponent': _jumpExponent});

  void play() {
    if (_playing || error != null) return;
    _insertedBlock = null;
    _playing = true;
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      // Backpressure: never accumulate timer ticks behind a slow jump.
      if (!isBusy) advance();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _playing = false;
    notifyListeners();
  }

  /// Hard cancellation: a fresh worker makes late results harmless, even if
  /// the old worker was in a very long synchronous HashLife recursion.
  Future<void> clear() {
    pause();
    _epoch++;
    _worker.dispose();
    _worker = _factory();
    while (_queue.isNotEmpty) {
      _queue.removeFirst().$2.complete();
    }
    _inFlight = false;
    _insertedBlock = null;
    cells = Float64List(0);
    generation = population = elapsedUs = 0;
    error = null;
    title = 'Untitled world';
    _drawnRevision = -1;
    notifyListeners();
    return _enqueue({'command': 'frame'});
  }

  Future<void> randomize({int? seed}) async {
    final reset = clear();
    final epoch = _epoch;
    await reset;
    if (_disposed || epoch != _epoch) return;
    title = 'Random field';
    await _enqueue({
      'command': 'randomize',
      'exponent': _seedExponent,
      'seed': seed,
    });
  }

  Future<void> saveState() => _enqueue({'command': 'save'});
  Future<void> restoreState() {
    pause();
    _insertedBlock = null;
    return _enqueue({'command': 'restore'});
  }

  List<List<int>> _pattern(Block block) => [
    for (var x = 0; x < block.matrixBlock.length; x++)
      for (var y = 0; y < block.matrixBlock[x].length; y++)
        if (block.matrixBlock[x][y]) [x, y],
  ];
  Future<void> loadPattern(Block block) async {
    final reset = clear();
    final epoch = _epoch;
    await reset;
    if (_disposed || epoch != _epoch) return;
    title = block.name;
    await _enqueue({'command': 'load', 'pattern': _pattern(block)});
    if (!_disposed && epoch == _epoch) {
      cameraReset++;
      notifyListeners();
    }
  }

  void enableBlockInsertionMode(Block block) {
    pause();
    _insertedBlock = block;
    notifyListeners();
  }

  void cancelInsertion() {
    _insertedBlock = null;
    notifyListeners();
  }

  Future<void> edit(int x, int y) {
    pause();
    return _enqueue({
      'command': 'edit',
      'x': x,
      'y': y,
      if (_insertedBlock != null) 'pattern': _pattern(_insertedBlock!),
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _timer?.cancel();
    _worker.dispose();
    while (_queue.isNotEmpty) {
      _queue.removeFirst().$2.complete();
    }
    super.dispose();
  }
}
