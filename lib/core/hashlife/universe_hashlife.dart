import 'dart:collection';
import 'dart:math';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:flutter/material.dart';

import 'node.dart';

class HashlifeUniverse {
  late Node _rootNode;
  final Map<Node, Node> _memoizedResults = {};

  final Map<Node, Node> _memoizedNodes = {};

  // Given a node, we'll lay it out here centered w/ a empty border and apply GoL rules.
  // Made it as a global var not to Overwhelm the Garbage Collector.
  final _auxMatrix = List.generate(6, (_) => List.generate(6, (_) => BinaryNode.OFF));
  // on the first Iteration, the result list should be same as working matrix. otherwise GoL will miss when number of Neighbors =2
  late List<List<BinaryNode>> _auxMatrixResult;

  int _generation = 0;
  final int _worldDepth;
  bool _isFastForward = false;

  final rand = Random();

  HashlifeUniverse(this._worldDepth, {bool randomize = false}) : assert(_worldDepth >= 2) {
    // rootNode = addBorder(addBorder(Node.CANONICAL_NODES[15]));
    _rootNode = getCanonicalOf(_worldDepth, randomize: randomize);
    _auxMatrixResult = _auxMatrix;
  }
  void setRootNode(Node node) {
    assert(node.depth == _worldDepth, "root node (${node.depth}) & worldDepth ($_worldDepth) has to be the same.");
    _rootNode = node;
  }

  Queue<Offset> stepOneGeneration() {
    _rootNode = addBorder(calCenter(_rootNode));

    return plotNode(_rootNode, Offset.zero, Queue());
  }

  // Given the list of Canonical nodes is of size 16 (1 1 1 1), I can get constant time access if I use bit Manipulation.
  // if nw node is alive, or  1 0 0 0 with zero. if ne is alive or it with 0 1 0 0 and so on.
  Node getCanonical(BinaryNode nw, BinaryNode ne, BinaryNode sw, BinaryNode se) =>
      Node.CANONICAL_NODES[0 | (nw.isAlive ? 0x08 : 0) | (ne.isAlive ? 0x04 : 0) | (sw.isAlive ? 0x02 : 0) | (se.isAlive ? 0x01 : 0)];

  // If the Compiled node is Previously hashed return the hash. Otherwise create a new one.
  // by doing so, only newly seen pointers are created. pointers are a mere recursive pointers to leaf Canonical nodes.
  Node createOrgetFromHash(Node nw, Node ne, Node sw, Node se) {
    assert(nw.depth + 1 <= _worldDepth, "Parent node can't have death higher than the world depth.");
    // in case of Canonical
    late Node out;
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
      return Node.fromQuads(
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
    Node border;
    if (node.depth == 1)
      border = BinaryNode.OFF;
    else
      border = getCanonicalOf(node.depth - 1);

    final resultNW = createOrgetFromHash(border, border, border, node.nw!);
    final resultNe = createOrgetFromHash(border, border, node.ne!, border);
    final resultSW = createOrgetFromHash(border, node.sw!, border, border);
    final resultSE = createOrgetFromHash(node.se!, border, border, border);

    return createOrgetFromHash(resultNW, resultNe, resultSW, resultSE);
  }

  Node getCenterNode(Node node) {
    assert(node.depth > 1, "Only works on node of depth 2^2 (4x4 grid) ");

    return createOrgetFromHash(node.nw!.se!, node.ne!.sw!, node.sw!.ne!, node.se!.nw!);
  }

  void applyGoLRulesToAux() {
    for (var eachRow = 1; eachRow < 5; eachRow++) {
      for (var eachCol = 1; eachCol < 5; eachCol++) {
        // those are the 8 nodes Surrounding (eachRow,eachCol)
        final n1 = _auxMatrix[eachRow - 1][eachCol - 1];
        final n2 = _auxMatrix[eachRow][eachCol - 1];
        final n3 = _auxMatrix[eachRow + 1][eachCol - 1];
        final n4 = _auxMatrix[eachRow + 1][eachCol];

        final n5 = _auxMatrix[eachRow + 1][eachCol + 1];
        final n6 = _auxMatrix[eachRow][eachCol + 1];
        final n7 = _auxMatrix[eachRow - 1][eachCol + 1];
        final n8 = _auxMatrix[eachRow - 1][eachCol];

        Node isAliveState = _auxMatrix[eachRow][eachCol];

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
          _auxMatrixResult[eachRow][eachCol] = BinaryNode.OFF;
        } else {
          // "Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction."
          if (numAliveNeighbors == 3) {
            _auxMatrixResult[eachRow][eachCol] = BinaryNode.ON;
          }
        }
      }
    }
  }

