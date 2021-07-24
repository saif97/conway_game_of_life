// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.

import 'boolean_cell.dart';
import 'composed_cell.dart';
import 'macrocell.dart';

/// A MacroCell of size 2x2, composed of four BooleanCell.
class FourCell extends ComposedCell {
  // final List<int> quad = int[4];
  late final List<int> quadAsInt;

  /// Builds a FourCell out of its four BooleanCell.
  /// @param quad the four quadrants of the FourCell

  FourCell(List<MacroCell> quad) : super(quad) {
    for (int i = 0; i < 4; i++) quadAsInt[i] = (quad[i] as BooleanCell).v;
  }

  @override
  BooleanCell getQuad(int i) {
    return (quadAsInt[i] == 0) ? BooleanCell.offCell : BooleanCell.onCell;
  }

  @override
  MacroCell getResultAt(int s) {
    throw "Can't compute the result of a FourCell";
  }
}
