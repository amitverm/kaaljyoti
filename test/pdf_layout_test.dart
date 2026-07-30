/// The exported document's LAYOUT, not its numbers.
///
/// Two user-visible defects motivate this file, and neither would fail
/// any other test in the suite:
///
///  * the birth-chart PDF ignored the widget's display settings — a
///    chart with "Planet degrees" on printed without a single degree;
///  * sections split badly — a "Navamsa · D9" header stranded at the
///    foot of one page with its chart floating, untitled, onto the next.
///
/// Both are caught by composing a realistic multi-section export and
/// asserting on the widget tree the modules hand back, plus a whole-
/// document render (`save()`), which is what actually exercises the
/// chart painter's geometry and the table splitter.
///
/// The chart deliberately carries a STELLIUM so the crowded-house path
/// (more planets than fit as stacked degree lines) is exercised too.
///
/// Everything here is synthetic and offline: no ephemeris call, no font
/// download, no simulator. The sample document is also written to disk
/// so the layout can be eyeballed — see [_samplePath].
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/charts/planet_token.dart';
import 'package:kaaljyoti/core/astro/dignity.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/data/models.dart' show Kundli;
import 'package:pdf/pdf.dart';
import 'package:kaaljyoti/core/theme/theme.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/modules/birth_chart_module.dart';
import 'package:kaaljyoti/modules/chalit_module.dart';
import 'package:kaaljyoti/modules/common.dart';
import 'package:kaaljyoti/modules/jaimini_aspect_module.dart';
import 'package:kaaljyoti/modules/jaimini_pada_module.dart';
import 'package:kaaljyoti/modules/dasha_module.dart';
import 'package:kaaljyoti/modules/divisional_module.dart';
import 'package:kaaljyoti/modules/panchang_module.dart';
import 'package:kaaljyoti/modules/planetary_positions_module.dart';
import 'package:kaaljyoti/pdf/pdf_chart.dart';
import 'package:kaaljyoti/pdf/pdf_exporter.dart';
import 'package:kaaljyoti/pdf/pw.dart' as pw;
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

/// Where the rendered sample lands for visual inspection. Outside the
/// repo on purpose — it is a build artefact, not a fixture.
const _samplePath =
    '/private/tmp/claude-503/-Users-mac-Desktop-work-TheThirdEyeAstro-apps/'
    '3c7465ed-e95d-4509-b7bc-4487d9929204/scratchpad/phaseB_sample.pdf';

PlanetPosition _at(Planet p, double longitude, {double speed = 1}) =>
    PlanetPosition(planet: p, longitude: longitude, latitude: 0, speed: speed);

