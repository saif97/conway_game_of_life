/// A pattern stored as either a small legacy matrix or sparse live coordinates.
class Block {
  final String name, des;
  final int rows, cols;
  final List<List<bool>>? _matrix;
  final List<(int, int)>? _cells;

  const Block({
    required this.name,
    required this.rows,
    required this.cols,
    required List<List<bool>> matrixBlock,
    this.des = '',
  }) : _matrix = matrixBlock,
       _cells = null;

  const Block.sparse({
    required this.name,
    required this.rows,
    required this.cols,
    required List<(int, int)> positions,
    this.des = '',
  }) : _cells = positions,
       _matrix = null;

  Iterable<(int, int)> get liveCells sync* {
    if (_cells != null) {
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

  int get population => _cells?.length ?? liveCells.length;

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
