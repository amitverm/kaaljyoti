/// Shared building blocks used by module card/detail/pdf views.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../pdf/pw.dart' as pw;
import 'package:printing/printing.dart';

import '../charts/chart_style.dart';
import '../core/astro/ayanamsa.dart';
import '../core/astro/models.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';

/// Yoga codes excluded from every DISPLAY surface (Yogas widget, its
/// PDF, dasha active-yoga chips) by editorial decision. Detection and
/// Mahakosh indexing are deliberately untouched: codes are stable index
/// identifiers (see core/astro/yogas.dart header) and already-contributed
/// charts keep them searchable — this only keeps them off screens.
const Set<String> kHiddenYogaCodes = {'kaal_sarp', 'kaal_sarp_partial'};

/// [yogas] minus [kHiddenYogaCodes] — use for anything user-facing.
List<DetectedYoga> visibleYogas(List<DetectedYoga> yogas) => [
      for (final y in yogas)
        if (!kHiddenYogaCodes.contains(y.code)) y
    ];

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
ModuleConfigChoice chartStyleChoice(AppLocalizations l10n) =>
    ModuleConfigChoice(
      key: 'style',
      label: l10n.labelChartStyle,
      options: [
        ('default', l10n.styleDefault),
        ('north', l10n.styleNorthIndian),
        ('south', l10n.styleSouthIndian),
        ('circular', l10n.styleCircular),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ctx.kundli.name} · '
          '${l10n.ayanamsaCaption(Ayanamsa.byId(ctx.snapshot.ayanamsaId).name)}',
          style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (value, label) in chartStyleChoice(l10n).options)
              ChoiceChip(
                label: Text(label),
                selected: raw == value,
                labelStyle: TextStyle(
                    color: raw == value ? KJColors.paper : KJColors.ink),
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
    final l10n = context.l10n;
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
            _head(l10n.labelGraha),
            _head(l10n.labelSign),
            _head(l10n.labelDegree),
            _head(l10n.labelNakshatra),
          ],
        ),
        if (showAscendant)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _cell(l10n.labelAscendant, color: KJColors.maroon, bold: true),
              _cell(snapshot.lagnaSign.label(l10n),
                  color: KJColors.maroon, bold: true),
              _cellMono(formatDegree(snapshot.ascendant),
                  color: KJColors.maroon),
              _cell(
                '${ascNakshatra.label(l10n)} · $ascPada',
                color: KJColors.maroon,
              ),
            ],
          ),
        for (final p in rows)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _cell('${p.planet.label(l10n)}${p.isRetrograde ? ' ℞' : ''}',
                  color: planetInk(p.planet), bold: true),
              _cell(p.sign.label(l10n)),
              _cellMono(formatDegree(p.longitude)),
              _cell('${p.nakshatra.label(l10n)} · ${p.pada}'),
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
                color: KJColors.inkSoft,
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
        child: Text(t, style: KJTheme.mono(size: 12.5, color: color)),
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
    final l10n = context.l10n;
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
          _thead(l10n.labelGraha),
          _thead(l10n.labelSign),
          _thead(l10n.labelDegree),
          _thead(l10n.labelNakshatra),
        ]),
        if (asc != null)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _tcell(l10n.labelAscendant, color: KJColors.maroon, bold: true),
              _tcell(ZodiacSign.fromLongitude(asc).label(l10n),
                  color: KJColors.maroon, bold: true),
              _tcellMono(formatDegree(asc), color: KJColors.maroon),
              _tcell(
                '${Nakshatra.fromLongitude(asc).label(l10n)}'
                ' · ${Nakshatra.padaFromLongitude(asc)}',
                color: KJColors.maroon,
              ),
            ],
          ),
        for (final p in positions.values)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KJColors.hairline)),
            ),
            children: [
              _tcell('${p.planet.label(l10n)}${p.isRetrograde ? ' ℞' : ''}',
                  color: planetInk(p.planet), bold: true),
              _tcell(p.sign.label(l10n)),
              _tcellMono(formatDegree(p.longitude)),
              _tcell('${p.nakshatra.label(l10n)} · ${p.pada}'),
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
                color: KJColors.inkSoft,
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
        child: Text(t, style: KJTheme.mono(size: 12.5, color: color)),
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
pw.Widget kjPdfCredit(AppLocalizations l10n) => pw.Text(
      l10n.pdfCredit,
      style: pw.TextStyle(fontSize: 6.5, color: pdfInkSoft),
    );

typedef _FontLoader = Future<pw.Font> Function();

/// Devanagari uses the bundled pre-shaped font, not a Noto fetch: its
/// PUA range carries the baked conjunct glyphs that
/// `devanagariVisualOrder` substitutes (see lib/pdf/devanagari.dart and
/// tool/gen_devanagari_font.py), so the two ship and version together.
/// Being an asset it also works offline on first export.
Future<pw.Font> kjDevanagariPdfFont() async => pw.Font.ttf(
    await rootBundle.load('assets/kj_devanagari_pdf.ttf'));

/// Unicode block → the Noto face covering it.
///
/// Keyed by SCRIPT rather than by language, and that is the whole point:
/// scripts are a closed set that changes on the scale of centuries,
/// while languages get added by contributors. A new `app_<code>.arb` in
/// any script below needs no Dart change at all — which is what lets the
/// README promise "one file, no code" (docs/adding-a-language.md).
///
/// Ranges are each script's base block; the matching Noto face also
/// covers that script's extended blocks, so one range per script is
/// enough. Latin, Greek and Cyrillic are absent deliberately: the IBM
/// Plex base font covers all three (checked against the actual TTF the
/// `printing` package fetches — 844 glyphs, incl. Greek and Cyrillic,
/// and no Devanagari), so an entry for them would never be reached.
const List<(int, int, _FontLoader)> _scriptFaces = [
  (0x0590, 0x05FF, PdfGoogleFonts.notoSansHebrewRegular),
  (0x0600, 0x06FF, PdfGoogleFonts.notoSansArabicRegular),
  (0x0780, 0x07BF, PdfGoogleFonts.notoSansThaanaRegular),
  (0x0900, 0x097F, kjDevanagariPdfFont),
  (0x0980, 0x09FF, PdfGoogleFonts.notoSansBengaliRegular),
  (0x0A00, 0x0A7F, PdfGoogleFonts.notoSansGurmukhiRegular),
  (0x0A80, 0x0AFF, PdfGoogleFonts.notoSansGujaratiRegular),
  (0x0B00, 0x0B7F, PdfGoogleFonts.notoSansOriyaRegular),
  (0x0B80, 0x0BFF, PdfGoogleFonts.notoSansTamilRegular),
  (0x0C00, 0x0C7F, PdfGoogleFonts.notoSansTeluguRegular),
  (0x0C80, 0x0CFF, PdfGoogleFonts.notoSansKannadaRegular),
  (0x0D00, 0x0D7F, PdfGoogleFonts.notoSansMalayalamRegular),
  (0x0D80, 0x0DFF, PdfGoogleFonts.notoSansSinhalaRegular),
  (0x0E00, 0x0E7F, PdfGoogleFonts.notoSansThaiRegular),
  (0x0E80, 0x0EFF, PdfGoogleFonts.notoSansLaoRegular),
  (0x1000, 0x109F, PdfGoogleFonts.notoSansMyanmarRegular),
  (0x10A0, 0x10FF, PdfGoogleFonts.notoSansGeorgianRegular),
  (0x1200, 0x137F, PdfGoogleFonts.notoSansEthiopicRegular),
  (0x1780, 0x17FF, PdfGoogleFonts.notoSansKhmerRegular),
  (0x0530, 0x058F, PdfGoogleFonts.notoSansArmenianRegular),
];

/// Faces needed to render [sample], embedded so the PDF is self-contained.
///
/// Driven by the TEXT rather than by the UI locale on purpose: a person's
/// name is user content and may be in any script regardless of the app's
/// language — a Devanagari name in an English export has to render, and
/// gating on locale would silently break exactly that.
///
/// Each face is fetched in its own try: a fallback that fails to download
/// must not cost us the Latin theme we already have (offline with only
/// the Latin fonts cached is the ordinary case for an English export).
///
/// `fontFallback` is one global list resolved per glyph by FIRST MATCH,
/// not by weight, so only regular faces are listed: bold Devanagari
/// renders at regular weight (a cosmetic loss), whereas listing a bold
/// face first would render *all* of that script bold.
Future<List<pw.Font>> _scriptFallback(String sample) async {
  final fonts = <pw.Font>[];
  for (final face in scriptFacesFor(sample)) {
    try {
      fonts.add(await face());
    } catch (_) {
      // Offline and not cached — that script degrades, the rest survive.
    }
  }
  return fonts;
}

/// Which faces [sample] needs, deduped and in [_scriptFaces] order.
/// Pure — decides without fetching anything, which is what makes the
/// decision testable offline.
@visibleForTesting
List<Future<pw.Font> Function()> scriptFacesFor(String sample) {
  final wanted = <_FontLoader>{};
  for (final rune in sample.runes) {
    // Latin-1 is the base font's own turf; skipping it keeps the common
    // all-English case from walking the table for every character.
    if (rune < 0x0100) continue;
    for (final (lo, hi, face) in _scriptFaces) {
      if (rune >= lo && rune <= hi) {
        wanted.add(face);
        break;
      }
    }
  }
  return wanted.toList();
}

/// The shared document theme: every `pw.Document` in the app should take
/// this. The built-in Helvetica is a non-Unicode Type1 font (console
/// warnings for — · etc.) with no coverage beyond Latin-1, and embedding
/// IBM Plex makes exports match the app's brand. Fonts are cached by
/// `printing` after the first fetch; offline on a fresh install this
/// returns null and the export falls back to the defaults.
///
/// [scriptSample] should contain any non-Latin text the document might
/// render — the caller's `l10n.languageEndonym` (which is by definition
/// written in the UI language's own script) plus whatever user-entered
/// names it prints. Only the scripts actually present are downloaded, so
/// an English export of an English chart still fetches nothing extra.
Future<pw.ThemeData?> pdfTheme({String scriptSample = ''}) async {
  try {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.iBMPlexSansRegular(),
      bold: await PdfGoogleFonts.iBMPlexSansBold(),
      italic: await PdfGoogleFonts.iBMPlexSansItalic(),
      fontFallback: await _scriptFallback(scriptSample),
    );
  } catch (_) {
    return null;
  }
}

