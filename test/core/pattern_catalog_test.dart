import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/pattern_catalog.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_worker.dart';
import '../support/reference_life.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'counter playback retains reusable futures between large jumps',
    () async {
      final catalog = await PatternCatalog.load();
      final entry = catalog.patterns.singleWhere(
        (e) => e.id == 'hexadecimal-counter',
      );
      final block = await catalog.loadPattern(entry);
      final universe = HashlifeUniverse()..loadTree(block.tree!);
      for (final population in [299568, 320552]) {
        universe.advance(exponent: 15);
        expect(universe.population, population);
        expect(universe.cachedResults, greaterThan(0));
        expect(universe.cacheCollections, 0);
      }
      expect(universe.generation, 65536);
      universe.restore();
      expect(universe.population, 328591);
      expect(universe.generation, 0);
    },
  );

  test('every catalog asset decodes, has credits, and can seed HashLife', () async {
    final catalog = await PatternCatalog.load();
    expect(catalog.patterns.length, greaterThanOrEqualTo(37));
    for (final entry in catalog.patterns) {
      final block = await catalog.loadPattern(entry);
      expect(block.name, entry.name);
      expect(block.population, greaterThan(0), reason: entry.id);
      expect(entry.source, startsWith('https://'));
      expect(entry.credit, isNotEmpty);
      final universe = HashlifeUniverse();
      if (block.tree != null) {
        universe.loadTree(block.tree!);
        expect(universe.population, block.population, reason: entry.id);
        expect(block.previewPixels(44 / block.rows).length, lessThan(3000));
        continue;
      }
      for (final (x, y) in block.liveCells) {
        expect(x, inInclusiveRange(0, block.cols - 1));
        expect(y, inInclusiveRange(0, block.rows - 1));
        universe.setCell(x, y, true);
      }
      expect(universe.population, block.population, reason: entry.id);
      // Also verify coordinate preservation, including the 31,473-cell circuit.
      final actual = universe.liveCells();
      expect(actual.length, block.population, reason: entry.id);
      expect(
        actual.difference(block.liveCells.toSet()),
        isEmpty,
        reason: entry.id,
      );
    }
  });

  test(
    'published metapixel world loads and restores without flattening',
    () async {
      final catalog = await PatternCatalog.load();
      final entry = catalog.patterns.singleWhere(
        (e) => e.id == 'metapixel-galaxy',
      );
      final block = await catalog.loadPattern(entry);
      expect(block.population, 7408195);
      final workers = <FakeWorker>[];
      final model = ModelBoard(
        workerFactory: () {
          final worker = FakeWorker();
          workers.add(worker);
          return worker;
        },
        demo: false,
      );
      addTearDown(model.dispose);
      await model.ready;
      await model.loadPattern(block);
      expect(model.error, isNull);
      expect(model.population, 7408195);
      expect(model.cameraReset, 1);
      final load = workers.last.requests.singleWhere(
        (m) => m['command'] == 'loadMacrocell',
      );
      expect(load.containsKey('pattern'), isFalse);
      expect(workers.last.service.universe.cachedNodes, lessThan(10000));
      await model.step();
      expect(model.generation, 1);
      await model.restoreState();
      expect(model.generation, 0);
      expect(model.population, 7408195);
    },
  );

  test(
    'downloaded classics have their documented periods and motion',
    () async {
      final catalog = await PatternCatalog.load();
      for (final (id, period, dx, dy) in [
        ('block', 1, 0, 0),
        ('beehive', 1, 0, 0),
        ('loaf', 1, 0, 0),
        ('boat', 1, 0, 0),
        ('tub', 1, 0, 0),
        ('blinker', 2, 0, 0),
        ('toad', 2, 0, 0),
        ('beacon', 2, 0, 0),
        ('pulsar', 3, 0, 0),
        ('pentadecathlon', 15, 0, 0),
        ('glider', 4, -1, -1),
      ]) {
        final block = await catalog.loadPattern(
          catalog.patterns.singleWhere((e) => e.id == id),
        );
        var cells = block.liveCells.toSet();
        for (var i = 0; i < period; i++) {
          cells = referenceStep(cells);
        }
        expect(cells, {
          for (final (x, y) in block.liveCells) (x + dx, y + dy),
        }, reason: id);
      }
    },
  );

  test(
    'large sparse patterns load and place through the board model',
    () async {
      final catalog = await PatternCatalog.load();
      final block = await catalog.loadPattern(
        catalog.patterns.singleWhere((e) => e.id == 'memory-loop'),
      );
      expect(block.cols * block.rows, greaterThan(900000000));
      final workers = <FakeWorker>[];
      final model = ModelBoard(
        workerFactory: () {
          final worker = FakeWorker();
          workers.add(worker);
          return worker;
        },
        demo: false,
      );
      addTearDown(model.dispose);
      await model.ready;
      await model.loadPattern(block);
      expect(model.error, isNull);
      expect(model.population, block.population);
      expect(model.cameraReset, 1);
      model.enableBlockInsertionMode(block);
      await model.edit(-40000, 100);
      expect(model.population, block.population * 2);
      expect(model.error, isNull);
      expect(
        workers.last.service.universe.cellAt(
          block.liveCells.first.$1 - 40000,
          block.liveCells.first.$2 + 100,
        ),
        isTrue,
      );
    },
  );
}