/// A chart with FIVE grahas packed into Aries (0–30°) — one more than
/// [pdfChart] will stack as individual degree lines, so the fallback
/// fires — plus a retrograde, an exalted, a debilitated and a combust
/// planet so every annotation channel is populated.
///
/// Longitudes are chosen, not computed: this test is about layout, and
/// a hand-built sky keeps it deterministic and ephemeris-free.
AstroSnapshot _stelliumSnapshot() {
  final birth = BirthData(
    dateTimeUtc: DateTime.utc(1981, 4, 9, 3, 45),
    latitude: 28.6139,
    longitude: 77.2090,
    timezoneName: 'Asia/Kolkata',
    utcOffsetMinutes: 330,
    placeName: 'New Delhi, India',
  );
  final positions = <Planet, PlanetPosition>{
    // Aries stellium — Sun exalted here, Mercury/Venus combust beside it.
    Planet.sun: _at(Planet.sun, 3.62),
    Planet.mercury: _at(Planet.mercury, 8.95, speed: -0.2),
    Planet.venus: _at(Planet.venus, 12.40),
    Planet.mars: _at(Planet.mars, 21.17),
    Planet.jupiter: _at(Planet.jupiter, 27.83),
    // Elsewhere.
    Planet.moon: _at(Planet.moon, 132.55),
    Planet.saturn: _at(Planet.saturn, 188.30), // exalted in Libra
    Planet.rahu: _at(Planet.rahu, 251.02, speed: -0.05),
    Planet.ketu: _at(Planet.ketu, 71.02, speed: -0.05),
  };
  return AstroSnapshot(
    birth: birth,
    ayanamsaId: 1,
    ayanamsaValue: 23.6,
    positions: positions,
    ascendant: 5.4, // Aries lagna, so the stellium sits in house 1
    // Deliberately UNEVEN (opposite cusps still 180° apart, as any real
    // ring is): with equal 30° cusps a chalit chart is indistinguishable
    // from the rashi one, and the whole point of chalit is that a graha
    // can sit in a different bhava than its sign — Jupiter at 27°50'
    // Aries lands in bhava 2 here.
    houseCusps: const [
      5.4, 38, 72, 95.4, 122, 152, //
      185.4, 218, 252, 275.4, 302, 332,
    ],
    panchang: const PanchangData(
      tithiIndex: 4,
      tithiName: 'Panchami',
      paksha: 'Shukla',
      nakshatra: Nakshatra.magha,
      pada: 2,
      yogaIndex: 6,
      yogaName: 'Sukarman',
      karanaIndex: 3,
      karanaName: 'Taitila',
      varaIndex: 4,
      vara: 'Thursday',
    ),
    yogas: const [],
  );
}

ModuleContext _ctx(AstroSnapshot snapshot) {
  final now = DateTime.utc(2026, 7, 29);
  return ModuleContext(
    kundli: Kundli(
      id: 'layout-test',
      name: 'Amit Verma',
      relationTag: 'Self',
      birthUtc: snapshot.birth.dateTimeUtc,
      latitude: snapshot.birth.latitude,
      longitude: snapshot.birth.longitude,
      timezoneName: snapshot.birth.timezoneName,
      utcOffsetMinutes: snapshot.birth.utcOffsetMinutes,
      placeName: snapshot.birth.placeName,
      createdAt: now,
      updatedAt: now,
    ),
    snapshot: snapshot,
    chartStyle: ChartStyle.north,
    l10n: lookupAppLocalizations(const Locale('en')),
  );
}

/// The blocks a practitioner would realistically tick: cover page plus
/// a chart section, a table-heavy section, a second chart and a short
/// key/value section.
const _blocks = <PdfBlock>[
  // Degrees ON: the annotated path, one graha per line.
  (
    widgetId: 'birth_chart',
    config: {'degrees': 'on', 'padas': 'on', 'karakas': 'on', 'extras': 'on'},
  ),
  // Degrees OFF on a second instance: the JOINED path, several grahas
  // sharing one line, each in its own ink. Both must render.
  (widgetId: 'birth_chart', config: {'degrees': 'off', 'padas': 'off'}),
  (widgetId: 'planetary_positions', config: {}),
  (widgetId: 'dasha', config: {'system': 'vimshottari'}),
  (widgetId: 'divisional', config: {'varga': 'd9'}),
  // Cusp-bounded houses: the chart is built from per-house data, not a
  // sign rotation.
  (
    widgetId: 'chalit_chart',
    // Placidus rides the snapshot's own cusps; Sripati (the real
    // default) would ask the ephemeris, which this host test has no
    // business booting — the chart code under test is identical.
    config: {'system': 'placidus', 'degrees': 'on', 'cusp_degrees': 'on'},
  ),
  // Padas as the chart's subject, not an overlay.
  (widgetId: 'jaimini_pada', config: {}),
  (widgetId: 'jaimini_aspect', config: {}),
  (widgetId: 'panchang', config: {}),
];

/// Every string a `pw.Text` in these widgets' subtrees renders.
///
/// A pdf document is bytes, not a queryable tree, so what gets asserted
/// is the widget tree the modules hand the exporter — the layer the
/// config actually has to reach. `Container` and `SizedBox` build their
/// children lazily from a layout `Context`, so their public `child` is
/// followed directly instead.
List<String> _texts(List<pw.Widget> widgets) =>
    [for (final t in _inkedTexts(widgets)) t.text];

