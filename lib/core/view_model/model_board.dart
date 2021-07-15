import 'dart:async';
import 'dart:math';

import 'package:conway_game_of_life/core/models/cell.dart';
import 'package:flutter/material.dart';

class ModelBoard extends ChangeNotifier {
  int _numOfColumns = 100;
  int _numOfRows = 100;
  late Timer _timer;
  int _speedMultiplier = 0;
  // final Queue<Cell> queueAliveCells = Queue();
  late List<List<Cell>> _currentMatrixUniverse;
  late List<List<Cell>> _initialMatrixUniverse;

  Canvas? canvasBoardGrid;

  bool _isModKeyPressed = false;

  ModelBoard({bool randomly = false}) {
    initBoard(randomly: randomly);
  }

  void initBoard({bool randomly = false}) {
    final randomNumberGenerator = Random();
    _initialMatrixUniverse = List.generate(
      _numOfColumns,
      (eachCol) => List.generate(
        _numOfRows,
        (eachRow) {
          final bool isAlive = randomly && randomNumberGenerator.nextBool();
          final newCell = Cell(isAlive, upperLeftX: eachCol, upperLeftY: eachRow);
          // if (isAlive) queueAliveCells.add(newCell);
          return newCell;
        },
      ),
    );
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  void play() {
    final updateRate = 50 + (speedMultiplier * 10);
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

// todo: use pop push instead of creating a new queue instance.
// todo: clean this up
  void updateCells() {
    final List<List<Cell>> updatedCells = List<List<Cell>>.of(_currentMatrixUniverse.map((e) => e
        .map<Cell>((e) => Cell(e.isAlive, upperLeftX: e.upperLeftX, upperLeftY: e.upperLeftY))
        .toList()));

    for (int col = 0; col < _numOfColumns; col++) {
      for (int row = 0; row < _numOfRows; row++) {
        final int aliveNeighbors = _getAliveNeighbors(col, row);
        final bool isCurrentCellAlive = _currentMatrixUniverse[col][row].isAlive;

        if (!isCurrentCellAlive && aliveNeighbors == 3) {
          updatedCells[col][row].revive();
        } else if (isCurrentCellAlive && aliveNeighbors != 2 && aliveNeighbors != 3) {
          updatedCells[col][row].die();
        }
      }
    }

    _currentMatrixUniverse = updatedCells;
  }

// todo: refactor this
  int _getAliveNeighbors(int col, int row) {
    int aliveNeighbours = 0;
    for (int rowSummand = -1; rowSummand <= 1; rowSummand++) {
      for (int colSummand = -1; colSummand <= 1; colSummand++) {
        final neighbourCellRow = row + rowSummand;
        final neighbourCellColumn = col + colSummand;
        final bool isOutOfRange = neighbourCellRow < 0 ||
            neighbourCellRow > (_numOfRows - 1) ||
            neighbourCellColumn < 0 ||
            neighbourCellColumn > (_numOfColumns - 1);
        final bool isNeighbourCell = rowSummand != 0 || colSummand != 0;

        if (!isOutOfRange &&
            isNeighbourCell &&
            _currentMatrixUniverse[neighbourCellColumn][neighbourCellRow].isAlive) {
          aliveNeighbours++;
        }
      }
    }

    return aliveNeighbours;
  }

  List<List<Cell>> get currentMatrixUniverse => _currentMatrixUniverse;
  int get speedMultiplier => _speedMultiplier;
  int get numOfColumns => _numOfColumns;
  int get numOfRows => _numOfRows;
  bool get isModKeyPressed => _isModKeyPressed;

  set speedMultiplier(int newValue) {
    if (newValue != _speedMultiplier) {
      _speedMultiplier = newValue;
      play();
      notifyListeners();
    }
  }

  set isModKeyPressed(bool newValue) {
    if (newValue != _isModKeyPressed) {
      _isModKeyPressed = newValue;
      notifyListeners();
    }
  }

  void setBoardSize(int cols, int rows) {
    if (cols != _numOfColumns || rows != _numOfRows) {
      _numOfColumns = cols;
      _numOfRows = rows;

      initBoard(randomly: true);

      notifyListeners();
    }
  }

  void setDrawPos(int x, int y) {
    if (x < 0 || y < 0 || x >= _numOfColumns || y >= _numOfRows) return;

    _currentMatrixUniverse[y][x].switchState();
    notifyListeners();
  }
}
