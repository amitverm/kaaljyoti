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
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/ayanamsa.dart';
import '../core/astro/ephemeris_service.dart';
import '../core/astro/kp.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Two-letter sign abbreviations (Aries → Pisces).
const List<String> _signAbbr = [
  'Ar', 'Ta', 'Ge', 'Cn', 'Le', 'Vi', //
  'Li', 'Sc', 'Sg', 'Cp', 'Aq', 'Pi',
];

const String _kpCategory = 'KP (Krishnamurti)';

String _degInSign(double lon) =>
    '${formatDegreeInSign(lon)} ${_signAbbr[(lon ~/ 30) % 12]}';

bool _isKpAyanamsa(AstroSnapshot s) => s.ayanamsaId == 5 || s.ayanamsaId == 45;

Widget _ayanamsaHint(AstroSnapshot s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Ayanamsa: ${Ayanamsa.byId(s.ayanamsaId).name} — KP analysis '
        'traditionally uses the Krishnamurti ayanamsa (editable on '
        'the kundli).',
        style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
      ),
    );

Widget _caption(String t) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(t, style: TextStyle(fontSize: 11, color: TEColors.inkSoft)),
    );

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: TETheme.serif(size: 17)),
    );

Widget _head(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(t,
          style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.6,
              color: TEColors.inkSoft,
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
      child: Text(t, style: TETheme.mono(size: 12)),
    );

Widget _lordChain(KpLords l, {bool subSub = false}) {
  final parts = [l.signLord, l.starLord, l.subLord, if (subSub) l.subSubLord];
  return Text.rich(
    TextSpan(children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0)
          TextSpan(
            text: '·',
            style: TextStyle(color: TEColors.hairline, fontSize: 12),
          ),
        TextSpan(
          text: parts[i].abbr,
          style: TETheme.mono(size: 12, color: planetInk(parts[i])),
        ),
      ],
    ]),
  );
}

Widget _planetList(List<Planet> planets) => planets.isEmpty
    ? Text('—', style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft))
    : Text.rich(
        TextSpan(children: [
          for (var i = 0; i < planets.length; i++) ...[
            if (i > 0) const TextSpan(text: ' '),
            TextSpan(
              text: planets[i].abbr,
              style: TETheme.mono(size: 12, color: planetInk(planets[i])),
            ),
          ],
        ]),
      );

// ---------------------------------------------------------------------------
// Shared tables
// ---------------------------------------------------------------------------

Widget _cuspsTable(KpChart kp, {required bool compact}) => Table(
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(children: [
          _head('Cusp'),
          _head('Degree'),
          _head(compact ? 'Sgn·Str·Sub' : 'Sign·Star·Sub·SS'),
        ]),
        for (final c in kp.cusps)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _cell('${c.house}', bold: c.house == 1 || c.house == 10),
              _cellMono(_degInSign(c.longitude)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                child: _lordChain(c.lords, subSub: !compact),
              ),
            ],
          ),
      ],
    );

Widget _planetsTable(KpChart kp, {required bool compact}) => Table(
      columnWidths: const {
        0: FlexColumnWidth(1.0),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(0.6),
        3: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(children: [
          _head('Graha'),
          _head('Degree'),
          _head('Hse'),
          _head(compact ? 'Sgn·Str·Sub' : 'Sign·Star·Sub·SS'),
        ]),
        for (final p in kp.planets)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _cell(
                '${p.planet.abbr}${p.position.isRetrograde ? ' ℞' : ''}',
                color: planetInk(p.planet),
                bold: true,
              ),
              _cellMono(_degInSign(p.position.longitude)),
              _cell('${p.house}'),
              Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                child: _lordChain(p.lords, subSub: !compact),
              ),
            ],
          ),
      ],
    );

Widget _significatorsTable(KpChart kp) => Table(
      columnWidths: const {
        0: FlexColumnWidth(0.7),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.6),
        4: FlexColumnWidth(0.7),
      },
      children: [
        TableRow(children: [
          _head('Hse'),
          _head('A'),
          _head('B'),
          _head('C'),
          _head('D'),
        ]),
        for (final s in kp.significators)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _cell('${s.house}'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList(s.inStarOfOccupants),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList(s.occupants),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList(s.inStarOfOwner),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _planetList([s.owner]),
              ),
            ],
          ),
      ],
    );

Widget _significationsTable(KpChart kp) => Table(
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(3.2),
      },
      children: [
        TableRow(children: [_head('Graha'), _head('Signifies houses')]),
        for (final p in kp.planets)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _cell(p.planet.abbr, color: planetInk(p.planet), bold: true),
              _cellMono(kp.housesSignifiedBy(p.planet).join(', ')),
            ],
          ),
      ],
    );

// ---------------------------------------------------------------------------
// Shared PDF helpers
// ---------------------------------------------------------------------------

