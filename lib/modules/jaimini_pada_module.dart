import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_view.dart';
import '../core/astro/jaimini_pada.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

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
        icon: Icons.grid_on_outlined,
        category: 'Jaimini',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices() => const [chartStyleChoice];

  /// Grahas sitting in a pada's sign — useful context alongside the
  /// bare sign (an Arudha with no occupants reads very differently
  /// from one crowded with planets).
  List<Planet> _occupants(AstroSnapshot s, ZodiacSign sign) =>
      s.positions.values.where((p) => p.sign == sign).map((p) => p.planet).toList();

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
          'Arudha Lagna (1P) ${al.sign.western}',
          style: TETheme.mono(size: 12, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final padas = arudhaPadas(s);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jaimini Arudha Padas', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'One per house — how that house "appears", as distinct from'
            ' its true placement. 1P (Arudha Lagna) is the most used.'
            ' K.N. Rao\'s calculation, without the 1st/7th exceptions.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 16),
          _padaChart(ctx),
          const SizedBox(height: 20),
          Text('Padas & occupants', style: TETheme.serif(size: 16)),
          const SizedBox(height: 8),
          for (final p in padas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(p.label,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(p.sign.western,
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _occupants(s, p.sign).isEmpty
                          ? '—'
                          : _occupants(s, p.sign)
                              .map((pl) => pl.displayName)
                              .join(', '),
                      style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
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
    final s = ctx.snapshot;
    final padas = arudhaPadas(s);
    return [
      pdfSectionHeader('Jaimini Arudha Padas'),
      pw.Center(
        child: pdfChart(
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
        headers: ['Pada', 'Sign', 'Occupants'],
        data: [
          for (final p in padas)
            [
              p.label,
              p.sign.western,
              _occupants(s, p.sign).map((pl) => pl.displayName).join(', '),
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
