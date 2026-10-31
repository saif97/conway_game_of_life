import 'dart:convert';

import 'package:conway_game_of_life/core/pattern_catalog.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:conway_game_of_life/ui/sub_block_explorer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fake_worker.dart';

class TestBundle extends CachingAssetBundle {
  TestBundle(this.files);
  final Map<String, String> files;
  final reads = <String>[];
  String? failOnce;
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    // Decode large fixtures without AssetBundle's background isolate, which
    // does not advance with the widget test's fake clock.
    final data = await load(key);
    return utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  @override
  Future<ByteData> load(String key) async {
    reads.add(key);
    if (failOnce == key) {
      failOnce = null;
      throw StateError('Temporary asset failure');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(files[key]!)));
  }
}

Future<TestBundle> bundledFiles() async {
  final manifest = await rootBundle.loadString('assets/patterns/catalog.json');
  final files = {'assets/patterns/catalog.json': manifest};
  for (final entry in jsonDecode(manifest)['patterns']) {
    files[entry['asset'] as String] = await rootBundle.loadString(
      entry['asset'] as String,
    );
  }
  return TestBundle(files);
}

Future<ModelBoard> mount(WidgetTester tester, TestBundle bundle) async {
  final model = ModelBoard(workerFactory: FakeWorker.new, demo: false);
  addTearDown(model.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider.value(
          value: model,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 292,
              child: SubBlockExplorer(
                loadCatalog: () => PatternCatalog.load(bundle: bundle),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return model;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, String> files;
  setUpAll(() async => files = (await bundledFiles()).files);

  testWidgets(
    'families expand independently; search finds collapsed patterns and clear restores groups',
    (tester) async {
      final bundle = TestBundle(files);
      final model = await mount(tester, bundle);
      final manifest = jsonDecode(files['assets/patterns/catalog.json']!);
      expect(
        find.text(
          '${manifest['patterns'].length} patterns · ${manifest['groups'].length} families',
        ),
        findsOneWidget,
      );
      expect(bundle.reads, ['assets/patterns/catalog.json']);
      await tester.tap(find.byKey(const ValueKey('group-still-lifes')));
      await tester.pumpAndSettle();
      expect(find.text('Block'), findsOneWidget);
      expect(bundle.reads, contains('assets/patterns/block.rle'));
      expect(bundle.reads, isNot(contains('assets/patterns/memory-loop.rle')));
      await tester.enterText(find.byType(TextField), 'constructor memory');
      await tester.pumpAndSettle();
      expect(find.text('Constructor memory loop'), findsOneWidget);
      expect(find.textContaining('31473 × 31101'), findsOneWidget);
      await tester.tap(find.text('Place'));
      await tester.pumpAndSettle();
      expect(model.insertedBlock?.name, 'Constructor memory loop');
      expect(model.population, 0);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Block'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'load, source details, no results and alphabetical ordering work',
    (tester) async {
      final model = await mount(tester, TestBundle(files));
      await tester.enterText(find.byType(TextField), 'pulsar');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('About Pulsar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CC BY-SA 3.0'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load world'));
      await tester.pumpAndSettle();
      expect(model.title, 'Pulsar');
      expect(model.population, 48);
      await tester.enterText(find.byType(TextField), 'nothing-matches-this');
      await tester.pumpAndSettle();
      expect(find.text('No matching patterns'), findsOneWidget);
      await tester.tap(find.text('Show all patterns'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('group-still-lifes')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name A–Z').last);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Beehive')).dy,
        lessThan(tester.getTopLeft(find.text('Block')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'published meta-world loads with its starting jump and no Place action',
    (tester) async {
      final model = await mount(tester, TestBundle(files));
      await tester.enterText(
        find.byType(TextField),
        'metapixel galaxy millions',
      );
      await tester.pumpAndSettle();
      expect(find.text('OTCA metapixel galaxy'), findsOneWidget);
      expect(find.text('Place'), findsNothing);
      await tester.ensureVisible(find.text('Load world'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load world'));
      await tester.pumpAndSettle();
      expect(model.population, 7408195);
      expect(model.jumpExponent, 10);
      expect(model.isPlaying, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('asset failures have retries without changing the world', (
    tester,
  ) async {
    final bundle = TestBundle(files)..failOnce = 'assets/patterns/catalog.json';
    final model = await mount(tester, bundle);
    expect(find.text('Could not load the library.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    bundle.failOnce = 'assets/patterns/pulsar.rle';
    await tester.enterText(find.byType(TextField), 'pulsar');
    await tester.pumpAndSettle();
    expect(find.text('Pattern unavailable'), findsOneWidget);
    expect(model.population, 0);
    await tester.tap(find.text('Retry pattern'));
    await tester.pumpAndSettle();
    expect(find.text('13 × 13 · 48 alive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
