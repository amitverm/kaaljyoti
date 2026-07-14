/// Builds the precomputed searchable index rows for a chart at
/// contribution time (brief §2.6) — planetary sign/house/nakshatra
/// placements + detected yogas — so search never recalculates charts.
library;

import '../core/astro/models.dart';

class ChartIndexRow {
  const ChartIndexRow({
    required this.planet,
    required this.sign,
    required this.house,
    required this.nakshatra,
    required this.pada,
  });

  final String planet; // Planet.name
  final int sign; // 0–11
  final int house; // 1–12 (whole-sign from lagna)
  final int nakshatra; // 0–26
  final int pada; // 1–4

  Map<String, dynamic> toJson() => {
        'planet': planet,
        'sign': sign,
        'house': house,
        'nakshatra': nakshatra,
        'pada': pada,
      };
}

List<ChartIndexRow> buildChartIndex(AstroSnapshot snapshot) => [
      for (final pos in snapshot.positions.values)
        ChartIndexRow(
          planet: pos.planet.name,
          sign: pos.sign.index,
          house: snapshot.houseOf(pos.longitude),
          nakshatra: pos.nakshatra.index,
          pada: pos.pada,
        ),
    ];

List<String> buildYogaCodes(AstroSnapshot snapshot) =>
    // Distinct codes only: a single chart can legitimately detect the same
    // yoga code more than once (e.g. multiple raj_yoga / dhana_yoga links),
    // but chart_yogas is keyed on (chart_id, yoga_code), so duplicates would
    // violate the primary key on contribute.
    snapshot.yogas.map((y) => y.code).toSet().toList();

/// Anonymized chart payload stored in mahakosh_charts.chart_payload —
/// raw longitudes + ascendant only. No name, no exact birth data.
Map<String, dynamic> buildAnonymizedPayload(AstroSnapshot snapshot) => {
      'ayanamsa_id': snapshot.ayanamsaId,
      'ascendant': snapshot.ascendant,
      'positions': {
        for (final e in snapshot.positions.entries)
          e.key.name: {
            'lon': e.value.longitude,
            'speed': e.value.speed,
          },
      },
    };
