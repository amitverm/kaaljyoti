/// Shared building blocks used by module card/detail/pdf views.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/chart_style.dart';
import '../core/astro/ayanamsa.dart';
import '../core/astro/models.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';

/// Per-instance chart style: 'default' follows the kundli setting.
class ChartStyleOverride {
  const ChartStyleOverride(this.style, this.isOverridden);
  final ChartStyle style;
  final bool isOverridden;
}

ChartStyleOverride chartStyleFromConfig(
  Map<String, dynamic> config,
  ChartStyle kundliDefault,
) {
  final raw = config['style'] as String?;
  if (raw == null || raw == 'default') {
    return ChartStyleOverride(kundliDefault, false);
  }
  return ChartStyleOverride(
    ChartStyle.values
        .firstWhere((s) => s.name == raw, orElse: () => kundliDefault),
    true,
  );
}

/// Shared config choice for chart-rendering modules.
const chartStyleChoice = ModuleConfigChoice(
  key: 'style',
  label: 'Chart style',
  options: [
    ('default', 'Default'),
    ('north', 'North Indian'),
    ('south', 'South Indian'),
    ('circular', 'Circular'),
  ],
);

/// Shared header for chart-module detail views (Birth Chart,
/// Divisional): kundli name + ayanamsa caption and the chart-style
/// selector. Lives INSIDE the module's scroll view so it scrolls away
/// with the content instead of sticking under the app bar (it used to
/// be host chrome on the Module Detail screen). Persists the style via
/// [ModuleContext.onConfigChanged] — non-null on the detail screen.
class ChartDetailHeader extends StatelessWidget {
  const ChartDetailHeader({super.key, required this.ctx});

  final ModuleContext ctx;

  @override
  Widget build(BuildContext context) {
    // 'default' means "inherit the kundli style" (kept reachable so
    // inheritance is reversible). The selected chip therefore always
    // matches what the chart renders.
    final raw = (ctx.config['style'] as String?) ?? 'default';
    final onChanged = ctx.onConfigChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ctx.kundli.name} · ${Ayanamsa.byId(ctx.snapshot.ayanamsaId).name} '
          'ayanamsa',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (value, label) in chartStyleChoice.options)
              ChoiceChip(
                label: Text(label),
                selected: raw == value,
                labelStyle: TextStyle(
                    color: raw == value ? TEColors.paper : TEColors.ink),
                onSelected: onChanged == null
                    ? null
                    : (_) => onChanged({...ctx.config, 'style': value}),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// On-screen planetary positions table (reused by the Planetary
/// Positions module card, the Birth Chart detail view, etc.).
class PositionsTable extends StatelessWidget {
  const PositionsTable({
    super.key,
    required this.snapshot,
    this.compact = false,
    this.showAscendant = false,
  });

  final AstroSnapshot snapshot;
  final bool compact;

  /// When true, prepends an "Ascendant" row above the grahas — the
  /// Ascendant isn't a [Planet], so it's otherwise absent from this
  /// table even though it's central to reading the chart.
  final bool showAscendant;

  @override
  Widget build(BuildContext context) {
    final rows = snapshot.positions.values.toList();
    final ascNakshatra = Nakshatra.fromLongitude(snapshot.ascendant);
    final ascPada = Nakshatra.padaFromLongitude(snapshot.ascendant);
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(
          children: [
            _head('Graha'),
            _head('Sign'),
            _head('Degree'),
            _head('Nakshatra'),
          ],
        ),
        if (showAscendant)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _cell('Ascendant', color: TEColors.maroon, bold: true),
              _cell(snapshot.lagnaSign.western,
                  color: TEColors.maroon, bold: true),
              _cellMono(formatDegree(snapshot.ascendant), color: TEColors.maroon),
              _cell(
                '${ascNakshatra.displayName} · $ascPada',
                color: TEColors.maroon,
              ),
            ],
          ),
        for (final p in rows)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _cell('${p.planet.displayName}${p.isRetrograde ? ' ℞' : ''}',
                  color: planetInk(p.planet), bold: true),
              _cell(p.sign.western),
              _cellMono(formatDegree(p.longitude)),
              _cell('${p.nakshatra.displayName} · ${p.pada}'),
            ],
          ),
      ],
    );
  }

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(t,
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                color: TEColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );

  Widget _cell(String t, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );

  Widget _cellMono(String t, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(t, style: TETheme.mono(size: 12.5, color: color)),
      );
}

/// A [PositionsTable]-alike for raw transit data, which (deliberately,
/// per core/astro/transit.dart) has no ascendant/houses of its own — so
/// unlike [PositionsTable] there's no natal Ascendant row here. Shared by
/// the standalone Transit widget and the Today screen's "Transit now"
/// card so both render one consistent Graha/Sign/Degree/Nakshatra table.
class TransitPositionsTable extends StatelessWidget {
  const TransitPositionsTable({
    super.key,
    required this.positions,
    this.ascendant,
  });

  final Map<Planet, PlanetPosition> positions;

  /// Sidereal longitude of the rising lagna. When given (e.g. the Today
  /// screen, which computes an ascendant for its place), an "Ascendant"
  /// row is prepended — raw transit data alone has none, so the
  /// standalone Transit widget leaves this null.
  final double? ascendant;

