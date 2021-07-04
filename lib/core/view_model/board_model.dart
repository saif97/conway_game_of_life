import 'dart:collection';

import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';

class BoardModel extends ChangeNotifier {
  final int columns;
  final int rows;

  final Queue<Cell> queueCells = Queue();
  final List<List<Cell>> matrixUniverse;

  BoardModel({required this.columns, required this.rows})
      : matrixUniverse = List.filled(columns, List.filled(rows, Cell(false)));


    
}
