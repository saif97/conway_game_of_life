class Block {
  final String name, des;
  final int rows, cols;
  final List<List<bool>> matrixBlock;

  const Block({
    required this.name,
    required this.rows,
    required this.cols,
    required this.matrixBlock,
    this.des = "",
  });
}
