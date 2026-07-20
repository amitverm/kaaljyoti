/// Sahams — the Tajika sensitive points, all 41 of Charak's list, for
/// the varsha chart of the shared year or (config) the birth chart —
/// the book: annual sahams should be read against their natal
/// counterparts. Engine: core/astro/sahams.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/ephemeris_service.dart';
import '../core/astro/models.dart';
import '../core/astro/sahams.dart';
import '../core/astro/varshphal.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';

String _title(AppLocalizations l10n) => l10n.moduleVarshphalSahamTitle;

bool _useNatal(Map<String, dynamic> config) => config['chart'] == 'natal';

/// Day/night for a chart instant at its own place — the same Hindu
/// rise/set convention the varshphal provider uses.
bool _isDayChart(AstroSnapshot chart) {
  try {
    final svc = EphemerisService.instance;
    final jd = svc.julianDayUt(chart.birth.dateTimeUtc);
    final rise =
        svc.sunriseBefore(jd, chart.birth.latitude, chart.birth.longitude);
    final set = rise == null
        ? null
        : svc.sunEventAfter(rise, chart.birth.latitude, chart.birth.longitude,
            rise: false);
    if (set != null) return jd < set;
  } catch (_) {}
  return true;
}

class VarshphalSahamModule extends AstroModule {
  const VarshphalSahamModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_sahams',
        title: 'Sahams',
        localizedTitle: _title,
        icon: Icons.my_location_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'chart',
          label: l10n.shChartSource,
          options: [
            ('varsha', l10n.shChartVarsha),
            ('natal', l10n.shChartNatal),
          ],
          defaultValue: 'varsha',
        ),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      _useNatal(config) ? l10n.shChartNatal : null;

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _SahamBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _SahamBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
}

class _SahamBody extends ConsumerWidget {
  const _SahamBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  /// How many rows the dashboard card shows before "open for all".
  static const _cardCap = 12;

  Widget _table(BuildContext context, AppLocalizations l10n,
      AstroSnapshot chart, String contextLine,
      {required bool day}) {
    final results = sahams(chart, day: day);
    final rows = detail ? results : results.take(_cardCap).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(contextLine,
            style: KJTheme.mono(size: 11, color: KJColors.inkSoft)),
        const SizedBox(height: 6),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.9),
            1: FlexColumnWidth(1.6),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(0.8),
            4: FlexColumnWidth(1.1),
          },
          children: [
            TableRow(children: [
              _head(l10n.shSaham),
              _head(l10n.labelSign),
              _head(l10n.labelDegree),
              _head(l10n.labelHouse),
              _head(l10n.shLord),
            ]),
            for (final r in rows)
              TableRow(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: KJColors.hairline)),
                ),
                children: [
                  _cell(sahamLabel(l10n, r.key), bold: true),
                  _cell(r.sign.label(l10n)),
                  _mono(formatDegreeInSign(r.longitude % 30)),
                  _mono(
                      '${((r.sign.index - chart.lagnaSign.index + 12) % 12) + 1}'),
                  _cell(r.sign.lord.abbrLabel(l10n),
                      color: planetInk(r.sign.lord)),
                ],
              ),
          ],
        ),
        if (!detail && results.length > _cardCap)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.shMoreFooter('${results.length - _cardCap}'),
              style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final natal = ctx.snapshot;

    if (_useNatal(ctx.config)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail) ...[
            Text(l10n.moduleVarshphalSahamTitle,
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 8),
          ],
          _table(context, l10n, natal, l10n.shChartNatal,
              day: _isDayChart(natal)),
        ],
      );
    }

    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));
    return async.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.vpError('$e')),
      data: (d) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail) ...[
            Text(l10n.moduleVarshphalSahamTitle,
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 8),
          ],
          _table(
            context,
            l10n,
            d.snapshot,
            '${l10n.vpYearLine('${d.varshaYear}', '${d.returnUtc.toUtc().year}')}'
            ' · ${d.dayPravesha ? l10n.vpDay : l10n.vpNight}',
            day: d.dayPravesha,
          ),
        ],
      ),
    );
  }

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(t,
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.4,
                color: KJColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );

  Widget _cell(String t, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );

  Widget _mono(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(t, style: KJTheme.mono(size: 11.5)),
      );
}