String _pdfChain(KpLords l) =>
    '${l.signLord.abbr} · ${l.starLord.abbr} · ${l.subLord.abbr} · '
    '${l.subSubLord.abbr}';

String _pdfList(List<Planet> ps) =>
    ps.isEmpty ? '-' : ps.map((p) => p.abbr).join(' ');

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
        icon: Icons.adjust,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot),
        _cuspsTable(kp, compact: true),
        _caption('Placidus cusps — Sign · Star · Sub lords'),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot),
          _sectionTitle('House Cusps (Placidus)'),
          _cuspsTable(kp, compact: false),
          _caption(
            'KP uses unequal Placidus houses: a matter belongs to the '
            'cusp whose span it falls in. The cusp SUB LORD is KP\'s '
            'deciding factor for whether a house\'s matters fructify.',
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return [
      pdfSectionHeader('KP — House Cusps (Placidus)'),
      _pdfTable(
        ['Cusp', 'Degree', 'Sign · Star · Sub · SS'],
        [
          for (final c in kp.cusps)
            ['${c.house}', _degInSign(c.longitude), _pdfChain(c.lords)],
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
        icon: Icons.language,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot),
        _planetsTable(kp, compact: true),
        _caption('Sign · Star · Sub lords; houses via Placidus cusps'),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isKpAyanamsa(ctx.snapshot)) _ayanamsaHint(ctx.snapshot),
          _sectionTitle('Planet Sub Lords'),
          _planetsTable(kp, compact: false),
          _caption(
            'A planet gives the results of its STAR lord; its SUB lord '
            'decides whether those results are favourable. Hse is the '
            'Placidus cusp-span house the planet occupies (can differ '
            'from its whole-sign house).',
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return [
      pdfSectionHeader('KP — Planet Sub Lords'),
      _pdfTable(
        ['Graha', 'Degree', 'House', 'Sign · Star · Sub · SS'],
        [
          for (final p in kp.planets)
            [
              '${p.planet.displayName}${p.position.isRetrograde ? ' (R)' : ''}',
              _degInSign(p.position.longitude),
              '${p.house}',
              _pdfChain(p.lords),
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
        icon: Icons.account_tree_outlined,
        category: _kpCategory,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _significatorsTable(kp),
        _caption(
          'A — in star of occupants · B — occupants · C — in star of '
          'owner · D — owner',
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('House Significators'),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'A — in star of occupants · B — occupants · '
              'C — in star of owner · D — owner (A is strongest)',
              style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
            ),
          ),
          _significatorsTable(kp),
          const SizedBox(height: 20),
          _sectionTitle('Planet Significations'),
          _significationsTable(kp),
          _caption(
            'The reverse view: every house each planet speaks for. An '
            'event fructifies when its dasha lords signify the '
            'relevant houses.',
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final kp = KpChart(ctx.snapshot);
    return [
      pdfSectionHeader('KP — House Significators (A / B / C / D)'),
      _pdfTable(
        [
          'House',
          'A — star of occupants',
          'B — occupants',
          'C — star of owner',
          'D — owner',
        ],
        [
          for (final s in kp.significators)
            [
              '${s.house}',
              _pdfList(s.inStarOfOccupants),
              _pdfList(s.occupants),
              _pdfList(s.inStarOfOwner),
              s.owner.abbr,
            ],
        ],
      ),
      pdfSectionHeader('KP — Planet Significations'),
      _pdfTable(
        ['Graha', 'Signifies houses'],
        [
          for (final p in kp.planets)
            [
              p.planet.displayName,
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
            _sectionTitle('Ruling Planets · now'),
            _RulingPlanetsView(snapshot: ctx.snapshot, compact: false),
            _caption(
              'KP horary: the lords ruling the moment a question is '
              'judged. Events tend to fructify when the ruling planets '
              'overlap the significators of the relevant houses. '
              'Reopen this view to refresh.',
            ),
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
        'Ruling planets unavailable (calculations not ready).',
        style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft),
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
                    style:
                        TextStyle(fontSize: 12.5, color: TEColors.inkSoft)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final p in ps)
                      Text(compact ? p.abbr : p.displayName,
                          style:
                              TETheme.mono(size: 12.5, color: planetInk(p))),
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Day lord', [rp.dayLord]),
        row('Lagna Sgn·Str·Sub',
            [rp.lagnaSignLord, rp.lagnaStarLord, rp.lagnaSubLord]),
        row('Moon Sgn·Str·Sub',
            [rp.moonSignLord, rp.moonStarLord, rp.moonSubLord]),
        row('Distinct RP', rp.distinct),
        const SizedBox(height: 4),
        Text(
          'Now, at ${snapshot.birth.placeName.isEmpty ? 'the birth place' : snapshot.birth.placeName}. '
          'Day lord follows the civil weekday.',
          style: TextStyle(fontSize: 11, color: TEColors.inkSoft),
        ),
      ],
    );
  }
}
