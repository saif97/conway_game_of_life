import 'package:conway_game_of_life/ui/subscreen_board.dart';
import 'package:flutter/material.dart';

class Cell {
  final int upperLeftX, upperLeftY;
  final Rect rect; // this is the Coordinates for drawing the squares.
  bool _isAlive;

  // Cell(this._isAlive, );
  Cell(this._isAlive, {required this.upperLeftX, required this.upperLeftY})
      : rect = Rect.fromCenter(
          center: Offset(
            (upperLeftX + 1) * (SQUARE_LENGTH / 2),
            (upperLeftY + 1) * (SQUARE_LENGTH / 2),
          ),
          height: SQUARE_LENGTH,
          width: SQUARE_LENGTH,
        );

  bool get isAlive => _isAlive;
  die() => this._isAlive = false;
  revive() => this._isAlive = true;

  bool operator ==(otherCell) => otherCell is Cell && this.isAlive == otherCell.isAlive;

  int get hashCode => this._isAlive.hashCode;
  @override
  String toString() => (isAlive.toString() + "| X: $upperLeftX, Y:$upperLeftY | rect $rect");
}
