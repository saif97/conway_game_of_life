// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.

import 'package:fixnum/fixnum.dart';

import 'life_algo.dart';
import 'macrocell.dart';
import 'memoization.dart';

/// A specialized LifeState for the Hashlife algorithm.
class HashlifeState implements LifeState {
  /// The current state is stored by a simple MacroCell, always simplified.
  MacroCell state;

  /// @param state to initialize the HashlifeState
  HashlifeState(MacroCell state) : state = state.simplify();

  /// Initialize the HashlifeState with an array.
  ///
  /// @param array an int array
  HashlifeState.fromArray(List<List<int>> array) : state = Memoization.fromArray(array);

  /// @param other another HashlifeState
  HashlifeState.from(HashlifeState other) : state = other.state;

  /// @return a copy of this HashlifeState
  HashlifeState copy() {
    return HashlifeState(this);
  }

  /// @param x the x coordinate of the cell to get
  /// @param y the y coordinate of the cell to get
  /// @return the state of the cell
  int getCellAt(int x, int y) {
    return state.getCell(x + state.size / 2, y + state.size / 2);
  }

  /// @param x the x coordinate of the cell to get
  /// @param y the y coordinate of the cell to get
  /// @param newState the new state of the cell
  void setCellAt(int x, int y, int newState) {
    state = state.setCell(x + state.size / 2, y + state.size / 2, newState);
  }

  /// @return an array representing the state of the universe
  List<List<int>> toArray() {
    return state.toArray();
  }

  /// @param steps the number of generations forward to evolve to
  void evolve(int steps) {
    final Int32 steps32 = steps;
    int s = 32 - steps32.numberOfLeadingZeros();
    int n = 1 << s;

    //Make sure we can go as far in the future as we want
    for (int i = 0; i <= s; i++) state = state.borderize().borderize();
    //We are using a binary decomposition as state.result(s) works with powers of two
    while (n > 0) {
      if ((steps & n) != 0) {
        state = state.getResultAt(s).borderize();
      }
      n /= 2;
      s--;
    }

    //Delete unnecessary borders introduced by borderize()
    state = state.simplify();
  }
}
