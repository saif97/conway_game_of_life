// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.
// All the logic is theirs I just refactored it to work on dart.

import 'hash_life_state.dart';
import 'hashlife_drawer.dart';
import 'life_algo.dart';

/// An implementation of the interface LifeAlgo for the Hashlife algorithm.
class HashlifeAlgo implements LifeAlgo {
  /// The current state of the algorithm, represented by a HashlifeState.
  late HashlifeState s;

  @override
  void setState(LifeState state) {
    if (state is HashlifeState) {
      s = state.copy();
    } else {
      throw "HashlifeAlgo.setState needs a HashlifeState";
    }
  }

  @override
  LifeState getState() {
    return s.copy();
  }

  @override
  LifeDrawer getDrawer() {
    return HashlifeDrawer();
  }

  @override
  void loadFromArray(List<List<int>> array) {
    s = HashlifeState(array);
  }

  @override
  List<List<int>> saveToArray() {
    return s.toArray();
  }

  @override
  int getCellAt(int x, int y) {
    return s.getCellAt(x, y);
  }

  @override
  void setCellAt(int x, int y, int status) {
    s.setCellAt(x, y, status);
  }

  @override
  int toggleCellAt(int x, int y) {
    int state = s.getCellAt(x, y);
    s.setCellAt(x, y, 1 - state);
    return state;
  }

  @override
  void evolve(int steps) {
    s.evolve(steps);
  }
}
