import 'dart:math';

import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/saved_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/reference_life.dart';

HashlifeUniverse seeded(
  Iterable<CellPosition> cells, {
  int cacheLimit = 200000,
}) {
  final universe = HashlifeUniverse(cacheLimit: cacheLimit);
  for (final (x, y) in cells) {
    universe.setCell(x, y, true);
  }
  return universe;
}

const glider = {(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)};

void main() {
  test('empty plane advances exact generation count', () {
    final u = HashlifeUniverse();
    u.advance();
    u.advance(exponent: 20);
    expect(u.generation, 1048577);
    expect(u.population, 0);
  });

  test('all 65,536 4x4 inputs match independent Life rules including births outside', () {
    for (var mask = 0; mask < 65536; mask++) {
      final cells = {
        for (var bit = 0; bit < 16; bit++)
          if ((mask & (1 << bit)) != 0) (bit % 4 - 2, bit ~/ 4 - 2),
      };
      final u = seeded(cells)..advance();
      final expected = referenceStep(cells);
      expect(u.liveCells(), expected, reason: 'mask=$mask');
      expect(u.population, expected.length, reason: 'population mask=$mask');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('block and beehive still lifes survive million-generation jumps', () {
    for (final cells in [
      {(0, 0), (1, 0), (0, 1), (1, 1)},
      {(1, 0), (2, 0), (0, 1), (3, 1), (1, 2), (2, 2)},
    ]) {
      final u = seeded(cells)..advance(exponent: 20);
      expect(u.liveCells(), cells);
    }
  });

  test(
    'blinker oscillates and changing jump sizes never reuses stale results',
    () {
      var expected = {(-1, 0), (0, 0), (1, 0)};
      final u = seeded(expected);
      for (final exponent in [0, 4, 0, 2, 0, 6, 1, 0]) {
        for (var i = 0; i < 1 << exponent; i++) {
          expected = referenceStep(expected);
        }
        u.advance(exponent: exponent);
        expect(u.liveCells(), expected);
      }
    },
  );

  test('glider translates correctly after 2^20 generations', () {
    final u = seeded(glider)..advance(exponent: 20);
    expect(u.liveCells(), {
      for (final (x, y) in glider) (x + 262144, y + 262144),
    });
    expect(u.generation, 1048576);
  });

  test('all edges, corners and negative coordinates preserve evolution', () {
    for (final (dx, dy) in [
      (0, 0),
      (30, 0),
      (0, 30),
      (30, 30),
      (-32, -32),
      (-1025, 1023),
    ]) {
      var expected = {for (final (x, y) in glider) (x + dx, y + dy)};
      final u = seeded(expected);
      for (var i = 0; i < 24; i++) {
        expected = referenceStep(expected);
        u.advance();
        expect(u.liveCells(), expected, reason: 'origin=($dx,$dy), step=$i');
      }
    }
  });

  test(
    'world sizes beyond 32 bits work on both native and JavaScript targets',
    () {
      const far = 1000000000000;
      final cells = {for (final (x, y) in glider) (x + far, y - far)};
      final u = seeded(cells)..advance(exponent: 2);
      expect(u.liveCells(), {for (final (x, y) in cells) (x + 1, y + 1)});
    },
  );

  test(
    'random sparse and dense worlds agree with oracle across mixed jumps',
    () {
      for (var seed = 0; seed < 24; seed++) {
        final random = Random(seed);
        var expected = {
          for (var y = -10; y < 10; y++)
            for (var x = -10; x < 10; x++)
              if (random.nextDouble() < (seed % 3 + 1) * .2) (x, y),
        };
        final u = seeded(expected);
        var generation = 0;
        for (final exponent in [0, 1, 3, 0, 4, 2, 0]) {
          for (var i = 0; i < 1 << exponent; i++) {
            expected = referenceStep(expected);
          }
          generation += 1 << exponent;
          u.advance(exponent: exponent);
          expect(
            u.liveCells(),
            expected,
            reason: 'seed=$seed, generation=$generation',
          );
          expect(u.population, expected.length);
          expect(u.generation, generation);
        }
      }
    },
  );

  test('bundled patterns including the gun and puffer match the oracle', () {
    for (final block in listBlocks) {
      var expected = {
        for (var x = 0; x < block.matrixBlock.length; x++)
          for (var y = 0; y < block.matrixBlock[x].length; y++)
            if (block.matrixBlock[x][y]) (x, y),
      };
      final u = seeded(expected);
      for (var tick = 0; tick < 8; tick++) {
        for (var i = 0; i < 8; i++) {
          expected = referenceStep(expected);
        }
        u.advance(exponent: 3);
        expect(u.liveCells(), expected, reason: '${block.name}, tick=$tick');
      }
    }
  });

  test(
    'edits invalidate affected paths while retaining canonical identity',
    () {
      final u = seeded(glider);
      final original = u.root;
      u.setCell(5, 5, true);
      u.setCell(5, 5, false);
      expect(identical(u.root, original), isTrue);
      u.advance(exponent: 3);
      var expected = u.liveCells()..add((-1, -1));
      u.setCell(-1, -1, true);
      expected = referenceStep(expected);
      u.advance();
      expect(u.liveCells(), expected);
    },
  );

  test(
    'cache collection preserves saved and live roots and future evolution',
    () {
      final u = seeded(glider, cacheLimit: 100);
      u.save();
      u.advance(exponent: 8);
      final future = u.liveCells();
      u.compact();
      expect(u.cachedResults, 0);
      expect(u.liveCells(), future);
      u.advance();
      expect(u.liveCells(), referenceStep(future));
      u.restore();
      expect(u.liveCells(), glider);
      expect(u.generation, 0);
      u.advance(exponent: 8);
      expect(u.liveCells(), future);
      u.clear();
      u.restore();
      expect(u.population, 0);
      expect(u.generation, 0);
    },
  );

  test('viewport traversal culls cells and aggregates subpixel nodes', () {
    final u = seeded({...glider, (1000000, 1000000)});
    final visible = <CellPosition>{};
    u.visit(
      left: 0,
      top: 0,
      right: 3,
      bottom: 3,
      onSquare: (x, y, _) => visible.add((x, y)),
    );
    expect(visible, glider);
    var visits = 0;
    u.visit(
      left: -2000000,
      top: -2000000,
      right: 2000000,
      bottom: 2000000,
      minimumSize: u.root.size,
      onSquare: (_, _, _) => visits++,
    );
    expect(visits, 1);
  });

  test('rejects invalid configuration and jumps', () {
    expect(() => HashlifeUniverse(universeExponent: 1), throwsRangeError);
    expect(() => HashlifeUniverse(cacheLimit: 0), throwsArgumentError);
    final u = HashlifeUniverse();
    expect(() => u.advance(exponent: -1), throwsRangeError);
    expect(() => u.advance(exponent: 21), throwsRangeError);
  });
}