/// Every `pw.Text` these widgets contain, paired with the ink it draws
/// in — the chart's whole point here is that a graha keeps its colour.
List<({String text, PdfColor? ink})> _inkedTexts(List<pw.Widget> widgets) {
  final out = <({String text, PdfColor? ink})>[];
  void walk(Object? w) {
    switch (w) {
      // RichText, not Text: the facade's shaping `Text` and the raw
      // package `Text` that TableHelper builds its cells from are
      // different classes, and both extend RichText.
      case pw.RichText():
        final span = w.text;
        out.add((
          text: span.toPlainText(),
          ink: span is pw.TextSpan ? span.style?.color : null,
        ));
      // Table is neither a Multi- nor a SingleChildWidget: its rows are
      // TableRows, which are not Widgets at all.
      case pw.Table():
        for (final row in w.children) {
          row.children.forEach(walk);
        }
      case pw.Container():
        walk(w.child);
      case pw.SizedBox():
        walk(w.child);
      case pw.MultiChildWidget():
        w.children.forEach(walk);
      case pw.SingleChildWidget():
        walk(w.child);
    }
  }

  widgets.forEach(walk);
  return out;
}

/// Every `pw.Text`, with the ink AND size it draws at.
List<({String text, PdfColor? ink, double? size})> _styledTexts(
    List<pw.Widget> widgets) {
  final out = <({String text, PdfColor? ink, double? size})>[];
  void walk(Object? w) {
    switch (w) {
      case pw.RichText():
        final span = w.text;
        out.add((
          text: span.toPlainText(),
          ink: span is pw.TextSpan ? span.style?.color : null,
          size: span is pw.TextSpan ? span.style?.fontSize : null,
        ));
      case pw.Table():
        for (final row in w.children) {
          row.children.forEach(walk);
        }
      case pw.Container():
        walk(w.child);
      case pw.SizedBox():
        walk(w.child);
      case pw.MultiChildWidget():
        w.children.forEach(walk);
      case pw.SingleChildWidget():
        walk(w.child);
    }
  }

  widgets.forEach(walk);
  return out;
}

/// The `repeat` flag of every table row these widgets contain, table by
/// table. A leading `true` means that row was emitted into the header
/// slot — styled as a column heading and reprinted on every page it
/// spills onto.
List<List<bool>> _tableRowRepeats(List<pw.Widget> widgets) {
  final out = <List<bool>>[];
  void walk(Object? w) {
    switch (w) {
      case pw.Table():
        out.add([for (final row in w.children) row.repeat]);
        for (final row in w.children) {
          row.children.forEach(walk);
        }
      case pw.Container():
        walk(w.child);
      case pw.SizedBox():
        walk(w.child);
      case pw.MultiChildWidget():
        w.children.forEach(walk);
      case pw.SingleChildWidget():
        walk(w.child);
    }
  }

  widgets.forEach(walk);
  return out;
}

/// The pdf package reports a glyph it cannot draw by `print`ing
/// "Unable to find a font to draw …" and emitting a `.notdef` box (see
/// its text.dart). Capturing prints is therefore the direct way to
/// assert a document has no tofu in it.
Future<List<String>> _printsDuring(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification:
        ZoneSpecification(print: (_, __, ___, line) => lines.add(line)),
  );
  return lines;
}

