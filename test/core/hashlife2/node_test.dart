import 'package:conway_game_of_life/core/hashlife/node.dart';
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
}
