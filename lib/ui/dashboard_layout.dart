/// Row packing for the dashboard board — the one place that decides how
/// span-aware cards fill a six-unit row.
///
/// Extracted from the dashboard grid so the offscreen screenshot view
/// ([DashboardCaptureView]) lays out byte-identically to what the user
/// sees. Two copies of this arithmetic would drift the moment a span is
/// added, and the drift would only ever show up in a shared image.
library;

import '../data/models.dart';

/// Row capacity a [span] consumes, in sixths of a row: full=6, half=3,
/// third=2. On a phone ([isWide] false) "third" widens to a half — three
/// columns of chart are unreadable below 720dp.
int spanUnits(CardSpan span, {required bool isWide}) => switch (span) {
      CardSpan.full => 6,
      CardSpan.half => 3,
      CardSpan.third => isWide ? 2 : 3,
    };

/// Greedily packs [placed] into rows of six units, preserving order.
/// A card that doesn't fit the current row starts a new one; the board's
/// order is the user's arrangement, so nothing is ever reordered to fill
/// a gap — an incomplete row simply stays incomplete.
List<List<PlacedWidget>> packDashboardRows(
  List<PlacedWidget> placed, {
  required bool isWide,
}) {
  final rows = <List<PlacedWidget>>[];
  var current = <PlacedWidget>[];
  var used = 0;
  for (final p in placed) {
    final u = spanUnits(p.span, isWide: isWide);
    if (used + u > 6 && current.isNotEmpty) {
      rows.add(current);
      current = [];
      used = 0;
    }
    current.add(p);
    used += u;
    if (used >= 6) {
      rows.add(current);
      current = [];
      used = 0;
    }
  }
  if (current.isNotEmpty) rows.add(current);
  return rows;
}

/// Units already consumed by a packed [row] — what's left over is the
/// empty remainder both hosts render (a drop target on the live board,
/// plain space in a screenshot).
int rowUnits(List<PlacedWidget> row, {required bool isWide}) =>
    row.fold<int>(0, (sum, p) => sum + spanUnits(p.span, isWide: isWide));
