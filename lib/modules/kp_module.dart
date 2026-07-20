/// KP (Krishnamurti Paddhati) widgets — four separate dashboard cards
/// so each concept is available on the dashboard on its own:
///
///  * [KpCuspsModule] — Placidus cusps with sign/star/sub lord chains
///    (the KP foundation; id 'kp' kept from the original combined
///    widget so existing dashboard cards keep working);
///  * [KpPlanetsModule] — each graha's lord chain + cusp-span house;
///  * [KpSignificatorsModule] — A–D house significators and planet
///    significations (the workhorse of KP judgment);
///  * [KpRulingPlanetsModule] — ruling planets at the moment of
///    viewing (KP horary timing).
///
/// Engine: core/astro/kp.dart.
library;

import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/ayanamsa.dart';
import '../core/astro/ephemeris_service.dart';
import '../core/astro/kp.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _kpCuspsTitle(AppLocalizations l10n) => l10n.moduleKpCuspsTitle;
String _kpPlanetsTitle(AppLocalizations l10n) => l10n.moduleKpPlanetsTitle;
String _kpSignificatorsTitle(AppLocalizations l10n) =>
    l10n.moduleKpSignificatorsTitle;
String _kpRulingPlanetsTitle(AppLocalizations l10n) =>
    l10n.moduleKpRulingPlanetsTitle;

const String _kpCategory = 'KP (Krishnamurti)';

String _degInSign(double lon, AppLocalizations l10n) =>
    '${formatDegreeInSign(lon)} '
    '${ZodiacSign.fromLongitude(lon).abbrLabel(l10n)}';

bool _isKpAyanamsa(AstroSnapshot s) => s.ayanamsaId == 5 || s.ayanamsaId == 45;

Widget _ayanamsaHint(AstroSnapshot s, AppLocalizations l10n) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        l10n.kpAyanamsaHint(Ayanamsa.byId(s.ayanamsaId).name),
        style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
      ),
    );

Widget _caption(String t) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(t, style: TextStyle(fontSize: 11, color: KJColors.inkSoft)),
    );

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: KJTheme.serif(size: 17)),
    );

Widget _head(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(t,
          style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.6,
              color: KJColors.inkSoft,
              fontWeight: FontWeight.w600)),
    );

Widget _cell(String t, {Color? color, bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(t,
          style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
    );

Widget _cellMono(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(t, style: KJTheme.mono(size: 12)),
    );

Widget _lordChain(KpLords l, AppLocalizations l10n, {bool subSub = false}) {
  final parts = [l.signLord, l.starLord, l.subLord, if (subSub) l.subSubLord];
  return Text.rich(
    TextSpan(children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0)
          TextSpan(
            text: '·',
            style: TextStyle(color: KJColors.hairline, fontSize: 12),
          ),
        TextSpan(
          text: parts[i].abbrLabel(l10n),
          style: KJTheme.mono(size: 12, color: planetInk(parts[i])),
        ),
      ],
    ]),
  );
}

Widget _planetList(List<Planet> planets, AppLocalizations l10n) =>
    planets.isEmpty
        ? Text('—', style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft))
        : Text.rich(
            TextSpan(children: [
              for (var i = 0; i < planets.length; i++) ...[
                if (i > 0) const TextSpan(text: ' '),
                TextSpan(
                  text: planets[i].abbrLabel(l10n),
                  style: KJTheme.mono(size: 12, color: planetInk(planets[i])),
                ),
              ],
            ]),
          );

// ---------------------------------------------------------------------------
// Shared tables
// ---------------------------------------------------------------------------

Widget _cuspsTable(KpChart kp, AppLocalizations l10n,
        {required bool compact}) =>
    Table(
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(children: [
          _head(l10n.kpHeadCusp),
          _head(l10n.labelDegree),
          _head(compact ? l10n.kpHeadChainCompact : l10n.kpHeadChainFull),
        ]),
        for (final c in kp.cusps)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _cell('${c.house}', bold: c.house == 1 || c.house == 10),
              _cellMono(_degInSign(c.longitude, l10n)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                child: _lordChain(c.lords, l10n, subSub: !compact),
              ),
            ],
          ),
      ],
    );

Widget _planetsTable(KpChart kp, AppLocalizations l10n,
        {required bool compact}) =>
    Table(
      columnWidths: const {
        0: FlexColumnWidth(1.0),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(0.6),
        3: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(children: [
          _head(l10n.labelGraha),
          _head(l10n.labelDegree),
          _head(l10n.kpHeadHouseAbbr),
          _head(compact ? l10n.kpHeadChainCompact : l10n.kpHeadChainFull),
        ]),
        for (final p in kp.planets)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _cell(
                '${p.planet.abbrLabel(l10n)}'
                '${p.position.isRetrograde ? ' ℞' : ''}',
                color: planetInk(p.planet),
                bold: true,
              ),
              _cellMono(_degInSign(p.position.longitude, l10n)),
              _cell('${p.house}'),
              Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                child: _lordChain(p.lords, l10n, subSub: !compact),
              ),
            ],
          ),
      ],
    );

