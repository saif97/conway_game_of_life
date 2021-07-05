import 'dart:async';
import 'dart:math';

import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';

class BoardModel extends ChangeNotifier {
  final int columns;
  final int rows;
  late Timer _timer;
  // final Queue<Cell> queueCells = Queue();
  late List<List<Cell>> _currentMatrixUniverse;
  List<List<Cell>> _initialMatrixUniverse;

  BoardModel({required this.columns, required this.rows})
      : _initialMatrixUniverse = List.filled(columns, List.filled(rows, Cell(false))) {
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  void initBoardRandomly() {
    final randomNumberGenerator = Random();
    _initialMatrixUniverse = List.generate(
        columns, (_) => List.generate(rows, (_) => Cell(randomNumberGenerator.nextBool())));
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  void play() {
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      updateCells();

      notifyListeners();
    });
  }

  void reset() {
    _currentMatrixUniverse = _initialMatrixUniverse;
    notifyListeners();
  }

  void pause() {
    _timer.cancel();
  }

  updateCells() {
    List<List<Cell>> updatedCells = List<List<Cell>>.of(
        _currentMatrixUniverse.map((e) => e.map<Cell>((e) => Cell(e.isAlive)).toList()));

    for (int col = 0; col < columns; col++) {
      for (int row = 0; row < rows; row++) {
        int aliveNeighbours = this._getAliveNeighbours(col, row);
        bool isCurrentCellAlive = this._currentMatrixUniverse[col][row].isAlive;

        if (!isCurrentCellAlive && aliveNeighbours == 3) {
          updatedCells[col][row].revive();
        } else if (isCurrentCellAlive && aliveNeighbours != 2 && aliveNeighbours != 3) {
          updatedCells[col][row].die();
        }
      }
    }

    _currentMatrixUniverse = updatedCells;
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
            _currentMatrixUniverse[neighbourCellColumn][neighbourCellRow].isAlive) {
          aliveNeighbours++;
        }
      }
    }

    return aliveNeighbours;
  }

  void dispose() {
    _timer.toString();
  }

  get currentMatrixUniverse => _currentMatrixUniverse;
}
