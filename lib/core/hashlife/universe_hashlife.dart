// Greatly inspired by
// - https://github.com/ngmsoftware's python Implementation https://github.com/ngmsoftware/hashlife/blob/master/hashLife.py

import 'dart:collection';
import 'dart:math';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import 'node.dart';

class HashlifeUniverse {
  late Node _rootNode;
  late Node _initialNode;
  final Map<Node, Node> _memoizedResults = {};

  // hash nodes so I point to them when a node with similar quads is created.
  final Map<Node, Node> _memoizedNodes = {};

  List<int> stats = List.filled(4, 0);

  // number of Game of Life rules calls made in a given generation.
  int _GOL_calls = 0;

  int _generation = 0;
  int _universeExponent;
  late int _universeLength;

  bool isSuperSpeed = true;
  final rand = Random();

  late List<List<Rect>> _rects;

  HashlifeUniverse({int universeExponent = 5, bool randomize = false}) : _universeExponent = universeExponent {
    _universeLength = 1 << universeExponent;
    initUniverse(randomize: randomize);
  }

  void initUniverse({bool randomize = false}) {
    assert(_universeExponent >= 2);
    final worldSize = 1 << _universeExponent;
    _rects = List.generate(
        worldSize,
        (eachRow) => List.generate(
            worldSize,
            (eachCol) => getRect(
                  eachCol,
                  eachRow,
                )));

    _rootNode = getCanonicalOf(_universeExponent, randomize: randomize);
    _initialNode = createOrGetHashed(_rootNode.nw!, _rootNode.ne!, _rootNode.sw!, _rootNode.se!);

    assert(_universeExponent == _rootNode.depth, "World Depth has to equal to the depth of the root node");
    assert(_rects.length == (1 << _universeExponent), "Length of rects has to equal depth of the world");
    assert(_rects.length == _rects[0].length, "rects has to be square.");

    assert(_rootNode == _initialNode);
    assert(_rootNode.hashCode == _initialNode.hashCode);
  }

  Queue<Rect> stepOneGeneration() {
    _updateStats();
    _GOL_calls = 0;
    _rootNode = calCenter(addBorder(_rootNode));

    return plotRootNode();
  }

  // Given the list of Canonical nodes is of size 16 (1 1 1 1), I can get constant time access if I use bit Manipulation.
  // if nw node is alive, or  1 0 0 0 with zero. if ne is alive or it with 0 1 0 0 and so on.
  Node getCanonical(BinaryNode nw, BinaryNode ne, BinaryNode sw, BinaryNode se) =>
      Node.CANONICAL_NODES[0 | (nw.isAlive ? 0x08 : 0) | (ne.isAlive ? 0x04 : 0) | (sw.isAlive ? 0x02 : 0) | (se.isAlive ? 0x01 : 0)];

  // If the Compiled node is Previously hashed return the hash. Otherwise create a new one.
  // by doing so, only newly seen pointers are created. pointers are a mere recursive pointers to leaf Canonical nodes.
  Node createOrGetHashed(Node nw, Node ne, Node sw, Node se) {
    // assert(nw.depth + 1 <= worldDepth, "Parent node can't have death higher than the world depth.");
    // in case of Canonical
    late Node out;

    // in case of 2x2 node
    if (nw.depth == 0) {
      out = getCanonical(nw as BinaryNode, ne as BinaryNode, sw as BinaryNode, se as BinaryNode);
    } else {
      out = Node.fromQuads(nw, ne, sw, se);
    }
    // If the node is previously cached return it otherwise return the newly created node.
    if (_memoizedNodes.containsKey(out)) {
      return _memoizedNodes[out]!;
    }

    _memoizedNodes[out] = out;

    return out;
  }

  Node getCanonicalOf(int depth, {bool randomize = false}) {
    assert(depth != 0, "Depth can't be zero.");

    // base case
    if (depth == 1) {
      return Node.CANONICAL_NODES[randomize ? rand.nextInt(15) + 1 : 0];
    } else {
      return createOrGetHashed(
        getCanonicalOf(depth - 1, randomize: randomize),
        getCanonicalOf(depth - 1, randomize: randomize),
        getCanonicalOf(depth - 1, randomize: randomize),
        getCanonicalOf(depth - 1, randomize: randomize),
      );
    }
  }

  // given a node add a border around it so it's centered.
  Node addBorder(Node node) {
    assert(node.depth >= 1, "Node can't be binary.");
    late final Node border;
    if (node.depth == 1)
      border = BinaryNode.OFF;
    else
      border = getCanonicalOf(node.depth - 1);

    final resultNW = createOrGetHashed(border, border, border, node.nw!);
    final resultNe = createOrGetHashed(border, border, node.ne!, border);
    final resultSW = createOrGetHashed(border, node.sw!, border, border);
    final resultSE = createOrGetHashed(node.se!, border, border, border);

    return createOrGetHashed(resultNW, resultNe, resultSW, resultSE);
  }

