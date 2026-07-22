/// Bhava Chalit — cusp-bounded houses beside the whole-sign rashi
/// chart. Sripati (bhava madhya from Porphyry cusps, sandhi midpoints)
/// by default, Placidus madhyas as a config option.
///
/// Rotation works exactly like the Birth Chart: double-tap (or
/// long-press) a house to view from it; tapping the Ascendant's house
/// resets. The rotation lives in [chalitViewHouseProvider] so card and
/// detail stay in sync and it survives navigation.
///
/// Deliberately its own widget with its own id — a practitioner who
/// works cuspal-houses-first should find it in the library, not buried
/// in the Birth Chart's config sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/north_chart_painter.dart';
import '../charts/pinch_zoom.dart';
import '../charts/planet_token.dart';
import '../core/astro/chalit.dart';
import '../core/astro/dignity.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _chalitTitle(AppLocalizations l10n) => l10n.moduleChalitTitle;

ChalitSystem _systemFromConfig(Map<String, dynamic> config) =>
    switch (config['system']) {
      'placidus' => ChalitSystem.placidus,
      'equal' => ChalitSystem.equal,
      _ => ChalitSystem.sripati,
    };

String _systemLabel(AppLocalizations l10n, ChalitSystem system) =>
    switch (system) {
      ChalitSystem.sripati => l10n.ccSripati,
      ChalitSystem.placidus => l10n.ccPlacidus,
      ChalitSystem.equal => l10n.ccEqual,
    };

bool _flag(Map<String, dynamic> config, String key) =>
    (config[key] as String?) == 'on';

class ChalitModule extends AstroModule {
  const ChalitModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'chalit_chart',
        title: 'Bhava Chalit',
        localizedTitle: _chalitTitle,
        icon: Icons.other_houses_outlined,
        category: 'Chart & Grahas',
        // CardSpan.half does not collapse on phones (dashboard breakpoint
        // logic) — full by default, tablet users can size it themselves.
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'system',
          label: l10n.cfgHouseSystem,
          options: [
            ('sripati', l10n.ccSripati),
            ('placidus', l10n.ccPlacidus),
            ('equal', l10n.ccEqual),
          ],
          defaultValue: 'sripati',
        ),
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
        ModuleConfigChoice(
          key: 'cusp_degrees',
          label: l10n.cfgCuspDegrees,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
        // Signs-passed labels, split into two toggles because box space
        // is cramped: cusp signs upgrade the madhya/sandhi labels to
        // "M 11ˢ11°16'"; planet signs prefix every graha's degree the
        // same way ("Ma 10ˢ23°57'").
        ModuleConfigChoice(
          key: 'cusp_signs',
          label: l10n.cfgCuspSigns,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
        ModuleConfigChoice(
          key: 'planet_signs',
          label: l10n.cfgPlanetSigns,
          options: onOffOptions(l10n),
          toggleOnValue: 'on',
        ),
      ];

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _ChalitBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _ChalitBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final system = _systemFromConfig(ctx.config);
    final d = computeChalit(ctx.snapshot, system);
    return [
      pdfSectionHeader(
          '${l10n.moduleChalitTitle} — ${_systemLabel(l10n, system)}'),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.labelHouse,
          l10n.labelSign,
          l10n.ccMadhyaCol,
          l10n.ccSandhiCol,
          l10n.labelGraha,
        ],
        data: [
          for (var h = 1; h <= 12; h++)
            [
              '$h',
              d.signOfHouse(h).label(l10n),
              formatDegree(d.madhya[h - 1]),
              formatDegree(d.sandhi[h - 1]),
              // Tables list grahas in traditional order; only the chart
              // boxes read in degree order ([planetsInHouse] is sorted
              // along the bhava).
              ([...d.planetsInHouse[h - 1]]
                    ..sort((a, b) => a.index.compareTo(b.index)))
                  .map((p) => p.abbrLabel(l10n))
                  .join(' '),
            ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 9),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
      pw.SizedBox(height: 4),
      pw.Text(l10n.ccCaption, style: pw.TextStyle(fontSize: 7.5)),
    ];
  }
}

class _ChalitBody extends ConsumerWidget {
  const _ChalitBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final system = _systemFromConfig(ctx.config);
    final showDegrees = _flag(ctx.config, 'degrees');
    final showExtras = _flag(ctx.config, 'extras');
    final showCuspDegrees = _flag(ctx.config, 'cusp_degrees');
    final showCuspSigns = _flag(ctx.config, 'cusp_signs');
    final showPlanetSigns = _flag(ctx.config, 'planet_signs');
    final viewHouse = ref.watch(chalitViewHouseProvider(ctx.kundli.id)) ?? 1;
    final d = computeChalit(s, system);

    // Same annotation set the Birth Chart builds (minus karakas), plus
    // the chalit-only signs-passed prefix: every graha's degree carries
    // its absolute position ("Ma 10ˢ23°57'"), so a reader never has to
    // guess which rashi a planet occupies when a bhava straddles a sign
    // boundary.
    final sun = s.positions[Planet.sun]!;
    final tokens = {
      for (final p in s.positions.values)
        p.planet: PlanetToken(
          planet: p.planet,
          retrograde: p.isRetrograde,
          degreeInSign: showDegrees ? p.degreesInSign : null,
          dignity: showExtras ? dignityOf(p) : PlanetDignity.none,
          combust:
              showExtras && p.planet != Planet.sun ? isCombust(p, sun) : false,
          signTag: showPlanetSigns ? signsPassed(p.longitude) : null,
        ),
    };

