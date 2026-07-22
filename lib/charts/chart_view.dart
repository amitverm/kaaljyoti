import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../l10n/astro_l10n.dart';
import 'chart_style.dart';
import 'circular_chart_painter.dart';
import 'north_chart_painter.dart';
import 'pinch_zoom.dart';
import 'planet_token.dart';
import 'south_chart_painter.dart';

/// Renders a rashi chart in the requested [ChartStyle], always square.
///
/// If [size] is given the chart is that exact edge length; otherwise it
/// fills the available width at a 1:1 aspect ratio.
///
/// [lagna] is the sign treated as "house 1" for layout purposes — the
/// Birth Chart widget's "view from" selector can pass a different sign
/// here (Moon, Sun, any graha, any house) to rotate the chart while
/// keeping sign-planet placements unchanged. The true rashi ascendant
/// is always marked separately via [trueAscendantSign]/[ascendantDegree]
/// regardless of [lagna], so the real Ascendant is never lost when
/// viewing the chart from somewhere else.
class ChartView extends StatelessWidget {
  const ChartView({
    super.key,
    required this.placements,
    required this.lagna,
    required this.style,
    this.retrograde = const {},
    this.size,
    this.trueAscendantSign,
    this.ascendantDegree,
    this.tokens = const {},
    this.showDegrees = false,
    this.showKarakas = false,
    this.transitPlacements,
    this.transitRetrograde = const {},
    this.padaLabels = const {},
    this.showNakshatras = true,
    this.directionalStack = true,
    this.ascendantRank,
    this.onSignSelect,
  });

  final Map<ZodiacSign, List<Planet>> placements;
  final ZodiacSign lagna;
  final ChartStyle style;
  final Map<Planet, bool> retrograde;
  final double? size;

  /// The real rashi ascendant sign, for the explicit "Asc" marker.
  /// Defaults to [lagna] when null (the common, non-rotated case).
  final ZodiacSign? trueAscendantSign;

  /// Exact ascendant longitude, shown next to the "Asc" marker when
  /// given.
  final double? ascendantDegree;

  /// Per-planet annotations (degree-in-sign, Jaimini karaka, dignity,
  /// combustion). Planets absent from this map render as a plain
  /// abbreviation, same as before this map existed.
  final Map<Planet, PlanetToken> tokens;
  final bool showDegrees;
  final bool showKarakas;

  /// Optional "current sky" overlay, shown as a smaller distinguished
  /// row under each house's natal planets.
  final Map<ZodiacSign, List<Planet>>? transitPlacements;
  final Map<Planet, bool> transitRetrograde;

  /// Arudha pada codes ('1P' … '12P') per sign — light-grey overlay,
  /// Parashar Light style. Empty map renders nothing.
  final Map<ZodiacSign, List<String>> padaLabels;

  /// Circular style only: outermost ring of the 27 nakshatras.
  /// Ignored by the North/South painters.
  final bool showNakshatras;

  /// Whether planet stacks follow the zodiacal progression spatially
  /// (see the painters' fields of the same name). Divisional (D2+)
  /// charts pass false — their boxes list planets in traditional order.
  final bool directionalStack;

  /// Planets preceding the ascendant in its house's zodiacal order —
  /// slots the North chart's "As" marker into the progression (see
  /// [ascendantRankIn]). Null pins As on top. North style only; the
  /// South/Circular As markers sit outside the planet stack.
  final int? ascendantRank;

  /// When set, double-tapping OR long-pressing a house/cell/sector
  /// reports the SIGN occupying it — the Birth Chart widget uses this
  /// to rotate its "view from" anchor without a settings list. (Card
  /// rearranging drags by the card header, so a body long-press is
  /// free for this.)
  final ValueChanged<ZodiacSign>? onSignSelect;

  ZodiacSign? _signAt(Size size, Offset pos) {
    switch (style) {
      case ChartStyle.north:
        final h = northHouseHit(size, pos);
        if (h == null) return null;
        return ZodiacSign.values[(lagna.index + h - 1) % 12];
      case ChartStyle.south:
        return southSignHit(size, pos);
      case ChartStyle.circular:
        final k = circularSectorHit(size, pos);
        if (k == null) return null;
        return ZodiacSign.values[(lagna.index + k) % 12];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final CustomPainter painter = switch (style) {
      ChartStyle.north => NorthChartPainter(
          l10n: l10n,
          placements: placements,
          lagna: lagna,
          retrograde: retrograde,
          trueAscendantSign: trueAscendantSign,
          ascendantDegree: ascendantDegree,
          tokens: tokens,
          showDegrees: showDegrees,
          showKarakas: showKarakas,
          transitPlacements: transitPlacements,
          transitRetrograde: transitRetrograde,
          padaLabels: padaLabels,
          directionalStack: directionalStack,
          ascendantRank: ascendantRank,
        ),
      ChartStyle.south => SouthChartPainter(
          l10n: l10n,
          placements: placements,
          lagna: lagna,
          retrograde: retrograde,
          trueAscendantSign: trueAscendantSign,
          ascendantDegree: ascendantDegree,
          tokens: tokens,
          showDegrees: showDegrees,
          showKarakas: showKarakas,
          transitPlacements: transitPlacements,
          transitRetrograde: transitRetrograde,
          padaLabels: padaLabels,
          directionalStack: directionalStack,
        ),
      ChartStyle.circular => CircularChartPainter(
          l10n: l10n,
          placements: placements,
          lagna: lagna,
          retrograde: retrograde,
          trueAscendantSign: trueAscendantSign,
          ascendantDegree: ascendantDegree,
          tokens: tokens,
          showDegrees: showDegrees,
          showKarakas: showKarakas,
          transitPlacements: transitPlacements,
          transitRetrograde: transitRetrograde,
          padaLabels: padaLabels,
          showNakshatras: showNakshatras,
          directionalStack: directionalStack,
        ),
    };

    Widget chart = CustomPaint(painter: painter);
    final onSelect = onSignSelect;
    if (onSelect != null) {
      chart = LayoutBuilder(
        builder: (context, constraints) {
          void report(Offset local) {
            final sign = _signAt(
              Size(constraints.maxWidth, constraints.maxHeight),
              local,
            );
            if (sign != null) onSelect(sign);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (d) => report(d.localPosition),
            // A no-op onDoubleTap keeps the recognizer in the arena so
            // onDoubleTapDown reliably fires before any parent tap.
            onDoubleTap: () {},
            onLongPressStart: (d) => report(d.localPosition),
            child: CustomPaint(painter: painter),
          );
        },
      );
    }
    // Every rashi/varga chart is pinch-zoomable, card and detail alike.
    chart = PinchZoom(child: chart);
    final side = size;
    return side != null
        ? SizedBox(width: side, height: side, child: chart)
        : AspectRatio(aspectRatio: 1, child: chart);
  }
}
