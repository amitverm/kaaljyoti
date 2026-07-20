/// Anonymized community chart viewer — the SAME dashboard experience
/// as the user's own kundlis: global views, all widgets, complete
/// calculations (dashas included), because Mahakosh charts carry full
/// birth details with only the name withheld. Cards support drill-in
/// detail views and the per-widget settings menu (which only edits the
/// viewer's OWN global dashboard layout, never the shared chart). The
/// chart data itself stays read-only and server-owned — birth details
/// cannot be edited, and the birth time is never displayed. PDF export
/// is deliberately NOT offered here: the export (cover page especially)
/// prints the exact birth time, which must stay withheld for anonymized
/// community charts. Legacy charts shared before the birth-data change
/// (no birth instant stored) get a limited longitude-only view.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../charts/chart_style.dart';
import '../charts/chart_view.dart';
import '../core/astro/ayanamsa.dart';
import '../core/astro/models.dart';
import '../core/astro/snapshot_builder.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../mahakosh/models.dart';
import '../mahakosh/report_chart.dart';
import '../screens/dashboard_screen.dart' show showWidgetMenu;
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../widgetsystem/astro_module.dart';
import '../widgetsystem/registry.dart';

typedef _MkEvent = ({
  String tag,
  String? date,
  String precision,
  int? ageYears,
  bool isHealth
});

/// The community-card label for one life event, honouring the precision the
/// native recorded (exact / month / year / age) rather than forcing a year.
String _mkEventLabel(AppLocalizations l10n, _MkEvent e) {
  final when = switch (e.precision) {
    'age' => e.ageYears == null ? '' : l10n.mkcAge('${e.ageYears}'),
    'year' => e.date == null ? '' : e.date!.split('-').first,
    'month' => e.date == null
        ? ''
        : DateFormat('MMM yyyy').format(DateTime.parse(e.date!)),
    _ => e.date == null ? '' : KJDate.date(DateTime.parse(e.date!)),
  };
  return when.isEmpty ? e.tag : '${e.tag} · $when';
}

/// Full snapshot for a community chart, recomputed on-device from its
/// birth details — identical precision to the user's own kundlis.
final _mahakoshSnapshotProvider =
    FutureProvider.family<AstroSnapshot, String>((ref, mkCode) async {
  final chart = await ref.watch(mahakoshChartProvider(mkCode).future);
  if (!chart.hasBirthData) throw StateError('legacy chart');
  final birth = BirthData(
    dateTimeUtc: chart.birthUtc!,
    latitude: chart.latitude ?? 0,
    longitude: chart.longitude ?? 0,
    timezoneName: chart.timezoneName ?? 'UTC',
    utcOffsetMinutes: chart.utcOffsetMinutes ?? 0,
    placeName: chart.placeName ?? chart.locationGeneral,
  );
  return SnapshotBuilder().build(birth, chart.ayanamsaId);
});

class MahakoshChartScreen extends ConsumerStatefulWidget {
  const MahakoshChartScreen({super.key, required this.mkCode});
  final String mkCode;

  @override
  ConsumerState<MahakoshChartScreen> createState() =>
      _MahakoshChartScreenState();
}

class _MahakoshChartScreenState extends ConsumerState<MahakoshChartScreen> {
  String? _activeViewId;

