/// Vector chart drawing for PDF export — North Indian and South
/// Indian styles rendered with the pdf package's canvas (the on-screen
/// Flutter painters can't be reused here). Circular falls back to
/// North for now.
///
/// This mirrors the on-screen chart's always-on fixes (explicit
/// Ascendant marker, no retrograde flag on the nodes) AND its opt-in
/// per-planet annotations: degrees, Jaimini karakas and
/// dignity/combustion arrive as pre-formatted text via [degreeLabels]
/// and [planetTags], which callers build with [pdfAnnotationsFor] from
/// the very same [PlanetToken]s their screen painter consumes. Sign
/// marks that ride the recessive grey channel on screen (arudha pada
/// codes, Indu Lagna, Muntha, SAV bindus) ride [padaLabels] here, so
/// they need no separate plumbing.
///
/// Only the TRANSIT overlay remains screen-only: it is a live "as of
/// now" reading with its own scrub control, and a static document can
/// only ever freeze one instant — the standalone Transit widget's own
/// PDF section is where that belongs.
library;

import 'package:pdf/pdf.dart';
import 'pw.dart' as pw;

import '../charts/chart_style.dart';
import '../charts/planet_token.dart';
import '../core/astro/dignity.dart';
import '../core/astro/models.dart';
import '../modules/common.dart';
import '../l10n/astro_l10n.dart';

/// Default drawn size in points. Roomy on purpose: at the old 230 the
/// labels crowded the diamond, and an A4 text column is 523pt wide, so
/// a 300pt chart still centres with generous margins.
const double kPdfChartSize = 300;

/// House label width as a fraction of the chart's side, and the line
/// leading the anchor offsets are derived from. The vertical anchor is
/// computed per house (see [_blockHeight]) rather than hardcoded, so a
/// tall annotated block stays centred on its house instead of drifting
/// toward the frame.
const double _labelWidthFactor = 0.25;
const double _leading = 1.2;

const double _signFontSize = 7;
const double _ascFontSize = 6;
const double _padaFontSize = 6.5;

/// Planet glyphs size to the room the house actually needs, instead of
/// one timid size for every house. An uncrowded house — which is most
/// of them — gets [_planetFontMax]; a house only shrinks toward
/// [_planetFontMin] as its content grows, so the stellium case is no
/// tighter than it was before while the ordinary case reads a fifth
/// larger.
const double _planetFontMax = 9.6;
const double _planetFontMid = 8.8;
const double _planetFontMin = 8;

/// The size for a block of [rows] lines carrying [chips] glyphs in
/// total. Both matter: four stacked "Ju(R) 12°34' AK" lines run out of
/// vertical room, while nine joined abbreviations on one line run out
/// of horizontal room.
double _planetFontFor(List<List<_Chip>> lines) {
  final rows = lines.length;
  final chips = lines.fold(0, (n, l) => n + l.length);
  if (rows > 3 || chips > 6) return _planetFontMin;
  if (rows == 3 || chips > 3) return _planetFontMid;
  return _planetFontMax;
}

/// Above this many planets a house drops back to the joined-abbreviation
/// line and omits degrees FOR THAT HOUSE. A five-planet stack of
/// "Ju(R) 12°34' AK" lines is already taller than a North diamond's
/// half-height at any legible size, and a stellium of eight or nine
/// would run clean through the frame. Full precision is never lost —
/// the Planetary Positions table prints every degree.
const int _maxStackedPlanets = 4;

