import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/macrocell.dart';
import 'package:conway_game_of_life/core/worker/worker_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/reference_life.dart';

const gliderTree = '[M2] (test)\n#R B3/S23\n.*\$..*\$***\$\n4 0 1 0 0\n';

void main() {
  test('M2 quadrant order and coordinates obey independent Life rules', () {
    final u = HashlifeUniverse()..loadTree(parseMacrocell(gliderTree));
    final initial = {(9, 0), (10, 1), (8, 2), (9, 2), (10, 2)};
    expect(u.liveCells(), initial);
    u.advance();
    expect(u.liveCells(), referenceStep(initial));
    u.restore();
    expect(u.generation, 0);
    expect(u.liveCells(), initial);
  });

  test('repeated M2 subtrees stay shared through loading and simulation', () {
    final root = parseMacrocell('[M2]\n*\n4 1 1 1 1\n5 2 2 2 2\n');
    expect(root.nw, same(root.ne));
    expect(root.population, 16);
    final u = HashlifeUniverse()..loadTree(root);
    expect(u.cachedNodes, lessThan(30));
    u.advance();
    expect(u.population, 0);
    u.restore();
    expect(u.population, 16);
  });

  test('worker loads, steps and restores compressed worlds', () {
    final worker = WorkerService();
    const view = [0, 0, 32, 32, 1];
    final loaded = worker.handle({
      'command': 'loadMacrocell',
      'source': gliderTree,
      'view': view,
    });
    expect(loaded['population'], 5);
    final frame = worker.handle({
      'command': 'advance',
      'exponent': 2,
      'view': view,
    });
    expect(frame['generation'], 4);
    expect(worker.universe.liveCells(), {
      (10, 1),
      (11, 2),
      (9, 3),
      (10, 3),
      (11, 3),
    });
    worker.handle({'command': 'restore', 'view': view});
    expect(worker.universe.generation, 0);
    expect(
      () => worker.handle({
        'command': 'loadMacrocell',
        'source': '[M2]\n#R B36/S23\n*',
        'view': view,
      }),
      throwsFormatException,
    );
    expect(worker.universe.population, 5);
  });

  test('invalid references, rules, dimensions and leaves are rejected', () {
    for (final source in [
      '',
      '[M2]',
      '[M2]\n#R WireWorld\n*',
      '[M2]\n*********',
      '[M2]\n\$\$\$\$\$\$\$\$*',
      '[M2]\n*\n4 2 0 0 0',
      '[M2]\n*\n5 1 0 0 0',
      '[M2]\n*\n4 -1 0 0 0',
      '[M2]\n1 1 0 0 0',
      '[M2]\n*\n31 0 0 0 0',
      '[M2]\n*\n*',
      '[M2]\n*\n4 1 0 0 0\n*',
    ]) {
      expect(
        () => parseMacrocell(source),
        throwsFormatException,
        reason: source,
      );
    }
  });
}
