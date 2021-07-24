// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.

import 'macrocell.dart';
import 'memoization.dart';

/// The standard MacroCell, with its four quadrants.
class ComposedCell extends MacroCell {
  /// The array of the four quadrants.
  @override
  final List<MacroCell> quads;

  /// The array of the already computed results.
  late final List<MacroCell?> results;

  /// Builds a ComposedCell out of its four MacroCell.
  /// @param quad the four quadrants of the ComposedCell
  ComposedCell(List<MacroCell> quad)
      : quads = [...quad], // clone the list instead of Referencing it.

        super(quad[0].dim + 1, quad[0].off && quad[1].off && quad[2].off && quad[3].off,
            _calcDensity(quad)) {
    results = List<MacroCell>.filled(dim - 1, null);
  }

  static int _calcDensity(List<MacroCell> quad) {
    assert(quad.length == 4);
    int density = 0;
    for (int i = 0; i < 4; i++) {
      density += quad[i].density;
    }
    return density ~/ 4;
  }

  @override
  bool operator ==(Object o) {
    if (o is! ComposedCell) return false;
    final ComposedCell c = o;
    return quads[0] == c.quads[0] &&
        quads[1] == c.quads[1] &&
        quads[2] == c.quads[2] &&
        quads[3] == c.quads[3];
  }

  @override
  int get hashCode {
    int hashCode = 1;
    for (int i = 0; i < 4; i++) hashCode = 31 * hashCode + quads[i].hashCode;
    return hashCode;
  }

  @override
  MacroCell getQuad(int i) {
    return quads[i];
  }

  /// Computes the result after 2^s steps.
  ///
  /// @param s gives the number of steps to do.
  void calcResult(int s) {
    final List<List<MacroCell?>> nine = List.filled(3, List.filled(3, null));

    for (int i = 0; i < 4; i++) {
      nine[(i / 2) * 2][(i % 2) * 2] = quads[i];
    }
    nine[0][1] = Memoization.get(
        [quads[0].getQuad(1), quads[1].getQuad(0), quads[0].getQuad(3), quads[1].getQuad(2)]);
    nine[1][0] = Memoization.get(
        [quads[0].getQuad(2), quads[0].getQuad(3), quads[2].getQuad(0), quads[2].getQuad(1)]);
    nine[1][2] = Memoization.get(
        [quads[1].getQuad(2), quads[1].getQuad(3), quads[3].getQuad(0), quads[3].getQuad(1)]);
    nine[2][1] = Memoization.get(
        [quads[2].getQuad(1), quads[3].getQuad(0), quads[2].getQuad(3), quads[3].getQuad(2)]);
    nine[1][1] = Memoization.get(
        [quads[0].getQuad(3), quads[1].getQuad(2), quads[2].getQuad(1), quads[3].getQuad(0)]);

    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++) {
        nine[i][j] = nine[i][j]!.getResultAt((s == dim - 2) ? (s - 1) : s);
      }

    List<MacroCell?> four = List.filled(4, null);
    /*List<MacroCell> four = new MacroCell[4];*/
    for (int i = 0; i < 2; i++)
      for (int j = 0; j < 2; j++) {
        int idx = i * 2 + j;
        four[idx] =
            Memoization.get([nine[i][j]!, nine[i][j + 1]!, nine[i + 1][j]!, nine[i + 1][j + 1]!]);
        if (s == dim - 2)
          four[idx] = four[idx]!.result();
        else {
          List<MacroCell?> tmp = List.filled(4, null);
          for (int k = 0; k < 4; k++) tmp[k] = four[idx]!.getQuad(k).getQuad(3 - k);
          four[idx] = Memoization.get(tmp);
        }
      }

    results[s] = Memoization.get(four);
  }

  @override
  MacroCell getResultAt(int s) {
    if (s > dim - 2)
      throw "Can't compute the result at time 2^" + s + " of a MacroCell of dim " + dim;
    if (s < 0) return this;
    if (results[s] == null) calcResult(s);
    return results[s]!;
  }

  @override
  void fillArray(List<List<int>> array, int i, int j) {
    if (off)
      for (int k = 0; k < size; k++) for (int l = 0; l < size; l++) array[i + k][j + l] = 0;
    else
      for (int k = 0; k < 4; k++)
        quads[k].fillArray(array, i + (k / 2) * (size / 2), j + (k % 2) * (size / 2));
  }

  @override
  MacroCell simplify() {
    if (off) return Memoization.empty(1);

    if (dim == 1) return this;

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (j != 3 - i && !quads[i].getQuad(j).off) return this;
      }
    }

    List<MacroCell> newQuad = List.filled(4, null);
    for (int i = 0; i < 4; i++) newQuad[i] = quads[i].getQuad(3 - i);
    return Memoization.get(newQuad).simplify();
  }

  @override
  MacroCell borderize() {
    if (off) return Memoization.empty(dim + 1);
    MacroCell e = Memoization.empty(dim - 1);
    return Memoization.get([
      Memoization.get([e, e, e, quads[0]]),
      Memoization.get([e, e, quads[1], e]),
      Memoization.get([e, quads[2], e, e]),
      Memoization.get([quads[3], e, e, e]),
    ]);
  }

  @override
  int getCell(int x, int y) {
    if (x < 0 || y < 0 || x >= size || y >= size) return 0;
    int halfSize = size / 2;
    int i = x / halfSize, j = y / halfSize;
    return quads[2 * i + j].getCell(x - i * halfSize, y - j * halfSize);
  }

  @override
  MacroCell setCell(int x, int y, int state) {
    int halfSize = size / 2;
    if (x < 0 || y < 0 || x >= size || y >= size)
      return borderize().setCell(x + halfSize, y + halfSize, state);
    int i = x / halfSize, j = y / halfSize;

    List<MacroCell> tmp = List.filled(4, null);
    for (int k = 0; k < 4; k++) tmp[k] = quads[k];
    tmp[2 * i + j] = tmp[2 * i + j].setCell(x - i * halfSize, y - j * halfSize, state);
    return Memoization.get(tmp);
  }
}
