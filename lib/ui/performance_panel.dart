import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../core/view_model/model_board.dart';

import '../core/performance/frame_rate.dart';
import '../core/performance/memory.dart';

class PerformancePanel extends StatefulWidget {
  const PerformancePanel({super.key});

  @override
  State<PerformancePanel> createState() => _PerformancePanelState();
}

class _PerformancePanelState extends State<PerformancePanel> {
  final _clock = Stopwatch();
  final _frames = FrameRate();
  Timer? _timer;
  double? _fps;
  MemorySample _memory = unavailableMemory;
  bool _samplingMemory = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _clock.start();
    SchedulerBinding.instance.addPostFrameCallback(_frame);
    _readMemory();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _fps = _frames.sample(_clock.elapsed));
      if (++_ticks % 10 == 0) _readMemory();
    });
  }

  void _frame(Duration _) {
    if (!mounted) return;
    _frames.recordFrame();
    // Register for the next frame, but never force the canvas to animate.
    SchedulerBinding.instance.addPostFrameCallback(_frame);
  }

  Future<void> _readMemory() async {
    if (_samplingMemory) return;
    _samplingMemory = true;
    try {
      final sample = await sampleMemory();
      if (mounted) setState(() => _memory = sample);
    } finally {
      _samplingMemory = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: const BoxDecoration(
      color: Color(0xFF171C19),
      border: Border(top: BorderSide(color: Color(0xFF30372F))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PERFORMANCE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: Color(0xFF9BA897),
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Flutter frames rendered per second, not generations per second or display refresh rate. Low values are normal when idle. This panel refreshes once a second.',
          child: _row('Rendered FPS', _fps?.toStringAsFixed(1) ?? '—'),
        ),
        const SizedBox(height: 8),
        Consumer<ModelBoard>(
          builder: (_, model, _) => Tooltip(
            message: 'Worker computation time for the last completed simulation jump; excludes rendering and message transfer. FPS can stay high while this is slow.',
            child: _row(
              'Simulation / jump',
              model.simulationUs == null
                  ? '—'
                  : '${(model.simulationUs! / 1000).toStringAsFixed(1)} ms',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Consumer<ModelBoard>(
          builder: (_, model, _) => _row(
            'Generations / jump',
            model.simulatedGenerations?.toString() ?? '—',
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: _memory.description,
          child: _row(
            _memory.label,
            _memory.bytes == null
                ? 'Unavailable'
                : '${(_memory.bytes! / (1024 * 1024)).toStringAsFixed(1)} MiB',
          ),
        ),
      ],
    ),
  );

  Widget _row(String label, String value) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      Text(
        value,
        style: const TextStyle(fontSize: 12, color: Color(0xFFB8F36D)),
      ),
    ],
  );
}
