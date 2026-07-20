/// Facade over `package:pdf/widgets.dart` for all PDF-building code.
///
/// Import THIS (as `pw`) instead of the raw package — a test enforces
/// it. It is a re-export with two shims, [Text] and [TableHelper],
/// that pass every string through [devanagariVisualOrder] so Hindi
/// renders with matras in the correct visual order (the `pdf` package
/// does no complex-script shaping; see devanagari.dart). Document
/// *metadata* (title, author) must NOT be shaped — PDF viewers shape
/// metadata themselves — which is why the transform lives here in the
/// widget layer and not on the l10n strings.
library;

import 'package:pdf/widgets.dart' as base;

import 'devanagari.dart';

export 'package:pdf/widgets.dart' hide Text, TableHelper;

final RegExp _devanagari = RegExp('[\u0900-\u097F\uE000-\uF8FF]');

/// Letter-spacing between a base and its combining matras tears
/// Devanagari apart (शृंखला → श ृंखला) — kicker/label styles drop it
/// when the string carries the script.
base.TextStyle? _deSpace(base.TextStyle? style, String text) =>
    _devanagari.hasMatch(text) ? _dropSpacing(style) : style;

base.TextStyle? _dropSpacing(base.TextStyle? style) =>
    style != null && style.letterSpacing != null
        ? style.copyWith(letterSpacing: 0)
        : style;

class Text extends base.Text {
  Text(
    String text, {
    base.TextStyle? style,
    base.TextAlign? textAlign,
    base.TextDirection? textDirection,
    bool? softWrap,
    bool tightBounds = false,
    double textScaleFactor = 1.0,
    int? maxLines,
    base.TextOverflow? overflow,
  }) : super(
          devanagariVisualOrder(text),
          style: _deSpace(style, text),
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: softWrap,
          tightBounds: tightBounds,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          overflow: overflow,
        );
}

abstract final class TableHelper {
  static dynamic _shapeCell(dynamic cell) =>
      cell is String ? devanagariVisualOrder(cell) : cell;

  static base.Table fromTextArray({
    base.Context? context,
    required List<List<dynamic>> data,
    base.EdgeInsetsGeometry cellPadding = const base.EdgeInsets.all(5),
    double cellHeight = 0,
    base.AlignmentGeometry cellAlignment = base.Alignment.topLeft,
    Map<int, base.AlignmentGeometry>? cellAlignments,
    base.TextStyle? cellStyle,
    base.TextStyle? oddCellStyle,
    base.OnCellFormat? cellFormat,
    base.OnCellDecoration? cellDecoration,
    int headerCount = 1,
    List<dynamic>? headers,
    base.EdgeInsetsGeometry? headerPadding,
    double? headerHeight,
    base.AlignmentGeometry headerAlignment = base.Alignment.center,
    Map<int, base.AlignmentGeometry>? headerAlignments,
    base.TextStyle? headerStyle,
    base.OnCellFormat? headerFormat,
    base.TableBorder? border = const base.TableBorder(
      left: base.BorderSide(),
      right: base.BorderSide(),
      top: base.BorderSide(),
      bottom: base.BorderSide(),
      horizontalInside: base.BorderSide(),
      verticalInside: base.BorderSide(),
    ),
    Map<int, base.TableColumnWidth>? columnWidths,
    base.TableColumnWidth defaultColumnWidth = const base.IntrinsicColumnWidth(),
    base.TableWidth tableWidth = base.TableWidth.max,
    base.BoxDecoration? headerDecoration,
    base.BoxDecoration? headerCellDecoration,
    base.BoxDecoration? rowDecoration,
    base.BoxDecoration? oddRowDecoration,
    base.TextDirection? headerDirection,
    base.TextDirection? tableDirection,
    base.OnCell? cellBuilder,
    base.OnCellTextStyle? textStyleBuilder,
  }) {
    final anyDeva = [
      ...?headers,
      for (final row in data) ...row,
    ].any((c) => c is String && _devanagari.hasMatch(c));
    return base.TableHelper.fromTextArray(
        context: context,
        data: [
          for (final row in data) [for (final cell in row) _shapeCell(cell)]
        ],
        cellPadding: cellPadding,
        cellHeight: cellHeight,
        cellAlignment: cellAlignment,
        cellAlignments: cellAlignments,
        cellStyle: anyDeva ? _dropSpacing(cellStyle) : cellStyle,
        oddCellStyle: anyDeva ? _dropSpacing(oddCellStyle) : oddCellStyle,
        cellFormat: cellFormat,
        cellDecoration: cellDecoration,
        headerCount: headerCount,
        headers:
            headers == null ? null : [for (final h in headers) _shapeCell(h)],
        headerPadding: headerPadding,
        headerHeight: headerHeight,
        headerAlignment: headerAlignment,
        headerAlignments: headerAlignments,
        headerStyle: anyDeva ? _dropSpacing(headerStyle) : headerStyle,
        headerFormat: headerFormat,
        border: border,
        columnWidths: columnWidths,
        defaultColumnWidth: defaultColumnWidth,
        tableWidth: tableWidth,
        headerDecoration: headerDecoration,
        headerCellDecoration: headerCellDecoration,
        rowDecoration: rowDecoration,
        oddRowDecoration: oddRowDecoration,
        headerDirection: headerDirection,
        tableDirection: tableDirection,
        cellBuilder: cellBuilder,
        textStyleBuilder: textStyleBuilder,
      );
  }
}
