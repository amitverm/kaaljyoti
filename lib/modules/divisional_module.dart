import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_view.dart';
import '../core/astro/divisional.dart';
import '../core/astro/jaimini_pada.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../pdf/pdf_chart.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Configurable divisional chart. Per-instance config picks the varga
/// ({'varga': 'd9'}), so duplicating this widget three times can show
/// D3 / D7 / D9 side by side. Chart style follows the kundli default
/// unless overridden per instance ({'style': 'south'}).
class DivisionalChartModule extends AstroModule {
  const DivisionalChartModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'divisional',
        title: 'Divisional Chart',
        icon: Icons.grid_view,
        category: 'Divisional Charts',
        defaultSpan: CardSpan.half,
      );

  Varga _varga(Map<String, dynamic> config) =>
      Varga.byName((config['varga'] as String?) ?? 'd9');

  /// Padas are on unless explicitly hidden. Computed from the varga's
  /// OWN lagna and lord placements (per K.N. Rao) — not the D1 padas
  /// overlaid.
  bool _showPadas(Map<String, dynamic> config) =>
      (config['padas'] as String?) != 'off';

  Map<ZodiacSign, List<String>> _padaLabels(
          AstroSnapshot s, Varga varga, Map<String, dynamic> config) =>
      _showPadas(config)
          ? padaLabelsBySign(vargaArudhaPadas(s, varga))
          : const {};

  ChartStyleOverride _style(ModuleContext ctx) =>
      chartStyleFromConfig(ctx.config, ctx.chartStyle);

  @override
  List<ModuleConfigChoice> configChoices() => [
        ModuleConfigChoice(
          key: 'varga',
          label: 'Divisional chart',
          options: [
            for (final v in Varga.values.where((v) => v != Varga.d1))
              (v.name, '${v.displayName} — ${v.theme}'),
          ],
        ),
        chartStyleChoice,
        const ModuleConfigChoice(
          key: 'padas',
          label: 'Jaimini padas (1P–12P)',
          options: [('off', 'Hide'), ('on', 'Show')],
          defaultValue: 'on', // shown by default, Parashar Light style
        ),
      ];

  @override
  String? configSummary(Map<String, dynamic> config) =>
      _varga(config).code;

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartDetailHeader(ctx: ctx),
            cardView(context, ctx),
          ],
        ),
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final varga = _varga(ctx.config);
    final s = ctx.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartView(
          placements: vargaPlacements(s, varga),
          lagna: vargaLagna(s, varga),
          style: _style(ctx).style,
          padaLabels: _padaLabels(s, varga, ctx.config),
        ),
        const SizedBox(height: 10),
        Text(
          '${varga.displayName} · ${varga.theme}\n'
          '${varga.code} Lagna ${vargaLagna(s, varga).western}',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final varga = _varga(ctx.config);
    final s = ctx.snapshot;
    return [
      pdfSectionHeader('${varga.displayName} (${varga.theme})'),
      pw.Text(
        '${varga.code} Lagna: ${vargaLagna(s, varga).western}',
        style: pdfBody(),
      ),
      pw.SizedBox(height: 10),
      pw.Center(
        child: pdfChart(
          placements: vargaPlacements(s, varga),
          lagna: vargaLagna(s, varga),
          style: _style(ctx).style,
          size: 200,
          padaLabels: _padaLabels(s, varga, ctx.config),
        ),
      ),
      pw.SizedBox(height: 6),
    ];
  }
}
