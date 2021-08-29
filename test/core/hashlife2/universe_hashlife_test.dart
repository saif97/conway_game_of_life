import 'dart:collection';
import 'dart:math';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:conway_game_of_life/core/hashlife/node.dart';
import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:conway_game_of_life/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Test Instantiating universe", () {
    test("test Init function", () {
      final HashlifeUniverse universe = HashlifeUniverse(3);
      expect(universe.universePopulation , 0);

    });
  });

  group("Testing Hashlife Universe", () {
    test("As nodes Recursively added, depth should reflect that.", () {
      final node = Node.fromQuads(BinaryNode.ON, BinaryNode.OFF, BinaryNode.ON, BinaryNode.ON);
      expect(node.depth, 1);

      final node2 = Node.fromQuads(node, node, node, node);
      expect(node2.depth, 2);
    });
    test("As nodes added, population of a give node should match the number of alive cells in the universe", () {
      final node = Node.fromQuads(BinaryNode.ON, BinaryNode.OFF, BinaryNode.ON, BinaryNode.ON);
      expect(node.population, 3);

      final node2 = Node.fromQuads(node, node, node, node);
      expect(node2.population, 12);
    });
    test("Given a node of depth 1 test if it returns the canonical node pre-defined", () {
      HashlifeUniverse universe = HashlifeUniverse(2);

      final node = universe.getCanonical(BinaryNode.ON, BinaryNode.OFF, BinaryNode.ON, BinaryNode.ON);
      expect(node, Node.CANONICAL_NODES[11]);

      final node2 = universe.getCanonical(BinaryNode.ON, BinaryNode.ON, BinaryNode.ON, BinaryNode.ON);
      expect(node2, Node.CANONICAL_NODES[15]);

      final node3 = universe.getCanonical(BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF);
      expect(node3, Node.CANONICAL_NODES[0]);
    });

    test("Test adding boarder", () {
      HashlifeUniverse universe = HashlifeUniverse(2);
      final node = Node.FromInt(1, 0, 1, 0);
      final match = Node.fromQuads(
        Node.CANONICAL_NODES[1],
        Node.CANONICAL_NODES[0],
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[0],
      );
      final bordered = universe.addBorder(node);
      expect(bordered, match);

      expect(universe.memoizedNodes.length, 4, reason: "3 Canonical, 1 Duplicate (discarded) and 1 the 8x8 cell");
    });
  });

  group("Test create or hash", () {
    test("given a canonical node, test if it returns a canonical node w/o caching it.", () {
      HashlifeUniverse universe = HashlifeUniverse(2);
      final node = universe.createOrGetHashed(BinaryNode.OFF, BinaryNode.ON, BinaryNode.OFF, BinaryNode.OFF);

      expect(node, Node.CANONICAL_NODES[4]);

      // check if the node is cached since it's canonicals aren't in the hash by Default.
      expect(universe.memoizedNodes.length, 1);

      universe.createOrGetHashed(BinaryNode.OFF, BinaryNode.ON, BinaryNode.OFF, BinaryNode.OFF);
      expect(universe.memoizedNodes.length, 1, reason: "The function should return the same node since it's cached.");
    });

    test("given a non-canonical node check if it's cached", () {
      HashlifeUniverse universe = HashlifeUniverse(2);
      // 8x8 node
      final node = universe.createOrGetHashed(
        Node.FromInt(0, 0, 0, 1),
        Node.FromInt(0, 0, 0, 0),
        Node.FromInt(0, 1, 0, 0),
        Node.FromInt(0, 0, 0, 0),
      );

      expect(universe.memoizedNodes.length, 1);
    });

    test("given a empty universe, check if it's properly cached", () {
      HashlifeUniverse universe = HashlifeUniverse(3);
      final node = Node.CANONICAL_NODES[0];
      final bordered8x8 = universe.addBorder(
        universe.addBorder(node),
      );

      expect(universe.memoizedNodes.length, 3, reason: "in an empty universe, only one node per depth has to be cached");
      expect(bordered8x8.depth, 3, reason: "Depth has to be 3. ");
    });

    test("given a node with a > 16X16 , check if it's properly cached", () {
      HashlifeUniverse universe = HashlifeUniverse(5);
      // node size 16x16
      final node = universe.addBorder(universe.addBorder(universe.addBorder(Node.CANONICAL_NODES[0])));
      expect(universe.memoizedNodes.length, 8);

      // create a node of size 32x32
      final hashedNode = universe.createOrGetHashed(node, node, node, node);
      expect(universe.memoizedNodes.length, 9);

      universe.createOrGetHashed(node, node, node, node);
      expect(universe.memoizedNodes.length, 9, reason: "Same subnodes should return the same node w/o hashing");

      final node2 = universe.addBorder(universe.addBorder(universe.addBorder(Node.CANONICAL_NODES[0])));
      expect(universe.memoizedNodes.length, 9, reason: "Same subnodes should return the same node w/o hashing");

      // create a node of size 32x32
      universe.createOrGetHashed(node2, node2, node2, node2);
      expect(universe.memoizedNodes.length, 9);

      final node3 = universe.addBorder(universe.addBorder(universe.addBorder(Node.FromInt(0, 0, 0, 0))));

      universe.createOrGetHashed(node3, node3, node3, node3);
      expect(universe.memoizedNodes.length, 9);
    });
  });

  test("Test get centered", () {
    HashlifeUniverse universe = HashlifeUniverse(2);
    final match = Node.CANONICAL_NODES[15];

    final actual = universe.getCenterNode(universe.addBorder(match));

    expect(actual, match);
  });

  group("test Node to Aux", () {
    test("Test Node to Auxiliary", () {
      HashlifeUniverse universe = HashlifeUniverse(2);
      final node4x4 = universe.addBorder(Node.CANONICAL_NODES[15]);
      final aux = universe.getAuxFromNode(node4x4);

      expect(
        [
          BinaryNode.OFF,
          BinaryNode.OFF,
          BinaryNode.ON,
          BinaryNode.ON,
          BinaryNode.OFF,
          BinaryNode.OFF,
        ],
        aux[2],
      );
    });

    test("Test Node to Auxiliary I shape", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node = Node.fromQuads(
        Node.CANONICAL_NODES[3],
        Node.CANONICAL_NODES[2],
        Node.CANONICAL_NODES[0],
        Node.CANONICAL_NODES[0],
      );

      final aux = universe.getAuxFromNode(node);

      expect([BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF], aux[0]);
      expect([BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF], aux[1]);
      expect([BinaryNode.OFF, BinaryNode.ON, BinaryNode.ON, BinaryNode.ON, BinaryNode.OFF, BinaryNode.OFF], aux[2]);
      expect([BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF], aux[3]);
      expect([BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF], aux[4]);
      expect([BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF, BinaryNode.OFF], aux[5]);
    });
  });

  test("Test auxResultToNode", () {
    final HashlifeUniverse universe = HashlifeUniverse(2);
    final node4x4 = universe.addBorder(Node.CANONICAL_NODES[3]);
    final aux = universe.getAuxFromNode(node4x4);
    final auxResult = universe.applyGoLRulesToAux(aux);
    final actual = universe.getNodeFromAux(auxResult);
    final node = Node.fromQuads(Node.CANONICAL_NODES[0], Node.CANONICAL_NODES[0], Node.CANONICAL_NODES[0], Node.CANONICAL_NODES[0]);
    expect(actual, node);
  });

  // rules are standard no need to test them thoroughly.
  group("Test GoL rules.", () {
    test("test full 4X4 node", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node4x4 = universe.addBorder(Node.CANONICAL_NODES[15]);
      final aux = universe.getAuxFromNode(node4x4);
      final auxResult = universe.applyGoLRulesToAux(aux);

      final actual = universe.getCenterNode(universe.getNodeFromAux(auxResult));
      expect(actual, Node.CANONICAL_NODES[15]);
    });

    test("Test < shape", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node4x4 = universe.addBorder(Node.CANONICAL_NODES[14]);
      final aux = universe.getAuxFromNode(node4x4);
      final auxResult = universe.applyGoLRulesToAux(aux);

      final actual = universe.getCenterNode(universe.getNodeFromAux(auxResult));
      expect(actual, Node.CANONICAL_NODES[15]);
    });
  });

  group("Test calResult function", () {
    test("Test 4 quads goes to empty.", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node = Node.fromQuads(
        Node.CANONICAL_NODES[2],
        Node.CANONICAL_NODES[2],
        Node.CANONICAL_NODES[2],
        Node.CANONICAL_NODES[2],
      );
      final out = universe.calCenter(node);

      expect(out, Node.CANONICAL_NODES[0]);
    });

    test("Test on 4X4 full block", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node = universe.addBorder(Node.CANONICAL_NODES[15]);
      final out = universe.calCenter(node);

      expect(out, Node.CANONICAL_NODES[15]);
    });

    test("Test that an empty universe of depth 3 should only have memResult of size 7.", () {
      final HashlifeUniverse universe = HashlifeUniverse(3);
      final node = Node.fromQuads(
        Node.CANONICAL_NODES[0],
        Node.CANONICAL_NODES[0],
        Node.CANONICAL_NODES[0],
        Node.CANONICAL_NODES[0],
      );
      final out = universe.calCenter(node);

      expect(universe.memoizedResults.length, 1);
      final out2 = universe.calCenter(universe.addBorder(out));
      expect(universe.memoizedResults.length, 1);
    });

    test("Test < shape", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node = universe.addBorder(Node.CANONICAL_NODES[14]);
      final out = universe.calCenter(node);

      expect(out, Node.CANONICAL_NODES[15]);
    });

    test("Test 4X4 full block on a universe of depth 3", () {
      final HashlifeUniverse universe = HashlifeUniverse(3);
      final node = universe.addBorder(universe.addBorder(Node.CANONICAL_NODES[15]));

      final result = universe.calCenter(node);
      final out = universe.getCenterNode(result);
      expect(out, Node.CANONICAL_NODES[15]);
    });

    test("Test that we fun. should use a result calculated previously. This is a bug happening on nodes w/ depth 3 and Higher.", () {
      HashlifeUniverse universe = HashlifeUniverse(5);

      // node size 16x16
      final node = universe.addBorder(universe.addBorder(universe.addBorder(Node.CANONICAL_NODES[0])));

      final r1 = universe.calCenter(universe.createOrGetHashed(node, node, node, node));

      final lenMemoizedNodes1 = universe.memoizedNodes.length;
      final lenMemoizedResults1 = universe.memoizedResults.length;

      final node2 = universe.addBorder(universe.addBorder(universe.addBorder(Node.FromInt(0, 0, 0, 0))));
      final r2 = universe.calCenter(universe.createOrGetHashed(node2, node2, node2, node2));

      final lenMemoizedNodes2 = universe.memoizedNodes.length;
      final lenMemoizedResults2 = universe.memoizedResults.length;
      expect(r1, r2);
      expect(lenMemoizedNodes1, lenMemoizedNodes2);
      expect(lenMemoizedResults1, lenMemoizedResults2);
    });
  });

  group("Test plotNode", () {
    test("Test Plotting a canonical node", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final offsetBy = Offset(pow(2, universe._universeExponent - 2).toDouble(), pow(2, universe._universeExponent - 2).toDouble());

      final node = Node.CANONICAL_NODES[1];
      final q = universe.plotNode(node, OffsetInt.fromInt(0, 0), Queue());
      expect(q, Queue.from([getRect(1, 1, offsetBy: -offsetBy)]));

      final node2 = Node.CANONICAL_NODES[14];
      final q2 = universe.plotNode(node2, OffsetInt.fromInt(0, 0), Queue());
      expect(q2, Queue.from([getRect(0, 0, offsetBy: -offsetBy), getRect(1, 0, offsetBy: -offsetBy), getRect(0, 1, offsetBy: -offsetBy)]));
    });
    test("Test Plotting a 4X4  node", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final offsetBy = Offset(pow(2, universe._universeExponent - 2).toDouble(), pow(2, universe._universeExponent - 2).toDouble());

      final node = Node.fromQuads(
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[4],
      );
      final q = universe.plotNode(node, OffsetInt.fromInt(0, 0), Queue());

      expect(
          q,
          Queue.from([
            getRect(1, 0, offsetBy: -offsetBy),
            getRect(3, 0, offsetBy: -offsetBy),
            getRect(1, 2, offsetBy: -offsetBy),
            getRect(3, 2, offsetBy: -offsetBy)
          ]));
    });

    test("Test I shape  on a universe of depth 3", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node = Node.fromQuads(
        Node.CANONICAL_NODES[3],
        Node.CANONICAL_NODES[2],
        Node.CANONICAL_NODES[0],
        Node.CANONICAL_NODES[0],
      );

      final aux = universe.getAuxFromNode(node);
      final auxResult = universe.applyGoLRulesToAux(aux);

      final actual = universe.getNodeFromAux(auxResult);
      print(universe.plotNode(actual, OffsetInt.fromInt(0, 0), Queue()));

      // final result = universe.calCenter(node);
      // final out = universe.plotNode(result, OffsetInt.fromInt(0, 0), Queue());
      // print(out);
      // expect(out, Node.CANONICAL_NODES[15]);
    });
  });

  group("Test Block Insertion", () {
    test("Test Inserting full 2x2 block into an empty universe", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);

      const block = [
        [true, true],
        [true, true]
      ];

      universe.insertBlock(block, OffsetInt.fromInt(1, 1));
      print(universe.plotRootNode());

      expect(universe.universePopulation, 4);
    });
  });
}