  Node getCenterNode(Node node) {
    assert(node.depth > 1, "Only works on node of depth 2^2 (4x4 grid) ");

    return createOrGetHashed(node.nw!.se!, node.ne!.sw!, node.sw!.ne!, node.se!.nw!);
  }

  List<List<BinaryNode>> applyGoLRulesToAux(List<List<BinaryNode>> auxMatrix) {
    _GOL_calls++;
    final matrixResult = List.generate(6, (eachRow) => List.generate(6, (eachCol) => auxMatrix[eachRow][eachCol]));
    for (var eachRow = 1; eachRow < 5; eachRow++) {
      for (var eachCol = 1; eachCol < 5; eachCol++) {
        // those are the 8 nodes Surrounding (eachRow,eachCol)
        final n1 = auxMatrix[eachRow - 1][eachCol - 1];
        final n2 = auxMatrix[eachRow][eachCol - 1];
        final n3 = auxMatrix[eachRow + 1][eachCol - 1];
        final n4 = auxMatrix[eachRow + 1][eachCol];

        final n5 = auxMatrix[eachRow + 1][eachCol + 1];
        final n6 = auxMatrix[eachRow][eachCol + 1];
        final n7 = auxMatrix[eachRow - 1][eachCol + 1];
        final n8 = auxMatrix[eachRow - 1][eachCol];

        Node isAliveState = auxMatrix[eachRow][eachCol];

        // add the number of alive Neighbors
        final numAliveNeighbors = n1.isAliveAsInt() +
            n2.isAliveAsInt() +
            n3.isAliveAsInt() +
            n4.isAliveAsInt() +
            n5.isAliveAsInt() +
            n6.isAliveAsInt() +
            n7.isAliveAsInt() +
            n8.isAliveAsInt();

        // if under populated or over populated kill the cell.
        if (numAliveNeighbors < 2 || numAliveNeighbors > 3) {
          matrixResult[eachRow][eachCol] = BinaryNode.OFF;
        } else {
          if (numAliveNeighbors == 3) {
            matrixResult[eachRow][eachCol] = BinaryNode.ON;
          }
        }
      }
    }
    return matrixResult;
  }

  // since the list is of size 6X6 we'll have border of size 1 of type BinaryNode.OFF around the node
  List<List<BinaryNode>> getAuxFromNode(Node node) {
    assert(node.depth == 2, "Only works on node of depth 2^2 (4x4 grid) ");
    final auxMatrix = List.generate(6, (_) => List.generate(6, (_) => BinaryNode.OFF));

    auxMatrix[1][1] = (node.nw!.nw)! as BinaryNode;
    auxMatrix[1][2] = (node.nw!.ne)! as BinaryNode;
    auxMatrix[1][3] = (node.ne!.nw)! as BinaryNode;
    auxMatrix[1][4] = (node.ne!.ne)! as BinaryNode;

    auxMatrix[2][1] = (node.nw!.sw)! as BinaryNode;
    auxMatrix[2][2] = (node.nw!.se)! as BinaryNode;
    auxMatrix[2][3] = (node.ne!.sw)! as BinaryNode;
    auxMatrix[2][4] = (node.ne!.se)! as BinaryNode;

    auxMatrix[3][1] = (node.sw!.nw)! as BinaryNode;
    auxMatrix[3][2] = (node.sw!.ne)! as BinaryNode;
    auxMatrix[3][3] = (node.se!.nw)! as BinaryNode;
    auxMatrix[3][4] = (node.se!.ne)! as BinaryNode;

    auxMatrix[4][1] = (node.sw!.sw)! as BinaryNode;
    auxMatrix[4][2] = (node.sw!.se)! as BinaryNode;
    auxMatrix[4][3] = (node.se!.sw)! as BinaryNode;
    auxMatrix[4][4] = (node.se!.se)! as BinaryNode;

    return auxMatrix;
  }

  Node getNodeFromAux(List<List<BinaryNode>> matrix) {
    final nw = createOrGetHashed(
      matrix[1][1],
      matrix[1][2],
      matrix[2][1],
      matrix[2][2],
    );
    final ne = createOrGetHashed(
      matrix[1][3],
      matrix[1][4],
      matrix[2][3],
      matrix[2][4],
    );
    final sw = createOrGetHashed(
      matrix[3][1],
      matrix[3][2],
      matrix[4][1],
      matrix[4][2],
    );
    final se = createOrGetHashed(
      matrix[3][3],
      matrix[3][4],
      matrix[4][3],
      matrix[4][4],
    );

    return createOrGetHashed(nw, ne, sw, se);
  }

