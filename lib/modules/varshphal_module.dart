/// Varshphal — the Tajika annual chart. Shows the varsha chart for a
/// selected year with a prev/current/next stepper, the varsha pravesh
/// instant (birth-place local time), and the Muntha with its house.
/// Defaults to the varsha running today. Chart is cast at the BIRTH
/// place in the kundli's own ayanamsa (see varshphalProvider).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../charts/chart_view.dart';
import '../charts/planet_token.dart';
import '../core/astro/dignity.dart';
import '../core/astro/divisional.dart';
import '../core/astro/models.dart';
import '../core/astro/snapshot_builder.dart';
import '../core/astro/varshphal.dart';
import '../core/astro/varshphal_bala.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../pdf/pdf_chart.dart';
import '../services/place_lookup_service.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _varshphalTitle(AppLocalizations l10n) => l10n.moduleVarshphalTitle;

DateFormat get _fmtPravesh => DateFormat('${KJDate.pref.datePattern}, HH:mm');

class VarshphalModule extends AstroModule {
  const VarshphalModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal',
        title: 'Varshphal Chart',
        localizedTitle: _varshphalTitle,
        icon: Icons.event_repeat_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        chartStyleChoice(l10n),
        ModuleConfigChoice(
          key: 'degrees',
          label: l10n.cfgPlanetDegrees,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
        ModuleConfigChoice(
          key: 'extras',
          label: l10n.cfgDignityCombustion,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
      ];

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _VarshphalBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _VarshphalBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final natal = ctx.snapshot;
    // PDF is synchronous, so this recomputes the CURRENT varsha inline
    // (buildSync — ephemeris is initialized long before any export).
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
    final varsha = _snapshotBuilderForPdf.buildSync(
      BirthData(
        dateTimeUtc: returnUtc,
        latitude: natal.birth.latitude,
        longitude: natal.birth.longitude,
        timezoneName: natal.birth.timezoneName,
        utcOffsetMinutes: offset,
      ),
      natal.ayanamsaId,
    );
    final muntha = munthaSign(natal.lagnaSign, year);
    final munthaHouse = ((muntha.index - varsha.lagnaSign.index + 12) % 12) + 1;
    return [
      pdfSectionHeader(l10n.vpPdfHeader('$year', '${returnUtc.toUtc().year}')),
      pw.Text(
        '${l10n.vpPraveshLine(_fmtPravesh.format(varsha.birth.localDateTime))}'
        ' · ${l10n.vpMunthaLine('${muntha.label(l10n)} ${formatDegreeInSign(natal.ascendant % 30)}', l10n.nrHouseN('$munthaHouse'))}',
        style: pdfBody(),
      ),
      pw.SizedBox(height: 10),
      pw.Center(
        child: pdfChart(
          l10n: l10n,
          placements: vargaPlacements(varsha, Varga.d1),
          lagna: varsha.lagnaSign,
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          retrograde: {
            for (final p in varsha.positions.values) p.planet: p.isRetrograde,
          },
          trueAscendantSign: varsha.lagnaSign,
          ascendantDegree: varsha.ascendant,
        ),
      ),
      pw.SizedBox(height: 6),
    ];
  }
}

final _snapshotBuilderForPdf = SnapshotBuilder();

class _VarshphalBody extends ConsumerStatefulWidget {
  const _VarshphalBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  @override
  ConsumerState<_VarshphalBody> createState() => _VarshphalBodyState();
}

