import 'dart:math';

import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';

import '../test/support/reference_life.dart';

// A Flutter-free target parity check, compiled and executed as both JS and Wasm.
// Repeat the exhaustive local-rule check on the production compilation targets.
void main() {
  void verify(HashlifeUniverse u, Set<CellPosition> expected) {
    final actual = u.liveCells();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw StateError('Target parity failure at generation ${u.generation}');
    }
  }

  for (var mask = 0; mask < 65536; mask++) {
    final cells = {
      for (var bit = 0; bit < 16; bit++)
        if ((mask & (1 << bit)) != 0) (bit % 4 - 2, bit ~/ 4 - 2),
    };
    final u = HashlifeUniverse();
    for (final (x, y) in cells) {
      u.setCell(x, y, true);
    }
    u.advance();
    verify(u, referenceStep(cells));
  }

  for (var seed = 0; seed < 20; seed++) {
    final random = Random(seed);
    var expected = {
      for (var y = -8; y < 8; y++)
        for (var x = -8; x < 8; x++)
          if (random.nextBool()) (x, y),
    };
    final u = HashlifeUniverse();
    for (final (x, y) in expected) {
      u.setCell(x, y, true);
    }
    for (final exponent in [0, 3, 0, 5, 1]) {
      for (var i = 0; i < 1 << exponent; i++) {
        expected = referenceStep(expected);
      }
      u.advance(exponent: exponent);
      verify(u, expected);
    }
  }
  const far = 1000000000000;
  const glider = {(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)};
  final u = HashlifeUniverse();
  for (final (x, y) in glider) {
    u.setCell(far + x, -far + y, true);
  }
  u.advance(exponent: 20);
  verify(u, {
    for (final (x, y) in glider) (far + x + 262144, -far + y + 262144),
  });
  // ignore: avoid_print
  print(
    'Web engine parity passed: 65,536 local patterns, mixed jumps, random seeds, large coordinates, million-generation glider.',
  );
}
