import 'dart:async';

import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:conway_game_of_life/ui/screen_home.dart';
import 'package:conway_game_of_life/ui/subscreen_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_worker.dart';

class GatedWorker extends FakeWorker {
  Completer<void>? advanceGate;

  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) async {
    if (message['command'] == 'advance') await advanceGate?.future;
    return super.request(message);
  }
}

Future<ModelBoard> mount(WidgetTester tester, {FakeWorker? worker}) async {
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  final model = ModelBoard(
    workerFactory: () => worker ?? FakeWorker(),
    demo: false,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: ScreenHome(model: model),
    ),
  );
  await tester.pumpAndSettle();
  return model;
}

void main() {
  testWidgets('running status stays steady across worker requests', (
    tester,
  ) async {
    final worker = GatedWorker();
    final model = await mount(tester, worker: worker);
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(find.text('Running'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      worker.advanceGate = Completer<void>();
      await tester.pump(const Duration(milliseconds: 33));
      expect(model.isBusy, isTrue);
      expect(model.isPlaying, isTrue);
      expect(find.text('Running'), findsOneWidget);

      worker.advanceGate!.complete();
      await tester.pump();
      expect(model.isBusy, isFalse);
      expect(find.text('Running'), findsOneWidget);
    }

    worker.advanceGate = Completer<void>();
    await tester.pump(const Duration(milliseconds: 33));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(
      find.text('Finishing current operation · you can keep exploring'),
      findsOneWidget,
    );
    worker.advanceGate!.complete();
    await tester.pump();
    expect(find.text('Paused · take a closer look'), findsOneWidget);
  });

  testWidgets('draw, step, save and restore through the redesigned controls', (
    tester,
  ) async {
    final model = await mount(tester);
    await tester.tap(find.text('Draw'));
    await tester.pump();
    final origin = tester.getTopLeft(find.byType(LifeViewport));
    for (final x in [0, 1, 2]) {
      await tester.tapAt(origin + Offset(40 + x * 10 + 5, 145));
      await tester.pumpAndSettle();
    }
    expect(model.population, 3);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Step'));
    await tester.pumpAndSettle();
    expect(model.generation, 1);
    expect(model.population, 3);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(model.generation, 0);
    expect(model.population, 3);
    await tester.tap(find.text('New world'));
    await tester.pumpAndSettle();
    expect(model.population, 0);
  });
  testWidgets('playback pauses and disposal cancels timer and worker', (
    tester,
  ) async {
    final model = await mount(tester);
    await tester.tap(find.text('Play'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    final generation = model.generation;
    await tester.pump(const Duration(seconds: 1));
    expect(model.generation, generation);
    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'phone layout supports searchable library and pattern selection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = await mount(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Glider Gun');
      await tester.pumpAndSettle();
      expect(find.text('Glider Gun'), findsNWidgets(2));
      await tester.tap(find.text('Glider Gun').last);
      await tester.pumpAndSettle();
      expect(model.title, 'Glider Gun');
      expect(model.population, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('desktop library and zoom controls are usable', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    expect(find.text('PATTERN LIBRARY'), findsOneWidget);
    expect(find.text('PERFORMANCE'), findsOneWidget);
    expect(find.text('Rendered FPS'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(find.text('150%'), findsOneWidget);
    await tester.tap(find.byTooltip('Fit world'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
