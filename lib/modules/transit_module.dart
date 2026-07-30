/// Standalone "sky" widget — distinct from the Birth Chart's transit
/// OVERLAY (which draws current planets alongside the natal ones on
/// the same wheel). This module dedicates its own card to the
/// transiting grahas, placed in the houses of the open kundli's lagna.
///
/// Defaults to live (ticking) via the shared [TransitTimeBar], but is
/// just as often scrubbed to a past or future instant — "Transit" is
/// the right name either way; "live" is a state the widget is in
/// (shown by the bar's own "Live · <timestamp>" pill), not a fixed
/// identity, so it doesn't belong in the module's name.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_style.dart';
import '../charts/chart_view.dart';
import '../charts/planet_token.dart';
import '../core/astro/models.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _transitTitle(AppLocalizations l10n) => l10n.moduleTransitTitle;

class TransitModule extends AstroModule {
  const TransitModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'transit',
        title: 'Transit',
        localizedTitle: _transitTitle,
        icon: Icons.public,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        chartStyleChoice(l10n),
        ModuleConfigChoice(
          key: 'degrees',
          label: l10n.cfgPlanetDegrees,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
        ModuleConfigChoice(
          key: 'sav',
          label: l10n.cfgSavPoints,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
        ModuleConfigChoice(
          key: 'tlagna',
          label: l10n.cfgTransitLagna,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
          // On by default: the rising lagna is the one transit datum
          // that can't be read off the natal wheel, and it's what gets
          // verified against desktop software.
          defaultValue: 'on',
        ),
      ];

  bool _showDegrees(Map<String, dynamic> config) =>
      (config['degrees'] as String?) == 'on';

  bool _showSav(Map<String, dynamic> config) =>
      (config['sav'] as String?) == 'on';

  static bool _showTLagna(Map<String, dynamic> config) =>
      (config['tlagna'] as String?) != 'off';

  /// Grey overlay code for the transit lagna: 'TL', carrying its degree
  /// when the degrees toggle is on — the mark then verifies against
  /// desktop software without leaving the chart.
  static String _tlCode(double asc, bool showDegrees) =>
      showDegrees ? 'TL ${formatDegreeInSign(asc % 30)}' : 'TL';

  /// Sarvashtakavarga bindu count per sign, in the same light-grey
  /// overlay channel [ChartView.padaLabels] already uses for Jaimini
  /// pada codes and the Indu Lagna mark — "same visual treatment" for
  /// free. SAV is purely natal (sign-relative, not time-relative), so
  /// it's identical regardless of the scrubbed "as of" transit instant.
  Map<ZodiacSign, List<String>> _savLabels(ModuleContext ctx) {
    final sav = ctx.ashtakavarga.sav();
    return {
      for (final sign in ZodiacSign.values) sign: ['${sav[sign.index]}'],
    };
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) => _TransitBody(
        ctx: ctx,
        style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
        showDegrees: _showDegrees(ctx.config),
        savLabels: _showSav(ctx.config) ? _savLabels(ctx) : const {},
        showTLagna: _showTLagna(ctx.config),
      );

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _TransitBody(
          ctx: ctx,
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          showDegrees: _showDegrees(ctx.config),
          savLabels: _showSav(ctx.config) ? _savLabels(ctx) : const {},
          showTLagna: _showTLagna(ctx.config),
          detailed: true,
        ),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final s = ctx.snapshot;
    final now = DateTime.now();
    final tPos =
        transit.currentTransitPositions(ayanamsaId: s.ayanamsaId, at: now);
    final showSav = _showSav(ctx.config);
    final l10n = ctx.l10n;
    final ann = pdfAnnotationsFor(
        chartTokens(tPos, showDegrees: _showDegrees(ctx.config)));
    final tlAsc = _showTLagna(ctx.config)
        ? transit.transitAscendant(
            at: now,
            latitude: s.birth.latitude,
            longitude: s.birth.longitude,
            ayanamsaId: s.ayanamsaId,
          )
        : null;
    var overlay = showSav ? _savLabels(ctx) : const <ZodiacSign, List<String>>{};
    if (tlAsc != null) {
      overlay = {for (final e in overlay.entries) e.key: [...e.value]};
      (overlay[ZodiacSign.fromLongitude(tlAsc)] ??= [])
          .add(_tlCode(tlAsc, _showDegrees(ctx.config)));
    }
    return pdfSection(
      header: pdfSectionHeader(l10n.moduleTransitTitle),
      lead: pdfStack([
        pw.Text(
          // A PDF is static, so it can only ever capture the instant it
          // was exported at — call that out explicitly.
          l10n.transitPdfAsOf('${now.toLocal()}'),
          style: pdfLabel(),
        ),
        if (tlAsc != null)
          pw.Text(
            l10n.transitLagnaLine(
                '${ZodiacSign.fromLongitude(tlAsc).label(l10n)} '
                '${formatDegreeInSign(tlAsc % 30)}'),
            style: pdfLabel(),
          ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pdfChart(
            l10n: l10n,
            placements: transit.transitPlacements(tPos),
            lagna: s.lagnaSign,
            style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
            retrograde: {for (final p in tPos.values) p.planet: p.isRetrograde},
            trueAscendantSign: s.lagnaSign,
            ascendantDegree: s.ascendant,
            padaLabels: overlay,
            degreeLabels: ann.degrees,
          ),
        ),
        if (showSav) pdfNote(l10n.transitSavNote),
        pdfSectionGap(),
      ]),
      rest: [
        pdfDataTable(
          headers: [
            l10n.labelGraha,
            l10n.labelSign,
            l10n.labelDegree,
            l10n.labelNakshatra,
          ],
          rows: [
            for (final p in tPos.values)
              [
                '${p.planet.label(l10n)}${p.isRetrograde ? ' (R)' : ''}',
                p.sign.label(l10n),
                formatDegree(p.longitude),
                p.nakshatra.label(l10n),
              ],
          ],
        ),
      ],
    );
  }
}

