import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_view.dart';
import '../core/astro/jaimini_pada.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _jaiminiPadasTitle(AppLocalizations l10n) =>
    l10n.moduleJaiminiPadasTitle;

/// Arudha Padas 1P–12P (1P = Arudha Lagna), K.N. Rao's method — see
/// core/astro/jaimini_pada.dart for the calculation. Rendered as an
/// independent pada kundli (Parashar Light's "Pada" chart): only the
/// pada codes and the ascendant marker, no grahas.
class JaiminiPadaModule extends AstroModule {
  const JaiminiPadaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'jaimini_pada',
        title: 'Jaimini Padas',
        localizedTitle: _jaiminiPadasTitle,
        icon: Icons.grid_on_outlined,
        category: 'Jaimini',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) =>
      [chartStyleChoice(l10n)];

  /// Grahas sitting in a pada's sign — useful context alongside the
  /// bare sign (an Arudha with no occupants reads very differently
  /// from one crowded with planets).
  List<Planet> _occupants(AstroSnapshot s, ZodiacSign sign) =>
      s.positions.values
          .where((p) => p.sign == sign)
          .map((p) => p.planet)
          .toList();

  Widget _padaChart(ModuleContext ctx) {
    final s = ctx.snapshot;
    return ChartView(
      placements: const {},
      padaLabels: padaLabelsBySign(arudhaPadas(s)),
      lagna: s.lagnaSign,
      trueAscendantSign: s.lagnaSign,
      style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
    );
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final padas = arudhaPadas(ctx.snapshot);
    final al = padas.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _padaChart(ctx),
        const SizedBox(height: 10),
        Text(
          context.l10n.jpArudhaLagnaLine(al.sign.label(context.l10n)),
          style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final padas = arudhaPadas(s);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.jpHeading, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.jpBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          _padaChart(ctx),
          const SizedBox(height: 20),
          Text(l10n.jpPadasOccupants, style: KJTheme.serif(size: 16)),
          const SizedBox(height: 8),
          for (final p in padas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(p.house == 1 ? l10n.jpArudhaLagnaLabel : p.code,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(p.sign.label(l10n),
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _occupants(s, p.sign).isEmpty
                          ? '—'
                          : _occupants(s, p.sign)
                              .map((pl) => pl.label(l10n))
                              .join(', '),
                      style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final s = ctx.snapshot;
    final padas = arudhaPadas(s);
    return [
      pdfSectionHeader(l10n.jpHeading),
      pw.Center(
        child: pdfChart(
          l10n: l10n,
          placements: const {},
          padaLabels: padaLabelsBySign(padas),
          lagna: s.lagnaSign,
          trueAscendantSign: s.lagnaSign,
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          size: 200,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        headers: [l10n.labelPada, l10n.labelSign, l10n.labelOccupants],
        data: [
          for (final p in padas)
            [
              p.house == 1 ? l10n.jpArudhaLagnaLabel : p.code,
              p.sign.label(l10n),
              _occupants(s, p.sign).map((pl) => pl.label(l10n)).join(', '),
            ],
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
