// Kundli Compare screen widget tests (spec §3.3/§3.4, resolution §8.5).
// Providers are overridden so no DB / network / ephemeris is touched:
// snapshots are synthesised from raw longitudes (à la compare_test), the
// dashboard view/widget providers return fixed data, and the findings
// provider is faked.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/compare.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/mahakosh/compare_subject.dart';
import 'package:kaaljyoti/screens/compare_screen.dart';
import 'package:kaaljyoti/screens/dashboard_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:kaaljyoti/ui/common.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longs = <Planet, double>{
  Planet.sun: 95,
  Planet.moon: 14, // Bharani
  Planet.mars: 155,
  Planet.mercury: 245,
  Planet.jupiter: 275,
  Planet.venus: 200,
  Planet.saturn: 340, // Pisces
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

ModuleContext _moduleCtx() => ModuleContext(
      kundli: _kundli('k1', 'Alice'),
      snapshot: _snapshot(),
      chartStyle: ChartStyle.north,
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

CompareSlot _fullSlot(String ref, String label) => CompareSlot(
      ref: ref,
      label: label,
      isMahakosh: false,
      subject:
          LocalSubject(kundli: _kundli(ref, label), snapshot: _snapshot()),
      kundliId: ref,
      ayanamsaId: 1,
    );

final _views = <DashboardView>[
  const DashboardView(id: 'v1', name: 'Overview', position: 0),
  const DashboardView(id: 'v2', name: 'Detail', position: 1),
];

List<PlacedWidget> _placed(String viewId) => [
      PlacedWidget(
          instanceId: '$viewId-a',
          viewId: viewId,
          widgetId: 'planetary_positions',
          position: 0,
          span: CardSpan.half),
      PlacedWidget(
          instanceId: '$viewId-b',
          viewId: viewId,
          widgetId: 'planetary_positions',
          position: 1,
          span: CardSpan.half),
    ];

List<Override> _dashboardOverrides() => [
      dashboardViewsProvider.overrideWith((ref) async => _views),
      viewWidgetsProvider.overrideWith((ref, viewId) async => _placed(viewId)),
      moduleContextProvider.overrideWith((ref, id) async => _moduleCtx()),
    ];

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('4-chart cap enforced at add time (spec §3.2)', () {
    final n = CompareSetNotifier(SettingsRepository());
    expect(n.add('a'), isTrue);
    expect(n.add('b'), isTrue);
    expect(n.add('c'), isTrue);
    expect(n.add('d'), isTrue);
    // The fifth is rejected without mutating the set.
    expect(n.add('e'), isFalse);
    expect(n.state, ['a', 'b', 'c', 'd']);
    // addAll also stops at the cap.
    final m = CompareSetNotifier(SettingsRepository());
    expect(m.addAll(['a', 'b', 'c', 'd', 'e', 'f']), 4);
    expect(m.state, ['a', 'b', 'c', 'd']);
  });

  testWidgets(
      'limited subject keeps the same grid geometry as a full subject (spec §3.3)',
      (tester) async {
    const chart = CompareChart(ascendant: 15, longitudes: _longs);

    Future<int> cardCount(Widget body) async {
      final container = ProviderContainer(overrides: _dashboardOverrides());
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: _wrap(body),
      ));
      await tester.pumpAndSettle();
      return find.byType(ModuleCard).evaluate().length;
    }

    // Full subject: real cards.
    final full = await cardCount(DashboardBody(
      kundliId: 'k1',
      moduleCtx: _moduleCtx(),
      activeViewId: 'v1',
      onSelectView: (_) {},
    ));

    // Limited subject: placeholder / positions cards, same slot count.
    final limited = await cardCount(DashboardBody(
      kundliId: 'mk1',
      moduleCtx: null,
      activeViewId: 'v1',
      onSelectView: (_) {},
      limitedCardBuilder: (ctx, pwd) =>
          const ComparePositionsCard(title: 'X', chart: chart),
    ));

    expect(full, 2);
    expect(limited, full);
  });

  testWidgets('switching chart tabs preserves the active view chip (spec §3.3)',
      (tester) async {
    final container = ProviderContainer(overrides: [
      ..._dashboardOverrides(),
      compareSubjectsProvider.overrideWith(
          (ref) async => [_fullSlot('k1', 'Alice'), _fullSlot('k2', 'Bob')]),
      compareFindingsProvider.overrideWith((ref) async => const []),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const CompareScreen()),
    ));
    await tester.pumpAndSettle();

    // Default active view is the first ('Overview').
    expect(container.read(compareViewIdProvider), anyOf(isNull, 'v1'));

    // Select the 'Detail' view chip on the first chart tab.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Detail').first);
    await tester.pumpAndSettle();
    expect(container.read(compareViewIdProvider), 'v2');

    // Switch to the second chart tab — the shared view state persists.
    await tester.tap(find.widgetWithText(Tab, 'Bob'));
    await tester.pumpAndSettle();
    expect(container.read(compareViewIdProvider), 'v2',
        reason: 'active view is locked across tabs');
  });

  testWidgets(
      'chart tabs swap instantly via IndexedStack, not a sliding TabBarView '
      '(spec §3.3 visual-diff)', (tester) async {
    final container = ProviderContainer(overrides: [
      ..._dashboardOverrides(),
      compareSubjectsProvider.overrideWith(
          (ref) async => [_fullSlot('k1', 'Alice'), _fullSlot('k2', 'Bob')]),
      compareFindingsProvider.overrideWith((ref) async => const []),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const CompareScreen()),
    ));
    await tester.pumpAndSettle();

    // The compare content lives in an IndexedStack (a single-frame swap),
    // never a TabBarView — a TabBarView would slide one chart over the
    // other and destroy the blink-comparison the feature depends on.
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.byType(TabBarView), findsNothing);

    // Tapping a tab reveals its content in the very next frame: a single
    // pump (no settle) is enough for the target chart's view chips to be
    // present, i.e. there is no interpolated content transition to wait on.
    await tester.tap(find.widgetWithText(Tab, 'Bob'));
    await tester.pump();
    expect(find.widgetWithText(ChoiceChip, 'Overview'), findsWidgets);
  });

  testWidgets('DashboardBody drives the externally-owned scroll controller '
      '(shared offset mechanism, spec §3.3)', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final container = ProviderContainer(overrides: _dashboardOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(SizedBox(
        height: 200, // small viewport so the grid scrolls
        child: DashboardBody(
          kundliId: 'k1',
          moduleCtx: _moduleCtx(),
          activeViewId: 'v1',
          onSelectView: (_) {},
          scrollController: controller,
        ),
      )),
    ));
    await tester.pumpAndSettle();

    expect(controller.hasClients, isTrue);
    controller.jumpTo(80);
    await tester.pump();
    // The grid reads its offset from the host-owned controller — the
    // exact mechanism compare uses to share one offset across tabs.
    expect(controller.offset, 80);
  });

  testWidgets('Similarities tab renders findings from a fake provider '
      '(spec §3.4)', (tester) async {
    final findings = <CompareFinding>[
      const CompareFinding(
        group: 'placements',
        key: 'graha-sign:saturn:pisces',
        params: {'planet': 'Saturn', 'sign': 'Pisces'},
        subjectIds: ['k1', 'k2'],
        strength: 2,
      ),
    ];
    final container = ProviderContainer(overrides: [
      ..._dashboardOverrides(),
      compareSubjectsProvider.overrideWith(
          (ref) async => [_fullSlot('k1', 'Alice'), _fullSlot('k2', 'Bob')]),
      compareFindingsProvider.overrideWith((ref) async => findings),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _wrap(const CompareScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Similarities'));
    await tester.pumpAndSettle();

    // The finding renders through the English-only label builder, and its
    // shared-charts line lists both subjects by name.
    expect(find.text('Saturn in Pisces'), findsOneWidget);
    expect(find.text('Alice, Bob'), findsOneWidget);
  });
}
