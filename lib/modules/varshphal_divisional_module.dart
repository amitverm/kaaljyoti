/// Divisional charts OF THE VARSHA chart (Tajika practice reads the
/// varsha's own D9, D10, …). Same varga machinery as the natal
/// Divisional Chart widget, but computed from the varsha snapshot —
/// and the year is NOT chosen here: it follows the per-kundli year the
/// Varshphal Chart's stepper sets (varshphalYearProvider), so a D9 can
/// never silently show a different varsha than the chart beside it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_view.dart';
import '../core/astro/divisional.dart';
import '../core/astro/models.dart';
import '../core/astro/snapshot_builder.dart';
import '../core/astro/varshphal.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../pdf/pdf_chart.dart';
import '../services/place_lookup_service.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _title(AppLocalizations l10n) => l10n.moduleVarshphalDivisionalTitle;

Varga _varga(Map<String, dynamic> config) =>
    Varga.byName((config['varga'] as String?) ?? 'd9');

class VarshphalDivisionalModule extends AstroModule {
  const VarshphalDivisionalModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_divisional',
        title: 'Varshphal Divisional',
        localizedTitle: _title,
        icon: Icons.grid_view,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'varga',
          label: l10n.cfgDivisionalChart,
          options: [
            for (final v in Varga.values.where((v) => v != Varga.d1))
              (v.name, v.displayLabel(l10n)),
          ],
        ),
        chartStyleChoice(l10n),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      _varga(config).code;

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _VarshphalDivisionalBody(ctx: ctx);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartDetailHeader(ctx: ctx),
            _VarshphalDivisionalBody(ctx: ctx),
          ],
        ),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final natal = ctx.snapshot;
    final varga = _varga(ctx.config);
    // PDF is synchronous → current varsha, same as the Varshphal Chart.
    final year =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final returnUtc = solarReturnUtc(
      birthUtc: natal.birth.dateTimeUtc,
      natalSunLongitude: natal.positions[Planet.sun]!.longitude,
      varshaYear: year,
      ayanamsaId: natal.ayanamsaId,
    );
    final offset = PlaceLookupService()
        .offsetMinutesAtUtc(natal.birth.timezoneName, returnUtc);
    final varsha = _pdfBuilder.buildSync(
      BirthData(
        dateTimeUtc: returnUtc,
        latitude: natal.birth.latitude,
        longitude: natal.birth.longitude,
        timezoneName: natal.birth.timezoneName,
        utcOffsetMinutes: offset,
      ),
      natal.ayanamsaId,
    );
    return [
      pdfSectionHeader(
          '${l10n.moduleVarshphalDivisionalTitle} — ${varga.displayLabel(l10n)}'
          ' (${l10n.vpYearLine('$year', '${returnUtc.toUtc().year}')})'),
      pw.SizedBox(height: 10),
      pw.Center(
        child: pdfChart(
          l10n: l10n,
          placements: vargaPlacements(varsha, varga),
          lagna: vargaLagna(varsha, varga),
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          size: 200,
        ),
      ),
      pw.SizedBox(height: 6),
    ];
  }
}

final _pdfBuilder = SnapshotBuilder();

class _VarshphalDivisionalBody extends ConsumerWidget {
  const _VarshphalDivisionalBody({required this.ctx});

  final ModuleContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final natal = ctx.snapshot;
    final varga = _varga(ctx.config);
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));

    return async.when(
      loading: () => const SizedBox(
          height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.vpError('$e')),
      data: (d) {
        final varsha = d.snapshot;
        final lagna = vargaLagna(varsha, varga);
        final viewKey = '${ctx.kundli.id}#vp_${varga.code}';
        final viewFrom = ref.watch(widgetViewFromProvider(viewKey)) ?? lagna;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartView(
              placements: vargaPlacements(varsha, varga),
              lagna: viewFrom,
              trueAscendantSign: lagna,
              style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
              // Only D1 boxes carry a real degree progression to mirror
              // spatially; higher vargas list in traditional order.
              directionalStack: varga == Varga.d1,
              ascendantRank: varga == Varga.d1
                  ? ascendantRankIn(varsha.positions, varsha.ascendant)
                  : null,
              onSignSelect: (sign) => ref
                  .read(widgetViewFromProvider(viewKey).notifier)
                  .state = sign == lagna ? null : sign,
            ),
            const SizedBox(height: 10),
            Text(
              '${varga.displayLabel(l10n)} · '
              '${l10n.vpYearLine('$year', '${d.returnUtc.toUtc().year}')}\n'
              '${l10n.vargaLagnaLine(varga.code, lagna.label(l10n))}',
              style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
            ),
          ],
        );
      },
    );
  }
}
