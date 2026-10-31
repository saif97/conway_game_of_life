import '../hashlife/node.dart';

/// A pattern stored as a small matrix, sparse cells, or a shared macrocell tree.
class Block {
  final String name, des;
  final int rows, cols;
  final List<List<bool>>? _matrix;
  final List<(int, int)>? _cells;
  final Node? tree;
  final String? macrocellSource;

  const Block({
    required this.name,
    required this.rows,
    required this.cols,
    required List<List<bool>> matrixBlock,
    this.des = '',
  }) : _matrix = matrixBlock,
       _cells = null,
       tree = null,
       macrocellSource = null;

  const Block.sparse({
    required this.name,
    required this.rows,
    required this.cols,
    required List<(int, int)> positions,
    this.des = '',
  }) : _cells = positions,
       _matrix = null,
       tree = null,
       macrocellSource = null;

  Block.macrocell({
    required this.name,
    required Node root,
    required String source,
    this.des = '',
  }) : tree = root,
       macrocellSource = source,
       cols = root.size,
       rows = root.size,
       _matrix = null,
       _cells = null;

  Iterable<(int, int)> get liveCells sync* {
    if (tree != null) {
      Iterable<(int, int)> walk(Node n, int x, int y) sync* {
        if (n.population == 0) return;
        if (n.depth == 0) {
          yield (x, y);
          return;
        }
        final h = n.size ~/ 2;
        yield* walk(n.nw!, x, y);
        yield* walk(n.ne!, x + h, y);
        yield* walk(n.sw!, x, y + h);
        yield* walk(n.se!, x + h, y + h);
      }

      yield* walk(tree!, 0, 0);
    } else if (_cells != null) {
      yield* _cells;
    } else {
      final matrix = _matrix!;
      for (var x = 0; x < matrix.length; x++) {
        for (var y = 0; y < matrix[x].length; y++) {
          if (matrix[x][y]) yield (x, y);
        }
      }
    }
  }

  int get population => tree?.population ?? _cells?.length ?? liveCells.length;

  /// Thumbnail traversal stops at a pixel-sized subtree for large worlds.
  Set<(int, int)> previewPixels(double scale) {
    if (tree == null) {
      return {
        for (final (x, y) in liveCells)
          ((x * scale).floor(), (y * scale).floor()),
      };
    }
    final pixels = <(int, int)>{};
    void walk(Node n, int x, int y) {
      if (n.population == 0) return;
      if (n.depth == 0 || n.size * scale <= 1) {
        pixels.add(((x * scale).floor(), (y * scale).floor()));
        return;
      }
      final h = n.size ~/ 2;
      walk(n.nw!, x, y);
      walk(n.ne!, x + h, y);
      walk(n.sw!, x, y + h);
      walk(n.se!, x + h, y + h);
    }

    walk(tree!, 0, 0);
    return pixels;
  }

  /// Compatibility for small matrix consumers. Large patterns stay sparse.
  List<List<bool>> get matrixBlock {
    if (_matrix != null) return _matrix;
    if (cols * rows > 1000000) {
      throw StateError('Use liveCells for large patterns');
    }
    final matrix = List.generate(cols, (_) => List.filled(rows, false));
    for (final (x, y) in liveCells) {
      matrix[x][y] = true;
    }
    return matrix;
  }
}
