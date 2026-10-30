import 'dart:convert';
import 'dart:math';

import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/saved_blocks.dart';

/// Run with `dart run tool/benchmark.dart`, or compile with `dart compile js`
/// and `dart compile wasm` to measure each target. No rendering is included.
void main() {
  final random = Random(42);
  final workloads = <String, Set<CellPosition>>{
    'glider': {(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)},
    'random-64-density-0.5': {
      for (var y = 0; y < 64; y++)
        for (var x = 0; x < 64; x++)
          if (random.nextBool()) (x, y),
    },
    for (final block in listBlocks)
      block.name: {
        for (var x = 0; x < block.matrixBlock.length; x++)
          for (var y = 0; y < block.matrixBlock[x].length; y++)
            if (block.matrixBlock[x][y]) (x, y),
      },
  };
  for (final entry in workloads.entries) {
    for (final exponent in [0, 8]) {
      final cold = <int>[], warm = <int>[];
      var population = 0;
      for (var sample = 0; sample < 7; sample++) {
        final u = HashlifeUniverse();
        for (final (x, y) in entry.value) {
          u.setCell(x, y, true);
        }
        u.save();
        final watch = Stopwatch()..start();
        u.advance(exponent: exponent);
        watch.stop();
        cold.add(watch.elapsedMicroseconds);
        population = u.population;
        u.restore();
        watch
          ..reset()
          ..start();
        u.advance(exponent: exponent);
        watch.stop();
        warm.add(watch.elapsedMicroseconds);
      }
      cold.sort();
      warm.sort();
      // Machine-readable benchmark output on every compilation target.
      // ignore: avoid_print
      print(
        jsonEncode({
          'workload': entry.key,
          'generations': 1 << exponent,
          'coldMedianUs': cold[3],
          'warmMedianUs': warm[3],
          'population': population,
        }),
      );
    }
  }
}
