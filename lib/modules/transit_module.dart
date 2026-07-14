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
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_style.dart';
import '../charts/chart_view.dart';
import '../charts/planet_token.dart';
import '../core/astro/models.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

class TransitModule extends AstroModule {
  const TransitModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'transit',
        title: 'Transit',
        icon: Icons.public,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices() => const [
        chartStyleChoice,
        ModuleConfigChoice(
          key: 'degrees',
          label: 'Planet degrees',
          options: [('off', 'Hide'), ('on', 'Show')],
        ),
        ModuleConfigChoice(
          key: 'sav',
          label: 'SAV points',
          options: [('off', 'Hide'), ('on', 'Show')],
        ),
      ];

  bool _showDegrees(Map<String, dynamic> config) =>
      (config['degrees'] as String?) == 'on';

  bool _showSav(Map<String, dynamic> config) =>
      (config['sav'] as String?) == 'on';

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
    return [
      pdfSectionHeader('Transit'),
      pw.Text(
        // A PDF is static, so it can only ever capture the instant it
        // was exported at — call that out explicitly.
        'Sky positions as of export time: ${now.toLocal()}',
        style: pdfLabel(),
      ),
      pw.SizedBox(height: 6),
      pw.Center(
        child: pdfChart(
          placements: transit.transitPlacements(tPos),
          lagna: s.lagnaSign,
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          retrograde: {for (final p in tPos.values) p.planet: p.isRetrograde},
          trueAscendantSign: s.lagnaSign,
          ascendantDegree: s.ascendant,
          padaLabels: showSav ? _savLabels(ctx) : const {},
        ),
      ),
      if (showSav) ...[
        pw.SizedBox(height: 4),
        pw.Text('SAV bindus per sign (Sarvashtakavarga)', style: pdfLabel()),
      ],
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        headers: ['Graha', 'Sign', 'Degree', 'Nakshatra'],
        data: [
          for (final p in tPos.values)
            [
              '${p.planet.displayName}${p.isRetrograde ? ' (R)' : ''}',
              p.sign.western,
              formatDegree(p.longitude),
              p.nakshatra.displayName,
            ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 9.5),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }
}

class _TransitBody extends ConsumerStatefulWidget {
  const _TransitBody({
    required this.ctx,
    required this.style,
    required this.showDegrees,
    this.savLabels = const {},
    this.detailed = false,
  });

  final ModuleContext ctx;
  final ChartStyle style;
  final bool showDegrees;

  /// SAV bindu-count overlay, one entry per sign — see
  /// [TransitModule._savLabels]. Empty when the config choice is off.
  final Map<ZodiacSign, List<String>> savLabels;
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
      final fixed =
          ref.read(transitFixedTimeProvider(widget.ctx.kundli.id));
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
    final fixed =
        ref.watch(transitFixedTimeProvider(widget.ctx.kundli.id));
    final asOf = fixed ?? DateTime.now();
    final isLive = fixed == null;
    final tPos = transit.currentTransitPositions(
        ayanamsaId: s.ayanamsaId, at: asOf);
    final placements = transit.transitPlacements(tPos);
    final retro = {for (final p in tPos.values) p.planet: p.isRetrograde};
    final tokens = <Planet, PlanetToken>{};
    if (widget.showDegrees) {
      for (final p in tPos.values) {
        tokens[p.planet] = PlanetToken(
          planet: p.planet,
          retrograde: p.isRetrograde,
          degreeInSign: p.degreesInSign,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartView(
          placements: placements,
          lagna: s.lagnaSign,
          trueAscendantSign: s.lagnaSign,
          ascendantDegree: s.ascendant,
          style: widget.style,
          retrograde: retro,
          tokens: tokens,
          showDegrees: widget.showDegrees,
          padaLabels: widget.savLabels,
        ),
        const SizedBox(height: 10),
        Text(
          'Transiting grahas in the ${s.lagnaSign.western} lagna houses'
          '${isLive ? ' · live' : ''}',
          style: TETheme.mono(size: 12, color: TEColors.inkSoft),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Graha positions are geocentric — identical from any place',
            style: TETheme.mono(
                size: 10.5, color: TEColors.inkSoft.withValues(alpha: 0.7)),
          ),
        ),
        if (widget.savLabels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'SAV bindus per sign (Sarvashtakavarga)',
              style: TETheme.mono(
                  size: 10.5, color: TEColors.inkSoft.withValues(alpha: 0.7)),
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
          Text('Transit Positions', style: TETheme.serif(size: 16)),
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