class _TransitBody extends ConsumerStatefulWidget {
  const _TransitBody({
    required this.ctx,
    required this.style,
    required this.showDegrees,
    this.savLabels = const {},
    this.showTLagna = true,
    this.detailed = false,
  });

  final ModuleContext ctx;
  final ChartStyle style;
  final bool showDegrees;

  /// SAV bindu-count overlay, one entry per sign — see
  /// [TransitModule._savLabels]. Empty when the config choice is off.
  final Map<ZodiacSign, List<String>> savLabels;

  /// Mark the transit lagna (the sign rising at the transit instant
  /// over the birth place) with a grey 'TL' and print its degree below.
  /// The chart's houses stay anchored to the NATAL lagna — that is the
  /// reference the transit is read against — so the rising lagna is an
  /// annotation, never the wheel's anchor.
  final bool showTLagna;
  final bool detailed;

  @override
  ConsumerState<_TransitBody> createState() => _TransitBodyState();
}

class _TransitBodyState extends ConsumerState<_TransitBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Live tick: refresh positions every 30s while tracking real time.
    // The scrubbed instant itself lives in [transitFixedTimeProvider]
    // (per kundli), NOT in this State — so it survives the dashboard
    // being remounted on navigation, and card + detail views stay in
    // sync with each other.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final fixed = ref.read(transitFixedTimeProvider(widget.ctx.kundli.id));
      if (fixed == null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.ctx.snapshot;
    final fixed = ref.watch(transitFixedTimeProvider(widget.ctx.kundli.id));
    final asOf = fixed ?? DateTime.now();
    final isLive = fixed == null;
    final tPos =
        transit.currentTransitPositions(ayanamsaId: s.ayanamsaId, at: asOf);
    final placements = transit.transitPlacements(tPos);
    final retro = {for (final p in tPos.values) p.planet: p.isRetrograde};
    // Degrees only: dignity and karakas are natal readings, not gochar.
    final tokens = chartTokens(tPos, showDegrees: widget.showDegrees);

    // Transit lagna — rides the grey overlay channel next to the SAV
    // numbers; null when disabled or in degenerate polar cases.
    final tlAsc = widget.showTLagna
        ? transit.transitAscendant(
            at: asOf,
            latitude: s.birth.latitude,
            longitude: s.birth.longitude,
            ayanamsaId: s.ayanamsaId,
          )
        : null;
    var overlay = widget.savLabels;
    if (tlAsc != null) {
      overlay = {for (final e in overlay.entries) e.key: [...e.value]};
      (overlay[ZodiacSign.fromLongitude(tlAsc)] ??= [])
          .add(TransitModule._tlCode(tlAsc, widget.showDegrees));
    }

    // Gochar is routinely read from an anchor other than the natal
    // lagna — Chandra lagna above all — so this chart wants the same
    // double-tap / long-press rotation as the rashi and varga charts.
    // Keyed per kundli so it survives navigation and stays independent
    // of the Birth Chart's own rotation.
    final viewKey = '${widget.ctx.kundli.id}#transit';
    final viewFrom = ref.watch(widgetViewFromProvider(viewKey)) ?? s.lagnaSign;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartView(
          placements: placements,
          lagna: viewFrom,
          trueAscendantSign: s.lagnaSign,
          ascendantDegree: s.ascendant,
          // Rank among the TRANSIT bodies — they are what share the box.
          ascendantRank: ascendantRankIn(tPos, s.ascendant),
          style: widget.style,
          retrograde: retro,
          tokens: tokens,
          showDegrees: widget.showDegrees,
          padaLabels: overlay,
          onSignSelect: (sign) => ref
              .read(widgetViewFromProvider(viewKey).notifier)
              .state = sign == s.lagnaSign ? null : sign,
        ),
        const SizedBox(height: 10),
        Text(
          '${context.l10n.transitInLagnaHouses(s.lagnaSign.label(context.l10n))}'
          '${isLive ? ' · ${context.l10n.transitLiveWord}' : ''}',
          style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
        ),
        if (tlAsc != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              context.l10n.transitLagnaLine(
                  '${ZodiacSign.fromLongitude(tlAsc).label(context.l10n)} '
                  '${formatDegreeInSign(tlAsc % 30)}'),
              style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            context.l10n.transitGeocentricNote,
            style: KJTheme.mono(
                size: 10.5, color: KJColors.inkSoft.withValues(alpha: 0.7)),
          ),
        ),
        if (widget.savLabels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              context.l10n.transitSavNote,
              style: KJTheme.mono(
                  size: 10.5, color: KJColors.inkSoft.withValues(alpha: 0.7)),
            ),
          ),
        const SizedBox(height: 8),
        TransitTimeBar(
          fixed: fixed,
          onChanged: (f) => ref
              .read(transitFixedTimeProvider(widget.ctx.kundli.id).notifier)
              .state = f,
        ),
        if (widget.detailed) ...[
          const SizedBox(height: 20),
          Text(context.l10n.transitPositionsHeading,
              style: KJTheme.serif(size: 16)),
          const SizedBox(height: 8),
          TransitPositionsTable(positions: tPos),
        ],
      ],
    );
  }
}

// The transit positions table now lives in common.dart as the shared
// [TransitPositionsTable], reused by the Today screen's "Transit now"
// card.
