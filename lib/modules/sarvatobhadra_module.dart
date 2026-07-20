import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/pinch_zoom.dart';
import '../charts/sbc_painter.dart';
import '../core/astro/kota_chakra.dart' show isChakraMalefic;
import '../core/astro/models.dart';
import '../core/astro/nakshatra28.dart';
import '../core/astro/sarvatobhadra.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _sarvatobhadraTitle(AppLocalizations l10n) =>
    l10n.moduleSarvatobhadraTitle;

/// Sarvatobhadra Chakra — the fixed 9×9 transit grid with vedha
/// analysis on the natal anchors (janma nakshatra, rashi, lagna,
/// tithi group, weekday). Follows the per-kundli transit scrub time.
class SarvatobhadraModule extends AstroModule {
  const SarvatobhadraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'sarvatobhadra',
        title: 'Sarvatobhadra Chakra',
        localizedTitle: _sarvatobhadraTitle,
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
    final l10n = ctx.l10n;
    final v = _SbcVedhas(ctx.snapshot, null, l10n);
    return [
      pdfSectionHeader(l10n.sarvatobhadraPdfHeader),
      pw.TableHelper.fromTextArray(
        headers: [l10n.sbcNatalAnchor, l10n.sbcVedhaFrom],
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
  _SbcVedhas(AstroSnapshot s, DateTime? fixed, AppLocalizations l10n) {
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
      janmaCell,
      rashiCell,
      lagnaCell,
      tithiCell,
      if (varaCell != null) varaCell,
    };

    // Vedha cells per transiting planet.
    maleficVedha = {};
    beneficVedha = {};
    final vedhas = sbcVedhasByPlanet(tPos);
    final anchorHits = <String, List<({String label, bool malefic})>>{
      l10n.sbcJanmaNakshatra(nakshatra28AbbrLabel(l10n,
          Nakshatra28.fromLongitude(s.positions[Planet.moon]!.longitude))): [],
      l10n.sbcJanmaRashi(s.moonSign.label(l10n)): [],
      l10n.sbcLagnaAnchor(s.lagnaSign.label(l10n)): [],
      l10n.sbcJanmaTithiGroup: [],
      l10n.sbcJanmaVara: [],
    };
    final anchorCells = [
      janmaCell,
      rashiCell,
      lagnaCell,
      tithiCell,
      varaCell,
    ];
    vedhas.forEach((planet, cells) {
      final malefic = isChakraMalefic(planet);
      final set = cells.toSet();
      (malefic ? maleficVedha : beneficVedha).addAll(set);
      for (var i = 0; i < anchorCells.length; i++) {
        final a = anchorCells[i];
        if (a != null && set.contains(a)) {
          anchorHits[anchorHits.keys.elementAt(i)]!.add((
            label: '${planet.label(l10n)}'
                ' (${malefic ? l10n.sbcMaleficMark : l10n.sbcBeneficMark})',
            malefic: malefic,
          ));
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
  late final Map<String, List<({String label, bool malefic})>> anchorReport;
}

class _SbcBody extends ConsumerWidget {
  const _SbcBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final fixed = ref.watch(transitFixedTimeProvider(ctx.kundli.id));
    final v = _SbcVedhas(s, fixed, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail) ...[
          Text(l10n.moduleSarvatobhadraTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.sbcBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 12),
        ],
        // Pinch to zoom (two fingers), card and detail alike — 81
        // cells of small text want magnification. AspectRatio outside
        // PinchZoom so the zoom viewport is bounded (see chart_view).
        AspectRatio(
          aspectRatio: 1,
          child: PinchZoom(
            child: CustomPaint(
              painter: SbcPainter(
                l10n: l10n,
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
          fixed != null ? l10n.kotaTransitAsOf : l10n.sbcTransitLive,
          style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
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
              '${e.key}: ${e.value.isEmpty ? context.l10n.sbNoVedha : e.value.map((h) => h.label).join(', ')}',
              style: KJTheme.mono(
                size: 11,
                color: e.value.any((h) => h.malefic)
                    ? KJColors.maroon
                    : e.value.isEmpty
                        ? KJColors.inkSoft
                        : KJColors.forest,
              ),
            ),
          ),
      ],
    );
  }
}
