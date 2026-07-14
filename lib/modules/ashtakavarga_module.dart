import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/bindu_chart.dart';
import '../core/astro/ashtakavarga.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Ashtakavarga: SAV/BAV bindu counts drawn in the classical chart
/// layout (numbers per house). The card shows one chart — SAV by
/// default, or a single graha's BAV via per-instance config, so the
/// widget can be duplicated for several grahas side by side. The
/// detail view adds a selector across SAV + all seven BAVs.
class AshtakavargaModule extends AstroModule {
  const AshtakavargaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'ashtakavarga',
        title: 'Ashtakavarga',
        icon: Icons.apps_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.half,
      );

  /// null = SAV; otherwise the BAV graha.
  Planet? _selected(Map<String, dynamic> config) {
    final raw = config['chart'] as String?;
    if (raw == null || raw == 'sav') return null;
    return Planet.values.firstWhere((p) => p.name == raw,
        orElse: () => Planet.sun);
  }

  @override
  List<ModuleConfigChoice> configChoices() => [
        ModuleConfigChoice(
          key: 'chart',
          label: 'Chart',
          options: [
            ('sav', 'Sarvashtakavarga (SAV)'),
            for (final p in ashtakavargaPlanets)
              (p.name, '${p.displayName} BAV'),
          ],
        ),
        chartStyleChoice,
      ];

  @override
  String? configSummary(Map<String, dynamic> config) {
    final p = _selected(config);
    return p == null ? 'SAV' : '${p.abbr} BAV';
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final av = ctx.ashtakavarga;
    final planet = _selected(ctx.config);
    final scores = planet == null ? av.sav() : av.bav(planet);
    final style = chartStyleFromConfig(ctx.config, ctx.chartStyle).style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BinduChartView(
          scores: scores,
          lagna: ctx.snapshot.lagnaSign,
          style: style,
          isSav: planet == null,
        ),
        const SizedBox(height: 10),
        Text(
          planet == null
              ? 'Sarvashtakavarga · ${scores.fold(0, (a, b) => a + b)} bindus'
              : '${planet.displayName} Bhinnashtakavarga · '
                  '${scores.fold(0, (a, b) => a + b)} bindus',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      _AshtakavargaDetailBody(ctx: ctx, initial: _selected(ctx.config));

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final av = ctx.ashtakavarga;
    final sav = av.sav();
    return [
      pdfSectionHeader('Ashtakavarga'),
      pw.TableHelper.fromTextArray(
        headers: [
          'Chart',
          for (final s in ZodiacSign.values) s.western.substring(0, 3),
          'Total',
        ],
        data: [
          ['SAV', ...sav.map((v) => '$v'), '${sav.fold(0, (a, b) => a + b)}'],
          for (final p in ashtakavargaPlanets)
            [
              p.abbr,
              ...av.bav(p).map((v) => '$v'),
              '${av.bav(p).fold(0, (a, b) => a + b)}',
            ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 8.5),
        border: null,
        cellAlignment: pw.Alignment.center,
        headerAlignment: pw.Alignment.center,
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Bindus per sign; SAV is the sum of the seven graha BAVs '
        '(grand total 337).',
        style: pdfLabel(),
      ),
    ];
  }
}

class _AshtakavargaDetailBody extends StatefulWidget {
  const _AshtakavargaDetailBody({required this.ctx, required this.initial});

  final ModuleContext ctx;
  final Planet? initial;

  @override
  State<_AshtakavargaDetailBody> createState() =>
      _AshtakavargaDetailBodyState();
}

class _AshtakavargaDetailBodyState extends State<_AshtakavargaDetailBody> {
  late Planet? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = widget.ctx.snapshot;
    final av = widget.ctx.ashtakavarga;
    final scores = _selected == null ? av.sav() : av.bav(_selected!);
    final total = scores.fold(0, (a, b) => a + b);
    final style =
        chartStyleFromConfig(widget.ctx.config, widget.ctx.chartStyle).style;

    var maxIdx = 0, minIdx = 0;
    for (var i = 1; i < 12; i++) {
      if (scores[i] > scores[maxIdx]) maxIdx = i;
      if (scores[i] < scores[minIdx]) minIdx = i;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ashtakavarga', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Benefic points (bindus) per sign. SAV sums the seven graha'
            ' charts; a graha transiting a high-bindu sign of its own BAV'
            ' gives better results.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('SAV'),
                selected: _selected == null,
                onSelected: (_) => setState(() => _selected = null),
              ),
              for (final p in ashtakavargaPlanets)
                ChoiceChip(
                  label: Text(p.abbr,
                      style: TextStyle(
                          color: _selected == p ? null : planetInk(p),
                          fontWeight: FontWeight.w600)),
                  selected: _selected == p,
                  onSelected: (_) => setState(() => _selected = p),
                ),
            ],
          ),
          const SizedBox(height: 16),
          BinduChartView(
            scores: scores,
            lagna: s.lagnaSign,
            style: style,
            isSav: _selected == null,
          ),
          const SizedBox(height: 12),
          Text(
            '${_selected == null ? 'Sarvashtakavarga' : '${_selected!.displayName} Bhinnashtakavarga'}'
            ' · $total bindus\n'
            'Strongest: ${ZodiacSign.values[maxIdx].western} (${scores[maxIdx]})'
            ' · Weakest: ${ZodiacSign.values[minIdx].western} (${scores[minIdx]})',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
