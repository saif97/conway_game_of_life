import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/block.dart';
import '../core/saved_blocks.dart';
import '../core/view_model/model_board.dart';

class SubBlockExplorer extends StatefulWidget {
  const SubBlockExplorer({super.key});
  @override
  State<SubBlockExplorer> createState() => _SubBlockExplorerState();
}

class _SubBlockExplorerState extends State<SubBlockExplorer> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final model = context.read<ModelBoard>();
    final blocks = listBlocks
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return ColoredBox(
      color: const Color(0xFF171C19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 26, 24, 8),
            child: Text(
              'PATTERN LIBRARY',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB8F36D),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Start something.',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: Text(
              'Small beginnings. Unexpected futures.',
              style: TextStyle(color: Color(0xFF9BA897), fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Find a pattern',
                prefixIcon: Icon(Icons.search, size: 19),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: blocks.isEmpty
                ? const Center(child: Text('No matching patterns'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: blocks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final block = blocks[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF202720),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF343E32)),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                model.loadPattern(block);
                                if (Scaffold.of(context).isDrawerOpen) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      height: 48,
                                      child: CustomPaint(
                                        painter: PatternPainter(block),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            block.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${block.cols} × ${block.rows} cells',
                                            style: const TextStyle(
                                              color: Color(0xFF9BA897),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.north_east,
                                      size: 16,
                                      color: Color(0xFF9BA897),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  model.enableBlockInsertionMode(block);
                                  if (Scaffold.of(context).isDrawerOpen) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text(
                                  'Place in world',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'CONWAY’S GAME OF LIFE\nB3 / S23 · An expanding universe',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF7F8D7C),
                height: 1.8,
                letterSpacing: .5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  const PatternPainter(this.block);
  final Block block;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / block.cols).clamp(
      0.1,
      size.height / block.rows,
    );
    final offset = Offset(
      (size.width - block.cols * scale) / 2,
      (size.height - block.rows * scale) / 2,
    );
    final paint = Paint()..color = const Color(0xFFB8F36D);
    for (var x = 0; x < block.matrixBlock.length; x++) {
      for (var y = 0; y < block.matrixBlock[x].length; y++) {
        if (block.matrixBlock[x][y]) {
          canvas.drawRect(
            Rect.fromLTWH(
              offset.dx + x * scale,
              offset.dy + y * scale,
              scale * .85,
              scale * .85,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) => oldDelegate.block != block;
}
