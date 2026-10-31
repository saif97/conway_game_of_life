import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/view_model/model_board.dart';
import 'sub_block_explorer.dart';
import 'performance_panel.dart';
import 'subscreen_board.dart';

class ScreenHome extends StatelessWidget {
  const ScreenHome({super.key, this.model});
  final ModelBoard? model;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => model ?? ModelBoard(),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 76,
            backgroundColor: const Color(0xFF171C19),
            title: Row(
              children: [
                const Icon(
                  Icons.blur_on_rounded,
                  color: Color(0xFFB8F36D),
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Text(
                  'LIFE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5,
                  ),
                ),
                if (MediaQuery.sizeOf(context).width >= 600)
                  const SizedBox(width: 20),
                if (MediaQuery.sizeOf(context).width >= 600)
                  const Expanded(
                    child: Text(
                      'A cellular playground',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Color(0xFF9BA897)),
                    ),
                  ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Simple rules. Endless possibility.'),
                      content: Text(
                        'A living cell survives with two or three neighbors. An empty cell comes to life with exactly three.\n\nDrag to explore. Scroll or pinch to zoom. Turn on Draw to edit cells, or choose a pattern to place.\n\nPause stops after the current jump. New world cancels a calculation immediately.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Guide'),
                ),
              ),
            ],
          ),
          drawer: compact
              ? const Drawer(width: 292, child: SafeArea(child: _Sidebar()))
              : null,
          body: compact
              ? const SubScreenBoard()
              : const Row(
                  children: [
                    SizedBox(width: 292, child: _Sidebar()),
                    VerticalDivider(width: 1),
                    Expanded(child: SubScreenBoard()),
                  ],
                ),
        );
      },
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Expanded(child: SubBlockExplorer()),
      PerformancePanel(),
    ],
  );
}
