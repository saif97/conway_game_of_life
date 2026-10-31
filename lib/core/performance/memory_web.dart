import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'memory_sample.dart';

Future<MemorySample> sampleMemory() async {
  final performance = web.window.performance;
  try {
    if (performance.hasProperty('measureUserAgentSpecificMemory'.toJS).toDart) {
      final result = await performance
          .callMethod<JSPromise<JSObject>>(
            'measureUserAgentSpecificMemory'.toJS,
          )
          .toDart;
      final bytes = (result.getProperty('bytes'.toJS) as JSNumber).toDartDouble;
      return MemorySample(
        bytes.round(),
        'App memory',
        'Browser estimate for this page and its workers; not total browser process RAM. Updated about every 10 seconds.',
      );
    }
  } catch (_) {
    // Permissions and browser isolation policies can deny the optional API.
  }
  try {
    final memory = performance.getProperty<JSAny?>('memory'.toJS);
    if (memory != null) {
      final bytes = (memory as JSObject)
          .getProperty<JSNumber>('usedJSHeapSize'.toJS)
          .toDartDouble;
      return MemorySample(
        bytes.round(),
        'JS heap only',
        'Partial estimate: excludes simulation worker memory, Wasm memory and GPU allocations. Not total RAM.',
      );
    }
  } catch (_) {
    // Unsupported browsers report unavailable rather than an invented value.
  }
  return unavailableMemory;
}
