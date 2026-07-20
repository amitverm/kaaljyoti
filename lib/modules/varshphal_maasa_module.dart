/// Maasa Pravesha — the monthly charts within the varsha (Charak
/// ch. XIII): chart cast for each successive 30° gain of the Sun over
/// its natal longitude, with a month stepper under the SHARED varsha
/// year, plus the Maasesha (six office-bearers, monthly-chart
/// strengths).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_view.dart';
import '../core/astro/divisional.dart';
import '../core/astro/varshphal.dart';
import '../core/astro/varshphal_bala.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _title(AppLocalizations l10n) => l10n.moduleVarshphalMaasaTitle;

DateFormat get _fmt => DateFormat('${KJDate.pref.datePattern}, HH:mm');

class VarshphalMaasaModule extends AstroModule {
  const VarshphalMaasaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_maasa',
        title: 'Maasa Pravesha',
        localizedTitle: _title,
        icon: Icons.calendar_view_month_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) =>
      [chartStyleChoice(l10n)];

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _MaasaBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _MaasaBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
}

class _MaasaBody extends ConsumerStatefulWidget {
  const _MaasaBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  @override
  ConsumerState<_MaasaBody> createState() => _MaasaBodyState();
}

class _MaasaBodyState extends ConsumerState<_MaasaBody> {
  int _month = 1;
  MaasaPraveshData? _last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctx = widget.ctx;
    final natal = ctx.snapshot;
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final varshaAsync = ref.watch(varshphalProvider((ctx.kundli.id, year)));
    final async =
        ref.watch(maasaPraveshProvider((ctx.kundli.id, year, _month)));
    final data = async.valueOrNull ?? _last;
    if (async.hasValue && !identical(async.value, _last)) {
      _last = async.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.detail) ...[
          Text(l10n.moduleVarshphalMaasaTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              visualDensity: VisualDensity.compact,
              onPressed: _month > 1 ? () => setState(() => _month -= 1) : null,
            ),
            Expanded(
              child: Text(
                '${l10n.vpYearLine('$year', async.valueOrNull != null ? '${async.value!.praveshUtc.toUtc().year}' : '…')}'
                ' · ${l10n.vmMonthN('$_month')}',
                textAlign: TextAlign.center,
                style: KJTheme.mono(size: 12.5, weight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              visualDensity: VisualDensity.compact,
              onPressed: _month < 12 ? () => setState(() => _month += 1) : null,
            ),
          ],
        ),
        if (async.hasError)
          Text(l10n.vpError('${async.error}'))
        else if (data == null)
          const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
        else
          Opacity(
            opacity: async.isLoading ? 0.45 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChartView(
                  placements: vargaPlacements(data.snapshot, Varga.d1),
                  lagna: data.snapshot.lagnaSign,
                  trueAscendantSign: data.snapshot.lagnaSign,
                  ascendantDegree: data.snapshot.ascendant,
                  style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
                  retrograde: {
                    for (final p in data.snapshot.positions.values)
                      p.planet: p.isRetrograde,
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.vmPraveshLine(_fmt.format(data.snapshot.birth.localDateTime))}'
                  ' · ${data.dayPravesha ? l10n.vpDay : l10n.vpNight}',
                  style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                ),
                if (varshaAsync.valueOrNull != null) ...[
                  const SizedBox(height: 2),
                  () {
                    final v = varshaAsync.value!;
                    final ml = monthLord(
                      varsha: v.snapshot,
                      maasa: data.snapshot,
                      natalLagna: v.natalLagna,
                      muntha: v.muntha,
                      dayPraveshaAnnual: v.dayPravesha,
                    );
                    return Text(
                      l10n.vmMonthLordLine(ml.yearLord.label(l10n)),
                      style: KJTheme.mono(
                          size: 11.5,
                          color: KJColors.maroon,
                          weight: FontWeight.w600),
                    );
                  }(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
