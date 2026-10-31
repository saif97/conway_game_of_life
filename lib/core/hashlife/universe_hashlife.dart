import 'dart:math';

import 'node.dart';
import 'node_table.dart';

typedef CellPosition = (int x, int y);

/// Conway B3/S23 on an expanding, dead-background plane.
///
/// Hash-consing makes node comparisons constant time. Each node remembers its
/// last successor AND jump exponent; changing speed never reuses a wrong result.
final class HashlifeUniverse {
  HashlifeUniverse({int universeExponent = 5, this.cacheLimit = 8000000}) {
    RangeError.checkValueInInterval(universeExponent, 3, 20);
    if (cacheLimit < 1) throw ArgumentError.value(cacheLimit, 'cacheLimit');
    _root = _empty(universeExponent);
    save();
  }

  static const _dead = Node.leaf(false);
  static const _alive = Node.leaf(true);

  /// Soft limit on interned nodes plus populated successor memos, not bytes.
  /// Large circuitry needs millions of entries to reuse work between jumps.
  final int cacheLimit;
  final _nodes = NodeTable();
  int _cachedResults = 0;
  final _empties = <int, Node>{0: _dead};
  late Node _root, _savedRoot;
  int _x = 0, _y = 0, _savedX = 0, _savedY = 0;
  int generation = 0, _savedGeneration = 0;
  int _cacheCollections = 0;
  int _cacheEntriesBeforeLastCollection = 0;

  Node get root => _root;
  int get originX => _x;
  int get originY => _y;
  int get population => _root.population;
  int get cachedNodes => _nodes.length;
  int get cachedResults => _cachedResults;

  /// Automatic collections over this universe's lifetime (excludes load/clear).
  int get cacheCollections => _cacheCollections;
  int get cacheEntriesBeforeLastCollection => _cacheEntriesBeforeLastCollection;

  Node _join(Node a, Node b, Node c, Node d) => _nodes.join(a, b, c, d);

  Node _empty(int depth) {
    final existing = _empties[depth];
    if (existing != null) return existing;
    final child = _empty(depth - 1);
    return _empties[depth] = _join(child, child, child, child);
  }

  Node _center(Node n) => _join(n.nw!.se!, n.ne!.sw!, n.sw!.ne!, n.se!.nw!);

  void _expand() {
    final n = _root;
    final e = _empty(n.depth - 1);
    _root = _join(
      _join(e, e, e, n.nw!),
      _join(e, e, n.ne!, e),
      _join(e, n.sw!, e, e),
      _join(n.se!, e, e, e),
    );
    _x -= n.size ~/ 2;
    _y -= n.size ~/ 2;
  }

  bool cellAt(int x, int y) {
    x -= _x;
    y -= _y;
    var node = _root;
    if (x < 0 || y < 0 || x >= node.size || y >= node.size) return false;
    while (node.depth > 0) {
      final half = node.size ~/ 2;
      node = y < half
          ? (x < half ? node.nw! : node.ne!)
          : (x < half ? node.sw! : node.se!);
      if (x >= half) x -= half;
      if (y >= half) y -= half;
    }
    return node.population != 0;
  }

  void setCell(int x, int y, bool alive) {
    if (cellAt(x, y) == alive) return;
    while (x < _x || y < _y || x >= _x + _root.size || y >= _y + _root.size) {
      _expand();
    }
    _root = _set(_root, x - _x, y - _y, alive);
    _maintainCache();
  }

  Node _set(Node n, int x, int y, bool alive) {
    if (n.depth == 0) return alive ? _alive : _dead;
    final h = n.size ~/ 2;
    if (y < h) {
      return x < h
          ? _join(_set(n.nw!, x, y, alive), n.ne!, n.sw!, n.se!)
          : _join(n.nw!, _set(n.ne!, x - h, y, alive), n.sw!, n.se!);
    }
    return x < h
        ? _join(n.nw!, n.ne!, _set(n.sw!, x, y - h, alive), n.se!)
        : _join(n.nw!, n.ne!, n.sw!, _set(n.se!, x - h, y - h, alive));
  }

  /// Advance exactly 2^exponent generations, preserving activity at every edge.
  void advance({int exponent = 0}) {
    RangeError.checkValueInInterval(exponent, 0, 20);
    if (population != 0) {
      // The central quarter plus a light cone of size/8 fits in the returned
      // central half. Padding also ensures the requested jump is valid.
      while (_root.depth < exponent + 3 ||
          _center(_center(_root)).population != population) {
        _expand();
      }
      final offset = _root.size ~/ 4;
      _root = _successor(_root, exponent);
      _x += offset;
      _y += offset;
    }
    generation += 1 << exponent;
    _maintainCache();
  }

  Node _successor(Node n, int exponent) {
    if (n.population == 0) return _empty(n.depth - 1);
    final memo = n.successor!;
    if (memo.exponent == exponent) return memo.result!;
    if (memo.result == null) _cachedResults++;
    final result = n.depth == 2 ? _base(n) : _computeSuccessor(n, exponent);
    memo.exponent = exponent;
    return memo.result = result;
  }