  Future<void> _toggleBookmark(bool currently) async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null) return;
    try {
      if (currently) {
        await repo.removeBookmark(widget.mkCode);
      } else {
        await repo.addBookmark(widget.mkCode);
      }
      ref.invalidate(mahakoshBookmarkCodesProvider);
      ref.invalidate(mahakoshBookmarksProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.mkcBookmarkError('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(mahakoshChartProvider(widget.mkCode));
    final isBm =
        (ref.watch(mahakoshBookmarkCodesProvider).value ?? const <String>{})
            .contains(widget.mkCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mkcTitle(widget.mkCode)),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: context.l10n.mkcDiscussion,
            onPressed: () =>
                context.push('/mahakosh/chart/${widget.mkCode}/discussion'),
          ),
          IconButton(
            icon: Icon(isBm ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isBm
                ? context.l10n.mkcRemoveBookmark
                : context.l10n.mkcBookmark,
            onPressed: () => _toggleBookmark(isBm),
          ),
          PopupMenuButton<void>(
            tooltip: context.l10n.rdMore,
            itemBuilder: (ctx) => [
              PopupMenuItem(
                onTap: _hideChart,
                child: Text(context.l10n.rdHideFromView),
              ),
              PopupMenuItem(
                onTap: () => showReportChartSheet(context, ref, widget.mkCode,
                    onReported: () => GoRouter.of(context).pop()),
                child: const Text('Report...'),
              ),
            ],
          ),
        ],
      ),
      body: chartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: context.l10n.mkcLoadError('$e')),
        data: (chart) =>
            chart.hasBirthData ? _fullDashboard(chart) : _legacyView(chart),
      ),
    );
  }

  /// Hide this chart from THIS user's Mahakosh view only (§2.7a). Once
  /// hidden, this user's own RLS-governed reads will 404 it — so the
  /// detail screen can no longer show it and pops back, with an "Undo"
  /// affordance in the snackbar.
  Future<void> _hideChart() async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null) return;
    final mkCode = widget.mkCode;
    // Captured before the first await — context must not be used across
    // suspension points (and this one pops the screen itself).
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.hideChart(mkCode);
      router.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.rdHidden(mkCode)),
        action: SnackBarAction(
          label: l10n.rdUndo,
          onPressed: () => repo.unhideChart(mkCode),
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.rdHideError('$e'))));
    }
  }

  // ------------------------------------------------------------------
  // Full experience: global views over a locally recomputed snapshot.
  // ------------------------------------------------------------------
  Widget _fullDashboard(AnonymizedChart chart) {
    final snapshotAsync = ref.watch(_mahakoshSnapshotProvider(widget.mkCode));
    final viewsAsync = ref.watch(dashboardViewsProvider);

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.dbCalcFailed('$e')),
      data: (snapshot) => viewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: context.l10n.dbViewsError('$e')),
        data: (views) {
          final active = views.isEmpty
              ? null
              : views.firstWhere((v) => v.id == _activeViewId,
                  orElse: () => views.first);
          if (active == null) {
            return EmptyState(message: context.l10n.dbNoViews);
          }
          final kundli = syntheticKundliForChart(chart);
          final ctx = ModuleContext(
            kundli: kundli,
            snapshot: snapshot,
            chartStyle: ChartStyle.north,
            // Community chart — modules must not expose the birth time.
            anonymized: true,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    // Birth TIME is deliberately not displayed — it is
                    // used for the calculations but withheld from the
                    // UI (thousands of births share a date + place;
                    // the exact minute is the identifying detail).
                    [
                      context.l10n.mkcAnonymized,
                      KJDate.date(kundli.toBirthData().localDateTime),
                      context.l10n.mkcBirthTimeHidden,
                      if ((chart.placeName ?? '').isNotEmpty) chart.placeName!,
                      Ayanamsa.byId(chart.ayanamsaId).name,
                    ].join(' · '),
                    style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final v in views)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(v.name),
                          selected: v.id == active.id,
                          labelStyle: TextStyle(
                              color: v.id == active.id
                                  ? KJColors.paper
                                  : KJColors.ink),
                          onSelected: (_) =>
                              setState(() => _activeViewId = v.id),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _grid(active.id, ctx, chart)),
            ],
          );
        },
      ),
    );
  }

  /// The dashboard grid: same packing and cards as the user's own
  /// kundlis. Drill-in and the per-widget settings menu are enabled;
  /// long-press drag-to-rearrange is not (arrangement is edited from the
  /// user's own dashboard, whose global views this chart also uses).
  Widget _grid(String viewId, ModuleContext ctx, AnonymizedChart chart) {
    final placedAsync = ref.watch(viewWidgetsProvider(viewId));
    return placedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(message: context.l10n.dbWidgetsError('$e')),
      data: (placed) => LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        int units(CardSpan s) => switch (s) {
              CardSpan.full => 6,
              CardSpan.half => 3,
              CardSpan.third => isWide ? 2 : 3,
            };
        final rows = <List<PlacedWidget>>[];
        var current = <PlacedWidget>[];
        var used = 0;
        for (final p in placed) {
          final u = units(p.span);
          if (used + u > 6 && current.isNotEmpty) {
            rows.add(current);
            current = [];
            used = 0;
          }
          current.add(p);
          used += u;
          if (used >= 6) {
            rows.add(current);
            current = [];
            used = 0;
          }
        }
        if (current.isNotEmpty) rows.add(current);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        flex: units(row[i].span),
                        child: _card(row[i], ctx),
                      ),
                    ],
                    if (row.fold<int>(0, (s, p) => s + units(p.span)) < 6)
                      Expanded(
                        flex: 6 - row.fold<int>(0, (s, p) => s + units(p.span)),
                        child: const SizedBox(),
                      ),
                  ],
                ),
              ),
            if (chart.events.isNotEmpty) _eventsCard(chart),
            _discussionCard(),
          ],
        );
      }),
    );
  }

  /// Entry card into the chart's discussion thread — the per-chart
  /// section where users comment on and discuss this kundli.
  Widget _discussionCard() {
    final count =
        ref.watch(chartCommentCountProvider(widget.mkCode)).value ?? 0;
    return Card(
      child: ListTile(
        leading: Icon(Icons.forum_outlined, color: KJColors.maroon),
        title: Text(context.l10n.mkcDiscussion,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(
          count == 0
              ? context.l10n.mkcBeFirst
              : context.l10n.mkcComments(count),
          style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () =>
            context.push('/mahakosh/chart/${widget.mkCode}/discussion'),
      ),
    );
  }

  Widget _card(PlacedWidget pwd, ModuleContext ctx) {
    final module = moduleById(pwd.widgetId);
    if (module == null) return const SizedBox();
    return ModuleCard(
      title: moduleInstanceTitle(module, pwd.config, context.l10n),
      // Drill-in — pure calculation, routed through the SAME detail
      // screen as the user's own kundlis (the mk_ id resolves to this
      // chart's in-memory synthetic kundli). The card's own config is
      // carried so the detail view shows the same instance.
      onDetail: module.meta.hasDetailView
          ? () => context.push(
                '/kundli/$kMahakoshKundliPrefix${widget.mkCode}/module/'
                '${module.meta.id}'
                '?instance=${Uri.encodeComponent(pwd.instanceId)}'
                '&view=${Uri.encodeComponent(pwd.viewId)}',
                extra: pwd.config,
              )
          : null,
      // Per-widget settings edit the viewer's OWN global dashboard views
      // (size / config / duplicate / remove) — never the shared chart.
      onSettings: () => showWidgetMenu(context, ref, module, pwd),
      child: module.cardView(context, ctx.withConfig(pwd.config)),
    );
  }

  Widget _eventsCard(AnonymizedChart chart) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.mkcLifeEvents,
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: KJColors.inkSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              for (final e in chart.events)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _mkEventLabel(context.l10n, e),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (e.isHealth)
                        KJTag(context.l10n.mkcHealth, maroon: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

  // ------------------------------------------------------------------
  // Legacy charts (shared before birth details were stored): basic
  // longitude-only rendering.
  // ------------------------------------------------------------------
  Widget _legacyView(AnonymizedChart chart) {
    final positions = <Planet, double>{
      for (final e in chart.longitudes.entries)
        if (_planetByName(e.key) != null) _planetByName(e.key)!: e.value,
    };
    final placements = {for (final s in ZodiacSign.values) s: <Planet>[]};
    positions.forEach((planet, lon) {
      placements[ZodiacSign.fromLongitude(lon)]!.add(planet);
    });
    final lagna = ZodiacSign.fromLongitude(chart.ascendant);

    return ListView(
      padding: formPadding(context),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KJColors.maroon.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KJColors.maroon.withValues(alpha: 0.3)),
          ),
          child: Text(
            context.l10n.mkcLegacyNotice,
            style: TextStyle(fontSize: 12.5, color: KJColors.maroon),
          ),
        ),
        const SizedBox(height: 12),
        ChartView(
            placements: placements, lagna: lagna, style: ChartStyle.north),
        const SizedBox(height: 8),
        Text(
          '${context.l10n.labelLagna} ${lagna.label(context.l10n)} · '
          '${formatDegree(chart.ascendant)}',
          style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
        ),
        const SizedBox(height: 12),
        for (final entry in positions.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 90,
                    child: Text(entry.key.label(context.l10n),
                        style: TextStyle(
                            fontSize: 13,
                            color: planetInk(entry.key),
                            fontWeight: FontWeight.w600))),
                Expanded(
                  child: Text(
                    '${ZodiacSign.fromLongitude(entry.value).label(context.l10n)} '
                    '${formatDegree(entry.value)} · '
                    '${Nakshatra.fromLongitude(entry.value).label(context.l10n)}',
                    style: KJTheme.mono(size: 11.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Planet? _planetByName(String name) {
    for (final p in Planet.values) {
      if (p.name == name) return p;
    }
    return null;
  }
}
