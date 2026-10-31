/// Immutable quadtree contents with a separate memo for the last computed jump.
/// Equality is identity: the universe interns branches.
final class Node {
  const Node.leaf(bool alive)
    : nw = null,
      ne = null,
      sw = null,
      se = null,
      depth = 0,
      size = 1,
      population = alive ? 1 : 0,
      successor = null;

  Node.branch(Node a, Node b, Node c, Node d)
    : assert(a.depth == b.depth && a.depth == c.depth && a.depth == d.depth),
      nw = a,
      ne = b,
      sw = c,
      se = d,
      depth = a.depth + 1,
      size = a.size * 2,
      population = a.population + b.population + c.population + d.population,
      successor = SuccessorMemo();

  final Node? nw, ne, sw, se;
  final int depth;
  final int population;
  // Multiplication avoids JavaScript's 32-bit bitwise shift limit.
  final int size;
  final SuccessorMemo? successor;
}

/// Changing jump sizes may replace a memo, but can never reuse a wrong result.
final class SuccessorMemo {
  int exponent = -1;
  Node? result;
}