class _VarshphalBodyState extends ConsumerState<_VarshphalBody> {
  /// Last successfully loaded year — kept on screen (dimmed) while the
  /// next year computes, so the card's height never collapses to a
  /// spinner and the page doesn't jump on prev/next.
  VarshphalData? _last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctx = widget.ctx;
    final natal = ctx.snapshot;
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    // Shared per-kundli year: this stepper WRITES it, every other
    // varsha widget (divisionals, dashas, …) reads it, so the whole
    // Varshphal view flips year together.
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));
    final data = async.valueOrNull ?? _last;
    if (async.hasValue && !identical(async.value, _last)) {
      _last = async.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.detail) ...[
          Text(l10n.moduleVarshphalTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.vpPrevYear,
              visualDensity: VisualDensity.compact,
              onPressed: year > 1
                  ? () => ref
                      .read(varshphalYearProvider(ctx.kundli.id).notifier)
                      .state = year - 1
                  : null,
            ),
            Expanded(
              child: Text(
                l10n.vpYearLine(
                    '$year',
                    async.valueOrNull != null
                        ? '${async.value!.returnUtc.toUtc().year}'
                        : '…'),
                textAlign: TextAlign.center,
                style: KJTheme.mono(size: 12.5, weight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.vpNextYear,
              visualDensity: VisualDensity.compact,
              // 120 varshas is beyond any professional need and keeps
              // the stepper from running to absurd instants.
              onPressed: year < 120
                  ? () => ref
                      .read(varshphalYearProvider(ctx.kundli.id).notifier)
                      .state = year + 1
                  : null,
            ),
          ],
        ),
        if (async.hasError)
          Text(l10n.vpError('${async.error}'))
        else if (data == null)
          const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
        else
          // While the next year computes, the previous chart stays (a
          // touch dimmed) so the card's height never collapses — that
          // collapse was what scrolled the dashboard on every prev/next.
          Opacity(
            opacity: async.isLoading ? 0.45 : 1,
            child: _chart(context, data),
          ),
      ],
    );
  }

  Widget _chart(BuildContext context, VarshphalData d) {
    final l10n = context.l10n;
    final ctx = widget.ctx;
    final varsha = d.snapshot;
    final showDegrees = (ctx.config['degrees'] as String?) == 'on';
    final showExtras = (ctx.config['extras'] as String?) == 'on';

    // Same annotation set the Birth Chart builds (minus karakas) —
    // computed from the VARSHA snapshot, not the natal one.
    final sun = varsha.positions[Planet.sun]!;
    final tokens = {
      for (final p in varsha.positions.values)
        p.planet: PlanetToken(
          planet: p.planet,
          retrograde: p.isRetrograde,
          degreeInSign: showDegrees ? p.degreesInSign : null,
          dignity: showExtras ? dignityOf(p) : PlanetDignity.none,
          combust:
              showExtras && p.planet != Planet.sun ? isCombust(p, sun) : false,
        ),
    };

    // Double-tap rotation, independent of the Birth Chart's.
    final viewKey = '${ctx.kundli.id}#varshphal';
    final viewFrom =
        ref.watch(widgetViewFromProvider(viewKey)) ?? varsha.lagnaSign;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartView(
          placements: vargaPlacements(varsha, Varga.d1),
          lagna: viewFrom,
          trueAscendantSign: varsha.lagnaSign,
          ascendantDegree: varsha.ascendant,
          ascendantRank: ascendantRankIn(varsha.positions, varsha.ascendant),
          style: chartStyleFromConfig(ctx.config, ctx.chartStyle).style,
          retrograde: {
            for (final p in varsha.positions.values) p.planet: p.isRetrograde,
          },
          tokens: tokens,
          showDegrees: showDegrees,
          // The Muntha rides the grey overlay channel (same as pada
          // codes) in its varsha-chart sign.
          padaLabels: {
            d.muntha: const ['Mu'],
          },
          onSignSelect: (sign) => ref
              .read(widgetViewFromProvider(viewKey).notifier)
              .state = sign == varsha.lagnaSign ? null : sign,
        ),
        const SizedBox(height: 8),
        Text(
          // Varsha pravesh shown in BIRTH-PLACE local time (the
          // snapshot's own offset at that instant), never the
          // device zone — same principle as birth data itself.
          '${l10n.vpPraveshLine(_fmtPravesh.format(varsha.birth.localDateTime))}'
          ' · ${varsha.birth.timezoneName}',
          style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.vpMunthaLine(
              '${d.muntha.label(l10n)} ${formatDegreeInSign(d.munthaDegreeInSign)}',
              l10n.nrHouseN('${d.munthaHouse}')),
          style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
        ),
        const SizedBox(height: 2),
        () {
          final yl = yearLord(
            varsha: varsha,
            natalLagna: d.natalLagna,
            muntha: d.muntha,
            dayPravesha: d.dayPravesha,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.vpYearLordLine(yl.yearLord.label(l10n))}'
                ' · ${d.dayPravesha ? l10n.vpDay : l10n.vpNight}',
                style: KJTheme.mono(
                    size: 11.5,
                    color: KJColors.maroon,
                    weight: FontWeight.w600),
              ),
              if (widget.detail) ...[
                const SizedBox(height: 8),
                Text(l10n.vpBearersHeader,
                    style: KJTheme.mono(
                        size: 10.5,
                        color: KJColors.inkSoft,
                        weight: FontWeight.w600)),
                for (final b in yl.bearers)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_bearerLabel(l10n, b.role)}: '
                      '${b.planet.label(l10n)}'
                      ' (${aspectsVarshaLagna(varsha, b.planet) ? l10n.vpAspectsLagna : l10n.vpNoAspect})',
                      style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                    ),
                  ),
              ],
            ],
          );
        }(),
      ],
    );
  }

  String _bearerLabel(AppLocalizations l10n, OfficeBearerRole role) =>
      switch (role) {
        OfficeBearerRole.munthaPati => l10n.obMunthaPati,
        OfficeBearerRole.janmaLagnaPati => l10n.obJanmaLagnaPati,
        OfficeBearerRole.varshaLagnaPati => l10n.obVarshaLagnaPati,
        OfficeBearerRole.triRashiPati => l10n.obTriRashiPati,
        OfficeBearerRole.dinaRatriPati => l10n.obDinaRatriPati,
        OfficeBearerRole.maasaLagnaPati => l10n.obMaasaLagnaPati,
      };
}
