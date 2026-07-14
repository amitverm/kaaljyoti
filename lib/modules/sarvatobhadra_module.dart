import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/pinch_zoom.dart';
import '../charts/sbc_painter.dart';
import '../core/astro/kota_chakra.dart' show isChakraMalefic;
import '../core/astro/models.dart';
import '../core/astro/nakshatra28.dart';
import '../core/astro/sarvatobhadra.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Sarvatobhadra Chakra — the fixed 9×9 transit grid with vedha
/// analysis on the natal anchors (janma nakshatra, rashi, lagna,
/// tithi group, weekday). Follows the per-kundli transit scrub time.
class SarvatobhadraModule extends AstroModule {
  const SarvatobhadraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'sarvatobhadra',
        title: 'Sarvatobhadra Chakra',
        icon: Icons.grid_on,
        category: 'Chakra',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _SbcBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _SbcBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final v = _SbcVedhas(ctx.snapshot, null);
    return [
      pdfSectionHeader('Sarvatobhadra Chakra — vedhas on natal anchors'),
      pw.TableHelper.fromTextArray(
        headers: ['Natal anchor', 'Vedha from (transit)'],
        data: [
          for (final e in v.anchorReport.entries)
            [e.key, e.value.isEmpty ? '—' : e.value.join(', ')],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 9),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }
}

/// Everything the painter + report need for one instant.
class _SbcVedhas {
  _SbcVedhas(AstroSnapshot s, DateTime? fixed) {
    final tPos = transit.currentTransitPositions(
        ayanamsaId: s.ayanamsaId, at: fixed ?? DateTime.now());

    (int, int) nakCell(double lon) =>
        sbcNakCell[Nakshatra28.fromLongitude(lon)]!;

    natalByCell = {};
    for (final p in s.positions.values) {
      (natalByCell[nakCell(p.longitude)] ??= []).add(p.planet);
    }
    transitByCell = {};
    for (final p in tPos.values) {
      (transitByCell[nakCell(p.longitude)] ??= []).add(p.planet);
    }

    // Natal anchors.
    final janmaCell = nakCell(s.positions[Planet.moon]!.longitude);
    final rashiCell = sbcRashiCell[s.moonSign]!;
    final lagnaCell = sbcRashiCell[s.lagnaSign]!;
    final tithiCell = sbcTithiCell(s.panchang.tithiIndex);
    final varaCell = sbcVaraCell(s.panchang.vara);
    anchors = {
      janmaCell, rashiCell, lagnaCell, tithiCell,
      if (varaCell != null) varaCell,
    };

    // Vedha cells per transiting planet.
    maleficVedha = {};
    beneficVedha = {};
    final vedhas = sbcVedhasByPlanet(tPos);
    final anchorHits = <String, List<String>>{
      'Janma nakshatra (${Nakshatra28.abbrs[Nakshatra28.fromLongitude(s.positions[Planet.moon]!.longitude)]})':
          [],
      'Janma rashi (${s.moonSign.western})': [],
      'Lagna (${s.lagnaSign.western})': [],
      'Janma tithi group': [],
      'Janma vara': [],
    };
    final anchorCells = [
      janmaCell, rashiCell, lagnaCell, tithiCell, varaCell,
    ];
    vedhas.forEach((planet, cells) {
      final malefic = isChakraMalefic(planet);
      final set = cells.toSet();
      (malefic ? maleficVedha : beneficVedha).addAll(set);
      for (var i = 0; i < anchorCells.length; i++) {
        final a = anchorCells[i];
        if (a != null && set.contains(a)) {
          anchorHits[anchorHits.keys.elementAt(i)]!.add(
              '${planet.displayName}${malefic ? ' (M)' : ' (B)'}');
        }
      }
    });
    anchorReport = anchorHits;
  }

  late final Map<(int, int), List<Planet>> natalByCell;
  late final Map<(int, int), List<Planet>> transitByCell;
  late final Set<(int, int)> anchors;
  late final Set<(int, int)> maleficVedha;
  late final Set<(int, int)> beneficVedha;
  late final Map<String, List<String>> anchorReport;
}

class _SbcBody extends ConsumerWidget {
  const _SbcBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ctx.snapshot;
    final fixed = ref.watch(transitFixedTimeProvider(ctx.kundli.id));
    final v = _SbcVedhas(s, fixed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail) ...[
          Text('Sarvatobhadra Chakra', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Fixed 9×9 grid. Each transiting graha pierces three vedha'
            ' lines (across + both diagonals) from its nakshatra. Warm'
            ' tint: malefic vedha; green: benefic; deep tint: your natal'
            ' anchors. Across is strongest at normal speed, the forward'
            ' diagonal when fast (always Sun/Moon), the rear when'
            ' retrograde (always Rahu/Ketu).',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 12),
        ],
        // Pinch to zoom (two fingers), card and detail alike — 81
        // cells of small text want magnification.
        PinchZoom(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: SbcPainter(
                anchors: v.anchors,
                maleficVedha: v.maleficVedha,
                beneficVedha: v.beneficVedha,
                natalByCell: v.natalByCell,
                transitByCell: v.transitByCell,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          fixed != null
              ? 'Transit as of chosen time'
              : 'Transit live · natal planets in ink, transit in green',
          style: TETheme.mono(size: 11, color: TEColors.inkSoft),
        ),
        if (detail) ...[
          const SizedBox(height: 8),
          TransitTimeBar(
            fixed: fixed,
            onChanged: (f) => ref
                .read(transitFixedTimeProvider(ctx.kundli.id).notifier)
                .state = f,
          ),
        ],
        const SizedBox(height: 8),
        for (final e in v.anchorReport.entries)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${e.key}: ${e.value.isEmpty ? 'no vedha' : e.value.join(', ')}',
              style: TETheme.mono(
                size: 11,
                color: e.value.any((s) => s.endsWith('(M)'))
                    ? TEColors.maroon
                    : e.value.isEmpty
                        ? TEColors.inkSoft
                        : TEColors.forest,
              ),
            ),
          ),
      ],
    );
  }
}