pw.Widget pdfChart({
  required AppLocalizations l10n,
  required Map<ZodiacSign, List<Planet>> placements,
  required ZodiacSign lagna,
  required ChartStyle style,
  double size = kPdfChartSize,
  Map<Planet, bool> retrograde = const {},
  ZodiacSign? trueAscendantSign,
  double? ascendantDegree,
  Map<ZodiacSign, List<String>> padaLabels = const {},

  /// Pre-formatted degree-in-sign per planet ("3°37'"). Non-empty means
  /// "degrees are on": each planet then gets its own line.
  Map<Planet, String> degreeLabels = const {},

  /// Compact trailing markers per planet ("Ex c AK") — see
  /// [pdfAnnotationsFor].
  Map<Planet, String> planetTags = const {},

  /// Renders [padaLabels] as the chart's SUBJECT — planet-sized, in
  /// ink — rather than as the recessive grey overlay other charts use.
  /// For the Arudha Pada chart, where the padas are the whole content
  /// and there are no grahas to compete with.
  bool primaryPadas = false,

  /// Cusp-bounded (chalit) mode: 12 records, drawn house 1..12. Set
  /// this and the sign-keyed [placements]/[lagna] inputs are ignored —
  /// see [PdfChartHouse].
  List<PdfChartHouse>? houses,

  /// Chalit mode only: which drawn house carries the "Asc" marker.
  int ascendantHouse = 1,
}) {
  final trueAsc = trueAscendantSign ?? lagna;
  final ann = _Annotations(retrograde, degreeLabels, planetTags);
  if (houses != null) {
    // Cusp-bounded houses are not sign-aligned, so only the North
    // layout (fixed house positions) can express them — exactly the
    // constraint the on-screen painter works under.
    return _northHouses(
        l10n, houses, size, ascendantHouse, ascendantDegree, ann, primaryPadas);
  }
  switch (style) {
    case ChartStyle.south:
      return _south(l10n, placements, lagna, size, trueAsc, ascendantDegree,
          padaLabels, ann, primaryPadas);
    case ChartStyle.north:
    case ChartStyle.circular: // circular: North fallback in PDF (v1)
      return _north(l10n, placements, lagna, size, trueAsc, ascendantDegree,
          padaLabels, ann, primaryPadas);
  }
}

/// Splits a screen [PlanetToken] map into the two text channels
/// [pdfChart] renders, so a module wires its PDF chart from the exact
/// annotation set its card already computed (`chartTokens`) instead of
/// recomputing — or, as before, silently dropping — the astrology.
///
/// Dignity is spelled out rather than drawn: the screen's ↑ ↓ ○ glyphs
/// are absent from IBM Plex Sans and the built-in PDF faces, so they'd
/// print as empty boxes. "Ex"/"De"/"Ow"/"c" carry the same four states
/// in characters every embedded face has.
({Map<Planet, String> degrees, Map<Planet, String> tags}) pdfAnnotationsFor(
    Map<Planet, PlanetToken> tokens) {
  final degrees = <Planet, String>{};
  final tags = <Planet, String>{};
  for (final t in tokens.values) {
    final d = t.degreeInSign;
    if (d != null) degrees[t.planet] = formatDegreeInSign(d);
    final dignity = _dignityTag(t.dignity);
    final karaka = t.karaka;
    final marks = [
      if (dignity != null) dignity,
      if (t.combust) 'c',
      if (karaka != null) karaka,
    ];
    if (marks.isNotEmpty) tags[t.planet] = marks.join(' ');
  }
  return (degrees: degrees, tags: tags);
}

String? _dignityTag(PlanetDignity dignity) => switch (dignity) {
      PlanetDignity.exalted => 'Ex',
      PlanetDignity.debilitated => 'De',
      PlanetDignity.ownSign => 'Ow',
      PlanetDignity.none => null,
    };

/// One drawn piece of a house label: text plus the ink it takes. A line
/// of several chips is drawn as separate widgets side by side rather
/// than one rich string — see [_planetRow].
typedef _Chip = ({String text, PdfColor ink});

/// The three per-planet text channels, bundled so the style builders
/// pass one thing around instead of three.
class _Annotations {
  const _Annotations(this.retrograde, this.degrees, this.tags);

  final Map<Planet, bool> retrograde;
  final Map<Planet, String> degrees;
  final Map<Planet, String> tags;