    // Cusp label text, per the two toggles. "Signs passed" notation:
    // 11ˢ11°16' = 11 completed signs + 11°16' into the twelfth (Pisces)
    // — the compact technical form, which matters most when a sandhi or
    // madhya falls in a different rashi than the box's sign suggests.
    final showCusps = showCuspDegrees || showCuspSigns;
    String cuspText(double lon) =>
        '${showCuspSigns ? signsPassed(lon) : ''}${formatDegreeInSign(lon % 30)}';

    // Rotate by cusp: the chosen house occupies the drawn house-1
    // position; everything else follows in order. The As marker stays
    // with the ORIGINAL first house wherever it lands.
    final houseData = [
      for (var drawn = 1; drawn <= 12; drawn++)
        () {
          final original = ((viewHouse - 1 + drawn - 1) % 12) + 1;
          return (
            signNumber: d.signOfHouse(original).index + 1,
            planets: d.planetsInHouse[original - 1],
            // The madhya line sits INSIDE its house, slotted into the
            // planet order at its own longitude (cuspAfter = planets
            // before it), so grahas above it are before the cusp and
            // those below are after. The sandhi rides the dividing line
            // itself (boundaryLabels below).
            cuspLabel:
                showCusps ? 'M ${cuspText(d.madhya[original - 1])}' : null,
            cuspAfter: d.madhyaRank[original - 1],
          );
        }(),
    ];
    final boundaryLabels = showCusps
        ? [
            for (var drawn = 1; drawn <= 12; drawn++)
              cuspText(d.sandhi[((viewHouse - 1 + drawn - 1) % 12)]),
          ]
        : null;
    final ascendantHouse = ((1 - viewHouse + 12) % 12) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail) ...[
          Text(l10n.moduleChalitTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.ccBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 12),
        ],
        // AspectRatio OUTSIDE PinchZoom so the zoom viewport is bounded
        // (see chart_view / the chakra pan fix); the gesture layer sits
        // INSIDE PinchZoom so hits are in child coordinates under zoom
        // — same nesting as ChartView.
        AspectRatio(
          aspectRatio: 1,
          child: PinchZoom(
            child: LayoutBuilder(
              builder: (context, constraints) {
                void report(Offset local) {
                  final hit = northHouseHit(
                      Size(constraints.maxWidth, constraints.maxHeight), local);
                  if (hit == null) return;
                  final original = ((viewHouse - 1 + hit - 1) % 12) + 1;
                  // Tapping the Ascendant's house resets, like the
                  // Birth Chart's lagna tap.
                  ref
                      .read(chalitViewHouseProvider(ctx.kundli.id).notifier)
                      .state = original == 1 ? null : original;
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTapDown: (t) => report(t.localPosition),
                  // No-op keeps the recognizer in the arena so
                  // onDoubleTapDown fires before any parent tap.
                  onDoubleTap: () {},
                  onLongPressStart: (t) => report(t.localPosition),
                  child: CustomPaint(
                    painter: NorthChartPainter(
                      l10n: l10n,
                      // Sign-keyed inputs are unused in houseData mode
                      // but required by the painter's base contract.
                      placements: const {},
                      lagna: s.lagnaSign,
                      trueAscendantSign: s.lagnaSign,
                      ascendantDegree: s.ascendant,
                      retrograde: {
                        for (final p in s.positions.values)
                          p.planet: p.isRetrograde,
                      },
                      tokens: tokens,
                      showDegrees: showDegrees,
                      houseData: houseData,
                      ascendantHouse: ascendantHouse,
                      // The ascendant IS house 1's madhya (cusp 1), so
                      // its slot along the bhava is the madhya's rank.
                      ascendantRank: d.madhyaRank[0],
                      boundaryLabels: boundaryLabels,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_systemLabel(l10n, system)}'
          '${viewHouse != 1 ? ' · ${l10n.summaryFrom(l10n.nrHouseN('$viewHouse'))}' : ''}'
          ' — ${l10n.ccCaption}',
          style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
        ),
        if (detail) ...[
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(0.7),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.3),
              3: FlexColumnWidth(1.3),
              4: FlexColumnWidth(1.6),
            },
            children: [
              TableRow(children: [
                _head(l10n.labelHouse),
                _head(l10n.labelSign),
                _head(l10n.ccMadhyaCol),
                _head(l10n.ccSandhiCol),
                _head(l10n.labelGraha),
              ]),
              for (var h = 1; h <= 12; h++)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: KJColors.hairline)),
                  ),
                  children: [
                    _cell('$h', bold: true),
                    _cell(d.signOfHouse(h).label(l10n)),
                    _mono(formatDegree(d.madhya[h - 1])),
                    _mono(formatDegree(d.sandhi[h - 1])),
                    // Traditional order in the table; degree order is a
                    // chart-box convention only.
                    _cell(([...d.planetsInHouse[h - 1]]
                          ..sort((a, b) => a.index.compareTo(b.index)))
                        .map((p) => p.abbrLabel(l10n))
                        .join(' ')),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(t,
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                color: KJColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );

  Widget _cell(String t, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(t,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );

  Widget _mono(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(t, style: KJTheme.mono(size: 12)),
      );
}
