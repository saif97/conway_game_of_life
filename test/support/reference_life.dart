import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';

/// Intentionally simple independent oracle: count all eight neighbors in a map.
Set<CellPosition> referenceStep(Set<CellPosition> cells) {
  final counts = <CellPosition, int>{};
  for (final (x, y) in cells) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        counts.update((x + dx, y + dy), (n) => n + 1, ifAbsent: () => 1);
      }
    }
  }
  return {
    for (final e in counts.entries)
      if (e.value == 3 || (e.value == 2 && cells.contains(e.key))) e.key,
  };
}