  bool get isEmpty => degrees.isEmpty && tags.isEmpty;

  /// The lunar nodes are retrograde by definition — never worth
  /// flagging — so the marker is suppressed for them, matching the
  /// on-screen painters. "(R)" (not ℞) matches [pdfPositionsTable]'s
  /// existing convention, since core PDF fonts don't reliably carry
  /// the ℞ glyph.
  String _abbr(AppLocalizations l10n, Planet p) {
    final isNode = p == Planet.rahu || p == Planet.ketu;
    final retro = !isNode && (retrograde[p] ?? false);
    return retro ? '${p.abbrLabel(l10n)}(R)' : p.abbrLabel(l10n);
  }

  /// One line per planet when there is anything to annotate and the
  /// house is not overcrowded; otherwise the joined "Su Me(R) Ma" line
  /// the charts have always used — which becomes several chips on ONE
  /// line, since each graha carries its own ink.
  List<List<_Chip>> lines(AppLocalizations l10n, List<Planet> planets) {
    if (planets.isEmpty) return const [];
    if (isEmpty || planets.length > _maxStackedPlanets) {
      return [
        [for (final p in planets) (text: _abbr(l10n, p), ink: pdfPlanetInk(p))],
      ];
    }
    // Annotated: the degree and the karaka/dignity marks belong to
    // their graha, so the whole line takes that graha's ink.
    return [
      for (final p in planets)
        [
          (
            text: [
              _abbr(l10n, p),
              if (degrees[p] != null) degrees[p]!,
              if (tags[p] != null) tags[p]!,
            ].join(' '),
            ink: pdfPlanetInk(p),
          ),
        ],
    ];
  }
}

String _ascText(AppLocalizations l10n, double? ascendantDegree) =>
    ascendantDegree != null
        ? '${l10n.chartAsc} ${formatDegreeInSign(ascendantDegree)}'
        : l10n.chartAsc;

/// Drawn height of a house block, used to centre it on its anchor.
/// Derived from what [_houseLabel] actually emits — the old hardcoded
/// -11 offset assumed a fixed two-line block and drifted as soon as a
/// house grew an Asc marker, pada codes or per-planet degree lines.
double _blockHeight({
  required bool isAsc,
  required int planetLines,
  required double planetFontSize,
  required bool hasPadas,
  double padaFontSize = _padaFontSize,
  bool hasCusp = false,
}) =>
    _leading *
    ((isAsc ? _ascFontSize : 0) +
        _signFontSize +
        planetLines * planetFontSize +
        (hasCusp ? _padaFontSize : 0) +
        (hasPadas ? padaFontSize : 0));

/// One line of a house label, each graha in its own ink.
///
/// A multi-graha line is a [pw.Wrap] of one small [pw.Text] per graha,
/// NOT a rich-text run. Every string then still goes through the
/// pw.dart facade's shaping `Text`, which is the only thing that puts
/// Hindi graha abbreviations in the right visual order; `pw.TextSpan`
/// is re-exported raw and would silently bypass it. The Wrap also
/// flows a crowded house onto a second line on its own, which the
/// single soft-wrapping Text it replaces did more grudgingly.
pw.Widget _planetRow(List<_Chip> chips, double fontSize) {
  if (chips.length == 1) {
    return pw.Text(
      chips.single.text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: fontSize, color: chips.single.ink),
    );
  }
  return pw.Wrap(
    alignment: pw.WrapAlignment.center,
    spacing: 2.5,
    children: [
      for (final chip in chips)
        pw.Text(chip.text,
            style: pw.TextStyle(fontSize: fontSize, color: chip.ink)),
    ],
  );
}