  Node _computeSuccessor(Node n, int exponent) {
    final a = n.nw!, b = n.ne!, c = n.sw!, d = n.se!;
    final jump = min(exponent, n.depth - 3);
    final r00 = _successor(a, jump);
    final r01 = _successor(_join(a.ne!, b.nw!, a.se!, b.sw!), jump);
    final r02 = _successor(b, jump);
    final r10 = _successor(_join(a.sw!, a.se!, c.nw!, c.ne!), jump);
    final r11 = _successor(_center(n), jump);
    final r12 = _successor(_join(b.sw!, b.se!, d.nw!, d.ne!), jump);
    final r20 = _successor(c, jump);
    final r21 = _successor(_join(c.ne!, d.nw!, c.se!, d.sw!), jump);
    final r22 = _successor(d, jump);
    Node finish(Node a, Node b, Node c, Node d) {
      final joined = _join(a, b, c, d);
      return exponent == n.depth - 2
          ? _successor(joined, jump)
          : _center(joined);
    }

    return _join(
      finish(r00, r01, r10, r11),
      finish(r01, r02, r11, r12),
      finish(r10, r11, r20, r21),
      finish(r11, r12, r21, r22),
    );
  }

  Node _base(Node n) {
    final a = n.nw!, b = n.ne!, c = n.sw!, d = n.se!;
    final bits = [
      a.nw!.population,
      a.ne!.population,
      b.nw!.population,
      b.ne!.population,
      a.sw!.population,
      a.se!.population,
      b.sw!.population,
      b.se!.population,
      c.nw!.population,
      c.ne!.population,
      d.nw!.population,
      d.ne!.population,
      c.sw!.population,
      c.se!.population,
      d.sw!.population,
      d.se!.population,
    ];
    Node next(int i) {
      final count =
          bits[i - 5] +
          bits[i - 4] +
          bits[i - 3] +
          bits[i - 1] +
          bits[i + 1] +
          bits[i + 3] +
          bits[i + 4] +
          bits[i + 5];
      return count == 3 || (count == 2 && bits[i] == 1) ? _alive : _dead;
    }

    return _join(next(5), next(6), next(9), next(10));
  }

  /// Visits occupied squares only, culling before descent. At low zoom, an
  /// occupied subtree becomes one pixel-sized square instead of many cells.
  void visit({
    required int left,
    required int top,
    required int right,
    required int bottom,
    int minimumSize = 1,
    required void Function(int x, int y, int size, int population) onSquare,
  }) {
    void walk(Node n, int x, int y) {
      if (n.population == 0 ||
          x >= right ||
          y >= bottom ||
          x + n.size <= left ||
          y + n.size <= top) {
        return;
      }
      if (n.depth == 0 || n.size <= minimumSize) {
        onSquare(x, y, n.size, n.population);
        return;
      }
      final h = n.size ~/ 2;
      walk(n.nw!, x, y);
      walk(n.ne!, x + h, y);
      walk(n.sw!, x, y + h);
      walk(n.se!, x + h, y + h);
    }

    walk(_root, _x, _y);
  }

  Set<CellPosition> liveCells() {
    final result = <CellPosition>{};
    visit(
      left: _x,
      top: _y,
      right: _x + _root.size,
      bottom: _y + _root.size,
      onSquare: (x, y, _, _) => result.add((x, y)),
    );
    return result;
  }

  void clear({int exponent = 5}) {
    RangeError.checkValueInInterval(exponent, 3, 20);
    _root = _empty(exponent);
    _x = _y = generation = 0;
    save();
    compact();
  }

  void save() {
    _savedRoot = _root;
    _savedX = _x;
    _savedY = _y;
    _savedGeneration = generation;
  }

  /// Install an already compressed pattern, preserving shared subtrees.
  void loadTree(Node root) {
    _root = root;
    _x = _y = generation = 0;
    save();
    compact();
  }

  void restore() {
    _root = _savedRoot;
    _x = _savedX;
    _y = _savedY;
    generation = _savedGeneration;
  }

  void _maintainCache() {
    final entries = _nodes.length + cachedResults;
    if (entries > cacheLimit) {
      _cacheCollections++;
      _cacheEntriesBeforeLastCollection = entries;
      compact();
    }
  }

  /// Drop historical results and re-intern the live and saved DAGs. The limit
  /// is soft: a single advance and reachable state may exceed it.
  void compact() {
    _nodes.clear();
    _cachedResults = 0;
    _empties
      ..clear()
      ..[0] = _dead;
    final visited = <Node, Node>{};
    Node rebuild(Node n) {
      if (n.depth == 0) return n;
      return visited.putIfAbsent(
        n,
        () => _join(
          rebuild(n.nw!),
          rebuild(n.ne!),
          rebuild(n.sw!),
          rebuild(n.se!),
        ),
      );
    }

    _root = rebuild(_root);
    _savedRoot = rebuild(_savedRoot);
  }
}