  // since the list is of size 6X6 we'll have border of size 1 of type BinaryNode.OFF around the node
  void addNodeToAux(Node node) {
    assert(node.depth == 2, "Only works on node of depth 2^2 (4x4 grid) ");

    _auxMatrix[1][1] = (node.nw!.nw)! as BinaryNode;
    _auxMatrix[1][2] = (node.nw!.ne)! as BinaryNode;
    _auxMatrix[1][3] = (node.ne!.nw)! as BinaryNode;
    _auxMatrix[1][4] = (node.ne!.ne)! as BinaryNode;

    _auxMatrix[2][1] = (node.nw!.sw)! as BinaryNode;
    _auxMatrix[2][2] = (node.nw!.se)! as BinaryNode;
    _auxMatrix[2][3] = (node.ne!.sw)! as BinaryNode;
    _auxMatrix[2][4] = (node.ne!.se)! as BinaryNode;

    _auxMatrix[3][1] = (node.sw!.nw)! as BinaryNode;
    _auxMatrix[3][2] = (node.sw!.ne)! as BinaryNode;
    _auxMatrix[3][3] = (node.se!.nw)! as BinaryNode;
    _auxMatrix[3][4] = (node.se!.ne)! as BinaryNode;

    _auxMatrix[4][1] = (node.sw!.sw)! as BinaryNode;
    _auxMatrix[4][2] = (node.sw!.se)! as BinaryNode;
    _auxMatrix[4][3] = (node.se!.sw)! as BinaryNode;
    _auxMatrix[4][4] = (node.se!.se)! as BinaryNode;
  }

  Node auxResultToNode() {
    final nw = createOrgetFromHash(
      _auxMatrixResult[1][1],
      _auxMatrixResult[1][2],
      _auxMatrixResult[2][1],
      _auxMatrixResult[2][2],
    );
    final ne = createOrgetFromHash(
      _auxMatrixResult[1][3],
      _auxMatrixResult[1][4],
      _auxMatrixResult[2][3],
      _auxMatrixResult[2][4],
    );
    final sw = createOrgetFromHash(
      _auxMatrixResult[3][1],
      _auxMatrixResult[3][2],
      _auxMatrixResult[4][1],
      _auxMatrixResult[4][2],
    );
    final se = createOrgetFromHash(
      _auxMatrixResult[3][3],
      _auxMatrixResult[3][4],
      _auxMatrixResult[4][3],
      _auxMatrixResult[4][4],
    );

    return createOrgetFromHash(nw, ne, sw, se);
  }

  // given a node, process the center result.
  // if the node is of depth 2(4x4), apply Gol rules
  Node calCenter(Node node) {
    assert(node.depth > 1);
    // increment generation if we are processing the top most node (whole universe)
    if (node.depth == _worldDepth) {
      _generation += 2 ^ _worldDepth;
    }

    if (_memoizedResults.containsKey(node)) {
      return _memoizedResults[node]!;
    }
    Node result;
    // when 4X4
    if (node.depth == 2) {
      addNodeToAux(node);
      applyGoLRulesToAux();

      result = getCenterNode(auxResultToNode());
    } else {
      final node11 = createOrgetFromHash(node.nw!.nw!, node.nw!.ne!, node.nw!.sw!, node.nw!.se!);
      final node21 = createOrgetFromHash(node.nw!.sw!, node.nw!.se!, node.sw!.nw!, node.sw!.ne!);
      final node31 = createOrgetFromHash(node.sw!.nw!, node.sw!.ne!, node.sw!.sw!, node.sw!.se!);

      final node12 = createOrgetFromHash(node.nw!.ne!, node.ne!.nw!, node.nw!.se!, node.ne!.sw!);
      final node22 = createOrgetFromHash(node.nw!.se!, node.ne!.sw!, node.sw!.ne!, node.se!.nw!);
      final node32 = createOrgetFromHash(node.sw!.ne!, node.se!.nw!, node.sw!.se!, node.se!.sw!);

      final node13 = createOrgetFromHash(node.ne!.nw!, node.ne!.ne!, node.ne!.sw!, node.ne!.se!);
      final node23 = createOrgetFromHash(node.ne!.sw!, node.ne!.se!, node.se!.nw!, node.se!.ne!);
      final node33 = createOrgetFromHash(node.se!.nw!, node.se!.ne!, node.se!.sw!, node.se!.se!);

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

      if (_isFastForward) {
        nw = calCenter(createOrgetFromHash(res11, res12, res21, res22));
        ne = calCenter(createOrgetFromHash(res12, res13, res22, res23));
        sw = calCenter(createOrgetFromHash(res21, res22, res31, res32));
        se = calCenter(createOrgetFromHash(res22, res23, res32, res33));
      } else {
        nw = getCenterNode(createOrgetFromHash(res11, res12, res21, res22));
        ne = getCenterNode(createOrgetFromHash(res12, res13, res22, res23));
        sw = getCenterNode(createOrgetFromHash(res21, res22, res31, res32));
        se = getCenterNode(createOrgetFromHash(res22, res23, res32, res33));
      }

      result = createOrgetFromHash(nw, ne, sw, se);
    }

    _memoizedResults[node] = result;

    return result;
  }