pw.Widget _houseLabel({
  required AppLocalizations l10n,
  required int signNumber,
  required List<List<_Chip>> planetLines,
  required double planetFontSize,
  required double width,
  List<String> padas = const [],
  bool primaryPadas = false,
  String? cuspLabel,
  bool isAsc = false,
  String ascText = '',
}) =>
    pw.SizedBox(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$signNumber',
              style: const pw.TextStyle(
                  fontSize: _signFontSize, color: pdfInkSoft)),
          if (isAsc)
            pw.Text(ascText,
                style: const pw.TextStyle(
                    fontSize: _ascFontSize,
                    color: pdfMaroon,
                    fontWeight: pw.FontWeight.bold)),
          for (final line in planetLines) _planetRow(line, planetFontSize),
          // The bhava madhya, in the same recessive grey the screen's
          // chalit chart gives it.
          if (cuspLabel != null)
            pw.Text(cuspLabel,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                    fontSize: _padaFontSize, color: PdfColors.grey500)),
          if (padas.isNotEmpty)
            pw.Text(
              padas.join(' '),
              textAlign: pw.TextAlign.center,
              // When the padas ARE the chart (the Arudha Pada module)
              // they take the planet slot's size and ink; everywhere
              // else they stay the recessive grey overlay that must not
              // compete with the grahas.
              style: primaryPadas
                  ? pw.TextStyle(fontSize: planetFontSize, color: pdfInk)
                  : const pw.TextStyle(
                      fontSize: _padaFontSize, color: PdfColors.grey500),
            ),
        ],
      ),
    );

/// One cusp-bounded house for [pdfChart]'s [houses] mode.
///
/// Chalit houses are not sign-aligned — two bhavas can share a rashi and
/// a rashi can host none — which no `Map<ZodiacSign, …>` can express, so
/// each drawn house carries its own sign number and occupants. Mirrors
/// the on-screen painter's `houseData`.
typedef PdfChartHouse = ({
  int signNumber,
  List<Planet> planets,

  /// The bhava madhya line ("M 11°16'"), or null when the module's cusp
  /// toggles are off.
  String? cuspLabel,
});

/// House anchor centers as fractions of the square (top-left origin),
/// shared by the sign-based and cusp-based North charts.
const _northAnchors = <int, (double, double)>{
  1: (0.50, 0.25),
  2: (0.25, 0.10),
  3: (0.10, 0.25),
  4: (0.25, 0.50),
  5: (0.10, 0.75),
  6: (0.25, 0.90),
  7: (0.50, 0.75),
  8: (0.75, 0.90),
  9: (0.90, 0.75),
  10: (0.75, 0.50),
  11: (0.90, 0.25),
  12: (0.75, 0.10),
};

/// The North diamond itself: frame, diagonals, midpoint diamond.
pw.Widget _northFrame(double s, List<pw.Widget> labels) => pw.SizedBox(
      width: s,
      height: s,
      child: pw.CustomPaint(
        size: PdfPoint(s, s),
        painter: (canvas, psize) {
          canvas
            ..setStrokeColor(pdfInk)
            ..setLineWidth(0.9)
            // Frame.
            ..drawRect(0, 0, s, s)
            ..strokePath()
            // Diagonals.
            ..moveTo(0, 0)
            ..lineTo(s, s)
            ..moveTo(0, s)
            ..lineTo(s, 0)
            ..strokePath()
            // Midpoint diamond.
            ..moveTo(s / 2, 0)
            ..lineTo(s, s / 2)
            ..lineTo(s / 2, s)
            ..lineTo(0, s / 2)
            ..closePath()
            ..strokePath();
        },
        child: pw.Stack(children: labels),
      ),
    );

/// Places a built house label on its anchor, centred on the block's own
/// measured height.
pw.Widget _positionedLabel({
  required int house,
  required double s,
  required double width,
  required double height,
  required pw.Widget child,
}) {
  final (ax, ay) = _northAnchors[house]!;
  return pw.Positioned(
    left: ax * s - width / 2,
    top: ay * s - height / 2,
    child: child,
  );
}

