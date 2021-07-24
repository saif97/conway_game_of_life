// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.

import 'boolean_cell.dart';
import 'composed_cell.dart';
import 'four_cell.dart';
import 'macrocell.dart';
import 'memoization.dart';

/// A MacroCell of size 4x4, composed of four HexaCell.
class HexaCell extends ComposedCell {
  late final List<FourCell> quad;

  /// Builds a HexaCell out of its four FourCell.
  /// @param quad the four quadrants of the HexaCell
  HexaCell(List<MacroCell> quad) : super(quad) {
    quad = List.generate(4, (i) => this.quad[i] = quad[i] as FourCell);
  }

  @override
  void calcResult(int s) {
    assert(s == 0);
    final List<int> count = List.filled(4, 0, growable: false);
    // List<int> count = new int[4];

    count[0] = quad[0].quadAsInt[0] +
        quad[0].quadAsInt[1] +
        quad[1].quadAsInt[0] +
        quad[0].quadAsInt[2] +
        quad[1].quadAsInt[2] +
        quad[2].quadAsInt[0] +
        quad[2].quadAsInt[1] +
        quad[3].quadAsInt[0];
    count[1] = quad[0].quadAsInt[1] +
        quad[1].quadAsInt[0] +
        quad[1].quadAsInt[1] +
        quad[0].quadAsInt[3] +
        quad[1].quadAsInt[3] +
        quad[2].quadAsInt[1] +
        quad[3].quadAsInt[0] +
        quad[3].quadAsInt[1];
    count[2] = quad[0].quadAsInt[2] +
        quad[0].quadAsInt[3] +
        quad[1].quadAsInt[2] +
        quad[2].quadAsInt[0] +
        quad[3].quadAsInt[0] +
        quad[2].quadAsInt[2] +
        quad[2].quadAsInt[3] +
        quad[3].quadAsInt[2];
    count[3] = quad[0].quadAsInt[3] +
        quad[1].quadAsInt[2] +
        quad[1].quadAsInt[3] +
        quad[2].quadAsInt[1] +
        quad[3].quadAsInt[1] +
        quad[2].quadAsInt[3] +
        quad[3].quadAsInt[2] +
        quad[3].quadAsInt[3];

    final List<BooleanCell?> newQuad = List.filled(4, null);
    // List<BooleanCell> newQuad =  BooleanCell[4];

    for (int i = 0; i < 4; i++) {
      if (count[i] < 2 || count[i] > 3)
        newQuad[i] = BooleanCell.offCell;
      else if (count[i] == 3)
        newQuad[i] = BooleanCell.onCell;
      else
        newQuad[i] = quad[i].getQuad(3 - i);
    }
    results[0] = Memoization.get(newQuad);
  }

  @override
  FourCell getQuad(int i) {
    return quad[i];
  }
}
