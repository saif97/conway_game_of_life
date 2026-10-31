import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        return _PlaybackShortcuts(
          child: Scaffold(
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
          ),
        );
      },
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.blur_on_rounded, color: lime),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'LIFE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Simple rules. Endless possibility.'),
                      content: Text(
                        'A living cell survives with two or three neighbors. An empty cell comes to life with exactly three.\n\nDrag to explore. Scroll or pinch to zoom. Turn on Draw to edit cells, or choose a pattern to place.\n\nSpace starts or pauses playback.\n\nPause stops after the current jump. New world cancels a calculation immediately.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Guide'),
                ),
              ],
            ),
          ),
          const WorldSummary(),
          const PlaybackControls(),
          SizedBox(
            height: (constraints.maxHeight - 510).clamp(450.0, double.infinity),
            child: const SubBlockExplorer(),
          ),
          const PerformancePanel(),
        ],
      ),
    ),
  );
}

class _PlaybackShortcuts extends StatelessWidget {
  const _PlaybackShortcuts({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: (_, event) {
      if (event.logicalKey != LogicalKeyboardKey.space ||
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isAltPressed ||
          HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isShiftPressed ||
          ModalRoute.of(context)?.isCurrent != true) {
        return KeyEventResult.ignored;
      }
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused != null &&
          (focused.widget is EditableText ||
              focused.findAncestorWidgetOfExactType<EditableText>() != null ||
              focused.findAncestorWidgetOfExactType<Drawer>() != null)) {
        return KeyEventResult.ignored;
      }
      if (event is KeyDownEvent) {
        final model = context.read<ModelBoard>();
        model.isPlaying ? model.pause() : model.play();
      }
      return KeyEventResult.handled;
    },
    child: child,
  );
}