/// North Indian: fixed houses (1 = top-center diamond, counter-
/// clockwise); the sign NUMBER rotates with the lagna. An explicit
/// "Asc" label marks the true ascendant's house regardless of [lagna]
/// (which may be a "view from" anchor rather than the true ascendant).
pw.Widget _north(
  AppLocalizations l10n,
  Map<ZodiacSign, List<Planet>> placements,
  ZodiacSign lagna,
  double s,
  ZodiacSign trueAsc,
  double? ascendantDegree,
  Map<ZodiacSign, List<String>> padaLabels,
  _Annotations ann,
  bool primaryPadas,
) {
  final houseOfTrueAsc = ((trueAsc.index - lagna.index + 12) % 12) + 1;
  final ascText = _ascText(l10n, ascendantDegree);
  final labelWidth = s * _labelWidthFactor;

  return _northFrame(s, [
    for (final house in _northAnchors.keys)
      () {
        final sign = ZodiacSign.values[(lagna.index + house - 1) % 12];
        final padas = padaLabels[sign] ?? const <String>[];
        final isAsc = house == houseOfTrueAsc;
        final lines = ann.lines(l10n, placements[sign] ?? const []);
        // With primary padas the pada line IS the content, so it drives
        // the size the way planet lines otherwise would.
        final font = primaryPadas
            ? _planetFontFor([
                for (final code in padas) [(text: code, ink: pdfInk)]
              ])
            : _planetFontFor(lines);
        return _positionedLabel(
          house: house,
          s: s,
          width: labelWidth,
          height: _blockHeight(
            isAsc: isAsc,
            planetLines: lines.length,
            planetFontSize: font,
            hasPadas: padas.isNotEmpty,
            padaFontSize: primaryPadas ? font : _padaFontSize,
          ),
          child: _houseLabel(
            l10n: l10n,
            signNumber: sign.index + 1,
            planetLines: lines,
            planetFontSize: font,
            width: labelWidth,
            padas: padas,
            primaryPadas: primaryPadas,
            isAsc: isAsc,
            ascText: ascText,
          ),
        );
      }(),
  ]);
}

/// Cusp-bounded (chalit) North chart: the layout is the same fixed
/// twelve houses, but every house takes its sign number and its
/// occupants from [houses] rather than from a lagna rotation.
///
/// The screen additionally paints each bhava SANDHI on the dividing
/// line it describes; that needs per-edge midpoint geometry the PDF
/// canvas layer doesn't have here, and the Chalit table below the chart
/// prints every sandhi degree anyway — so the chart carries the madhya
/// only.
pw.Widget _northHouses(
  AppLocalizations l10n,
  List<PdfChartHouse> houses,
  double s,
  int ascendantHouse,
  double? ascendantDegree,
  _Annotations ann,
  bool primaryPadas,
) {
  final ascText = _ascText(l10n, ascendantDegree);
  final labelWidth = s * _labelWidthFactor;

  return _northFrame(s, [
    for (final house in _northAnchors.keys)
      () {
        final data = houses[house - 1];
        final isAsc = house == ascendantHouse;
        final lines = ann.lines(l10n, data.planets);
        final font = _planetFontFor(lines);
        return _positionedLabel(
          house: house,
          s: s,
          width: labelWidth,
          height: _blockHeight(
            isAsc: isAsc,
            planetLines: lines.length,
            planetFontSize: font,
            hasPadas: false,
            hasCusp: data.cuspLabel != null,
          ),
          child: _houseLabel(
            l10n: l10n,
            signNumber: data.signNumber,
            planetLines: lines,
            planetFontSize: font,
            width: labelWidth,
            cuspLabel: data.cuspLabel,
            isAsc: isAsc,
            ascText: ascText,
          ),
        );
      }(),
  ]);
}

