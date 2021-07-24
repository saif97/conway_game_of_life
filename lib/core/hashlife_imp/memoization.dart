// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.


import 'package:fixnum/fixnum.dart';

import 'boolean_cell.dart';
import 'composed_cell.dart';
import 'four_cell.dart';
import 'hex_cell.dart';
import 'macrocell.dart';

// ignore: avoid_classes_with_only_static_members
/// A static class responsible for the memoization of all built MacroCell.
class Memoization {
  static List<MacroCell> _empty = [];
  static final Map<MacroCell, MacroCell> _built = <MacroCell, MacroCell>{};

  /// Builds a MacroCell out of 4 MacroCell.
  /// It first makes sure the MacroCell isn't built yet. Otherwise, it returns the build cell.
  ///
  /// @param quad the four base MacroCell
  /// @return the new MacroCell
  static MacroCell get(List<MacroCell> quad) {
    assert(quad.length == 4 &&
        quad[0].dim == quad[1].dim &&
        quad[1].dim == quad[2].dim &&
        quad[2].dim == quad[3].dim);
    MacroCell m;
    if (quad[0].dim == 0)
      m = FourCell(quad);
    else if (quad[0].dim == 1)
      m = HexaCell(quad);
    else
      m = ComposedCell(quad);
    if (_built.containsKey(m))
      m = _built[m];
    else
      _built[m] = m;

    return m;
  }

  /// Builds an empty MacroCell.
  /// If it has been already built, it returns the previously built cell.
  ///
  /// @param dim the dimension of the empty MacroCell
  /// @return the new empty MacroCell
  static MacroCell empty(int dim) {
    if (dim < 0) throw "The dimension of an empty MacroCell must be at least 0.";

    // _empty.ensureCapacity(dim+1);
    if (_empty.isEmpty) _empty.add(BooleanCell.offCell);

    int todo = dim - _empty.length + 1;
    while (todo-- > 0) {
      final MacroCell e = _empty[dim - todo - 1];
      _empty.add(get([e, e, e, e]));
    }
    return _empty[dim];
  }

  /// Builds a MacroCell out of an int array.
  /// A value of 0 means the cell is off, otherwise it's on.
  ///
  /// @param array the source array
  /// @return the built MacroCell
  static MacroCell fromArray(List<List<int>> array) {
    if (array == null || array.length == 0) return empty(1);
    Int32 h = array.length, w = array[0].length, dim;

    if (h < w)
      dim = 32 - w.numberOfLeadingZeros;
    else
      dim = 32 - w.numberOfLeadingZeros;
    if (dim < 1) dim = 1;
    return fromTab(array, 0, 0, dim);
  }

  /// Builds a MacroCell out of a portion of an int array.
  ///
  /// @param array the source array
  /// @param i the line of the top left cell
  /// @param j the column of the top left cell
  /// @param dim the dimension of the MacroCell to build
  /// @return the built MacroCell
  static MacroCell fromTab(List<List<int>> array, int i, int j, int dim) {
    if (dim == 0) {
      if (i >= array.length || j >= array[i].length || array[i][j] == 0) return BooleanCell.offCell;
      return BooleanCell.onCell;
    }
    int offset = 1 << (dim - 1);
    return get([
      fromTab(array, i, j, dim - 1),
      fromTab(array, i, j + offset, dim - 1),
      fromTab(array, i + offset, j, dim - 1),
      fromTab(array, i + offset, j + offset, dim - 1)
    ]);
  }
}
