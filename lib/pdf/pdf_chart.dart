/// Vector chart drawing for PDF export — North Indian and South
/// Indian styles rendered with the pdf package's canvas (the on-screen
/// Flutter painters can't be reused here). Circular falls back to
/// North for now.
///
/// This mirrors the on-screen chart's always-on fixes (explicit
/// Ascendant marker, no retrograde flag on the nodes) but not yet the
/// opt-in annotations (degrees, Jaimini karakas, dignity/combustion,
/// transit overlay) — those remain screen-only for now; bringing them
/// to PDF export is a natural follow-up once this vector layout has
/// more headroom for extra text per house.
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_style.dart';
import '../core/astro/models.dart';
import '../modules/common.dart';

pw.Widget pdfChart({
  required Map<ZodiacSign, List<Planet>> placements,
  required ZodiacSign lagna,
  required ChartStyle style,
  double size = 230,
  Map<Planet, bool> retrograde = const {},
  ZodiacSign? trueAscendantSign,
  double? ascendantDegree,
  Map<ZodiacSign, List<String>> padaLabels = const {},
}) {
  final trueAsc = trueAscendantSign ?? lagna;
  switch (style) {
    case ChartStyle.south:
      return _south(placements, lagna, size, retrograde, trueAsc,
          ascendantDegree, padaLabels);
    case ChartStyle.north:
    case ChartStyle.circular: // circular: North fallback in PDF (v1)
      return _north(placements, lagna, size, retrograde, trueAsc,
          ascendantDegree, padaLabels);
  }
}

/// The lunar nodes are retrograde by definition — never worth flagging
/// — so the marker is suppressed for them, matching the on-screen
/// painters. "(R)" (not ℞) matches [pdfPositionsTable]'s existing
/// convention, since core PDF fonts don't reliably carry the ℞ glyph.
String _planetLine(List<Planet> planets, Map<Planet, bool> retrograde) =>
    planets.map((p) {
      final isNode = p == Planet.rahu || p == Planet.ketu;
      final retro = !isNode && (retrograde[p] ?? false);
      return retro ? '${p.abbr}(R)' : p.abbr;
    }).join(' ');

String _ascText(double? ascendantDegree) => ascendantDegree != null
    ? 'Asc ${formatDegreeInSign(ascendantDegree)}'
    : 'Asc';

pw.Widget _houseLabel({
  required int signNumber,
  required List<Planet> planets,
  required Map<Planet, bool> retrograde,
  List<String> padas = const [],
  bool isAsc = false,
  String ascText = 'Asc',
  double width = 58,
}) =>
    pw.SizedBox(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$signNumber',
              style: pw.TextStyle(fontSize: 6.5, color: pdfInkSoft)),
          if (isAsc)
            pw.Text(ascText,
                style: pw.TextStyle(
                    fontSize: 6,
                    color: pdfMaroon,
                    fontWeight: pw.FontWeight.bold)),
          if (planets.isNotEmpty)
            pw.Text(
              _planetLine(planets, retrograde),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8, color: pdfInk),
            ),
          if (padas.isNotEmpty)
            pw.Text(
              padas.join(' '),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
            ),
        ],
      ),
    );

/// North Indian: fixed houses (1 = top-center diamond, counter-
/// clockwise); the sign NUMBER rotates with the lagna. An explicit
/// "Asc" label marks the true ascendant's house regardless of [lagna]
/// (which may be a "view from" anchor rather than the true ascendant).
pw.Widget _north(
  Map<ZodiacSign, List<Planet>> placements,
  ZodiacSign lagna,
  double s,
  Map<Planet, bool> retrograde,
  ZodiacSign trueAsc,
  double? ascendantDegree,
  Map<ZodiacSign, List<String>> padaLabels,
) {
  // House anchor centers as fractions of the square (top-left origin).
  const anchors = <int, (double, double)>{
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
  final houseOfTrueAsc = ((trueAsc.index - lagna.index + 12) % 12) + 1;
  final ascText = _ascText(ascendantDegree);

  return pw.SizedBox(
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
      child: pw.Stack(
        children: [
          for (final entry in anchors.entries)
            () {
              final house = entry.key;
              final (ax, ay) = entry.value;
              final sign =
                  ZodiacSign.values[(lagna.index + house - 1) % 12];
              return pw.Positioned(
                left: ax * s - 29,
                top: ay * s - 11,
                child: _houseLabel(
                  signNumber: sign.index + 1,
                  planets: placements[sign] ?? const [],
                  retrograde: retrograde,
                  padas: padaLabels[sign] ?? const [],
                  isAsc: house == houseOfTrueAsc,
                  ascText: ascText,
                ),
              );
            }(),
        ],
      ),
    ),
  );
}

/// South Indian: signs fixed in a 4×4 ring (Pisces top-left, Aries →
/// Gemini across the top, clockwise); lagna cell marked with a corner
/// stroke. An explicit "Asc" label marks the true ascendant's cell
/// regardless of [lagna].
pw.Widget _south(
  Map<ZodiacSign, List<Planet>> placements,
  ZodiacSign lagna,
  double s,
  Map<Planet, bool> retrograde,
  ZodiacSign trueAsc,
  double? ascendantDegree,
  Map<ZodiacSign, List<String>> padaLabels,
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
  final ascText = _ascText(ascendantDegree);

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
              return pw.Positioned(
                left: col * cell,
                top: row * cell,
                child: pw.SizedBox(
                  width: cell,
                  height: cell,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(sign.western.substring(0, 3),
                          style: pw.TextStyle(
                              fontSize: 5.5, color: pdfInkSoft)),
                      if (sign == trueAsc)
                        pw.Text(ascText,
                            style: pw.TextStyle(
                                fontSize: 5.5,
                                color: pdfMaroon,
                                fontWeight: pw.FontWeight.bold)),
                      if ((placements[sign] ?? const []).isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 2),
                          child: pw.Text(
                            _planetLine(placements[sign]!, retrograde),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 8, color: pdfInk),
                          ),
                        ),
                      if ((padaLabels[sign] ?? const []).isNotEmpty)
                        pw.Text(
                          padaLabels[sign]!.join(' '),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 6, color: PdfColors.grey500),
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
