import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/view_model/model_board.dart';

const lime = Color(0xFFB8F36D);
String number(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

class SubScreenBoard extends StatelessWidget {
  const SubScreenBoard({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _WorldHeader(),
      Expanded(child: LifeViewport()),
      _Controls(),
    ],
  );
}

class _WorldHeader extends StatelessWidget {
  const _WorldHeader();
  @override
  Widget build(BuildContext context) {
    final (title, generation, population, error) = context.select(
      (ModelBoard m) => (m.title, m.generation, m.population, m.error),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF30372F))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR UNIVERSE',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2,
                        color: Color(0xFF9BA897),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _Metric(
                'GENERATION',
                number(generation),
                key: const Key('generation'),
              ),
              const SizedBox(width: 22),
              _Metric(
                'LIVING CELLS',
                number(population),
                key: const Key('population'),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          letterSpacing: 1.1,
          color: Color(0xFF9BA897),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'monospace',
          color: lime,
        ),
      ),
    ],
  );
}

class _Controls extends StatelessWidget {
  const _Controls();
  @override
  Widget build(BuildContext context) {
    final model = context.read<ModelBoard>();
    final (playing, busy, jump, seed, hasError) = context.select(
      (ModelBoard m) => (
        m.isPlaying,
        m.isBusy,
        m.jumpExponent,
        m.seedExponent,
        m.error != null,
      ),
    );
    final disabled = busy || hasError;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF171C19),
        border: Border(top: BorderSide(color: Color(0xFF30372F))),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: hasError
                    ? null
                    : (playing ? model.pause : model.play),
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(playing ? 'Pause' : 'Play'),
              ),
              OutlinedButton.icon(
                onPressed: disabled || playing ? null : model.step,
                icon: const Icon(Icons.skip_next_rounded, size: 17),
                label: const Text('Step'),
              ),
              OutlinedButton.icon(
                onPressed: disabled || playing ? null : model.advance,
                icon: const Icon(Icons.fast_forward_rounded, size: 17),
                label: const Text('Jump'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222922),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'JUMP SIZE',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: Color(0xFF9BA897),
                      ),
                    ),
                    const SizedBox(width: 14),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: jump,
                        isDense: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        items: [
                          for (var i = 0; i <= 20; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(
                                '${number(1 << i)} gen',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) model.jumpExponent = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 4,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: model.clear,
                icon: const Icon(Icons.add_circle_outline, size: 15),
                label: const Text('New world'),
              ),
              TextButton.icon(
                onPressed: disabled ? null : model.randomize,
                icon: const Icon(Icons.casino_outlined, size: 15),
                label: const Text('Randomize'),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: seed,
                  isDense: true,
                  items: [
                    for (var i = 3; i <= 9; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${1 << i}²',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                  onChanged: disabled
                      ? null
                      : (value) {
                          if (value != null) model.seedExponent = value;
                        },
                ),
              ),
              TextButton.icon(
                onPressed: disabled ? null : model.saveState,
                icon: const Icon(Icons.bookmark_border, size: 15),
                label: const Text('Save'),
              ),
              TextButton.icon(
                onPressed: disabled ? null : model.restoreState,
                icon: const Icon(Icons.history, size: 15),
                label: const Text('Restore'),
              ),
            ],
          ),
          _Status(),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (busy, playing, time) = context.select(
      (ModelBoard m) => (m.isBusy, m.isPlaying, m.elapsedUs),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.circle,
          size: 6,
          color: busy || playing ? lime : const Color(0xFF7F8D7C),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            textAlign: TextAlign.center,
            playing
                ? 'Running'
                : busy
                ? 'Finishing current operation · you can keep exploring'
                : 'Paused · take a closer look',
            style: const TextStyle(fontSize: 10, color: Color(0xFF9BA897)),
          ),
        ),
        if (time > 0)
          Text(
            '   /   ${(time / 1000).toStringAsFixed(1)} ms',
            style: const TextStyle(fontSize: 10, color: Color(0xFF7F8D7C)),
          ),
      ],
    );
  }
}