  // // given a node, assemble a hash of all of its sub nodes recursively.
  // Map<Node, Node> getNodeList(Node node, Map<Node, Node> nodeList) {
  // if (node.area > 0) {
  // if (node.depth == 1) {
  // nodeList[node] = node;
  // } else {
  // if (node.sw!.area > 0) nodeList[node.sw!] = node.sw!;
  // if (node.se!.area > 0) nodeList[node.se!] = node.se!;
  // if (node.nw!.area > 0) nodeList[node.nw!] = node.nw!;
  // if (node.ne!.area > 0) nodeList[node.ne!] = node.ne!;

  // getNodeList(node.sw!, nodeList);
  // getNodeList(node.se!, nodeList);
  // getNodeList(node.nw!, nodeList);
  // getNodeList(node.ne!, nodeList);
  // }
  // }
  // return nodeList;
  // }

  // pos is the Absolute position in the grid this will be used by painter to draw rects.
  // todo: abort if no population in a given node.
  Queue<Offset> plotNode(Node node, Offset pos, Queue<Offset> drawPos) {
    final depth = node.depth;
    assert(depth > 0);
    final BinaryNode nw, ne, sw, se;
    // in case of a single
    if (depth == 1) {
      nw = node.nw! as BinaryNode;
      ne = node.ne! as BinaryNode;
      sw = node.sw! as BinaryNode;
      se = node.se! as BinaryNode;

      // changed the how to access pos to match how flutter dose things. flutter starts 0,0 top left
      // while in the python version it started bottom left.
      if (nw.isAlive) drawPos.add(OffsetInt.fromInt(pos.dxInt, pos.dyInt));
      if (ne.isAlive) drawPos.add(OffsetInt.fromInt(pos.dxInt + 1, pos.dyInt));
      if (sw.isAlive) drawPos.add(OffsetInt.fromInt(pos.dxInt, pos.dyInt + 1));
      if (se.isAlive) drawPos.add(OffsetInt.fromInt(pos.dxInt + 1, pos.dyInt + 1));
    } else {
      // in case of nodes with area higher than 2x2 or depth higher than 10
      //
      // recurse to north. will have the same pos since 0,0 is top left.
      plotNode(node.nw!, pos, drawPos);
      // the distance to the middle of the node
      final offsetToMidNode = pow(2, depth - 1).toInt();
      plotNode(node.ne!, pos + OffsetInt.fromInt(offsetToMidNode, 0), drawPos);
      plotNode(node.sw!, pos + OffsetInt.fromInt(0, offsetToMidNode), drawPos);
      plotNode(node.se!, pos + OffsetInt.fromInt(offsetToMidNode, offsetToMidNode), drawPos);
    }
    return drawPos;
  }

  Map<Node, Node> get memoizedNodes => Map.from(_memoizedNodes);
  List get auxMatrix => List.from(_auxMatrix);
  List get auxMatrixResult => List.from(_auxMatrixResult);
}
