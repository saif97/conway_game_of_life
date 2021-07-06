import 'dart:async';
import 'dart:math';

import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';

class BoardModel extends ChangeNotifier {
  final int numOfColumns = 50;
  final int numOfRows = 50;
  late Timer _timer;
  int _speedMultiplier = 0;
  // final Queue<Cell> queueCells = Queue();
  late List<List<Cell>> _currentMatrixUniverse;
  late List<List<Cell>> _initialMatrixUniverse;

  bool isModKeyPressed = false;
  Offset _drawPos = Offset.zero;

  BoardModel() {
    _initialMatrixUniverse = List.filled(numOfColumns, List.filled(numOfRows, Cell(false)));
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  void initBoardRandomly() {
    final randomNumberGenerator = Random();
    _initialMatrixUniverse = List.generate(numOfColumns,
        (_) => List.generate(numOfRows, (_) => Cell(randomNumberGenerator.nextBool())));
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  void play() {
    var updateRate = 50 + (speedMultiplier * 10);
    print(updateRate);
    _timer = Timer.periodic(Duration(milliseconds: updateRate), (timer) {
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

    for (int col = 0; col < numOfColumns; col++) {
      for (int row = 0; row < numOfRows; row++) {
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
            (neighbourCellRow) > (numOfRows - 1) ||
            (neighbourCellColumn) < 0 ||
            (neighbourCellColumn) > (numOfColumns - 1);
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

  List<List<Cell>> get currentMatrixUniverse => _currentMatrixUniverse;
  int get speedMultiplier => _speedMultiplier;
  Offset get drawPos => _drawPos;

  set speedMultiplier(int newValue) {
    if (newValue != _speedMultiplier) {
      _speedMultiplier = newValue;
      play();
      notifyListeners();
    }
  }

  void setDrawPos(int x, int y) {
    if (x < 0 || y < 0 || x >= numOfColumns || y >= numOfRows) return;

    _currentMatrixUniverse[y][x].revive();
  }
}