class LifeViewport extends StatefulWidget {
  const LifeViewport({super.key});
  @override
  State<LifeViewport> createState() => _LifeViewportState();
}

class _LifeViewportState extends State<LifeViewport> {
  final _camera = ValueNotifier<(Offset, double, Offset?)>((
    const Offset(40, 40),
    10,
    null,
  ));
  final _focus = FocusNode();
  double _startScale = 10;
  Offset _anchor = Offset.zero;
  Size _size = Size.zero;
  bool _draw = false;
  late ModelBoard _model;
  int _reset = 0;

  @override
  void initState() {
    super.initState();
    _model = context.read<ModelBoard>();
    _model.addListener(_modelChanged);
    _camera.addListener(_syncViewport);
  }

  void _modelChanged() {
    if (_model.cameraReset != _reset) {
      _reset = _model.cameraReset;
      _fit();
    }
  }

  void _syncViewport() {
    if (!mounted || _size.isEmpty) return;
    final (offset, scale, _) = _camera.value;
    _model.setViewport([
      (-offset.dx / scale).floor(),
      (-offset.dy / scale).floor(),
      ((_size.width - offset.dx) / scale).ceil(),
      ((_size.height - offset.dy) / scale).ceil(),
      max(1, (1 / (scale * View.of(context).devicePixelRatio)).floor()),
    ]);
  }

  Offset _world(Offset local) => (local - _camera.value.$1) / _camera.value.$2;
  void _zoom(Offset focal, double scale) {
    final world = _world(focal);
    final next = scale.clamp(.000001, 60.0);
    _camera.value = (focal - world * next, next, _camera.value.$3);
  }

  void _fit() {
    if (_size.isEmpty) return;
    final b = _model.bounds;
    final scale = (min(_size.width, _size.height) / b[2] * .82).clamp(
      .000001,
      30.0,
    );
    final center = Offset(
      (b[0] + b[2] / 2).toDouble(),
      (b[1] + b[2] / 2).toDouble(),
    );
    _camera.value = (_size.center(Offset.zero) - center * scale, scale, null);
  }

