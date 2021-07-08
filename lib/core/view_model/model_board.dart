import 'dart:async';
import 'dart:math';

import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';

class ModelBoard extends ChangeNotifier {
  int _numOfColumns = 50;
  int _numOfRows = 50;
  late Timer _timer;
  int _speedMultiplier = 0;
  // final Queue<Cell> queueAliveCells = Queue();
  late List<List<Cell>> _currentMatrixUniverse;
  late List<List<Cell>> _initialMatrixUniverse;

  bool isModKeyPressed = false;
  Offset _drawPos = Offset.zero;

  ModelBoard({bool randomly = false}) {
    _initialMatrixUniverse = getBoard(randomly: randomly);
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  List<List<Cell>> getBoard({bool randomly = false}) {
    final randomNumberGenerator = Random();
    return List.generate(
      _numOfColumns,
      (eachCol) => List.generate(
        _numOfRows,
        (eachRow) {
          bool isAlive = randomly ? randomNumberGenerator.nextBool() : false;
          final newCell = Cell(isAlive, upperLeftX: eachCol, upperLeftY: eachRow);
          // if (isAlive) queueAliveCells.add(newCell);
          return newCell;
        },
      ),
    );
  }

  void play() {
    var updateRate = 50 + (speedMultiplier * 10);
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

  void randomize() {
    _initialMatrixUniverse = getBoard(randomly: true);
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

// todo: use pop push instead of creating a new queue instance.
// todo: clean this up
  updateCells() {
    List<List<Cell>> updatedCells = List<List<Cell>>.of(_currentMatrixUniverse.map((e) => e
        .map<Cell>((e) => Cell(e.isAlive, upperLeftX: e.upperLeftX, upperLeftY: e.upperLeftY))
        .toList()));

    for (int col = 0; col < _numOfColumns; col++) {
      for (int row = 0; row < _numOfRows; row++) {
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

// todo: refactor this
  int _getAliveNeighbours(int col, int row) {
    int aliveNeighbours = 0;
    for (int rowSummand = -1; rowSummand <= 1; rowSummand++) {
      for (int colSummand = -1; colSummand <= 1; colSummand++) {
        final neighbourCellRow = row + rowSummand;
        final neighbourCellColumn = col + colSummand;
        bool isOutOfRange = (neighbourCellRow) < 0 ||
            (neighbourCellRow) > (_numOfRows - 1) ||
            (neighbourCellColumn) < 0 ||
            (neighbourCellColumn) > (_numOfColumns - 1);
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
  int get numOfColumns => _numOfColumns;
  int get numOfRows => _numOfRows;

  set speedMultiplier(int newValue) {
    if (newValue != _speedMultiplier) {
      _speedMultiplier = newValue;
      play();
      notifyListeners();
    }
  }

  setBoardSize(int cols, int rows) {
    if (cols != _numOfColumns || rows != _numOfRows) {
      _numOfColumns = cols;
      _numOfRows = rows;

      _initialMatrixUniverse = getBoard(randomly: true);
      _currentMatrixUniverse = _initialMatrixUniverse;

      notifyListeners();
    }
  }

  void setDrawPos(int x, int y) {
    if (x < 0 || y < 0 || x >= _numOfColumns || y >= _numOfRows) return;

    _currentMatrixUniverse[y][x].revive();
  }
}