Widget _significatorsTable(KpChart kp, AppLocalizations l10n) => Table(
      columnWidths: const {
        0: FlexColumnWidth(0.7),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.6),
        4: FlexColumnWidth(0.7),
      },
      children: [
        TableRow(children: [
          _head(l10n.kpHeadHouseAbbr),
          _head('A'),
          _head('B'),
          _head('C'),
          _head('D'),
        ]),
        for (final s in kp.significators)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _cell('${s.house}'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList(s.inStarOfOccupants, l10n),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList(s.occupants, l10n),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList(s.inStarOfOwner, l10n),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList([s.owner], l10n),
              ),
            ],
          ),
      ],
    );

Widget _significationsTable(KpChart kp, AppLocalizations l10n) => Table(
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(3.2),
      },
      children: [
        TableRow(children: [
          _head(l10n.labelGraha),
          _head(l10n.kpHeadSignifiesHouses),
        ]),
        for (final p in kp.planets)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _cell(p.planet.abbrLabel(l10n),
                  color: planetInk(p.planet), bold: true),
              _cellMono(kp.housesSignifiedBy(p.planet).join(', ')),
            ],
          ),
      ],
    );

// ---------------------------------------------------------------------------
// Shared PDF helpers
// ---------------------------------------------------------------------------

String _pdfChain(KpLords l, AppLocalizations l10n) =>
    '${l.signLord.abbrLabel(l10n)} · ${l.starLord.abbrLabel(l10n)} · '
    '${l.subLord.abbrLabel(l10n)} · ${l.subSubLord.abbrLabel(l10n)}';

String _pdfList(List<Planet> ps, AppLocalizations l10n) =>
    ps.isEmpty ? '-' : ps.map((p) => p.abbrLabel(l10n)).join(' ');

pw.Widget _pdfTable(List<String> headers, List<List<String>> data) =>
    pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
          fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
      cellStyle: pdfBody(size: 9.5),
      border: null,
      rowDecoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );

// ---------------------------------------------------------------------------
// 1. Cusps & sub lords (id 'kp' — the original combined widget's id,
//    kept so dashboards that already placed it don't break)
// ---------------------------------------------------------------------------

