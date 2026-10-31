import 'package:conway_game_of_life/core/worker/worker_native.dart';
import 'package:conway_game_of_life/core/worker/worker_service.dart';
import 'package:conway_game_of_life/core/worker/transport.dart';
import 'package:flutter_test/flutter_test.dart';

const view = [-10, -10, 50, 50, 1];
const glider = [
  [1, 0],
  [2, 1],
  [0, 2],
  [1, 2],
  [2, 2],
];
void main() {
  test('real isolate owns state, steps, saves and restores', () async {
    final worker = IsolateTransport();
    addTearDown(worker.dispose);
    await worker.request({'command': 'load', 'pattern': glider, 'view': view});
    final result = await worker.request({
      'command': 'advance',
      'exponent': 20,
      'view': view,
    });
    expect(result['generation'], 1048576);
    expect(result['population'], 5);
    expect(result['cells'], isEmpty); // The glider left this viewport.
    final restored = await worker.request({'command': 'restore', 'view': view});
    expect(restored['generation'], 0);
    expect((restored['cells'] as List).length, 15);
  });
  test('worker errors do not silently discard the world', () async {
    final worker = IsolateTransport();
    addTearDown(worker.dispose);
    await worker.request({'command': 'load', 'pattern': glider, 'view': view});
    await expectLater(
      worker.request({'command': 'unknown', 'view': view}),
      throwsStateError,
    );
    expect(
      (await worker.request({'command': 'frame', 'view': view}))['population'],
      5,
    );
  });
  test('dispose during startup settles outstanding requests', () async {
    final worker = IsolateTransport();
    final pending = worker.request({'command': 'frame', 'view': view});
    worker.dispose();
    await expectLater(pending, throwsA(isA<WorkerStopped>()));
  });
  test(
    'large viewport produces bounded display data without changing population',
    () {
      final worker = WorkerService();
      worker.handle({
        'command': 'randomize',
        'exponent': 8,
        'seed': 42,
        'view': view,
      });
      final population = worker.universe.population;
      final frame = worker.handle({
        'command': 'frame',
        'view': [-1000, -1000, 1000, 1000, 1],
      });
      expect((frame['cells'] as List).length, lessThan(200000));
      expect(worker.universe.population, population);
      expect(frame['detail'], greaterThan(1));
    },
  );
}
