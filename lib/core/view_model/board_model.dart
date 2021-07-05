import 'dart:async';
import 'dart:math';

import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';

class BoardModel extends ChangeNotifier {
  final int columns;
  final int rows;
  late Timer _timer;
  // final Queue<Cell> queueCells = Queue();
  late List<List<Cell>> currentMatrixUniverse;
  List<List<Cell>> initialMatrixUniverse;

  BoardModel({required this.columns, required this.rows})
      : initialMatrixUniverse = List.filled(columns, List.filled(rows, Cell(false))) {
    currentMatrixUniverse = initialMatrixUniverse;
  }

  void initBoardRandomly() {
    final randomNumberGenerator = Random();
    initialMatrixUniverse = List.generate(
        columns, (_) => List.generate(rows, (_) => Cell(randomNumberGenerator.nextBool())));
    currentMatrixUniverse = initialMatrixUniverse;
  }

  void play() {
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      updateCells();

      notifyListeners();
    });
  }

  void reset() {
    currentMatrixUniverse = initialMatrixUniverse;
    notifyListeners();
  }

  updateCells() {
    List<List<Cell>> updatedCells = List<List<Cell>>.of(
        currentMatrixUniverse.map((e) => e.map<Cell>((e) => Cell(e.isAlive)).toList()));

    for (int col = 0; col < columns; col++) {
      for (int row = 0; row < rows; row++) {
        int aliveNeighbours = this._getAliveNeighbours(col, row);
        bool isCurrentCellAlive = this.currentMatrixUniverse[col][row].isAlive;

        if (!isCurrentCellAlive && aliveNeighbours == 3) {
          updatedCells[col][row].revive();
        } else if (isCurrentCellAlive && aliveNeighbours != 2 && aliveNeighbours != 3) {
          updatedCells[col][row].die();
        }
      }
    }

    currentMatrixUniverse = updatedCells;
  }

  int _getAliveNeighbours(int col, int row) {
    int aliveNeighbours = 0;
    for (int rowSummand = -1; rowSummand <= 1; rowSummand++) {
      for (int colSummand = -1; colSummand <= 1; colSummand++) {
        final neighbourCellRow = row + rowSummand;
        final neighbourCellColumn = col + colSummand;
        bool isOutOfRange = (neighbourCellRow) < 0 ||
            (neighbourCellRow) > (rows - 1) ||
            (neighbourCellColumn) < 0 ||
            (neighbourCellColumn) > (columns - 1);
        bool isNeighbourCell = rowSummand != 0 || colSummand != 0;

        if (!isOutOfRange &&
            isNeighbourCell &&
            currentMatrixUniverse[neighbourCellColumn][neighbourCellRow].isAlive) {
          aliveNeighbours++;
        }
      }
    }

    return aliveNeighbours;
  }
}