/// South Indian: signs fixed in a 4×4 ring (Pisces top-left, Aries →
/// Gemini across the top, clockwise); lagna cell marked with a corner
/// stroke. An explicit "Asc" label marks the true ascendant's cell
/// regardless of [lagna].
pw.Widget _south(
  AppLocalizations l10n,
  Map<ZodiacSign, List<Planet>> placements,
  ZodiacSign lagna,
  double s,
  ZodiacSign trueAsc,
  double? ascendantDegree,
  Map<ZodiacSign, List<String>> padaLabels,
  _Annotations ann,
  bool primaryPadas,
) {
  // (row, col) per sign, top-left origin.
  const cells = <ZodiacSign, (int, int)>{
    ZodiacSign.pisces: (0, 0),
    ZodiacSign.aries: (0, 1),
    ZodiacSign.taurus: (0, 2),
    ZodiacSign.gemini: (0, 3),
    ZodiacSign.cancer: (1, 3),
    ZodiacSign.leo: (2, 3),
    ZodiacSign.virgo: (3, 3),
    ZodiacSign.libra: (3, 2),
    ZodiacSign.scorpio: (3, 1),
    ZodiacSign.sagittarius: (3, 0),
    ZodiacSign.capricorn: (2, 0),
    ZodiacSign.aquarius: (1, 0),
  };
  final cell = s / 4;
  final ascText = _ascText(l10n, ascendantDegree);

  return pw.SizedBox(
    width: s,
    height: s,
    child: pw.CustomPaint(
      size: PdfPoint(s, s),
      painter: (canvas, psize) {
        canvas
          ..setStrokeColor(pdfInk)
          ..setLineWidth(0.9);
        // Cell borders (PDF y-origin is bottom-left; convert rows).
        for (final pos in cells.values) {
          final (row, col) = pos;
          final x = col * cell;
          final yTop = row * cell;
          final yPdf = s - yTop - cell;
          canvas
            ..drawRect(x, yPdf, cell, cell)
            ..strokePath();
        }
        // Lagna marker: short diagonal in the cell's top-left corner.
        final (lr, lc) = cells[lagna]!;
        final lx = lc * cell;
        final lyTopPdf = s - lr * cell;
        canvas
          ..setStrokeColor(pdfMaroon)
          ..setLineWidth(1.2)
          ..moveTo(lx, lyTopPdf - cell * 0.28)
          ..lineTo(lx + cell * 0.28, lyTopPdf)
          ..strokePath();
      },
      child: pw.Stack(
        children: [
          for (final entry in cells.entries)
            () {
              final sign = entry.key;
              final (row, col) = entry.value;
              final padas = padaLabels[sign] ?? const <String>[];
              final lines = ann.lines(l10n, placements[sign] ?? const []);
              // A South cell is squarer than a North wedge, so it takes
              // the same sizing ladder one step down.
              final font = (primaryPadas
                      ? _planetFontFor([
                          for (final code in padas) [(text: code, ink: pdfInk)]
                        ])
                      : _planetFontFor(lines)) -
                  0.6;
              return pw.Positioned(
                left: col * cell,
                top: row * cell,
                child: pw.SizedBox(
                  width: cell,
                  height: cell,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(sign.abbrLabel(l10n),
                          style: const pw.TextStyle(
                              fontSize: _signFontSize - 1, color: pdfInkSoft)),
                      if (sign == trueAsc)
                        pw.Text(ascText,
                            style: const pw.TextStyle(
                                fontSize: _ascFontSize - 0.5,
                                color: pdfMaroon,
                                fontWeight: pw.FontWeight.bold)),
                      for (final line in lines)
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                          child: _planetRow(line, font),
                        ),
                      if (padas.isNotEmpty)
                        pw.Text(
                          padas.join(' '),
                          textAlign: pw.TextAlign.center,
                          style: primaryPadas
                              ? pw.TextStyle(fontSize: font, color: pdfInk)
                              : const pw.TextStyle(
                                  fontSize: _padaFontSize - 0.5,
                                  color: PdfColors.grey500),
                        ),
                    ],
                  ),
                ),
              );
            }(),
        ],
      ),
    ),
  );
}