  @override
  void dispose() {
    _model.removeListener(_modelChanged);
    _camera.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = context.select((ModelBoard m) => m.insertedBlock);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_size != constraints.biggest) {
          _size = constraints.biggest;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncViewport();
          });
        }
        return Stack(
          children: [
            Positioned.fill(
              child: Focus(
                focusNode: _focus,
                autofocus: true,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _model.cancelInsertion();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: MouseRegion(
                  cursor: _draw || block != null
                      ? SystemMouseCursors.precise
                      : SystemMouseCursors.grab,
                  onHover: (event) {
                    if (block != null) {
                      _camera.value = (
                        _camera.value.$1,
                        _camera.value.$2,
                        _world(event.localPosition),
                      );
                    }
                  },
                  onExit: (_) => _camera.value = (
                    _camera.value.$1,
                    _camera.value.$2,
                    null,
                  ),
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        GestureBinding.instance.pointerSignalResolver.register(
                          event,
                          (event) {
                            final scroll = event as PointerScrollEvent;
                            _zoom(
                              scroll.localPosition,
                              _camera.value.$2 *
                                  exp(-scroll.scrollDelta.dy * .002),
                            );
                          },
                        );
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (event) {
                        _focus.requestFocus();
                        if (_draw || block != null) {
                          final cell = _world(event.localPosition);
                          _model.edit(cell.dx.floor(), cell.dy.floor());
                        }
                      },
                      onScaleStart: (event) {
                        _startScale = _camera.value.$2;
                        _anchor = _world(event.localFocalPoint);
                      },
                      onScaleUpdate: (event) {
                        final scale = (_startScale * event.scale).clamp(
                          .000001,
                          60.0,
                        );
                        _camera.value = (
                          event.localFocalPoint - _anchor * scale,
                          scale,
                          null,
                        );
                      },
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: LifePainter(_model, _camera),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE6232B21),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INFINITE CANVAS',
                      style: TextStyle(
                        color: Color(0xFF9BA897),
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text('Draw', style: TextStyle(fontSize: 11)),
                    selected: _draw,
                    avatar: const Icon(Icons.edit_outlined, size: 14),
                    onSelected: (value) => setState(() => _draw = value),
                  ),
                ],
              ),
            ),
            if (block != null)
              Positioned(
                top: 65,
                left: 20,
                right: 20,
                child: Material(
                  color: const Color(0xFF34452A),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Click to place ${block.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cancel placement',
                          onPressed: _model.cancelInsertion,
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 18,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF222922),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A4536)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () => _zoom(
                        _size.center(Offset.zero),
                        _camera.value.$2 / 1.5,
                      ),
                      icon: const Icon(Icons.remove, size: 17),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _camera,
                      builder: (_, camera, _) => SizedBox(
                        width: 48,
                        child: Text(
                          '${(camera.$2 * 10).round()}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () => _zoom(
                        _size.center(Offset.zero),
                        _camera.value.$2 * 1.5,
                      ),
                      icon: const Icon(Icons.add, size: 17),
                    ),
                    IconButton(
                      tooltip: 'Fit world',
                      onPressed: _fit,
                      icon: const Icon(Icons.center_focus_strong, size: 17),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 22,
              left: 20,
              child: Text(
                'DRAG TO EXPLORE',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.3,
                  color: Color(0xFF75816F),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LifePainter extends CustomPainter {
  LifePainter(this.model, this.camera)
    : super(repaint: Listenable.merge([model, camera]));
  final ModelBoard model;
  final ValueNotifier<(Offset, double, Offset?)> camera;
  final _cells = Paint()..color = lime;
  final _grid = Paint()
    ..color = const Color(0xFF252E23)
    ..strokeWidth = 1;
  final _preview = Paint()..color = const Color(0x99DDF9B9);
  @override
  void paint(Canvas canvas, Size size) {
    final (offset, scale, hover) = camera.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(const Color(0xFF101710), BlendMode.src);
    if (scale >= 7) {
      final left = (-offset.dx / scale).floor(),
          right = ((size.width - offset.dx) / scale).ceil();
      final top = (-offset.dy / scale).floor(),
          bottom = ((size.height - offset.dy) / scale).ceil();
      for (var x = left; x <= right; x++) {
        final px = offset.dx + x * scale;
        canvas.drawLine(Offset(px, 0), Offset(px, size.height), _grid);
      }
      for (var y = top; y <= bottom; y++) {
        final py = offset.dy + y * scale;
        canvas.drawLine(Offset(0, py), Offset(size.width, py), _grid);
      }
    }
    final paths = List.generate(16, (_) => Path()), cells = model.cells;
    for (var i = 0; i < cells.length; i += 4) {
      final side = cells[i + 2] * scale;
      final rect = Rect.fromLTWH(
        offset.dx + cells[i] * scale,
        offset.dy + cells[i + 1] * scale,
        side,
        side,
      );
      if (rect.overlaps(Offset.zero & size)) {
        // A square-root curve keeps sparse subpixel patterns visible without
        // giving them the same brightness as solid living regions.
        final shade = (sqrt(cells[i + 3]) * 16).ceil().clamp(1, 16) - 1;
        paths[shade].addRect(
          scale >= 7 && cells[i + 2] == 1 ? rect.deflate(.6) : rect,
        );
      }
    }
    for (var i = 0; i < paths.length; i++) {
      _cells.color = lime.withValues(alpha: (i + 1) / paths.length);
      canvas.drawPath(paths[i], _cells);
    }
    final block = model.insertedBlock;
    if (block != null && hover != null) {
      for (var x = 0; x < block.matrixBlock.length; x++) {
        for (var y = 0; y < block.matrixBlock[x].length; y++) {
          if (block.matrixBlock[x][y]) {
            canvas.drawRect(
              Rect.fromLTWH(
                offset.dx + (hover.dx.floor() + x) * scale,
                offset.dy + (hover.dy.floor() + y) * scale,
                scale,
                scale,
              ),
              _preview,
            );
          }
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LifePainter oldDelegate) =>
      oldDelegate.model != model || oldDelegate.camera != camera;
}
