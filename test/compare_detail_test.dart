// Compare-aware module detail host widget tests (spec §3.3). Providers
// are overridden so no DB / network / ephemeris is touched: the compare
// subject set and the per-chart module context are faked, exactly like
// compare_screen_test.dart. These assert the three host invariants:
//   - the subject tab content is an IndexedStack instant swap, never a
//     sliding TabBarView (the blink-comparison the feature depends on),
//   - the one per-instance config is shared/preserved across every
//     subject tab,
//   - the subject the user drilled in from is pre-selected.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/mahakosh/compare_subject.dart';
import 'package:kaaljyoti/screens/compare_module_detail_screen.dart';
import 'package:kaaljyoti/screens/module_detail_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longs = <Planet, double>{
  Planet.sun: 95,
  Planet.moon: 14,
  Planet.mars: 155,
  Planet.mercury: 245,
  Planet.jupiter: 275,
  Planet.venus: 200,
  Planet.saturn: 340,
  Planet.rahu: 65,
  Planet.ketu: 245,
};

AstroSnapshot _snapshot() => AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(1980, 1, 1, 6, 0),
        latitude: 28.6,
        longitude: 77.2,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 24.1,
      positions: {
        for (final e in _longs.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: 15,
      houseCusps: List.filled(12, 0.0),
      panchang: computePanchang(
          sunLongitude: 95, moonLongitude: 14, localDateTime: DateTime(1980)),
      yogas: const [],
    );

Kundli _kundli(String id, String name) => Kundli(
      id: id,
      name: name,
      relationTag: 'Self',
      birthUtc: DateTime.utc(1980, 1, 1, 6, 0),
      latitude: 28.6,
      longitude: 77.2,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
      placeName: 'Delhi',
      createdAt: DateTime.utc(1980),
      updatedAt: DateTime.utc(1980),
    );

ModuleContext _moduleCtx(String id, String name) => ModuleContext(
      kundli: _kundli(id, name),
      snapshot: _snapshot(),
      chartStyle: ChartStyle.north,
    );

CompareSlot _fullSlot(String ref, String label) => CompareSlot(
      ref: ref,
      label: label,
      isMahakosh: false,
      subject:
          LocalSubject(kundli: _kundli(ref, label), snapshot: _snapshot()),
      kundliId: ref,
      ayanamsaId: 1,
    );

List<Override> _overrides() => [
      compareSubjectsProvider.overrideWith(
          (ref) async => [_fullSlot('k1', 'Alice'), _fullSlot('k2', 'Bob')]),
      moduleContextProvider.overrideWith(
          (ref, id) async => _moduleCtx(id, id == 'k2' ? 'Bob' : 'Alice')),
    ];

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'subject tabs swap via IndexedStack, never a sliding TabBarView '
      '(spec §3.3 visual-diff)', (tester) async {
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const CompareModuleDetailScreen(
        moduleId: 'planetary_positions',
        subjectRef: 'k1',
      )),
    ));
    await tester.pumpAndSettle();

    // Instant blink-swap, not a slide.
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.byType(TabBarView), findsNothing);

    // A single pump (no settle) reveals the target subject's body — no
    // interpolated content transition to wait on.
    await tester.tap(find.widgetWithText(Tab, 'Bob'));
    await tester.pump();
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 1);
  });

  testWidgets('the drilled-in subject is pre-selected (spec §3.3)',
      (tester) async {
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const CompareModuleDetailScreen(
        moduleId: 'planetary_positions',
        subjectRef: 'k2', // drilled in from Bob's chart tab
      )),
    ));
    await tester.pumpAndSettle();

    // The host opens on Bob's tab (index 1), not the first subject.
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 1);
  });

  testWidgets(
      'one per-instance config is shared across, and preserved through, '
      'subject tab switches (spec §3.3 locked context)', (tester) async {
    const config = <String, dynamic>{'style': 'south'};
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const CompareModuleDetailScreen(
        moduleId: 'planetary_positions',
        subjectRef: 'k1',
        initialConfig: config,
      )),
    ));
    await tester.pumpAndSettle();

    // Every tab's body (IndexedStack keeps them all alive) is handed the
    // exact same config — no per-tab config.
    // skipOffstage: false — IndexedStack keeps non-visible tabs mounted
    // but offstage, and those bodies must carry the same shared config.
    Iterable<Map<String, dynamic>?> bodyConfigs() => tester
        .widgetList<ModuleDetailBody>(
            find.byType(ModuleDetailBody, skipOffstage: false))
        .map((b) => b.configOverride);

    expect(bodyConfigs().length, 2);
    for (final c in bodyConfigs()) {
      expect(c, config);
    }

    // Switching subject tabs does not disturb the shared config.
    await tester.tap(find.widgetWithText(Tab, 'Bob'));
    await tester.pumpAndSettle();
    for (final c in bodyConfigs()) {
      expect(c, config);
    }
  });
}
