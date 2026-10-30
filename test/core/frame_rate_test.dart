import 'package:conway_game_of_life/core/performance/frame_rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FPS uses elapsed time and resets between sampling windows', () {
    final counter = FrameRate();
    for (var i = 0; i < 90; i++) {
      counter.recordFrame();
    }
    expect(counter.sample(const Duration(milliseconds: 1500)), 60);
    expect(counter.sample(const Duration(milliseconds: 2500)), 0);
    for (var i = 0; i < 15; i++) {
      counter.recordFrame();
    }
    expect(counter.sample(const Duration(milliseconds: 3000)), 30);
  });

  test('zero elapsed time never produces an invalid FPS value', () {
    expect(FrameRate().sample(Duration.zero), 0);
  });
}
