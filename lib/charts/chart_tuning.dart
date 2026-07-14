/// Chart text settings — user-adjustable rendering knobs for the
/// chart painters, surfaced in Settings ▸ Chart text and stored
/// locally (SharedPreferences, loaded in main() before the first
/// frame).
///
/// Defaults were chosen empirically with the (since removed) live
/// tuning panel: base ×1.15, floor 70%, bold, degrees with minutes,
/// annotations ×0.85.
///
/// All three chart painters pass [chartTuning] as their
/// `CustomPainter.repaint` listenable, so a settings change repaints
/// every chart on screen — dashboard cards included — with no widget
/// rebuild plumbing.
library;

import 'package:flutter/material.dart';

class ChartTuning {
  const ChartTuning({
    this.baseScale = 1.15,
    this.minFontScale = 0.7,
    this.weight = FontWeight.w600,
    this.degreeMinutes = true,
    this.annotationScale = 0.85,
    this.signScale = 1.0,
    this.contentInflate = 1.0,
  });

  /// Multiplier on the planet base font (0.036·edge N/S, 0.032·edge
  /// circular).
  final double baseScale;

  /// Auto-shrink floor in [HouseLabelLayout]: crowded houses never
  /// render below this fraction of the base size.
  final double minFontScale;

  /// Weight of the planet abbreviation.
  final FontWeight weight;

  /// Degree precision on-chart: true = 23°41', false = 23°.
  final bool degreeMinutes;

  /// Size of degrees/glyphs relative to the abbreviation.
  final double annotationScale;

  /// Multiplier on sign numbers/names.
  final double signScale;

  /// North/South only: inflates each house's content rect — lets text
  /// use more of the triangle/cell at the risk of touching diagonals.
  final double contentInflate;

  static const defaults = ChartTuning();

  ChartTuning copyWith({
    double? baseScale,
    double? minFontScale,
    FontWeight? weight,
    bool? degreeMinutes,
    double? annotationScale,
    double? signScale,
    double? contentInflate,
  }) =>
      ChartTuning(
        baseScale: baseScale ?? this.baseScale,
        minFontScale: minFontScale ?? this.minFontScale,
        weight: weight ?? this.weight,
        degreeMinutes: degreeMinutes ?? this.degreeMinutes,
        annotationScale: annotationScale ?? this.annotationScale,
        signScale: signScale ?? this.signScale,
        contentInflate: contentInflate ?? this.contentInflate,
      );
}

/// The single live instance every painter reads. Settings writes to it
/// (and persists); main() seeds it from SharedPreferences at startup.
final ValueNotifier<ChartTuning> chartTuning =
    ValueNotifier(ChartTuning.defaults);
