import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../charts/pinch_zoom.dart';
import '../charts/sudarshana_painter.dart';
import '../core/astro/divisional.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _sudarshanaTitle(AppLocalizations l10n) => l10n.moduleSudarshanaTitle;

/// Sudarshana Chakra — the Lagna, Chandra and Surya charts drawn as
/// three radially-aligned wheels (Lagna innermost), so every house is
/// read three ways at once, per BPHS.
class SudarshanaModule extends AstroModule {
  const SudarshanaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'sudarshana',
        title: 'Sudarshana Chakra',
        localizedTitle: _sudarshanaTitle,
        icon: Icons.track_changes_outlined,
        category: 'Chakra',
        defaultSpan: CardSpan.full,
      );

  // Pinch to zoom (two fingers), card and detail alike. AspectRatio
  // outside PinchZoom so the zoom viewport is bounded (see chart_view).
  Widget _chart(AppLocalizations l10n, AstroSnapshot s) => AspectRatio(
        aspectRatio: 1,
        child: PinchZoom(
          child: CustomPaint(
            painter: SudarshanaPainter(
              l10n: l10n,
              lagnaSign: s.lagnaSign,
              moonSign: s.moonSign,
              sunSign: s.positions[Planet.sun]!.sign,
              placements: vargaPlacements(s, Varga.d1),
            ),
          ),
        ),
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chart(l10n, s),
        const SizedBox(height: 10),
        Text(
          '${l10n.sudarshanaInnerOuter(
            s.lagnaSign.label(l10n),
            s.moonSign.label(l10n),
            s.positions[Planet.sun]!.sign.label(l10n),
          )} ${l10n.sudarshanaSectorNote}',
          style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final bases = [
      (l10n.labelLagna, s.lagnaSign),
      (l10n.labelChandra, s.moonSign),
      (l10n.labelSurya, s.positions[Planet.sun]!.sign),
    ];
    final placements = vargaPlacements(s, Varga.d1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.moduleSudarshanaTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.sudarshanaBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 12),
          _chart(l10n, s),
          const SizedBox(height: 8),
          Text(
            l10n.sudarshanaInnerOuter(
              s.lagnaSign.label(l10n),
              s.moonSign.label(l10n),
              s.positions[Planet.sun]!.sign.label(l10n),
            ),
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          for (final (name, base) in bases) ...[
            Text(l10n.sudarshanaChartHouses(name),
                style: KJTheme.serif(size: 15)),
            const SizedBox(height: 6),
            for (var h = 1; h <= 12; h++)
              if ((placements[ZodiacSign.values[(base.index + h - 1) % 12]] ??
                      const [])
                  .isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'H$h · ${ZodiacSign.values[(base.index + h - 1) % 12].label(l10n)}'
                    ' — ${placements[ZodiacSign.values[(base.index + h - 1) % 12]]!.map((p) => p.label(l10n)).join(', ')}',
                    style: KJTheme.mono(size: 11.5),
                  ),
                ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final s = ctx.snapshot;
    final placements = vargaPlacements(s, Varga.d1);
    final bases = [
      (l10n.labelLagna, s.lagnaSign),
      (l10n.labelChandra, s.moonSign),
      (l10n.labelSurya, s.positions[Planet.sun]!.sign),
    ];
    return [
      pdfSectionHeader(l10n.moduleSudarshanaTitle),
      pw.TableHelper.fromTextArray(
        headers: [l10n.labelHouse, for (final (name, _) in bases) name],
        data: [
          for (var h = 1; h <= 12; h++)
            [
              'H$h',
              for (final (_, base) in bases)
                () {
                  final sign = ZodiacSign.values[(base.index + h - 1) % 12];
                  final planets = placements[sign] ?? const [];
                  return '${sign.abbrLabel(l10n)}'
                      '${planets.isEmpty ? '' : ' · ${planets.map((p) => p.abbrLabel(l10n)).join(' ')}'}';
                }(),
            ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 8),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }
}
