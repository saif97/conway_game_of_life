import 'dart:collection';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:conway_game_of_life/core/hashlife/node.dart';
import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    group("Test create or hash", () {
      test("given a canonical node, test if it returns a canonical node w/o caching it.", () {
        HashlifeUniverse universe = HashlifeUniverse(2);
        final node = universe.createOrgetFromHash(BinaryNode.OFF, BinaryNode.ON, BinaryNode.OFF, BinaryNode.OFF);

        expect(node, Node.CANONICAL_NODES[4]);

        // check if the node is cached since it's canonicals aren't in the hash by Default.
        expect(universe.memoizedNodes.length, 1);

        universe.createOrgetFromHash(BinaryNode.OFF, BinaryNode.ON, BinaryNode.OFF, BinaryNode.OFF);
        expect(universe.memoizedNodes.length, 1, reason: "The function should return the same node since it's cached.");
      });

      test("given a non-canonical node check if it's cached", () {
        HashlifeUniverse universe = HashlifeUniverse(2);
        // 8x8 node
        final node = universe.createOrgetFromHash(
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

  test("Test get centered", () {
    HashlifeUniverse universe = HashlifeUniverse(2);
    final match = Node.CANONICAL_NODES[15];

    final actual = universe.getCenterNode(universe.addBorder(match));

    expect(actual, match);
  });

  test("Test Node to Auxiliary", () {
    HashlifeUniverse universe = HashlifeUniverse(2);
    final node4x4 = universe.addBorder(Node.CANONICAL_NODES[15]);
    universe.addNodeToAux(node4x4);

    expect([
      BinaryNode.OFF,
      BinaryNode.OFF,
      BinaryNode.ON,
      BinaryNode.ON,
      BinaryNode.OFF,
      BinaryNode.OFF,
    ], universe.auxMatrix[2]);
  });

  test("Test auxResultToNode", () {
    final HashlifeUniverse universe = HashlifeUniverse(2);
    final node4x4 = universe.addBorder(Node.CANONICAL_NODES[3]);
    universe.addNodeToAux(node4x4);
    universe.applyGoLRulesToAux();
    final actual = universe.auxResultToNode();
    final node = Node.fromQuads(Node.CANONICAL_NODES[0], Node.CANONICAL_NODES[0], Node.CANONICAL_NODES[0], Node.CANONICAL_NODES[0]);
    expect(actual, node);
  });

  // rules are standard no need to test them thoroughly.
  group("Test GoL rules.", () {
    test("test full 4X4 node", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node4x4 = universe.addBorder(Node.CANONICAL_NODES[15]);
      universe.addNodeToAux(node4x4);
      universe.applyGoLRulesToAux();

      final actual = universe.getCenterNode(universe.auxResultToNode());
      expect(actual, Node.CANONICAL_NODES[15]);
    });

    test("Test < shape", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);
      final node4x4 = universe.addBorder(Node.CANONICAL_NODES[14]);
      universe.addNodeToAux(node4x4);
      universe.applyGoLRulesToAux();

      final actual = universe.getCenterNode(universe.auxResultToNode());
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
  });

  group("Test plotNode", () {
    test("Test Plotting a canonical node", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);

      final node = Node.CANONICAL_NODES[1];
      final q = universe.plotNode(node, OffsetInt.fromInt(0, 0), Queue());
      expect(q, Queue.from([const Offset(1, 1)]));

      final node2 = Node.CANONICAL_NODES[14];
      final q2 = universe.plotNode(node2, OffsetInt.fromInt(0, 0), Queue());
      expect(q2, Queue.from(const [Offset(0, 0), Offset(1, 0), Offset(0, 1)]));
    });
    test("Test Plotting a 4X4  node", () {
      final HashlifeUniverse universe = HashlifeUniverse(2);

      final node = Node.fromQuads(
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[4],
        Node.CANONICAL_NODES[4],
      );
      final q = universe.plotNode(node, OffsetInt.fromInt(0, 0), Queue());

      expect(q, Queue.from(const [Offset(1.0, 0.0), Offset(3.0, 0.0), Offset(1.0, 2.0), Offset(3.0, 2.0)]));
    });
  });
}
