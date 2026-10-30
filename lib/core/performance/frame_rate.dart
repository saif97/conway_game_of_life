/// Counts rendered Flutter frames without requesting extra animation frames.
class FrameRate {
  Duration _start = Duration.zero;
  int _frames = 0;

  void recordFrame() => _frames++;

  double sample(Duration now) {
    final elapsed = now - _start;
    final fps = elapsed.inMicroseconds > 0
        ? _frames * Duration.microsecondsPerSecond / elapsed.inMicroseconds
        : 0.0;
    _start = now;
    _frames = 0;
    return fps;
  }
}
