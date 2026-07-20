/// The PDF exporter picks its embedded fonts by looking at the text it
/// is about to render (see `scriptFacesFor`). These tests pin that
/// decision: it is what lets a new app_<code>.arb ship with no Dart
/// change, and it fails invisibly — a wrong answer here is a PDF full
/// of empty boxes, which nothing else in the suite would notice.
///
/// Only the pure decision is exercised; no font is fetched, so this
/// runs offline.
library;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/data/models.dart' show Kundli;
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/modules/common.dart';
import 'package:kaaljyoti/pdf/pdf_exporter.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';
import 'package:printing/printing.dart';

/// Minimal context for [pdfScriptSample] — only the user-content
/// fields it reads matter; the snapshot is inert filler.
ModuleContext _ctx({
  required String locale,
  required String name,
  required String place,
}) {
  final birth = BirthData(
    dateTimeUtc: DateTime.utc(1981, 4, 9),
    latitude: 28.6,
    longitude: 77.2,
    timezoneName: 'Asia/Kolkata',
    utcOffsetMinutes: 330,
  );
  final now = DateTime.utc(2026, 7, 20);
  return ModuleContext(
    kundli: Kundli(
      id: 'test',
      name: name,
      relationTag: 'Self',
      birthUtc: birth.dateTimeUtc,
      latitude: birth.latitude,
      longitude: birth.longitude,
      timezoneName: birth.timezoneName,
      utcOffsetMinutes: birth.utcOffsetMinutes,
      placeName: place,
      createdAt: now,
      updatedAt: now,
    ),
    snapshot: AstroSnapshot(
      birth: birth,
      ayanamsaId: 1,
      ayanamsaValue: 23.6,
      positions: const {},
      ascendant: 0,
      houseCusps: List<double>.generate(12, (i) => i * 30),
      panchang: const PanchangData(
        tithiIndex: 0,
        tithiName: 'Pratipada',
        paksha: 'Shukla',
        nakshatra: Nakshatra.ashwini,
        pada: 1,
        yogaIndex: 0,
        yogaName: 'Vishkambha',
        karanaIndex: 1,
        karanaName: 'Bava',
        varaIndex: 4,
        vara: 'Thursday',
      ),
      yogas: const [],
    ),
    chartStyle: ChartStyle.north,
    l10n: lookupAppLocalizations(Locale(locale)),
  );
}

void main() {
  group('scriptFacesFor', () {
    test('Latin text needs no fallback — the base font covers it', () {
      expect(scriptFacesFor('Amit Verma, New Delhi'), isEmpty);
      expect(scriptFacesFor('English'), isEmpty);
      // Latin-1 accents too (Español, Việt): still the base font.
      expect(scriptFacesFor('Español'), isEmpty);
    });

    test('Greek and Cyrillic need no fallback — IBM Plex ships them', () {
      // Verified against the actual TTF the printing package fetches:
      // 844 glyphs incl. Greek + Cyrillic, no Devanagari.
      expect(scriptFacesFor('ελληνικά'), isEmpty);
      expect(scriptFacesFor('Русский'), isEmpty);
    });

    test('an endonym selects its own script', () {
      expect(
          scriptFacesFor('हिन्दी'), [kjDevanagariPdfFont]);
      expect(scriptFacesFor('தமிழ்'), [PdfGoogleFonts.notoSansTamilRegular]);
      expect(scriptFacesFor('বাংলা'), [PdfGoogleFonts.notoSansBengaliRegular]);
      expect(scriptFacesFor('العربية'), [PdfGoogleFonts.notoSansArabicRegular]);
    });

    test('a non-Latin name in an English export still selects its face', () {
      // The regression this design exists to prevent: gating fonts on the
      // UI locale would leave this name as tofu.
      expect(scriptFacesFor('English' 'अमित वर्मा' 'New Delhi'),
          [kjDevanagariPdfFont]);
    });

    test('a mixed-script document selects every script present', () {
      final faces = scriptFacesFor('हिन्दी' 'Ramesh' 'சென்னை');
      expect(faces, hasLength(2));
      expect(faces, contains(kjDevanagariPdfFont));
      expect(faces, contains(PdfGoogleFonts.notoSansTamilRegular));
    });

    test('a repeated script is requested once', () {
      expect(scriptFacesFor('अअअ आआआ इइइ'), hasLength(1));
    });

    test('an uncovered script degrades quietly rather than throwing', () {
      // CJK is deliberately absent (font size). Must not throw — the
      // export proceeds and only those glyphs are lost.
      expect(scriptFacesFor('日本語'), isEmpty);
    });

    test('empty sample is safe', () {
      expect(scriptFacesFor(''), isEmpty);
    });
  });

  group('pdfScriptSample', () {
    const blocks = <PdfBlock>[];

    test('a Hindi branding line selects Devanagari in an English export', () {
      // The regression: branding was left out of the sample, so a
      // practitioner's Hindi credit printed as empty boxes on the cover
      // and every page footer of an otherwise-Latin report.
      final sample = pdfScriptSample(
        _ctx(locale: 'en', name: 'Amit Verma', place: 'Delhi, India'),
        const PdfExportOptions(
            blocks: blocks, brandingFooter: 'आचार्य अमित वर्मा'),
      );
      expect(scriptFacesFor(sample), [kjDevanagariPdfFont]);
    });

    test('covers every user-entered string that reaches a page', () {
      final sample = pdfScriptSample(
        _ctx(locale: 'en', name: 'नाम', place: 'स्थान'),
        const PdfExportOptions(blocks: blocks, brandingFooter: 'ब्रांड'),
      );
      for (final field in ['नाम', 'स्थान', 'ब्रांड']) {
        expect(sample, contains(field));
      }
    });

    test('an all-Latin export still needs no fallback', () {
      final sample = pdfScriptSample(
        _ctx(locale: 'en', name: 'Amit Verma', place: 'Delhi'),
        const PdfExportOptions(blocks: blocks, brandingFooter: 'Jyotish Kendra'),
      );
      expect(scriptFacesFor(sample), isEmpty);
    });

    test('no branding set is safe', () {
      final sample = pdfScriptSample(
        _ctx(locale: 'en', name: 'Amit', place: 'Delhi'),
        const PdfExportOptions(blocks: blocks),
      );
      expect(scriptFacesFor(sample), isEmpty);
    });
  });
}