  // given a node, process the center result.
  // if the node is of depth 2(4x4), apply Gol rules
  Node calCenter(Node node) {
    assert(node.depth > 1);
    // increment generation if we are processing the top most node (whole universe)
    if (node.depth == _universeExponent) {
      _generation += 2 ^ _universeExponent;
    }

    if (_memoizedResults.containsKey(node)) {
      return _memoizedResults[node]!;
    }
    Node result;
    // when 4X4
    if (node.depth == 2) {
      final aux = getAuxFromNode(node);
      final resultAx = applyGoLRulesToAux(aux);

      result = getCenterNode(getNodeFromAux(resultAx));
    } else {
      final node11 = createOrGetHashed(node.nw!.nw!, node.nw!.ne!, node.nw!.sw!, node.nw!.se!);
      final node21 = createOrGetHashed(node.nw!.sw!, node.nw!.se!, node.sw!.nw!, node.sw!.ne!);
      final node31 = createOrGetHashed(node.sw!.nw!, node.sw!.ne!, node.sw!.sw!, node.sw!.se!);

      final node12 = createOrGetHashed(node.nw!.ne!, node.ne!.nw!, node.nw!.se!, node.ne!.sw!);
      final node22 = createOrGetHashed(node.nw!.se!, node.ne!.sw!, node.sw!.ne!, node.se!.nw!);
      final node32 = createOrGetHashed(node.sw!.ne!, node.se!.nw!, node.sw!.se!, node.se!.sw!);

      final node13 = createOrGetHashed(node.ne!.nw!, node.ne!.ne!, node.ne!.sw!, node.ne!.se!);
      final node23 = createOrGetHashed(node.ne!.sw!, node.ne!.se!, node.se!.nw!, node.se!.ne!);
      final node33 = createOrGetHashed(node.se!.nw!, node.se!.ne!, node.se!.sw!, node.se!.se!);

      // step the auxiliary nodes!

      final res11 = calCenter(node11);
      final res12 = calCenter(node12);
      final res13 = calCenter(node13);
      final res21 = calCenter(node21);
      final res22 = calCenter(node22);
      final res23 = calCenter(node23);
      final res31 = calCenter(node31);
      final res32 = calCenter(node32);
      final res33 = calCenter(node33);

      final Node nw, ne, sw, se;

      if (isSuperSpeed) {
        nw = calCenter(createOrGetHashed(res11, res12, res21, res22));
        ne = calCenter(createOrGetHashed(res12, res13, res22, res23));
        sw = calCenter(createOrGetHashed(res21, res22, res31, res32));
        se = calCenter(createOrGetHashed(res22, res23, res32, res33));
      } else {
        nw = getCenterNode(createOrGetHashed(res11, res12, res21, res22));
        ne = getCenterNode(createOrGetHashed(res12, res13, res22, res23));
        sw = getCenterNode(createOrGetHashed(res21, res22, res31, res32));
        se = getCenterNode(createOrGetHashed(res22, res23, res32, res33));
      }

      result = createOrGetHashed(nw, ne, sw, se);
    }

    _memoizedResults[node] = result;

    return result;
  }

  Queue<Rect> plotRootNode() => plotNode(_rootNode, Offset.zero, Queue());
  // Queue<Rect> plotRootNode() => plotNode(_rootNode, -Offset(pow(2, worldDepth - 2).toDouble(), pow(2, worldDepth - 2).toDouble()), Queue());
  // pos is the Absolute position in the grid this will be used by painter to draw rects.
  // todo: abort if no population in a given node.
  @visibleForTesting
  Queue<Rect> plotNode(Node node, Offset pos, Queue<Rect> queueRects) {
    final depth = node.depth;
    assert(depth > 0);
    assert(pos.dx >= 0 && pos.dy >= 0);
    final BinaryNode nw, ne, sw, se;
    // in case of a single
    if (depth == 1) {
      nw = node.nw! as BinaryNode;
      ne = node.ne! as BinaryNode;
      sw = node.sw! as BinaryNode;
      se = node.se! as BinaryNode;

      // changed the how to access pos to match how flutter dose things. flutter starts 0,0 top left
      // while in the python version it started bottom left.
      if (nw.isAlive) queueRects.add(_rects[pos.dyInt][pos.dxInt]);
      if (ne.isAlive) queueRects.add(_rects[pos.dyInt][pos.dxInt + 1]);
      if (sw.isAlive) queueRects.add(_rects[pos.dyInt + 1][pos.dxInt]);
      if (se.isAlive) queueRects.add(_rects[pos.dyInt + 1][pos.dxInt + 1]);
    } else {
      // in case of nodes with area higher than 2x2 or depth higher than 10
      //
      // recurse to north. will have the same pos since 0,0 is top left.
      plotNode(node.nw!, pos, queueRects);
      // the distance to the middle of the node
      final offsetToMidNode = pow(2, depth - 1).toInt();
      plotNode(node.ne!, pos + OffsetInt.fromInt(offsetToMidNode, 0), queueRects);
      plotNode(node.sw!, pos + OffsetInt.fromInt(0, offsetToMidNode), queueRects);
      plotNode(node.se!, pos + OffsetInt.fromInt(offsetToMidNode, offsetToMidNode), queueRects);
    }
    return queueRects;
  }

