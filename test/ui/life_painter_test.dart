import 'dart:ui' as ui;

import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:conway_game_of_life/ui/subscreen_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_worker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sparse zoomed-out regions paint softer than solid regions', () async {
    final worker = FakeWorker();
    final model = ModelBoard(workerFactory: () => worker, demo: false);
    final camera = ValueNotifier<(Offset, double, Offset?)>((
      const Offset(8, 8),
      .5,
      null,
    ));
    addTearDown(model.dispose);
    addTearDown(camera.dispose);
    await model.ready;
    worker.service.universe.setCell(0, 0, true);
    model.setViewport([0, 0, 64, 64, 16]);
    await model.saveState();

    Future<int> greenAtTileCenter() async {
      final recorder = ui.PictureRecorder();
      LifePainter(model, camera).paint(Canvas(recorder), const Size(32, 32));
      final picture = recorder.endRecording();
      final image = await picture.toImage(32, 32);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final green = pixels!.getUint8((10 * 32 + 10) * 4 + 1);
      image.dispose();
      picture.dispose();
      return green;
    }

    final sparseGreen = await greenAtTileCenter();
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        worker.service.universe.setCell(x, y, true);
      }
    }
    await model.saveState();
    final solidGreen = await greenAtTileCenter();

    expect(sparseGreen, greaterThan(23)); // Visible against the background.
    expect(sparseGreen, lessThan(solidGreen ~/ 2));
    expect(solidGreen, 243); // Fully occupied tiles retain the lime color.
  });
}
