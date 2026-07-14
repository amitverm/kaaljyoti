import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_style.dart';
import '../charts/chart_view.dart';
import '../charts/planet_token.dart';
import '../core/astro/dignity.dart';
import '../core/astro/divisional.dart';
import '../core/astro/jaimini_karaka.dart';
import '../core/astro/jaimini_pada.dart';
import '../core/astro/special_lagna.dart';
import '../core/astro/models.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

const _onOff = <(String, String)>[('off', 'Hide'), ('on', 'Show')];

class BirthChartModule extends AstroModule {
  const BirthChartModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'birth_chart',
        title: 'Birth Chart',
        icon: Icons.grid_4x4,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  // The old 22-option "View from" list is gone: rotation now happens
  // by double-tapping a house on the chart itself (stored per kundli
  // in [chartViewFromProvider]). Legacy saved 'view_from' configs are
  // still honored via [_viewFromSign].
  @override
  List<ModuleConfigChoice> configChoices() => const [
        chartStyleChoice,
        ModuleConfigChoice(
          key: 'degrees', label: 'Planet degrees', options: _onOff),
        ModuleConfigChoice(
          key: 'karakas',
          label: 'Jaimini karakas (Sapta)',
          options: _onOff,
        ),
        ModuleConfigChoice(
          key: 'padas',
          label: 'Jaimini padas (1P–12P)',
          options: _onOff,
          defaultValue: 'on', // shown by default, Parashar Light style
        ),
        ModuleConfigChoice(
          key: 'indu',
          label: 'Indu Lagna mark (IL)',
          options: _onOff,
        ),
        ModuleConfigChoice(
          key: 'extras',
          label: 'Dignity & combustion',
          options: _onOff,
        ),
        ModuleConfigChoice(
          key: 'transit', label: 'Current transit overlay', options: _onOff),
      ];

  bool _flag(Map<String, dynamic> config, String key) =>
      (config[key] as String?) == 'on';

  /// Padas are on unless explicitly hidden.
  bool _showPadas(Map<String, dynamic> config) =>
      (config['padas'] as String?) != 'off';

  /// Grey chart overlay: pada codes plus, optionally, the Indu Lagna
  /// marker — both ride the same light-grey label channel.
  Map<ZodiacSign, List<String>> _overlay(
      AstroSnapshot s, Map<String, dynamic> config) {
    final map = <ZodiacSign, List<String>>{};
    if (_showPadas(config)) {
      padaLabelsBySign(arudhaPadas(s))
          .forEach((sign, codes) => map[sign] = [...codes]);
    }
    if (_flag(config, 'indu')) {
      (map[induLagnaSign(s)] ??= []).add('IL');
    }
    return map;
  }

  ZodiacSign _viewFromSign(Map<String, dynamic> config, AstroSnapshot s) {
    final raw = config['view_from'] as String?;
    if (raw == null || raw == 'lagna') return s.lagnaSign;
    const planetKeys = {
      'moon': Planet.moon,
      'sun': Planet.sun,
      'mars': Planet.mars,
      'mercury': Planet.mercury,
      'jupiter': Planet.jupiter,
      'venus': Planet.venus,
      'saturn': Planet.saturn,
      'rahu': Planet.rahu,
      'ketu': Planet.ketu,
    };
    final planet = planetKeys[raw];
    if (planet != null) return s.positions[planet]!.sign;
    if (raw.startsWith('h')) {
      final n = int.tryParse(raw.substring(1));
      if (n != null && n >= 1 && n <= 12) {
        return ZodiacSign.values[(s.lagnaSign.index + n - 1) % 12];
      }
    }
    return s.lagnaSign;
  }

