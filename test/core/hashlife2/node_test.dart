import 'package:conway_game_of_life/core/hashlife/node.dart';
import 'package:conway_game_of_life/core/hashlife/universe_hashlife.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("test Node class", () {
    test("test area", () {
      final node = Node.CANONICAL_NODES[1];
      expect(4, node.area);
      expect(1, node.population);

      final node2 = Node.fromQuads(Node.CANONICAL_NODES[1], Node.CANONICAL_NODES[1], Node.CANONICAL_NODES[1], Node.CANONICAL_NODES[1]);
      expect(16, node2.area);
      expect(4, node2.population);
    });
  });

  test("Test Node of size 2x2 hashing.", () {
    final uni = HashlifeUniverse(3);
    final node1 = Node.FromInt(0, 0, 0, 0);
    final node2 = Node.CANONICAL_NODES[0];
    expect(node1.hashCode, node2.hashCode);
    expect(node1, node2);
  });
  test("Test Node of size 4x4 hashing.", () {
    final uni = HashlifeUniverse(3);
    final node1 = uni.createOrGetHashed(
      Node.CANONICAL_NODES[15],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
    );

    final node2 = uni.createOrGetHashed(
      Node.CANONICAL_NODES[15],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
    );
    expect(node1.hashCode, node2.hashCode);
    expect(node1, node2);
  });

  test("Test node hashing against add border.", () {
    final uni = HashlifeUniverse(3);
    final node1 = uni.addBorder(uni.createOrGetHashed(
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
    ));

    final node2 = uni.addBorder(uni.addBorder(Node.CANONICAL_NODES[0]));
    expect(node1.hashCode, node2.hashCode);
    expect(node1, node2);
  });

  test("Test Node of size 4x4 hashing with different Combination.", () {
    final uni = HashlifeUniverse(3);
    final node1 = uni.createOrGetHashed(
      Node.FromInt(0, 0, 0, 0),
      Node.FromInt(0, 0, 0, 0),
      Node.FromInt(1, 1, 1, 1),
      Node.FromInt(0, 0, 0, 0),
    );
    final node2 = uni.createOrGetHashed(
      Node.CANONICAL_NODES[15],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
      Node.CANONICAL_NODES[0],
    );

    expect(node1.hashCode != node2.hashCode, true);
    expect(node1 != node2, true);
  });
}
