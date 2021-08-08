import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:conway_game_of_life/core/hashlife/node.dart';
import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/models/block.dart';
import 'package:conway_game_of_life/core/models/cell.dart';
import 'package:conway_game_of_life/core/saved_blocks.dart';
import 'package:flutter/material.dart';

class ModelBoard extends ChangeNotifier {
  late int _numOfColumns;
  late int _numOfRows;
  int _universeSizeExponent = 6;
  Timer? _timer;
  int _speedMultiplier = 0;
  // notify listener in itself dosen't trigger the selector to repaint the cells. I've to reasign to a new value.
  final Queue<Cell> queueAliveCells = Queue();
  Queue<Offset> queueHashlifeCells = Queue();
  late List<List<Cell>> _currentMatrixUniverse;
  late List<List<Cell>> _initialMatrixUniverse;

  late Block _insertedBlock = listBlocks[0];

  late final HashlifeUniverse _hashlifeUniverse;

  bool _isModKeyPressed = false;
  bool _isModeInsertBlock = false;
  Offset _mousePosInBoard = Offset.zero;

  ModelBoard({bool randomly = true}) {
    _hashlifeUniverse = HashlifeUniverse(_universeSizeExponent + 1, randomize: randomly);
    // testHL();
    _numOfColumns = pow(2, _universeSizeExponent).toInt();
    _numOfRows = _numOfColumns;

    // initBoard(randomly: randomly);
    // universe = Universe(rows: _numOfRows, cols: _numOfColumns)..randomizeUniverse();
  }

  void testHL() {
    final node = _hashlifeUniverse.addBorder(Node.fromQuads(
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[3],
      // Node.CANONICAL_NODES[2],
      Node.CANONICAL_NODES[0],
    ));
    _hashlifeUniverse.setRootNode(node);
  }

  void play() {
    _timer?.cancel();
    final updateRate = 50 + (speedMultiplier * 10);
    _timer = Timer.periodic(Duration(milliseconds: updateRate), (timer) {
      queueHashlifeCells = _hashlifeUniverse.stepOneGeneration();
      notifyListeners();
    });
  }

  void saveState() {
    _initialMatrixUniverse = _currentMatrixUniverse;
  }

  void restoreState() {
    _currentMatrixUniverse = _initialMatrixUniverse;
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
  }

  void confirmBlockInsertion() {
    for (var eachCol = 0; eachCol < _insertedBlock.cols; eachCol++) {
      for (var eachRow = 0; eachRow < _insertedBlock.rows; eachRow++) {
        final eachBlockCellState = _insertedBlock.matrixBlock[eachCol][eachRow];
        final posInUniverse = OffsetInt.fromInt(eachCol, eachRow) + mousePosInBoard;
        final eachUniverseCell = _currentMatrixUniverse[posInUniverse.dxInt][posInUniverse.dyInt];

        if (eachBlockCellState) {
          eachUniverseCell.revive();
          queueAliveCells.add(eachUniverseCell);
        } else {
          eachUniverseCell.die();
          queueAliveCells.remove(eachUniverseCell);
        }
      }
    }
  }

  void enableBlockInsertionMode(Block block) {
    _isModeInsertBlock = true;
    _insertedBlock = block;
    pause();
  }

  void disableBlockInsertionMode() {
    _isModeInsertBlock = false;
    play();
  }

  /*********************
   * GETTERS & SETTERS *
   *********************/

  List<List<Cell>> get currentMatrixUniverse => _currentMatrixUniverse;
  int get speedMultiplier => _speedMultiplier;
  int get numOfColumns => _numOfColumns;
  int get numOfRows => _numOfRows;
  bool get isModKeyPressed => _isModKeyPressed;

  bool get isModeInsertBlock => _isModeInsertBlock;
  Block get insertedBlock => _insertedBlock;
  Offset get mousePosInBoard => _mousePosInBoard;

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

      notifyListeners();
    }
  }

  set mousePosInBoard(Offset newPos) {
    if (_isWithinBoard(newPos)) return;
    if (_mousePosInBoard == newPos) return;

    _mousePosInBoard = newPos;

    notifyListeners();
  }

  void setDrawPos(Offset newPos) {
    if (_isWithinBoard(newPos)) return;

    final updatedCell = _currentMatrixUniverse[newPos.dxInt][newPos.dyInt];
    updatedCell.switchState();
    // have to re-assign it to new value otherwise selector won't get triggered.
    if (updatedCell.isAlive)
      queueAliveCells.add(updatedCell);
    else
      queueAliveCells.remove(updatedCell);

    notifyListeners();
  }

  bool _isWithinBoard(Offset pos) => pos.dxInt < 0 || pos.dyInt < 0 || pos.dxInt >= _numOfColumns || pos.dyInt >= _numOfRows;

  void saveBlock() {
    // don't save blocks of size bigger than 10 X 10
    if (_numOfColumns > 10 && _numOfRows > 10) {
      print('Block is too big to save');
      return;
    }

    final out = _currentMatrixUniverse.map((eachRow) => eachRow.map((eachCell) => eachCell.isAlive).toList()).toList();

    print(out);
  }

  get getUniverseSizeExponent => this._universeSizeExponent;

  set setUniverseSizeExponent(universeSizeExponent) => this._universeSizeExponent = universeSizeExponent;
}
