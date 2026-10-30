import 'dart:async';
import 'dart:isolate';

import 'transport.dart';
import 'worker_service.dart';

SimulationTransport createWorker() => IsolateTransport();

void _run(SendPort parent) {
  final inbox = ReceivePort();
  final service = WorkerService();
  parent.send(inbox.sendPort);
  inbox.listen((dynamic value) {
    final message = value as Map<String, Object?>;
    try {
      parent.send({'id': message['id'], ...service.handle(message)});
    } catch (error) {
      parent.send({'id': message['id'], 'error': error.toString()});
    }
  });
}

class IsolateTransport implements SimulationTransport {
  IsolateTransport() {
    _inbox.listen((dynamic value) {
      if (value is SendPort) {
        if (!_ready.isCompleted) _ready.complete(value);
      } else {
        final reply = value as Map<String, Object?>;
        final pending = _pending.remove(reply.remove('id'));
        if (reply['error'] != null) {
          pending?.completeError(StateError(reply['error'] as String));
        } else {
          pending?.complete(reply);
        }
      }
    });
    Isolate.spawn(_run, _inbox.sendPort).then(
      (isolate) {
        if (_disposed) {
          isolate.kill(priority: Isolate.immediate);
        } else {
          _isolate = isolate;
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!_ready.isCompleted) _ready.completeError(error, stack);
      },
    );
  }
  final _inbox = ReceivePort();
  final _ready = Completer<SendPort>();
  final _pending = <int, Completer<Map<String, Object?>>>{};
  Isolate? _isolate;
  bool _disposed = false;
  int _id = 0;

  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) async {
    final port = await _ready.future;
    if (_disposed) throw const WorkerStopped();
    final id = _id++;
    final result = Completer<Map<String, Object?>>();
    _pending[id] = result;
    port.send({...message, 'id': id});
    return result.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _inbox.close();
    // Resolve startup as well as established requests when disposed early.
    if (!_ready.isCompleted) _ready.complete(_inbox.sendPort);
    for (final pending in _pending.values) {
      pending.completeError(const WorkerStopped());
    }
    _pending.clear();
  }
}