  @override
  Widget build(BuildContext context) {
    final asc = ascendant;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(children: [
          _thead('Graha'),
          _thead('Sign'),
          _thead('Degree'),
          _thead('Nakshatra'),
        ]),
        if (asc != null)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _tcell('Ascendant', color: TEColors.maroon, bold: true),
              _tcell(ZodiacSign.fromLongitude(asc).western,
                  color: TEColors.maroon, bold: true),
              _tcellMono(formatDegree(asc), color: TEColors.maroon),
              _tcell(
                '${Nakshatra.fromLongitude(asc).displayName}'
                ' · ${Nakshatra.padaFromLongitude(asc)}',
                color: TEColors.maroon,
              ),
            ],
          ),
        for (final p in positions.values)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: TEColors.hairline)),
            ),
            children: [
              _tcell('${p.planet.displayName}${p.isRetrograde ? ' ℞' : ''}',
                  color: planetInk(p.planet), bold: true),
              _tcell(p.sign.western),
              _tcellMono(formatDegree(p.longitude)),
              _tcell('${p.nakshatra.displayName} · ${p.pada}'),
            ],
          ),
      ],
    );
  }

  static Widget _thead(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(t,
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                color: TEColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );

  static Widget _tcell(String t, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );

  static Widget _tcellMono(String t, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(t, style: TETheme.mono(size: 12.5, color: color)),
      );
}

// ---------------------------------------------------------------------------
// PDF helpers
// ---------------------------------------------------------------------------

const pdfInk = PdfColor.fromInt(0xFF221F18);
const pdfInkSoft = PdfColor.fromInt(0xFF56503F);
const pdfMaroon = PdfColor.fromInt(0xFF7A1F2B);
const pdfHairline = PdfColor.fromInt(0xFFEAE5D8);

pw.TextStyle pdfHeading() => pw.TextStyle(
    fontSize: 14, color: pdfMaroon, fontWeight: pw.FontWeight.bold);

/// Non-configurable open-source credit, shown once on the LAST page of
/// every exported PDF. The practitioner's brandingFooter may replace
/// the per-page footer text, but exported documents are the app's only
/// word-of-mouth channel — this microline keeps Kaal Jyoti discoverable
/// on charts handed to clients without competing with the
/// practitioner's own branding.
pw.Widget kjPdfCredit() => pw.Text(
      'Charts computed with Kaal Jyoti — free & open source · '
      'kaaljyoti.com',
      style: pw.TextStyle(fontSize: 6.5, color: pdfInkSoft),
    );

pw.TextStyle pdfBody({double size = 10}) =>
    pw.TextStyle(fontSize: size, color: pdfInk);

pw.TextStyle pdfLabel() => pw.TextStyle(
    fontSize: 8, color: pdfInkSoft, letterSpacing: 0.5);

/// Section header emitted as its own top-level widget so following
/// tables remain splittable across pages.
pw.Widget pdfSectionHeader(String title) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 14, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pdfHeading()),
          pw.SizedBox(height: 6),
          pw.Container(height: 0.8, color: pdfHairline),
        ],
      ),
    );

// ---------------------------------------------------------------------------
// Live / scrubbable transit time control
// ---------------------------------------------------------------------------

// Follows the user's app-wide date-format choice (lazy getter so a settings
// change is reflected on the next rebuild).
DateFormat get _transitClockFmt =>
    DateFormat('${TEDate.pref.datePattern}, h:mm a');

/// Shared "as of" time control for transit-based widgets (the Birth
/// Chart's transit overlay and the standalone Transit widget).
///
/// CONTROLLED widget: the scrubbed instant lives with the PARENT
/// (normally in `transitFixedTimeProvider`, so it survives navigation
/// and is shared between the dashboard card and the detail view) —
/// this widget only renders the clock/picker UI. [fixed] == null means
/// live; the parent owns the live tick that refreshes positions.
/// Tapping "Change date/time" reports a chosen instant via
/// [onChanged]; "Go live" reports null.
class TransitTimeBar extends StatelessWidget {
  const TransitTimeBar({
    super.key,
    required this.fixed,
    required this.onChanged,
  });

  /// The frozen instant, or null when tracking real time.
  final DateTime? fixed;

  /// Called with the picked instant, or null when "Go live" is tapped.
  final ValueChanged<DateTime?> onChanged;

  bool get _isLive => fixed == null;
  DateTime get _asOf => fixed ?? DateTime.now();

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_asOf),
    );
    if (time == null) return;
    onChanged(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isLive ? TEColors.transit.withValues(alpha: 0.12) : TEColors.paperAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TEColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLive) ...[
                Icon(Icons.circle, size: 8, color: TEColors.transit),
                const SizedBox(width: 6),
              ],
              Text(
                _isLive
                    ? 'Live · ${_transitClockFmt.format(_asOf)}'
                    : _transitClockFmt.format(_asOf),
                style: TETheme.mono(size: 11, color: TEColors.inkSoft),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => _pickDateTime(context),
          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
          label: const Text('Change date/time'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (!_isLive)
          TextButton.icon(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text('Go live'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

pw.Widget pdfPositionsTable(AstroSnapshot snapshot) => pw.TableHelper.fromTextArray(
      headers: ['Graha', 'Sign', 'Degree', 'Nakshatra', 'Pada'],
      data: [
        for (final p in snapshot.positions.values)
          [
            '${p.planet.displayName}${p.isRetrograde ? ' (R)' : ''}',
            p.sign.western,
            formatDegree(p.longitude),
            p.nakshatra.displayName,
            '${p.pada}',
          ],
      ],
      headerStyle: pw.TextStyle(
          fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
      cellStyle: pdfBody(size: 9.5),
      border: null,
      headerDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: pdfInk, width: 0.8)),
      ),
      rowDecoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
