import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:conway_game_of_life/core/worker/worker_service.dart';
import 'package:web/web.dart' as web;

@JS('self')
external web.DedicatedWorkerGlobalScope get workerScope;

void main() {
  final scope = workerScope;
  final service = WorkerService();
  scope.onmessage = ((web.MessageEvent event) {
    final request =
        jsonDecode((event.data as JSString).toDart) as Map<String, dynamic>;
    try {
      final reply = service.handle(request);
      final cells = (reply.remove('cells') as Float64List).toJS;
      final object =
          {
                'meta': jsonEncode({'id': request['id'], ...reply}),
              }.jsify()
              as JSObject;
      object.setProperty('cells'.toJS, cells);
      scope.postMessage(
        object,
        [cells.getProperty<JSArrayBuffer>('buffer'.toJS)].toJS,
      );
    } catch (error) {
      scope.postMessage(
        {
          'meta': jsonEncode({'id': request['id'], 'error': error.toString()}),
        }.jsify(),
      );
    }
  }).toJS;
  scope.postMessage(
    {
      'meta': jsonEncode({'ready': true}),
    }.jsify(),
  );
}
