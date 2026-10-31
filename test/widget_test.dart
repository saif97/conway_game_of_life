import 'dart:async';

import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:conway_game_of_life/ui/screen_home.dart';
import 'package:conway_game_of_life/ui/subscreen_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets(
    'Space toggles once, pauses busy work, and respects text and dialogs',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final worker = GatedWorker();
      final model = await mount(tester, worker: worker);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(model.isPlaying, isTrue);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(model.isPlaying, isTrue);
      worker.advanceGate = Completer<void>();
      await tester.pump(const Duration(milliseconds: 33));
      expect(model.isBusy, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(model.isPlaying, isFalse);
      worker.advanceGate!.complete();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(model.isPlaying, isFalse);
      await tester.tap(find.text('Guide'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(model.isPlaying, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LifeViewport));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(model.isPlaying, isTrue);
      model.pause();
    },
  );

  testWidgets('Draw paints a continuous stroke without moving the camera', (
    tester,
  ) async {
    final worker = FakeWorker();
    final model = await mount(tester, worker: worker);
    final viewport = find.byType(LifeViewport);
    final paint = find.descendant(
      of: viewport,
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is LifePainter,
      ),
    );
    final camera =
        (tester.widget<CustomPaint>(paint).painter! as LifePainter).camera;
    final before = camera.value;
    final origin = tester.getTopLeft(viewport);
    await tester.tap(find.text('Draw'));
    await tester.pump();
    final gesture = await tester.startGesture(origin + const Offset(85, 145));
    await gesture.moveTo(origin + const Offset(185, 145));
    await tester.pump();
    await gesture.moveTo(origin + const Offset(85, 145));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(camera.value, before);
    expect(model.population, 11);
    expect(worker.service.universe.liveCells(), {
      for (var x = 4; x <= 14; x++) (x, 10),
    });

    // A new stroke may toggle the same cells again.
    final erase = await tester.startGesture(origin + const Offset(185, 145));
    await erase.moveTo(origin + const Offset(85, 145));
    await erase.up();
    await tester.pumpAndSettle();
    expect(model.population, 0);
    expect(camera.value, before);

    await tester.tap(find.text('Draw'));
    await tester.pump();
    await tester.dragFrom(origin + const Offset(85, 145), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(camera.value.$1, isNot(before.$1));
    expect(model.population, 0);
  });

  testWidgets('pattern library uses a sidebar or drawer, never both', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);

    expect(find.text('PATTERN LIBRARY'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).drawer, isNull);

    tester.view.physicalSize = const Size(899, 900);
    await tester.pumpAndSettle();
    expect(find.text('PATTERN LIBRARY'), findsNothing);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('PATTERN LIBRARY'), findsOneWidget);

    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpAndSettle();
    expect(find.text('PATTERN LIBRARY'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).drawer, isNull);
    expect(tester.takeException(), isNull);
  });

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
