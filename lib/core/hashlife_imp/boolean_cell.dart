// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.

import 'macrocell.dart';

/// A basic MacroCell of size 1x1, representing a single cell.
class BooleanCell extends MacroCell {
  /// The base on cell.
  static final BooleanCell onCell = BooleanCell._(1);

  /// The base off cell.
  static final BooleanCell offCell = BooleanCell._(0);

  /// 0 = off<br />
  /// 1 = on
  final int v;

  BooleanCell._(int v)
      : v = (v == 0) ? 0 : 1 // anything more than 1 (if by mistake) is set to 1 (on)
        ,
        super(0, v == 0, (v == 0) ? 0 : 255);

  @override
  MacroCell getQuad(int i) {
    throw "Can't get quads of a BooleanCell";
  }

  @override
  MacroCell getResultAt(int s) {
    throw "Can't compute the result of a BooleanCell";
  }

  @override
  void fillArray(List<List<int>> array, int i, int j) {
    array[i][j] = v;
  }

  @override
  MacroCell simplify() {
    throw "Can't simplify a BooleanCell";
  }

  @override
  MacroCell borderize() {
    throw "Can't borderize a BooleanCell";
  }

  @override
  int getCell(int x, int y) {
    return v;
  }

  @override
  MacroCell setCell(int x, int y, int state) {
    if (state == 0) return offCell;
    return onCell;
  }
}
