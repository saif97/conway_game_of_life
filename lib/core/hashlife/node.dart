/// Immutable quadtree node. Equality is identity: the universe interns branches.
final class Node {
  const Node.leaf(bool alive)
    : nw = null,
      ne = null,
      sw = null,
      se = null,
      depth = 0,
      size = 1,
      population = alive ? 1 : 0;

  Node.branch(Node a, Node b, Node c, Node d)
    : assert(a.depth == b.depth && a.depth == c.depth && a.depth == d.depth),
      nw = a,
      ne = b,
      sw = c,
      se = d,
      depth = a.depth + 1,
      size = a.size * 2,
      population = a.population + b.population + c.population + d.population;

  final Node? nw, ne, sw, se;
  final int depth;
  final int population;
  // Multiplication avoids JavaScript's 32-bit bitwise shift limit.
  final int size;
}