pw.TextStyle pdfBody({double size = 10}) =>
    pw.TextStyle(fontSize: size, color: pdfInk);

pw.TextStyle pdfLabel() =>
    pw.TextStyle(fontSize: 8, color: pdfInkSoft, letterSpacing: 0.5);

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
    DateFormat('${KJDate.pref.datePattern}, h:mm a');

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
            color: _isLive
                ? KJColors.transit.withValues(alpha: 0.12)
                : KJColors.paperAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KJColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLive) ...[
                Icon(Icons.circle, size: 8, color: KJColors.transit),
                const SizedBox(width: 6),
              ],
              Text(
                _isLive
                    ? '${context.l10n.transitLive} · '
                        '${_transitClockFmt.format(_asOf)}'
                    : _transitClockFmt.format(_asOf),
                style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => _pickDateTime(context),
          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
          label: Text(context.l10n.transitChangeDateTime),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (!_isLive)
          TextButton.icon(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.bolt, size: 16),
            label: Text(context.l10n.transitGoLive),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

pw.Widget pdfPositionsTable(AstroSnapshot snapshot, AppLocalizations l10n) =>
    pw.TableHelper.fromTextArray(
      headers: [
        l10n.labelGraha,
        l10n.labelSign,
        l10n.labelDegree,
        l10n.labelNakshatra,
        l10n.labelPada,
      ],
      data: [
        for (final p in snapshot.positions.values)
          [
            '${p.planet.label(l10n)}${p.isRetrograde ? ' (R)' : ''}',
            p.sign.label(l10n),
            formatDegree(p.longitude),
            p.nakshatra.label(l10n),
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