  void _updateStats() {
    stats[0] = _rootNode.population;
    stats[1] = _GOL_calls;
    stats[2] = _memoizedNodes.length;
    stats[3] = _memoizedResults.length;
  }

  void resetUniverse() => _rootNode = _initialNode;

  void insertBlock(List<List<bool>> block, Offset mousePosInBoard) {
    final midPos = OffsetInt.fromInt(1 << (_rootNode.depth - 1), 1 << (_rootNode.depth - 1));
    for (var eachRow = 0; eachRow < block.length; eachRow++) {
      for (var eachCol = 0; eachCol < block[eachRow].length; eachCol++) {
        final eachBlockCellState = block[eachRow][eachCol];
        final posInUniverse = OffsetInt.fromInt(eachRow, eachCol) + mousePosInBoard;

        _rootNode = _setCellState(_rootNode, eachBlockCellState, posInUniverse, midPos);
        // _setBit(posInUniverse.dxInt, posInUniverse.dyInt, _rootNode, eachBlockCellState);
      }
    }
  }

  // currently, it's log N per cell. in an NxN it'll be N^2 log N.
  // todo: performance can be improved by changing a 2x2 at a time.
  Node _setCellState(Node node, bool state, Offset targetPos, Offset midPos) {
    // base case of recursion.
    if (node is BinaryNode) {
      return state ? BinaryNode.ON : BinaryNode.OFF;
    }

    // given a 16x16 node (4x quads of area 8x8), it's mid is 8x8. if I want to recurse to its upper right quad, I need to move 4 steps.
    //  that's depth - 2.
    // in the case when depth = 1, set the offset to 1 otherwise bit shift by -1 which is invalid.
    late final int mid;

    if (node.depth == 1)
      mid = 1;
    // distance from center of this node to center of subnode is
    // one fourth the size of this node.
    else
      mid = 1 << (node.depth - 2);
    Offset newMid;

    // target is up
    if (targetPos.dy < midPos.dy) {
      // is left
      if (targetPos.dx < midPos.dx) {
        // NW
        newMid = OffsetInt.fromInt(midPos.dxInt - mid, midPos.dyInt - mid);
        return createOrGetHashed(_setCellState(node.nw!, state, targetPos, newMid), node.ne!, node.sw!, node.se!);
      } else {
        // NE
        newMid = OffsetInt.fromInt(midPos.dxInt + mid, midPos.dyInt - mid);
        return createOrGetHashed(node.nw!, _setCellState(node.ne!, state, targetPos, newMid), node.sw!, node.se!);
      }
    } else {
      if (targetPos.dx < midPos.dx) {
        // SW
        newMid = OffsetInt.fromInt(midPos.dxInt - mid, midPos.dyInt + mid);
        return createOrGetHashed(node.nw!, node.ne!, _setCellState(node.sw!, state, targetPos, newMid), node.se!);
      } else {
        // SE
        newMid = OffsetInt.fromInt(midPos.dxInt + mid, midPos.dyInt + mid);
        return createOrGetHashed(node.nw!, node.ne!, node.sw!, _setCellState(node.se!, state, targetPos, newMid));
      }
    }
  }

  int get universePopulation => _rootNode.population;
  int get universeExponent => _universeExponent;
  int get universeLength => 1 << universeExponent;
  Map<Node, Node> get memoizedNodes => Map.from(_memoizedNodes);
  Map<Node, Node> get memoizedResults => Map.from(_memoizedResults);

  void setRootNode(Node node) {
    assert(node.depth == _universeExponent, "root node (${node.depth}) & worldDepth ($_universeExponent) has to be the same.");
    _rootNode = node;
  }

  void setUniverseSizeExponent(int newExponent) {
    assert(newExponent >= 3);
    if (newExponent != _universeExponent) {
      _universeExponent = newExponent;
      initUniverse();
    }
  }
}
