import 'dart:async';
import 'dart:collection';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:conway_game_of_life/core/hashlife/node.dart';
import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/models/block.dart';
import 'package:conway_game_of_life/core/saved_blocks.dart';
import 'package:flutter/material.dart';

class ModelBoard extends ChangeNotifier {
  late int _numOfColumns;
  late int _numOfRows;
  int _universeSizeExponent = 6;
  Timer? _timer;
  int _speedMultiplier = 0;

  // notify listener in itself dosen't trigger the selector to repaint the cells. I've to reasign to a new value.
  Queue<Rect> queueHashlifeCells = Queue();

  late Block _insertedBlock = listBlocks[0];

  late final HashlifeUniverse _hashlifeUniverse;

  bool _isModKeyPressed = false;
  bool _isModeInsertBlock = false;
  @Deprecated("I should pass it as argument to the function insertion.")
  Offset _mousePosInBoard = Offset.zero;

  ModelBoard({bool randomly = true}) {
    _hashlifeUniverse = HashlifeUniverse(_universeSizeExponent, randomize: randomly);

    _numOfColumns = 1 << (_universeSizeExponent);
    _numOfRows = _numOfColumns;
  }

  void testHL() {
    final node = _hashlifeUniverse.addBorder(Node.fromQuads(
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[3],
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

  void initBoard({bool randomly = false}) => _hashlifeUniverse.initUniverse(randomize: randomly);

  void saveState() {
    throw "Unimplemented";

    // _initialMatrixUniverse = _currentMatrixUniverse;
  }

  void restoreState() => _hashlifeUniverse.resetUniverse();

  void pause() {
    _timer?.cancel();
  }

  void confirmBlockInsertion() {
    _hashlifeUniverse.insertBlock(_insertedBlock.matrixBlock, _mousePosInBoard);

    queueHashlifeCells = _hashlifeUniverse.plotRootNode();
    notifyListeners();
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

  bool _isWithinBoard(Offset pos) => pos.dxInt < 0 || pos.dyInt < 0 || pos.dxInt >= _numOfColumns || pos.dyInt >= _numOfRows;

  void saveBlock() {
    throw "Unimplemented";

    // // don't save blocks of size bigger than 10 X 10
    // if (_numOfColumns > 10 && _numOfRows > 10) {
    //   print('Block is too big to save');
    //   return;
    // }

    // final out = _currentMatrixUniverse.map((eachRow) => eachRow.map((eachCell) => eachCell.isAlive).toList()).toList();

    // print(out);
  }

  /*********************
   * GETTERS & SETTERS *
   *********************/

  int get speedMultiplier => _speedMultiplier;
  int get numOfColumns => _numOfColumns;
  int get numOfRows => _numOfRows;
  bool get isModKeyPressed => _isModKeyPressed;

  bool get isModeInsertBlock => _isModeInsertBlock;
  Block get insertedBlock => _insertedBlock;
  Offset get mousePosInBoard => _mousePosInBoard;

  List<int> get stats => _hashlifeUniverse.stats;

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
    throw "Unimplemented";

    // if (_isWithinBoard(newPos)) return;

    // final updatedCell = _currentMatrixUniverse[newPos.dxInt][newPos.dyInt];
    // updatedCell.switchState();
    // // have to re-assign it to new value otherwise selector won't get triggered.
    // if (updatedCell.isAlive)
    // queueAliveCells.add(updatedCell);
    // else
    // queueAliveCells.remove(updatedCell);

    // notifyListeners();
  }
}
