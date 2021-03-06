// rects are simply rectangle Coordinates used to draw them using Custom Painter.
// here using the col & row iteration will give the rect.
import 'dart:ui';

import 'package:conway_game_of_life/ui/subscreen_board.dart';

Rect getRect(int x, int y, {Offset offsetBy = Offset.zero}) => Rect.fromPoints(
      (Offset(x.toDouble(), y.toDouble()) + offsetBy) * SQUARE_LENGTH,
      (Offset(x.toDouble() + 1, y.toDouble() + 1) + offsetBy) * SQUARE_LENGTH,
    );