const _missingGlyph = 'Unable to find a font to draw';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chart annotations follow the widget config', () {
    final snapshot = _stelliumSnapshot();

    test('degrees ON puts a degree on every annotated planet line', () {
      final on = const BirthChartModule()
          .pdfView(_ctx(snapshot).withConfig({'degrees': 'on'}));
      // Saturn is alone in Libra, so it keeps its own stacked line.
      expect(_texts(on).where((t) => t.contains('°')), isNotEmpty,
          reason: 'the chart printed no degrees at all');
      expect(
          _texts(on).any((t) => RegExp(r"^Sa \d+°\d+'$").hasMatch(t)), isTrue,
          reason: 'expected a "Sa 8°18\'" style line for the lone planet');
    });

    test('degrees OFF keeps the joined abbreviation line', () {
      final off = const BirthChartModule().pdfView(_ctx(snapshot));
      expect(_texts(off).any((t) => t.contains('°') && t.startsWith('Sa')),
          isFalse);
      expect(_texts(off), contains('Sa'));
    });

    test('karakas and dignity/combustion reach the chart when on', () {
      final texts = _texts(const BirthChartModule().pdfView(
          _ctx(snapshot).withConfig({'karakas': 'on', 'extras': 'on'})));
      // Saturn is alone in Libra and exalted there, and sixth by
      // degree-in-sign among the seven — so its line carries both the
      // dignity marker and its Gnatikaraka code.
      expect(texts, contains('Sa Ex GK'));
      // The Atmakaraka (Jupiter, highest degree) is inside the Aries
      // stellium, so it is deliberately NOT annotated — the crowded
      // house falls back to bare abbreviations.
      expect(texts.any((t) => t.contains('AK')), isFalse);
    });

    test('a crowded house drops back to joined abbreviations', () {
      // Five grahas share Aries. Stacking five annotated lines would
      // overflow the diamond, so that house prints them as bare
      // abbreviations — while the uncrowded houses keep their degrees.
      // Joined mode is one chip PER GRAHA (each needs its own ink), so
      // the five arrive as five separate strings.
      final texts = _texts(const BirthChartModule()
          .pdfView(_ctx(snapshot).withConfig({'degrees': 'on'})));
      for (final abbr in ['Su', 'Me(R)', 'Ve', 'Ma', 'Ju']) {
        expect(texts, contains(abbr));
      }
      expect(
          texts.where((t) => t.startsWith('Ju')).single, isNot(contains('°')));
      // …but Saturn, alone in Libra, still gets its degree.
      expect(texts.any((t) => t.startsWith('Sa') && t.contains('°')), isTrue);
    });

    test('a varga chart is not annotated with natal degrees', () {
      // The D9 has no 'degrees' toggle: a natal degree-in-sign says
      // nothing true about a divisional placement.
      final texts = _texts(const DivisionalChartModule()
          .pdfView(_ctx(snapshot).withConfig({'varga': 'd9'})));
      expect(
          texts.any((t) => RegExp(r'^[A-Z][a-z] \d+°').hasMatch(t)), isFalse);
    });
  });

  group('pdfAnnotationsFor', () {
    test('spells dignity in core-font-safe letters, never arrows', () {
      final ann = pdfAnnotationsFor({
        Planet.saturn: const PlanetToken(
          planet: Planet.saturn,
          dignity: PlanetDignity.exalted,
          degreeInSign: 8.3,
          karaka: 'AK',
        ),
        Planet.mars: const PlanetToken(
          planet: Planet.mars,
          dignity: PlanetDignity.debilitated,
          combust: true,
        ),
      });
      expect(ann.degrees[Planet.saturn], "8°18'");
      expect(ann.tags[Planet.saturn], 'Ex AK');
      expect(ann.tags[Planet.mars], 'De c');
      // ↑ ↓ ○ are absent from IBM Plex and the built-in PDF faces.
      for (final tag in ann.tags.values) {
        expect(tag, isNot(matches(r'[↑↓○]')));
      }
    });

    test('an unannotated token contributes nothing', () {
      final ann = pdfAnnotationsFor(
          {Planet.moon: const PlanetToken(planet: Planet.moon)});
      expect(ann.degrees, isEmpty);
      expect(ann.tags, isEmpty);
    });
  });

  group('graha colours', () {
    final snapshot = _stelliumSnapshot();
    final classic = KJPalette.classic.planets;

    test('pdfPlanetInk mirrors the classic palette', () {
      expect(
          pdfPlanetInk(Planet.mars), PdfColor.fromInt(classic.mars.toARGB32()));
      expect(pdfPlanetInk(Planet.saturn),
          PdfColor.fromInt(classic.saturn.toARGB32()));
      // The Moon has no colour of its own on paper — white is
      // illegible — so it takes the palette's ink, as on screen.
      expect(classic.moon, isNull);
      expect(pdfPlanetInk(Planet.moon), pdfInk);
    });

    test('it stays pinned to classic when the app is in dark mode', () {
      // A printed chart handed to a client must not change colour
      // because the practitioner flipped the app to dark: those inks
      // are tuned to glow on a dark ground and would print washed out.
      final before = pdfPlanetInk(Planet.saturn);
      KJColors.current = KJPalette.dark;
      addTearDown(() => KJColors.current = KJPalette.classic);
      expect(pdfPlanetInk(Planet.saturn), before);
      expect(pdfPlanetInk(Planet.saturn),
          isNot(PdfColor.fromInt(KJPalette.dark.planets.saturn.toARGB32())));
    });

    test('a rashi takes its lord ink, as signInk does on screen', () {
      expect(pdfSignInk(ZodiacSign.scorpio), pdfPlanetInk(Planet.mars));
      expect(pdfSignInk(ZodiacSign.aquarius), pdfPlanetInk(Planet.saturn));
    });

    test('joined mode gives each graha its own ink', () {
      // The crowded Aries house, degrees off: five chips, five colours.
      final inked =
          _inkedTexts(const BirthChartModule().pdfView(_ctx(snapshot)));
      expect(inked.firstWhere((t) => t.text == 'Su').ink,
          pdfPlanetInk(Planet.sun));
      expect(inked.firstWhere((t) => t.text == 'Me(R)').ink,
          pdfPlanetInk(Planet.mercury));
      expect(inked.firstWhere((t) => t.text == 'Ju').ink,
          pdfPlanetInk(Planet.jupiter));
    });

    test('an annotated line takes its own graha ink, degree and all', () {
      final inked = _inkedTexts(const BirthChartModule()
          .pdfView(_ctx(snapshot).withConfig({'degrees': 'on'})));
      final saturn = inked.firstWhere((t) => t.text.startsWith('Sa '));
      expect(saturn.text, contains('°'));
      expect(saturn.ink, pdfPlanetInk(Planet.saturn));
    });

    test('house numbers, the Asc marker and padas keep their own ink', () {
      final inked = _inkedTexts(const BirthChartModule()
          .pdfView(_ctx(snapshot).withConfig({'padas': 'on'})));
      // Sign numbers stay soft ink, never a planet colour.
      expect(inked.firstWhere((t) => t.text == '7').ink, pdfInkSoft);
      expect(inked.firstWhere((t) => t.text.startsWith('Asc')).ink, pdfMaroon);
      expect(inked.firstWhere((t) => t.text == '1P').ink, PdfColors.grey500);
    });

    test('the positions table tints the graha column only', () {
      final inked =
          _inkedTexts(const PlanetaryPositionsModule().pdfView(_ctx(snapshot)));
      expect(inked.firstWhere((t) => t.text.startsWith('Mars')).ink,
          pdfPlanetInk(Planet.mars));
      // The sign cell stays plain body ink, matching the screen table.
      expect(inked.firstWhere((t) => t.text == 'Libra').ink, pdfInk);
    });

    test('the dasha lord columns are tinted without losing the header', () {
      final blocks = const DashaModule()
          .pdfView(_ctx(snapshot).withConfig({'system': 'vimshottari'}));
      final inked = _inkedTexts(blocks);
      expect(
          inked.any((t) =>
              t.text.contains('Ketu') && t.ink == pdfPlanetInk(Planet.ketu)),
          isTrue);
      // The tint rides textStyleBuilder, so every table still repeats
      // its heading when it splits.
      for (final table in _tableRowRepeats(blocks)) {
        expect(table.first, isTrue);
      }
    });
  });

  group('chart legibility', () {
    final snapshot = _stelliumSnapshot();

    test('an uncrowded house gets bigger glyphs than a stellium', () {
      final styled = _styledTexts(const BirthChartModule()
          .pdfView(_ctx(snapshot).withConfig({'degrees': 'on'})));
      // Saturn is alone in Libra; the five-graha Aries house is not.
      final lone = styled.firstWhere((t) => t.text.startsWith('Sa ')).size!;
      final crowded = styled.firstWhere((t) => t.text == 'Ju').size!;
      expect(lone, greaterThan(crowded));
      // …and the roomy case is meaningfully larger than the old flat 8pt.
      expect(lone, greaterThanOrEqualTo(9));
    });

    test('padas render as the subject in the Arudha chart', () {
      final styled =
          _styledTexts(const JaiminiPadaModule().pdfView(_ctx(snapshot)));
      final pada = styled.firstWhere((t) => t.text == '12P');
      expect(pada.ink, pdfInk, reason: 'the subject should not be grey');
      expect(pada.size, greaterThanOrEqualTo(9));
    });

    test('a pada OVERLAY on someone else\'s chart stays recessive', () {
      final styled = _styledTexts(const BirthChartModule()
          .pdfView(_ctx(snapshot).withConfig({'padas': 'on'})));
      final pada = styled.firstWhere((t) => t.text == '12P');
      expect(pada.ink, PdfColors.grey500);
      expect(pada.size, lessThan(8));
    });
  });

  group('cusp-bounded (chalit) chart', () {
    final ctx = _ctx(_stelliumSnapshot())
        .withConfig({'system': 'placidus', 'degrees': 'on'});

    test('places grahas by BHAVA, not by rashi', () {
      final texts = _texts(const ChalitModule().pdfView(ctx));
      // Jupiter at 27°50' Aries is in rashi-house 1 but bhava 2 under
      // this cusp ring — the whole reason chalit needs its own chart.
      expect(texts.any((t) => t.startsWith('Ju 27°')), isTrue);
      expect(ctx.snapshot.houseOfPlanet(Planet.jupiter), 1);
    });

    test('the chart is glued to the header and the table still flows', () {
      final blocks = const ChalitModule().pdfView(ctx);
      // [0] = header+chart glued, then the 12-row table, note and gap.
      expect(blocks.length, greaterThan(1));
      expect(_tableRowRepeats(blocks).single.first, isTrue);
    });
  });

  group('jaimini aspects', () {
    test('composes the pair into one cell with a covered arrow', () {
      final texts = _texts(
          const JaiminiAspectModule().pdfView(_ctx(_stelliumSnapshot())));
      final pair = texts.firstWhere((t) => t.contains('\u2194'));
      // "Sun (Aries) <-> Moon (Leo)": both grahas AND both signs, so the
      // relationship is legible without a legend.
      expect(pair, matches(r'^\w+ \(\w+\) \u2194 \w+ \(\w+\)$'));
      // U+27F7, the screen's long arrow, is NOT in the embedded faces.
      expect(texts.any((t) => t.contains('\u27F7')), isFalse);
      // The blurb frames it as sign-based, so no angle is implied.
      expect(texts.any((t) => t.toLowerCase().contains('sign-based')), isTrue);
    });
  });

  group('section gluing', () {
    final ctx = _ctx(_stelliumSnapshot());

    test('a chart section is ONE top-level widget, header and all', () {
      // This is the orphaned-header fix: MultiPage only breaks BETWEEN
      // top-level widgets, so header + lagna line + chart being a
      // single widget is what makes them travel together.
      final blocks = const BirthChartModule().pdfView(ctx);
      expect(blocks, hasLength(1));
      final texts = _texts(blocks);
      expect(texts.first, isNotEmpty); // the section header
    });

    test('a table section keeps its table splittable', () {
      // Header glued, table separate — a 12-row dasha table must still
      // be allowed to break across pages.
      final blocks = const DivisionalChartModule()
          .pdfView(ctx.withConfig({'varga': 'd9'}));
      expect(blocks, hasLength(1)); // chart-only module: all glued
    });
  });

  group('label/value tables', () {
    test('a headerless table does not promote its first reading', () {
      // TableHelper counts header and data rows on one running index,
      // so a headerless table with the default headerCount:1 styles its
      // first DATA row as a column heading. Panchang printed
      // "Tithi | Shukla Panchami" that way — a reading dressed up as a
      // header, and repeated on every page it spilled onto.
      final repeats = _tableRowRepeats(
          const PanchangModule().pdfView(_ctx(_stelliumSnapshot())));
      expect(repeats, hasLength(1));
      expect(repeats.single, everyElement(isFalse));
    });

    test('a columnar table still repeats its heading across pages', () {
      final repeats = _tableRowRepeats(
          const PlanetaryPositionsModule().pdfView(_ctx(_stelliumSnapshot())));
      expect(repeats.single.first, isTrue);
      expect(repeats.single.skip(1), everyElement(isFalse));
    });
  });

  group('glyph coverage', () {
    // The section header carries an em dash ("Dasha Periods — …"), which
    // Helvetica — the built-in non-Unicode Type1 face — cannot draw. It
    // printed as a .notdef box because PdfGoogleFonts silently returns
    // Helvetica when a face fails to download, so the theme's BOLD face
    // degraded while its regular face stayed IBM Plex. The brand faces
    // are bundled assets now, which is what makes this deterministic.
    test('the em dash in a section header really is U+2014', () {
      final texts = _texts(
          const DashaModule().pdfView(_ctx(_stelliumSnapshot()).withConfig(
        {'system': 'vimshottari'},
      )));
      expect(texts.any((t) => t.contains('—')), isTrue,
          reason: 'this test is pointless if no header has an em dash');
    });

    test('a full export draws every glyph it asks for', () async {
      final logs = await _printsDuring(() async {
        final doc = await PdfExporter().buildDocument(
          _ctx(_stelliumSnapshot()),
          const PdfExportOptions(blocks: _blocks, coverPage: true),
        );
        await doc.save();
      });
      expect(logs.where((l) => l.contains(_missingGlyph)), isEmpty,
          reason: 'the document contains a .notdef box');
    });

    test('...and the check has teeth', () async {
      // Negative control: the same em-dash header on a Helvetica-only
      // theme must trip the detector. Without this, a renamed warning
      // would make the assertion above pass silently forever.
      final logs = await _printsDuring(() async {
        final doc = pw.Document(
          theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
        );
        doc.addPage(pw.Page(build: (_) => pw.Text('Dasha Periods — X')));
        await doc.save();
      });
      expect(logs.where((l) => l.contains(_missingGlyph)), isNotEmpty);
    });
  });

  group('whole document', () {
    test('renders, paginates sanely, and lands on disk for inspection',
        () async {
      final ctx = _ctx(_stelliumSnapshot());
      final doc = await PdfExporter().buildDocument(
        ctx,
        const PdfExportOptions(blocks: _blocks, coverPage: true),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);

      // Cover + the sections above. Fewer than three would mean a
      // section vanished; more than a dozen would mean the layout blew
      // up (a chart overflowing its page, or a table exploding).
      final pages = doc.document.pdfPageList.pages.length;
      expect(pages, inInclusiveRange(3, 18));

      final out = File(_samplePath);
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes);
      expect(out.lengthSync(), greaterThan(0));
    });

    test('the South Indian style renders too', () async {
      final ctx = _ctx(_stelliumSnapshot());
      final doc = await PdfExporter().buildDocument(
        ModuleContext(
          kundli: ctx.kundli,
          snapshot: ctx.snapshot,
          chartStyle: ChartStyle.south,
          l10n: ctx.l10n,
        ),
        const PdfExportOptions(blocks: _blocks, coverPage: false),
      );
      expect(await doc.save(), isNotEmpty);
    });
  });
}
