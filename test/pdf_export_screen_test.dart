/// The PDF export screen against a real (FFI) database.
///
/// The layout risk this catches: the block list is a ReorderableListView
/// nested inside the page's own ListView, and the widget tester fails on
/// any layout exception. The behaviour it pins down: every edit writes
/// the GLOBAL template immediately (the old screen saved only after a
/// successful export, so an edit backed out of was silently lost), and a
/// seeded block records the dashboard instance it must keep following.
///
/// sqflite_common_ffi does real file I/O, which the widget tester's fake
/// async never advances — every database call therefore goes through
/// [WidgetTester.runAsync], and the screen's own loading future is
/// pumped with real delays rather than pumpAndSettle (the loading
/// spinner animates forever and would never settle).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/dashboard_repository.dart';
import 'package:kaaljyoti/data/db.dart';
import 'package:kaaljyoti/data/export_repository.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/screens/pdf_export_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _ffiOpener(
  String path, {
  required String password,
  required int version,
  required OnDatabaseConfigureFn onConfigure,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) =>
    databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late AppDb appDb;
  late DashboardRepository dashboard;
  late ExportRepository export;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kaaljyoti_pdf_export_test');
    appDb = AppDb.forTest(
      path: '${dir.path}/kaaljyoti.db',
      opener: _ffiOpener,
      passphrase: 'test-passphrase',
    );
    dashboard = DashboardRepository(db: appDb);
    export = ExportRepository(db: appDb);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Runs a database call for real — the fake async clock of a widget
  /// test never lets file I/O complete on its own.
  Future<T> io<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  /// Pumps the screen and waits (in real time) for its initial load.
  Future<void> pump(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      dashboardRepoProvider.overrideWithValue(dashboard),
      exportRepoProvider.overrideWithValue(export),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const PdfExportScreen(kundliId: 'k1')),
    ));
    for (var i = 0; i < 50; i++) {
      if (find.byType(CheckboxListTile).evaluate().isNotEmpty) return;
      await io(
          tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    fail('the export screen never finished loading');
  }

  /// Lets fire-and-forget database work (a template write, a reseed)
  /// land before it is asserted on. Several rounds, because a reset is
  /// two round-trips and one 100ms window is not reliably enough.
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await io(
          tester, () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump();
    }
  }

  int checkedCount(WidgetTester tester) => tester
      .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
      .where((c) => c.value == true)
      .length;

  testWidgets('seeds from the dashboard, with a drag handle per block',
      (tester) async {
    await pump(tester);

    expect(checkedCount(tester), DashboardRepository.defaultOverview.length);
    expect(find.byIcon(Icons.drag_indicator), findsWidgets);
    expect(await io(tester, export.load), isNull,
        reason: 'merely opening the screen must not write a template');
  });

  testWidgets('toggling a block writes the global template immediately',
      (tester) async {
    await pump(tester);
    final before = checkedCount(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await flush(tester);

    final saved = await io(tester, export.load);
    expect(saved, isNotNull);
    expect(saved!.blocks, hasLength(before - 1));
    // Seeded blocks carry the instance link that makes them follow the
    // dashboard card instead of freezing its settings.
    expect(saved.blocks.every((b) => b.instanceId != null), isTrue);
    expect(saved.blocks.every((b) => !b.overridden), isTrue);
  });

  testWidgets('duplicating a block freezes the copy and persists',
      (tester) async {
    await pump(tester);
    final before = checkedCount(tester);

    await tester.tap(find.byIcon(Icons.copy).first);
    await tester.pump();
    await flush(tester);

    final saved = await io(tester, export.load);
    expect(saved!.blocks, hasLength(before + 1));
    expect(saved.blocks.where((b) => b.overridden), hasLength(1),
        reason: 'a duplicate has no card of its own to follow');
  });

  testWidgets('dragging a block reorders the report and persists',
      (tester) async {
    await pump(tester);

    final handle = find.byIcon(Icons.drag_indicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 140));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await flush(tester);

    final saved = await io(tester, export.load);
    expect(saved, isNotNull);
    expect(saved!.blocks.first.widgetId,
        isNot(DashboardRepository.defaultOverview.first.widgetId),
        reason: 'the dragged block should no longer be first');
  });

  testWidgets('Reset drops the template and reseeds from the dashboard',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await flush(tester);
    expect(await io(tester, export.load), isNotNull);

    // The affordance appears only once a template exists.
    await tester.tap(find.text('Reset'));
    await tester.pump();
    await flush(tester);

    expect(await io(tester, export.load), isNull);
    // Reset is two round-trips (clear, then reseed) — flush again.
    await flush(tester);
    expect(checkedCount(tester), DashboardRepository.defaultOverview.length,
        reason: 'the block deselected above is back');
  });
}