class KpCuspsModule extends AstroModule {
  const KpCuspsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'kp',
        title: 'KP · Cusps',
        localizedTitle: _kpCuspsTitle,
        icon: Icons.adjust,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final kp = KpChart(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot, l10n),
        _cuspsTable(kp, l10n, compact: true),
        _caption(l10n.kpCuspsCardCaption),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final kp = KpChart(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot, l10n),
          _sectionTitle(l10n.kpCuspsSectionTitle),
          _cuspsTable(kp, l10n, compact: false),
          _caption(l10n.kpCuspsDetailCaption),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final kp = KpChart(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.kpPdfCuspsHeader),
      _pdfTable(
        [l10n.kpHeadCusp, l10n.labelDegree, l10n.kpHeadChainFull],
        [
          for (final c in kp.cusps)
            [
              '${c.house}',
              _degInSign(c.longitude, l10n),
              _pdfChain(c.lords, l10n),
            ],
        ],
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 2. Planet sub lords
// ---------------------------------------------------------------------------

class KpPlanetsModule extends AstroModule {
  const KpPlanetsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'kp_planets',
        title: 'KP · Planets',
        localizedTitle: _kpPlanetsTitle,
        icon: Icons.language,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final kp = KpChart(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot, l10n),
        _planetsTable(kp, l10n, compact: true),
        _caption(l10n.kpPlanetsCardCaption),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final kp = KpChart(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot, l10n),
          _sectionTitle(l10n.kpPlanetsSectionTitle),
          _planetsTable(kp, l10n, compact: false),
          _caption(l10n.kpPlanetsDetailCaption),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final kp = KpChart(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.kpPdfPlanetsHeader),
      _pdfTable(
        [
          l10n.labelGraha,
          l10n.labelDegree,
          l10n.labelHouse,
          l10n.kpHeadChainFull,
        ],
        [
          for (final p in kp.planets)
            [
              '${p.planet.label(l10n)}'
                  '${p.position.isRetrograde ? ' (R)' : ''}',
              _degInSign(p.position.longitude, l10n),
              '${p.house}',
              _pdfChain(p.lords, l10n),
            ],
        ],
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 3. Significators
// ---------------------------------------------------------------------------

class KpSignificatorsModule extends AstroModule {
  const KpSignificatorsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'kp_significators',
        title: 'KP · Significators',
        localizedTitle: _kpSignificatorsTitle,
        icon: Icons.account_tree_outlined,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final kp = KpChart(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _significatorsTable(kp, l10n),
        _caption(l10n.kpSignificatorsLegend),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final kp = KpChart(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.kpHouseSignificatorsTitle),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.kpSignificatorsLegendDetail,
              style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
            ),
          ),
          _significatorsTable(kp, l10n),
          const SizedBox(height: 20),
          _sectionTitle(l10n.kpPlanetSignificationsTitle),
          _significationsTable(kp, l10n),
          _caption(l10n.kpSignificationsCaption),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final kp = KpChart(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.kpPdfSignificatorsHeader),
      _pdfTable(
        [
          l10n.labelHouse,
          l10n.kpHeadAStarOfOccupants,
          l10n.kpHeadBOccupants,
          l10n.kpHeadCStarOfOwner,
          l10n.kpHeadDOwner,
        ],
        [
          for (final s in kp.significators)
            [
              '${s.house}',
              _pdfList(s.inStarOfOccupants, l10n),
              _pdfList(s.occupants, l10n),
              _pdfList(s.inStarOfOwner, l10n),
              s.owner.abbrLabel(l10n),
            ],
        ],
      ),
      pdfSectionHeader(l10n.kpPdfSignificationsHeader),
      _pdfTable(
        [l10n.labelGraha, l10n.kpHeadSignifiesHouses],
        [
          for (final p in kp.planets)
            [
              p.planet.label(l10n),
              kp.housesSignifiedBy(p.planet).join(', '),
            ],
        ],
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 4. Ruling planets (moment of viewing)
// ---------------------------------------------------------------------------

class KpRulingPlanetsModule extends AstroModule {
  const KpRulingPlanetsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'kp_ruling',
        title: 'KP · Ruling Planets',
        localizedTitle: _kpRulingPlanetsTitle,
        icon: Icons.schedule,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _RulingPlanetsView(snapshot: ctx.snapshot, compact: true);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context.l10n.kpRulingPlanetsNowTitle),
            _RulingPlanetsView(snapshot: ctx.snapshot, compact: false),
            _caption(context.l10n.kpRulingPlanetsCaption),
          ],
        ),
      );

  /// Ruling planets are a live, moment-of-viewing value — meaningless
  /// frozen into a printed report, so the PDF section is omitted.
  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
}

/// Ruling planets at the moment the view is built, computed for the
/// kundli's place (KP convention is the place of judgment; the birth
/// place is the closest stable anchor the app has). Recomputed on each
/// rebuild — no live tick needed at RP granularity.
class _RulingPlanetsView extends StatelessWidget {
  const _RulingPlanetsView({required this.snapshot, required this.compact});

  final AstroSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final KpRulingPlanets rp;
    try {
      final eph = EphemerisService.instance;
      final now = DateTime.now();
      final jd = eph.julianDayUt(now.toUtc());
      final moon =
          eph.planetPositions(jd, snapshot.ayanamsaId)[Planet.moon]!.longitude;
      final houses = eph.housesAndAscendant(
        jd,
        snapshot.birth.latitude,
        snapshot.birth.longitude,
        snapshot.ayanamsaId,
      );
      rp = KpRulingPlanets.compute(
        ascendant: houses.ascendant,
        moonLongitude: moon,
        localWeekday: now.weekday,
      );
    } catch (_) {
      return Text(
        l10n.kpRulingPlanetsUnavailable,
        style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
      );
    }

    Widget row(String label, List<Planet> ps) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 104 : 120,
                child: Text(label,
                    style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final p in ps)
                      Text(compact ? p.abbrLabel(l10n) : p.label(l10n),
                          style: KJTheme.mono(size: 12.5, color: planetInk(p))),
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(l10n.kpDayLord, [rp.dayLord]),
        row(l10n.kpLagnaChainLabel,
            [rp.lagnaSignLord, rp.lagnaStarLord, rp.lagnaSubLord]),
        row(l10n.kpMoonChainLabel,
            [rp.moonSignLord, rp.moonStarLord, rp.moonSubLord]),
        row(l10n.kpDistinctRp, rp.distinct),
        const SizedBox(height: 4),
        Text(
          l10n.kpRulingPlanetsFootnote(
            snapshot.birth.placeName.isEmpty
                ? l10n.kpBirthPlaceFallback
                : snapshot.birth.placeName,
          ),
          style: TextStyle(fontSize: 11, color: KJColors.inkSoft),
        ),
      ],
    );
  }
}
