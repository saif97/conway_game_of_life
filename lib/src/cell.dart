import 'package:conway_game_of_life/ui/subscreen_board.dart';
import 'package:flutter/material.dart';

class Cell {
  final int upperLeftX, upperLeftY;
  final Rect rect; // this is the Coordinates for drawing the squares.
  bool _isAlive;

  // Cell(this._isAlive, );
  Cell(this._isAlive, {required this.upperLeftX, required this.upperLeftY})
      : rect = getRect(upperLeftX, upperLeftY);

  bool get isAlive => _isAlive;
  die() => this._isAlive = false;
  revive() => this._isAlive = true;

  bool operator ==(otherCell) => otherCell is Cell && this.isAlive == otherCell.isAlive;

  int get hashCode => this._isAlive.hashCode;
  @override
  String toString() => (isAlive.toString() + "| X: $upperLeftX, Y:$upperLeftY | rect $rect");

// rects are simply rectangle Coordinates used to draw them using Custom Painter.
// here using the col & row iteration will give the rect.
  static Rect getRect(x, y) => Rect.fromPoints(
        Offset(x.toDouble(), y.toDouble()) * SQUARE_LENGTH,
        Offset(x.toDouble() + 1, y.toDouble() + 1) * SQUARE_LENGTH,
      );
}
