import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../charts/bindu_chart.dart';
import '../core/astro/ashtakavarga.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _ashtakavargaTitle(AppLocalizations l10n) =>
    l10n.moduleAshtakavargaTitle;

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
        localizedTitle: _ashtakavargaTitle,
        icon: Icons.apps_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.half,
      );

  /// null = SAV; otherwise the BAV graha.
  Planet? _selected(Map<String, dynamic> config) {
    final raw = config['chart'] as String?;
    if (raw == null || raw == 'sav') return null;
    return Planet.values
        .firstWhere((p) => p.name == raw, orElse: () => Planet.sun);
  }

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'chart',
          label: l10n.cfgChart,
          options: [
            ('sav', l10n.savFull),
            for (final p in ashtakavargaPlanets)
              (p.name, l10n.bavOf(p.label(l10n))),
          ],
        ),
        chartStyleChoice(l10n),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) {
    final p = _selected(config);
    return p == null ? 'SAV' : l10n.bavOf(p.abbrLabel(l10n));
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
          '${planet == null ? context.l10n.avSarv : context.l10n.avBhinnaOf(planet.label(context.l10n))}'
          ' · ${context.l10n.avBindusCount('${scores.fold(0, (a, b) => a + b)}')}',
          style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
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
      pdfSectionHeader(ctx.l10n.moduleAshtakavargaTitle),
      pw.TableHelper.fromTextArray(
        headers: [
          ctx.l10n.cfgChart,
          for (final s in ZodiacSign.values) s.abbrLabel(ctx.l10n),
          ctx.l10n.labelTotal,
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
        ctx.l10n.avPdfNote,
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
          Text(context.l10n.moduleAshtakavargaTitle,
              style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            context.l10n.avBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
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
            '${_selected == null ? context.l10n.avSarv : context.l10n.avBhinnaOf(_selected!.label(context.l10n))}'
            ' · ${context.l10n.avBindusCount('$total')}\n'
            '${context.l10n.avStrongWeak(ZodiacSign.values[maxIdx].label(context.l10n), '${scores[maxIdx]}', ZodiacSign.values[minIdx].label(context.l10n), '${scores[minIdx]}')}',
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
