/// Home-dashboard body behaviours that are easy to regress:
///
///  * scroll offsets are remembered PER VIEW and PER KUNDLI. Views are
///    global, so a view-keyed offset alone let kundli B open at kundli
///    A's position, and a grid that didn't remount on a view switch
///    showed the new view at the old view's offset AND then overwrote
///    the new view's stored offset with it.
///  * the view chips reorder by long-press drag, which took over the
///    gesture that used to open rename/delete — that sheet now opens by
///    tapping the chip that is already active.
///
/// Providers are overridden so no DB / ephemeris is touched (same
/// approach as compare_screen_test).
library;

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/data/dashboard_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/screens/dashboard_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

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

Kundli _kundli(String id) => Kundli(
      id: id,
      name: id,
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

ModuleContext _moduleCtx(String kundliId) => ModuleContext(
      kundli: _kundli(kundliId),
      snapshot: _snapshot(),
      chartStyle: ChartStyle.north,
    );

final _views = <DashboardView>[
  const DashboardView(id: 'v1', name: 'Overview', position: 0),
  const DashboardView(id: 'v2', name: 'Detail', position: 1),
];

/// Enough cards that the board is taller than the test viewport.
List<PlacedWidget> _placed(String viewId) => [
      for (var i = 0; i < 6; i++)
        PlacedWidget(
          instanceId: '$viewId-$i',
          viewId: viewId,
          widgetId: 'planetary_positions',
          position: i,
          span: CardSpan.full,
        ),
    ];

/// Captures the reorder call instead of writing to a database.
class _FakeDashboardRepo extends DashboardRepository {
  List<String>? lastOrder;

  @override
  Future<void> reorderViews(List<String> idsInOrder) async {
    lastOrder = idsInOrder;
  }
}

/// Owns the selected view (and the kundli) the way DashboardScreen does.
class _Host extends StatefulWidget {
  const _Host({required this.kundliId});
  final String kundliId;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String kundliId = widget.kundliId;
  String viewId = 'v1';

  void openKundli(String id) => setState(() => kundliId = id);

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          // A short viewport so the board actually scrolls.
          body: SizedBox(
            height: 300,
            child: DashboardBody(
              kundliId: kundliId,
              moduleCtx: _moduleCtx(kundliId),
              activeViewId: viewId,
              onSelectView: (id) => setState(() => viewId = id),
            ),
          ),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Override> overrides({DashboardRepository? repo}) => [
        dashboardViewsProvider.overrideWith((ref) async => _views),
        viewWidgetsProvider
            .overrideWith((ref, viewId) async => _placed(viewId)),
        moduleContextProvider.overrideWith((ref, id) async => _moduleCtx(id)),
        if (repo != null) dashboardRepoProvider.overrideWithValue(repo),
      ];

  /// The board's own (vertical) scroll position — the chips strip
  /// scrolls horizontally, so the axis picks the grid out.
  ScrollPosition gridPosition(WidgetTester tester) {
    final states = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) => s.position.axis == Axis.vertical)
        .toList();
    expect(states, hasLength(1), reason: 'exactly one vertical board');
    return states.single.position;
  }

  testWidgets('each view keeps its OWN scroll offset across a view switch',
      (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const _Host(kundliId: 'k1'),
    ));
    await tester.pumpAndSettle();

    // Scroll the Overview board down.
    gridPosition(tester).jumpTo(120);
    await tester.pumpAndSettle();
    expect(
        container.read(
            dashboardScrollOffsetProvider((kundliId: 'k1', viewId: 'v1'))),
        120);

    // Switch to the Detail view: it opens at the TOP, not at Overview's
    // offset — and it must not have inherited Overview's stored value.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Detail'));
    await tester.pumpAndSettle();
    expect(gridPosition(tester).pixels, 0);
    expect(
        container.read(
            dashboardScrollOffsetProvider((kundliId: 'k1', viewId: 'v2'))),
        0);
    // Overview's own offset survived the switch (it used to be clobbered
    // by the shared controller's listener).
    expect(
        container.read(
            dashboardScrollOffsetProvider((kundliId: 'k1', viewId: 'v1'))),
        120);

    // Scroll Detail somewhere else, then come back to Overview.
    gridPosition(tester).jumpTo(60);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Overview'));
    await tester.pumpAndSettle();
    expect(gridPosition(tester).pixels, 120, reason: 'Overview restored');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Detail'));
    await tester.pumpAndSettle();
    expect(gridPosition(tester).pixels, 60, reason: 'Detail restored');
  });

  testWidgets('a different kundli starts at the top of the same (global) view',
      (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const _Host(kundliId: 'k1'),
    ));
    await tester.pumpAndSettle();

    gridPosition(tester).jumpTo(120);
    await tester.pumpAndSettle();

    // Same view id (views are global), different chart.
    tester.state<_HostState>(find.byType(_Host)).openKundli('k2');
    await tester.pumpAndSettle();
    expect(gridPosition(tester).pixels, 0);
    expect(
        container.read(
            dashboardScrollOffsetProvider((kundliId: 'k1', viewId: 'v1'))),
        120,
        reason: "k1's position is kept for when it is reopened");
  });

  testWidgets(
      'tapping the ACTIVE chip opens rename/delete; tapping another '
      'just switches view', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const _Host(kundliId: 'k1'),
    ));
    await tester.pumpAndSettle();

    // Non-active chip: plain switch, no sheet.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Rename view'), findsNothing);
    expect(tester.state<_HostState>(find.byType(_Host)).viewId, 'v2');

    // The now-active chip: the actions sheet.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Rename view'), findsOneWidget);
    expect(find.text('Delete view'), findsOneWidget);
  });

  testWidgets('long-press dragging a chip persists the new view order',
      (tester) async {
    final repo = _FakeDashboardRepo();
    final container = ProviderContainer(overrides: overrides(repo: repo));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const _Host(kundliId: 'k1'),
    ));
    await tester.pumpAndSettle();

    // Drag "Detail" left, past "Overview".
    final detail = tester.getCenter(find.widgetWithText(ChoiceChip, 'Detail'));
    final overview =
        tester.getCenter(find.widgetWithText(ChoiceChip, 'Overview'));
    final gesture = await tester.startGesture(detail);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(Offset(overview.dx - 20, overview.dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repo.lastOrder, ['v2', 'v1']);
    // The active view is tracked by id, so the drag doesn't change it.
    expect(tester.state<_HostState>(find.byType(_Host)).viewId, 'v1');
  });

  testWidgets(
      'read-only (compare) chips are neither reorderable nor '
      'actionable', (tester) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: DashboardBody(
            kundliId: 'k1',
            moduleCtx: _moduleCtx('k1'),
            activeViewId: 'v1',
            onSelectView: (_) {},
            readOnly: true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
    // Tapping the active chip in a read-only host does nothing.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Overview'));
    await tester.pumpAndSettle();
    expect(find.text('Rename view'), findsNothing);
  });
}
