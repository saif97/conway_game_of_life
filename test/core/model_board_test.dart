import 'dart:async';

import 'package:conway_game_of_life/core/models/block.dart';
import 'package:conway_game_of_life/core/saved_blocks.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_worker.dart';

class DelayedWorker extends FakeWorker {
  Completer<Map<String, Object?>>? held;
  Map<String, Object?>? heldMessage;
  bool delay = false;
  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) {
    if (!delay) return super.request(message);
    requests.add(message);
    heldMessage = message;
    held = Completer<Map<String, Object?>>();
    return held!.future;
  }

  void finish() {
    delay = false;
    held!.complete(service.handle(heldMessage!));
  }
}

void main() {
  test(
    'rectangular patterns insert without transposing or erasing neighbors',
    () async {
      final worker = FakeWorker();
      final model = ModelBoard(workerFactory: () => worker, demo: false);
      addTearDown(model.dispose);
      await model.ready;
      await model.edit(11, 20);
      model.enableBlockInsertionMode(
        const Block(
          name: 'Asymmetric',
          cols: 2,
          rows: 3,
          matrixBlock: [
            [true, false, true],
            [false, true, false],
          ],
        ),
      );
      await model.edit(10, 20);
      expect(worker.service.universe.liveCells(), {
        (10, 20),
        (10, 22),
        (11, 21),
        (11, 20),
      });
      expect(model.population, 4);
    },
  );
  test('step is exactly one generation regardless of playback jump', () async {
    final model = ModelBoard(workerFactory: FakeWorker.new, demo: false);
    addTearDown(model.dispose);
    await model.ready;
    model.jumpExponent = 20;
    await model.step();
    expect(model.generation, 1);
    await model.advance();
    expect(model.generation, 1048577);
  });
  test(
    'randomize is reproducible and snapshot restore retains the seed',
    () async {
      final model = ModelBoard(workerFactory: FakeWorker.new, demo: false);
      addTearDown(model.dispose);
      await model.ready;
      await model.randomize(seed: 42);
      final original = model.cells.toList();
      await model.step();
      await model.restoreState();
      expect(model.cells, original);
      await model.randomize(seed: 42);
      expect(model.cells, original);
    },
  );
  test(
    'clear invalidates late results and starts a fresh worker immediately',
    () async {
      final old = DelayedWorker();
      final workers = [old, FakeWorker()];
      var index = 0;
      final model = ModelBoard(
        workerFactory: () => workers[index++],
        demo: false,
      );
      addTearDown(model.dispose);
      await model.ready;
      old.delay = true;
      final step = model.step();
      await model.clear();
      expect(old.disposed, isTrue);
      old.finish();
      await step;
      expect(model.generation, 0);
      expect(model.population, 0);
      expect(model.isBusy, isFalse);
    },
  );
  test('viewport requests coalesce during a slow simulation', () async {
    final worker = DelayedWorker();
    final model = ModelBoard(workerFactory: () => worker, demo: false);
    addTearDown(model.dispose);
    await model.ready;
    worker.delay = true;
    final operation = model.advance();
    for (var i = 0; i < 100; i++) {
      model.setViewport([i, 0, i + 50, 50, 1]);
    }
    expect(worker.requests.length, 2);
    worker.finish();
    await operation;
    await Future<void>.delayed(Duration.zero);
    expect(worker.requests.length, 3);
    expect(worker.requests.last['view'], [99, 0, 149, 50, 1]);
  });
  testWidgets(
    'playback has backpressure and pause schedules no additional jump',
    (tester) async {
      final worker = DelayedWorker();
      final model = ModelBoard(workerFactory: () => worker, demo: false);
      await tester.pump();
      worker.delay = true;
      model.play();
      await tester.pump(const Duration(seconds: 1));
      expect(worker.requests.length, 2);
      model.pause();
      worker.finish();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(worker.requests.length, 2);
      model.dispose();
    },
  );
  test('worker failure stops playback and new world recovers', () async {
    final broken = DelayedWorker();
    final workers = [broken, FakeWorker()];
    var index = 0;
    final model = ModelBoard(
      workerFactory: () => workers[index++],
      demo: false,
    );
    addTearDown(model.dispose);
    await model.ready;
    broken.delay = true;
    model.play();
    final operation = model.step();
    broken.held!.completeError(StateError('Worker crashed'));
    await operation;
    expect(model.error, contains('Worker crashed'));
    expect(model.isPlaying, isFalse);
    expect(model.isBusy, isFalse);
    await model.clear();
    await model.step();
    expect(model.error, isNull);
    expect(model.generation, 1);
  });
  test('older pattern load cannot replace a newer selection', () async {
    final workers = <FakeWorker>[];
    final model = ModelBoard(
      workerFactory: () {
        final worker = workers.isEmpty
            ? FakeWorker()
            : (DelayedWorker()..delay = true);
        workers.add(worker);
        return worker;
      },
      demo: false,
    );
    addTearDown(model.dispose);
    await model.ready;
    final first = model.loadPattern(listBlocks[1]);
    final second = model.loadPattern(listBlocks.last);
    (workers[1] as DelayedWorker).finish();
    await first;
    (workers[2] as DelayedWorker).finish();
    await second;
    expect(model.title, listBlocks.last.name);
  });
  test(
    'disposing during work ignores late replies and emits no notifications',
    () async {
      final worker = DelayedWorker();
      final model = ModelBoard(workerFactory: () => worker, demo: false);
      await model.ready;
      worker.delay = true;
      final operation = model.step();
      model.dispose();
      worker.finish();
      await operation;
      expect(worker.disposed, isTrue);
    },
  );
}
