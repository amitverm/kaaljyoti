/// Tajika strength widgets — Panch Vargiya Bala (the strength that
/// elects the Varshesha) and Harsha Bala — both computed on the varsha
/// chart of the shared year (Charak ch. VI; engine in
/// core/astro/varshphal_bala.dart, golden-tested against the book).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/varshphal.dart';
import '../core/astro/varshphal_bala.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';

String _pvTitle(AppLocalizations l10n) => l10n.moduleVarshphalPanchaBalaTitle;
String _hbTitle(AppLocalizations l10n) => l10n.moduleHarshaBalaTitle;

String _fmtUnits(double v) => v.toStringAsFixed(2);

/// Shared varsha-year loader scaffold for the small bala tables.
class _VarshaTable extends ConsumerWidget {
  const _VarshaTable({required this.ctx, required this.builder});

  final ModuleContext ctx;
  final Widget Function(BuildContext, AppLocalizations, VarshphalData) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final natal = ctx.snapshot;
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
          Text(
            '${l10n.vpYearLine('${d.varshaYear}', '${d.returnUtc.toUtc().year}')}'
            ' · ${d.dayPravesha ? l10n.vpDay : l10n.vpNight}',
            style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 6),
          builder(context, l10n, d),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panch Vargiya Bala
// ---------------------------------------------------------------------------

class PanchaVargiyaBalaModule extends AstroModule {
  const PanchaVargiyaBalaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_pancha_bala',
        title: 'Panch Vargiya Bala',
        localizedTitle: _pvTitle,
        icon: Icons.stacked_bar_chart,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) => _VarshaTable(
        ctx: ctx,
        builder: (context, l10n, d) {
          final rows = panchavargiyaBala(d.snapshot);
          return Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1.1),
            },
            children: [
              TableRow(children: [
                _head(l10n.labelGraha),
                _head(l10n.pvGriha),
                _head(l10n.pvUchcha),
                _head(l10n.pvHudda),
                _head(l10n.pvDrekkana),
                _head(l10n.pvNavamsha),
                _head(l10n.pvVishwaBala),
              ]),
              for (final r in rows)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: KJColors.hairline)),
                  ),
                  children: [
                    _cell(r.planet.abbrLabel(l10n),
                        color: planetInk(r.planet), bold: true),
                    _mono(_fmtUnits(r.griha)),
                    _mono(_fmtUnits(r.uchcha)),
                    _mono(_fmtUnits(r.hudda)),
                    _mono(_fmtUnits(r.drekkana)),
                    _mono(_fmtUnits(r.navamsha)),
                    _mono(_fmtUnits(r.vishwaBala), bold: true),
                  ],
                ),
            ],
          );
        },
      );

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.moduleVarshphalPanchaBalaTitle,
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 4),
            Text(context.l10n.pvBlurb,
                style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
            const SizedBox(height: 12),
            cardView(context, ctx),
          ],
        ),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
}

// ---------------------------------------------------------------------------
// Harsha Bala
// ---------------------------------------------------------------------------

class HarshaBalaModule extends AstroModule {
  const HarshaBalaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_harsha_bala',
        title: 'Harsha Bala',
        localizedTitle: _hbTitle,
        icon: Icons.bar_chart_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  String _category(AppLocalizations l10n, int total) => switch (total) {
        0 => l10n.hbNirbala,
        5 => l10n.hbAlpabali,
        10 => l10n.hbMadhyaBali,
        15 => l10n.hbPoornaBali,
        _ => l10n.hbExtraordinary,
      };

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) => _VarshaTable(
        ctx: ctx,
        builder: (context, l10n, d) {
          final rows = harshaBala(d.snapshot, dayPravesha: d.dayPravesha);
          return Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(0.9),
              6: FlexColumnWidth(1.7),
            },
            children: [
              TableRow(children: [
                _head(l10n.labelGraha),
                _head(l10n.hbFirst),
                _head(l10n.hbSecond),
                _head(l10n.hbThird),
                _head(l10n.hbFourth),
                _head(l10n.pvTotal),
                _head(''),
              ]),
              for (final r in rows)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: KJColors.hairline)),
                  ),
                  children: [
                    _cell(r.planet.abbrLabel(l10n),
                        color: planetInk(r.planet), bold: true),
                    _mono('${r.first}'),
                    _mono('${r.second}'),
                    _mono('${r.third}'),
                    _mono('${r.fourth}'),
                    _mono('${r.total}', bold: true),
                    _cell(_category(l10n, r.total)),
                  ],
                ),
            ],
          );
        },
      );

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.moduleHarshaBalaTitle,
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 4),
            Text(context.l10n.hbBlurb,
                style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
            const SizedBox(height: 12),
            cardView(context, ctx),
          ],
        ),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(t,
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
    );

Widget _mono(String t, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(t,
          style: KJTheme.mono(
              size: 11.5, weight: bold ? FontWeight.w600 : FontWeight.w400)),
    );
