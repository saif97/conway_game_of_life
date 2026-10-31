import 'dart:math';
import 'dart:typed_data';

import '../hashlife/universe_hashlife.dart';
import '../macrocell.dart';

/// Runs exclusively in a worker/isolate in the application. No Flutter imports.
class WorkerService {
  final universe = HashlifeUniverse();

  Map<String, Object?> handle(Map<String, Object?> message) {
    final watch = Stopwatch()..start();
    switch (message['command']) {
      case 'advance':
        universe.advance(exponent: message['exponent'] as int);
      case 'edit':
        final x = message['x'] as int, y = message['y'] as int;
        final pattern = message['pattern'] as List?;
        if (pattern == null) {
          universe.setCell(x, y, !universe.cellAt(x, y));
        } else {
          for (final cell in pattern.cast<List>()) {
            universe.setCell(x + (cell[0] as int), y + (cell[1] as int), true);
          }
        }
      case 'load':
        universe.clear();
        for (final cell in (message['pattern'] as List).cast<List>()) {
          universe.setCell(cell[0] as int, cell[1] as int, true);
        }
        universe.save();
      case 'loadMacrocell':
        universe.loadTree(parseMacrocell(message['source'] as String));
      case 'randomize':
        final exponent = message['exponent'] as int;
        RangeError.checkValueInInterval(exponent, 3, 9);
        universe.clear(exponent: exponent);
        final random = Random(message['seed'] as int?);
        for (var y = 0; y < 1 << exponent; y++) {
          for (var x = 0; x < 1 << exponent; x++) {
            if (random.nextDouble() < .25) universe.setCell(x, y, true);
          }
        }
        universe.save();
      case 'save':
        universe.save();
      case 'restore':
        universe.restore();
      case 'frame':
        break;
      default:
        throw ArgumentError('Unknown worker command');
    }
    final elapsed = watch.elapsedMicroseconds;
    final view = (message['view'] as List).cast<num>();
    final left = view[0].floor(), top = view[1].floor();
    final right = view[2].ceil(), bottom = view[3].ceil();
    // Match screen resolution, with a safety cap for unusually large views.
    // Aggregation is display-only; preserve density instead of filling sparse
    // subtrees as if every cell in them were alive.
    final detail = max(
      1,
      max(view[4].floor(), (max(right - left, bottom - top) / 2048).ceil()),
    );
    final cells = <double>[];
    universe.visit(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      minimumSize: detail,
      onSquare: (x, y, size, population) => cells.addAll([
        x.toDouble(),
        y.toDouble(),
        size.toDouble(),
        population / (size.toDouble() * size),
      ]),
    );
    return {
      'bounds': [universe.originX, universe.originY, universe.root.size],
      'generation': universe.generation,
      'population': universe.population,
      'elapsedUs': elapsed,
      'nodes': universe.cachedNodes,
      'detail': detail,
      'cells': Float64List.fromList(cells),
    };
  }
}