  String _viewFromLabel(String value) {
    if (value == 'lagna' || value.isEmpty) return 'Lagna';
    if (value.startsWith('h') && int.tryParse(value.substring(1)) != null) {
      return 'House ${value.substring(1)}';
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Builds per-planet annotations from the natal snapshot according to
  /// the instance's config — degrees, Sapta Karakas, dignity, and
  /// combustion. Cheap enough to recompute per build (no ephemeris
  /// calls; those only happen for the optional transit overlay).
  Map<Planet, PlanetToken> _tokens(
    AstroSnapshot s, {
    required bool showDegrees,
    required bool showKarakas,
    required bool showExtras,
  }) {
    final karakas =
        showKarakas ? saptaKarakas(s.positions) : const <Planet, Karaka>{};
    final sun = s.positions[Planet.sun]!;
    return {
      for (final p in s.positions.values)
        p.planet: PlanetToken(
          planet: p.planet,
          retrograde: p.isRetrograde,
          degreeInSign: showDegrees ? p.degreesInSign : null,
          karaka: karakas[p.planet]?.code,
          dignity: showExtras ? dignityOf(p) : PlanetDignity.none,
          combust: showExtras && p.planet != Planet.sun
              ? isCombust(p, sun)
              : false,
        ),
    };
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final showDegrees = _flag(ctx.config, 'degrees');
    final showKarakas = _flag(ctx.config, 'karakas');
    final showExtras = _flag(ctx.config, 'extras');
    final showTransit = _flag(ctx.config, 'transit');
    final viewFrom = _viewFromSign(ctx.config, s);

    final tokens = _tokens(s,
        showDegrees: showDegrees, showKarakas: showKarakas, showExtras: showExtras);

    return _BirthChartCardBody(
      kundliId: ctx.kundli.id,
      snapshot: s,
      viewFrom: viewFrom,
      tokens: tokens,
      showDegrees: showDegrees,
      showKarakas: showKarakas,
      showTransit: showTransit,
      padaLabels: _overlay(s, ctx.config),
      style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
      viewFromLabel: viewFrom != s.lagnaSign
          ? _viewFromLabel((ctx.config['view_from'] as String?) ?? 'lagna')
          : null,
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final showKarakas = _flag(ctx.config, 'karakas');
    final showExtras = _flag(ctx.config, 'extras');
    final karakas =
        showKarakas ? saptaKarakas(s.positions) : const <Planet, Karaka>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartDetailHeader(ctx: ctx),
          cardView(context, ctx),
          if (showKarakas) ...[
            const SizedBox(height: 20),
            Text('Jaimini Karakas (Sapta)', style: TETheme.serif(size: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in karakas.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TEColors.paperAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TEColors.hairline),
                    ),
                    child: Text(
                      '${entry.value.code} · ${entry.key.displayName}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ],
          if (showExtras) ...[
            const SizedBox(height: 16),
            Text(
              '↑ exalted · ↓ debilitated · ○ own sign · • combust',
              style: TETheme.mono(size: 11, color: TEColors.inkSoft),
            ),
          ],
          const SizedBox(height: 24),
          Text('Planetary Positions', style: TETheme.serif(size: 18)),
          const SizedBox(height: 8),
          PositionsTable(snapshot: s, showAscendant: true),
        ],
      ),
    );
  }

  @override
  String? configSummary(Map<String, dynamic> config) {
    final parts = <String>[];
    final o = chartStyleFromConfig(config, ChartStyle.north);
    if (o.isOverridden) parts.add(o.style.displayName);
    final viewFrom = config['view_from'] as String?;
    if (viewFrom != null && viewFrom != 'lagna') {
      parts.add('From ${_viewFromLabel(viewFrom)}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final s = ctx.snapshot;
    return [
      pdfSectionHeader('Birth Chart (Rashi / D1)'),
      pw.Text(
        'Lagna: ${s.lagnaSign.western} ${formatDegree(s.ascendant)}',
        style: pdfBody(),
      ),
      pw.SizedBox(height: 10),
      pw.Center(
        child: pdfChart(
          placements: vargaPlacements(s, Varga.d1),
          lagna: s.lagnaSign,
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          retrograde: {
            for (final p in s.positions.values) p.planet: p.isRetrograde,
          },
          trueAscendantSign: s.lagnaSign,
          ascendantDegree: s.ascendant,
          padaLabels: _overlay(s, ctx.config),
        ),
      ),
      pw.SizedBox(height: 6),
    ];
  }
}

/// Card body split out from [BirthChartModule.cardView] so the optional
/// transit overlay can render a live-ticking "as of" clock via
/// [TransitTimeBar]. The scrubbed instant itself lives in
/// [transitFixedTimeProvider] (per kundli), NOT in this State — so it
/// survives the dashboard being remounted on navigation and stays in
/// sync with the standalone Transit widget.
class _BirthChartCardBody extends ConsumerStatefulWidget {
  const _BirthChartCardBody({
    required this.kundliId,
    required this.snapshot,
    required this.viewFrom,
    required this.tokens,
    required this.showDegrees,
    required this.showKarakas,
    required this.showTransit,
    required this.padaLabels,
    required this.style,
    this.viewFromLabel,
  });

  final String kundliId;
  final AstroSnapshot snapshot;
  final ZodiacSign viewFrom;
  final Map<Planet, PlanetToken> tokens;
  final bool showDegrees;
  final bool showKarakas;
  final bool showTransit;
  final Map<ZodiacSign, List<String>> padaLabels;
  final ChartStyle style;
  final String? viewFromLabel;

  @override
  ConsumerState<_BirthChartCardBody> createState() =>
      _BirthChartCardBodyState();
}

class _BirthChartCardBodyState extends ConsumerState<_BirthChartCardBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!widget.showTransit || !mounted) return;
      final fixed = ref.read(transitFixedTimeProvider(widget.kundliId));
      if (fixed == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    // Double-tap rotation wins over any legacy 'view_from' config.
    final tapped = ref.watch(chartViewFromProvider(widget.kundliId));
    final viewFrom = tapped ?? widget.viewFrom;
    final fixed = widget.showTransit
        ? ref.watch(transitFixedTimeProvider(widget.kundliId))
        : null;
    final isLive = fixed == null;

    Map<ZodiacSign, List<Planet>>? transitPlace;
    var transitRetro = const <Planet, bool>{};
    if (widget.showTransit) {
      final tPos = transit.currentTransitPositions(
          ayanamsaId: s.ayanamsaId, at: fixed ?? DateTime.now());
      transitPlace = transit.transitPlacements(tPos);
      transitRetro = {for (final p in tPos.values) p.planet: p.isRetrograde};
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartView(
          placements: vargaPlacements(s, Varga.d1),
          lagna: viewFrom,
          trueAscendantSign: s.lagnaSign,
          ascendantDegree: s.ascendant,
          style: widget.style,
          retrograde: {
            for (final p in s.positions.values) p.planet: p.isRetrograde,
          },
          tokens: widget.tokens,
          showDegrees: widget.showDegrees,
          showKarakas: widget.showKarakas,
          transitPlacements: transitPlace,
          transitRetrograde: transitRetro,
          padaLabels: widget.padaLabels,
          // Tapping the lagna's own house resets — unless a legacy
          // 'view_from' config would then re-rotate, in which case the
          // lagna sign is stored explicitly to override it.
          onSignSelect: (sign) => ref
                  .read(chartViewFromProvider(widget.kundliId).notifier)
                  .state =
              (sign == s.lagnaSign && widget.viewFrom == s.lagnaSign)
                  ? null
                  : sign,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Lagna ${s.lagnaSign.western} · ${formatDegree(s.ascendant)}'
                '${viewFrom != s.lagnaSign ? ' · Viewing from '
                    '${tapped != null ? tapped.western : widget.viewFromLabel ?? viewFrom.western}' : ''}',
                style: TETheme.mono(size: 12, color: TEColors.inkSoft),
              ),
            ),
            if (viewFrom != s.lagnaSign)
              InkWell(
                onTap: () => ref
                        .read(chartViewFromProvider(widget.kundliId).notifier)
                        .state =
                    widget.viewFrom == s.lagnaSign ? null : s.lagnaSign,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Text(
                    'Reset',
                    style: TETheme.mono(
                        size: 11.5,
                        color: TEColors.maroon,
                        weight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        if (viewFrom == s.lagnaSign)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Double-tap or long-press a house to view the chart from it',
              style: TETheme.mono(
                  size: 10.5,
                  color: TEColors.inkSoft.withValues(alpha: 0.7)),
            ),
          ),
        if (widget.showTransit) ...[
          const SizedBox(height: 8),
          TransitTimeBar(
            fixed: fixed,
            onChanged: (f) => ref
                .read(transitFixedTimeProvider(widget.kundliId).notifier)
                .state = f,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              isLive
                  ? 'Transit shown in green, live'
                  : 'Transit shown in green, as of the chosen date/time '
                      '(past, present, or future)',
              style: TETheme.mono(size: 10.5, color: TEColors.transit),
            ),
          ),
        ],
      ],
    );
  }
}
