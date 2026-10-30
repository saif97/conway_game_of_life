import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'transport.dart';

SimulationTransport createWorker() => BrowserTransport();

class BrowserTransport implements SimulationTransport {
  BrowserTransport() {
    const wasm = bool.fromEnvironment('dart.tool.dart2wasm');
    final url = Uri.parse(web.document.baseURI)
        .resolve('workers/life_worker_bootstrap.js');
    _worker = web.Worker(
      '$url?wasm=$wasm'.toJS,
      web.WorkerOptions(type: 'module'),
    );
    _worker.onmessage = ((web.MessageEvent event) {
      final object = event.data as JSObject;
      final meta = jsonDecode(
        (object.getProperty('meta'.toJS) as JSString).toDart,
      ) as Map<String, dynamic>;
      if (meta['ready'] == true) {
        _startup.cancel();
        if (!_ready.isCompleted) _ready.complete();
        return;
      }
      if (meta['fatal'] != null) {
        _fail(StateError(meta['fatal'] as String));
        return;
      }
      final pending = _pending.remove(meta.remove('id'));
      if (pending == null) return;
      if (meta['error'] != null) {
        pending.completeError(StateError(meta['error'] as String));
      } else {
        meta['cells'] =
            (object.getProperty('cells'.toJS) as JSFloat64Array).toDart;
        pending.complete(meta);
      }
    }).toJS;
    _worker.onerror = ((web.Event event) {
      _fail(
        StateError('Simulation worker failed. Reload or start a new world.'),
      );
    }).toJS;
    _startup = Timer(const Duration(seconds: 30), () {
      _fail(
        StateError(
          'Worker could not start. Build worker assets with tool/build_web.sh.',
        ),
      );
    });
  }

  late final web.Worker _worker;
  late final Timer _startup;
  final _ready = Completer<void>();
  final _pending = <int, Completer<Map<String, Object?>>>{};
  bool _disposed = false;
  Object? _failure;
  int _id = 0;

  void _fail(Object error) {
    _failure = error;
    _startup.cancel();
    _worker.terminate();
    if (!_ready.isCompleted) _ready.complete();
    for (final pending in _pending.values) {
      pending.completeError(error);
    }
    _pending.clear();
  }

  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) async {
    await _ready.future;
    if (_disposed) throw const WorkerStopped();
    if (_failure != null) throw _failure!;
    final id = _id++;
    final pending = Completer<Map<String, Object?>>();
    _pending[id] = pending;
    _worker.postMessage(jsonEncode({...message, 'id': id}).toJS);
    return pending.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _fail(const WorkerStopped());
  }
}
