// Sade Sati card-fix pure-function tests (Round 2, Task 8) — cycle
// merging, duration text, and Ashtakavarga severity tagging. No
// ephemeris/FFI: severity tests build a minimal fixed AstroSnapshot
// (only the fields Ashtakavarga actually reads: positions + ascendant).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/ashtakavarga.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart' show SadeSatiPhaseKindL10n;
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/transit_scan.dart';
import 'package:kaaljyoti/modules/sade_sati_module.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

/// Some concrete Ashtakavarga for the severity fragment — the bindu
/// table itself is exercised by the severityOf group below; here it
/// only has to be a real one.
Ashtakavarga _fixtureAv() => Ashtakavarga(_fixtureSnapshot(
      {for (final p in ashtakavargaPlanets) p: 0.0, Planet.moon: 100.0},
      0.0,
    ));

SadeSatiPhase _phase(SadeSatiPhaseKind kind, ZodiacSign sign, DateTime start,
        DateTime end) =>
    SadeSatiPhase(kind: kind, sign: sign, start: start, end: end);

AstroSnapshot _fixtureSnapshot(
    Map<Planet, double> longitudes, double ascendant) {
  PlanetPosition pos(Planet p, double lon) =>
      PlanetPosition(planet: p, longitude: lon, latitude: 0, speed: 1);
  return AstroSnapshot(
    birth: BirthData(
      dateTimeUtc: DateTime.utc(2000, 1, 1),
      latitude: 0,
      longitude: 0,
      timezoneName: 'UTC',
      utcOffsetMinutes: 0,
    ),
    ayanamsaId: 1,
    ayanamsaValue: 24,
    positions: {for (final e in longitudes.entries) e.key: pos(e.key, e.value)},
    ascendant: ascendant,
    houseCusps: List<double>.generate(12, (i) => (ascendant + i * 30) % 360),
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
      varaIndex: 6,
      vara: 'Sunday',
    ),
    yogas: const [],
  );
}

void main() {
  group('mergeCycleByLabel', () {
    test('one interval per label -> passthrough, no re-entries', () {
      final cycle = [
        _phase(SadeSatiPhaseKind.rising, ZodiacSign.pisces, DateTime.utc(2020),
            DateTime.utc(2022)),
        _phase(SadeSatiPhaseKind.peak, ZodiacSign.aries, DateTime.utc(2022),
            DateTime.utc(2024, 6)),
        _phase(SadeSatiPhaseKind.setting, ZodiacSign.taurus,
            DateTime.utc(2024, 6), DateTime.utc(2027)),
      ];
      final merged = mergeCycleByLabel(cycle);
      expect(merged.length, 3);
      expect(merged.map((m) => m.kind), [
        SadeSatiPhaseKind.rising,
        SadeSatiPhaseKind.peak,
        SadeSatiPhaseKind.setting
      ]);
      for (final m in merged) {
        expect(m.hasReentries, false);
      }
      expect(merged[1].sign, ZodiacSign.aries);
    });

    test('retrograde re-entry (repeated label) merges into one segment', () {
      // Peak, then a brief retro dip back into Rising's sign, then Peak
      // again — 4 raw phases collapse to 3 merged segments. Durations
      // are CALENDAR spans (first entry until the next phase begins):
      // the retro dip counts inside Peak, the segments tile the whole
      // cycle, and retro lengthens a cycle — never shortens it.
      final cycle = [
        _phase(SadeSatiPhaseKind.rising, ZodiacSign.pisces, DateTime.utc(2020),
            DateTime.utc(2022)),
        _phase(SadeSatiPhaseKind.peak, ZodiacSign.aries, DateTime.utc(2022),
            DateTime.utc(2022, 6)),
        _phase(SadeSatiPhaseKind.rising, ZodiacSign.pisces,
            DateTime.utc(2022, 6), DateTime.utc(2022, 8)),
        _phase(SadeSatiPhaseKind.peak, ZodiacSign.aries, DateTime.utc(2022, 8),
            DateTime.utc(2024, 6)),
        _phase(SadeSatiPhaseKind.setting, ZodiacSign.taurus,
            DateTime.utc(2024, 6), DateTime.utc(2027)),
      ];
      final merged = mergeCycleByLabel(cycle);
      expect(merged.length, 3);
      final rising =
          merged.firstWhere((m) => m.kind == SadeSatiPhaseKind.rising);
      final peak = merged.firstWhere((m) => m.kind == SadeSatiPhaseKind.peak);
      expect(rising.hasReentries, true);
      expect(rising.subPhases.length, 2);
      expect(peak.hasReentries, true);
      // Calendar span: first Peak entry (2022) until Setting begins
      // (2024-06) — the 2-month retro dip is included, not subtracted.
      expect(
          peak.duration, DateTime.utc(2024, 6).difference(DateTime.utc(2022)));
      // And the three segments tile the cycle exactly.
      final total = merged.fold(Duration.zero, (a, m) => a + m.duration);
      expect(total, DateTime.utc(2027).difference(DateTime.utc(2020)));
    });
  });

  group('groupIntoCycles', () {
    test('a >2yr gap starts a new cycle; a short gap does not', () {
      final phases = [
        _phase(SadeSatiPhaseKind.rising, ZodiacSign.pisces, DateTime.utc(2020),
            DateTime.utc(2022)),
        // ~6 month gap (retro dip out of the zone) - same cycle.
        _phase(SadeSatiPhaseKind.peak, ZodiacSign.aries, DateTime.utc(2022, 7),
            DateTime.utc(2024)),
        // ~29 year gap - genuinely the next Sade Sati cycle.
        _phase(SadeSatiPhaseKind.rising, ZodiacSign.pisces, DateTime.utc(2053),
            DateTime.utc(2055)),
      ];
      final cycles = groupIntoCycles(phases);
      expect(cycles.length, 2);
      expect(cycles[0].length, 2);
      expect(cycles[1].length, 1);
    });
  });

  group('approxYears', () {
    // The module's formatters are locale-aware now; assert against the
    // English (template) localization.
    final l10n = lookupAppLocalizations(const Locale('en'));
    test('renders a half-year fraction with the ½ glyph', () {
      expect(
          approxYears(l10n, const Duration(days: 2739)), '≈7½ years'); // ~7.5y
    });
    test('renders a whole year with no fraction', () {
      expect(
          approxYears(l10n, const Duration(days: 2922)), '≈8 years'); // ~8.0y
    });
  });

  group('severityOf', () {
    test('bands: >=5 eased, 3-4 moderate, <=2 harsh', () {
      // Build a snapshot where every contributor sits at 0° Aries, so
      // Saturn's BAV is trivially the same fixed pattern for every
      // sign — we only need SOME concrete AstroSnapshot to drive
      // Ashtakavarga; the exact bindu table is exercised by whatever
      // real chart the app computes, not re-derived here.
      final snapshot = _fixtureSnapshot(
        {
          for (final p in ashtakavargaPlanets) p: 0.0,
        },
        0.0,
      );
      final av = Ashtakavarga(snapshot);
      final bav = av.bav(Planet.saturn);
      // Find one sign scoring >=5, one scoring 3-4, one scoring <=2,
      // if present, and check the band function's boundaries directly
      // (independent of which signs happen to hit which band for this
      // particular fixture).
      for (var i = 0; i < 12; i++) {
        final sev = severityOf(av, ZodiacSign.values[i]);
        expect(sev.bav, bav[i]);
        expect(sev.sav, av.sav()[i]);
        if (sev.bav >= 5) {
          expect(sev.band, 'eased');
        } else if (sev.bav >= 3) {
          expect(sev.band, 'moderate');
        } else {
          expect(sev.band, 'harsh');
        }
      }
    });

    test('severityTag formats as "Sa BAV x/8 · SAV y · band"', () {
      final snapshot = _fixtureSnapshot(
        {for (final p in ashtakavargaPlanets) p: 0.0},
        0.0,
      );
      final av = Ashtakavarga(snapshot);
      final sev = severityOf(av, ZodiacSign.aries);
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(severityTag(l10n, sev),
          'Sa BAV ${sev.bav}/8 · SAV ${sev.sav} · ${sev.band}');
    });
  });

  // --- Degree method (±45° of the natal Moon) -----------------------------

  final l10n = lookupAppLocalizations(const Locale('en'));
  const module = SadeSatiModule();

  SadeSatiDegreeWindow window(
    DateTime start,
    DateTime end, {
    List<DateTime> conjunctions = const [],
  }) =>
      SadeSatiDegreeWindow(start: start, end: end, conjunctions: conjunctions);

  group('method config', () {
    test('defaults to the classical sign method', () {
      final choice = module
          .configChoices(l10n)
          .firstWhere((c) => c.key == kSadeSatiMethodKey);
      // The declared default and the module's own parsing fallback are
      // the SAME answer to "what does an absent key mean?" — the
      // contract module_config_defaults_test.dart guards generically.
      expect(choice.effectiveDefault, 'signs');
      expect(choice.defaultValue, 'signs');
      expect(isDegreeMethod(const {}), false);
      expect(isDegreeMethod(const {'method': 'signs'}), false);
      expect(isDegreeMethod(const {'method': 'degrees'}), true);
      // An unconfigured card keeps its plain title.
      expect(module.configSummary(const {}, l10n), isNull);
      expect(module.configSummary(const {'method': 'degrees'}, l10n),
          l10n.ssMethodDegrees);
    });
  });

  group('separationText', () {
    test('renders past 30° instead of reducing into a sign', () {
      // formatDegree would print this as 14°30' — see the doc comment.
      expect(separationText(44.5), "44°30'");
      expect(separationText(-44.5), "44°30'");
      expect(separationText(0), "0°00'");
      expect(separationText(7 + 5 / 60), "7°05'");
    });
  });

  group('groupDegreeWindows', () {
    // The shapes below are the ones the real chart produces: a 1-day
    // retrograde sliver, a months-long gap, then the long window — all
    // one lap past the Moon, not three separate Sade Satis.
    test('a 1-day sliver, a gap and a 7y window are ONE passage', () {
      final passages = groupDegreeWindows([
        window(DateTime.utc(1990, 6, 15), DateTime.utc(1990, 6, 16)),
        window(DateTime.utc(1990, 12, 17), DateTime.utc(1997, 8, 1)),
      ]);
      expect(passages.length, 1);
      expect(passages.single.length, 2);
    });

    test('a second lap ~29 years later is its own passage', () {
      final passages = groupDegreeWindows([
        window(DateTime.utc(1990, 6, 15), DateTime.utc(1990, 6, 16)),
        window(DateTime.utc(1990, 12, 17), DateTime.utc(1997, 8, 1)),
        // The 2049 pair — again one lap, split by a retrograde dip.
        window(DateTime.utc(2049, 2, 1), DateTime.utc(2049, 5, 1)),
        window(DateTime.utc(2049, 11, 1), DateTime.utc(2056, 3, 1)),
      ]);
      expect(passages.length, 2);
      expect(passages[0].length, 2);
      expect(passages[1].length, 2);
      expect(passages[1].first.start, DateTime.utc(2049, 2, 1));
    });

    test('singletons pass through, and empty stays empty', () {
      final one = window(DateTime.utc(2020), DateTime.utc(2027));
      expect(groupDegreeWindows([one]), [
        [one]
      ]);
      expect(groupDegreeWindows(const []), isEmpty);
    });

    test('a gap just over two years splits, just under does not', () {
      final base = window(DateTime.utc(2020), DateTime.utc(2021));
      List<List<SadeSatiDegreeWindow>> after(Duration gap) =>
          groupDegreeWindows([
            base,
            window(base.end.add(gap),
                base.end.add(gap + const Duration(days: 90))),
          ]);
      expect(after(const Duration(days: 700)).length, 1);
      expect(after(const Duration(days: 760)).length, 2);
    });
  });

  group('degreeStatusLine', () {
    final now = DateTime.utc(2030, 6, 1);
    final fmt = DateFormat('d MMM yyyy');

    // The sign of the separation is the whole point of these three:
    // it carries what the classical method gets from its phase name.
    test('in Sade Sati, Saturn still approaching → "before"', () {
      final w = window(DateTime.utc(2029), DateTime.utc(2032));
      final line = degreeStatusLine(l10n, [w], -12.5, now);
      expect(line,
          l10n.ssDegStatusInBefore("12°30'", fmt.format(w.end.toLocal())));
      expect(
          line,
          'In Sade Sati — Saturn 12°30\' before the natal Moon '
          '· ends ${fmt.format(w.end.toLocal())}');
    });

    test('in Sade Sati, Saturn already crossed → "past"', () {
      final w = window(DateTime.utc(2029), DateTime.utc(2032));
      final line = degreeStatusLine(l10n, [w], 35.25, now);
      expect(
          line, l10n.ssDegStatusInPast("35°15'", fmt.format(w.end.toLocal())));
      expect(line, contains('past the natal Moon'));
      expect(line, isNot(contains('before')));
    });

    test('an exact conjunction reads as "past", not a fourth state', () {
      final w = window(DateTime.utc(2029), DateTime.utc(2032));
      expect(degreeStatusLine(l10n, [w], 0, now),
          l10n.ssDegStatusInPast("0°00'", fmt.format(w.end.toLocal())));
    });

    test('not in Sade Sati: the next entry date, no separation', () {
      final w = window(DateTime.utc(2040), DateTime.utc(2043));
      final line = degreeStatusLine(l10n, [w], 60, now);
      expect(line, l10n.ssDegStatusNext(fmt.format(w.start.toLocal())));
      // The separation is meaningless when Saturn is nowhere near.
      expect(line, isNot(contains('°')));
    });

    test('the BAV/SAV fragment is appended like the classical line', () {
      final w = window(DateTime.utc(2029), DateTime.utc(2032));
      final sev =
          severityTag(l10n, severityOf(_fixtureAv(), ZodiacSign.cancer));
      final line = degreeStatusLine(l10n, [w], 12.5, now, severity: sev);
      expect(line, endsWith(' · $sev'));
      expect(
          line,
          startsWith(l10n.ssDegStatusInPast(
              "12°30'", DateFormat('d MMM yyyy').format(w.end.toLocal()))));
      // Omitted → the line is unchanged.
      expect(degreeStatusLine(l10n, [w], 12.5, now), isNot(contains(sev)));
    });

    test('not in Sade Sati with nothing ahead', () {
      final past = window(DateTime.utc(2000), DateTime.utc(2003));
      expect(degreeStatusLine(l10n, [past], 60, now), l10n.ssDegStatusNone);
      expect(degreeStatusLine(l10n, const [], 60, now), l10n.ssDegStatusNone);
    });
  });

  group('SadeSatiDegreeView', () {
    final av = _fixtureAv();
    // Saturn transits Cancer at 112.5° — the sign whose bindus the
    // status line reports.
    final severity = severityTag(l10n, severityOf(av, ZodiacSign.cancer));
    final birth = DateTime.utc(2000, 1, 1);
    final now = DateTime.utc(2030, 6, 1);
    final fmt = DateFormat('d MMM yyyy');
    // Passage 1 is split by a retrograde dip out of the arc; passage 2
    // is the next lap, ~29 years on.
    final windows = [
      window(DateTime.utc(2029, 3, 1), DateTime.utc(2029, 6, 15)),
      window(DateTime.utc(2029, 12, 17), DateTime.utc(2031, 9, 1),
          conjunctions: [DateTime.utc(2030, 4, 10)]),
      window(DateTime.utc(2058, 5, 1), DateTime.utc(2061, 2, 1)),
    ];

    Future<String> pump(WidgetTester tester, {required bool detailed}) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: SadeSatiDegreeView(
                windows: windows,
                moonLon: 100,
                saturnLon: 112.5, // 12°30' past the Moon → inside the arc
                ashtakavarga: _fixtureAv(),
                birth: birth,
                now: now,
                detailed: detailed,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .join(' | ');
    }

    testWidgets('the detail view lists every window with its conjunctions',
        (tester) async {
      final text = await pump(tester, detailed: true);
      expect(text, contains(l10n.ssDegCaption));
      // Saturn is 12°30' PAST the Moon here, and the status line says so
      // in the same shape the classical card uses.
      expect(
        text,
        contains(l10n.ssDegStatusInPast(
            "12°30'", fmt.format(windows[1].end.toLocal()))),
      );
      // Parity with the classical status line's trailing BAV/SAV.
      expect(text, contains(severity));
      // Organised into passages, labelled with the same string the
      // classical body uses for its cycles.
      expect(text, contains(l10n.ssCycleHeading('1')));
      expect(text, contains(l10n.ssCycleHeading('2')));
      // The retrograde gap inside passage 1 is a sub-row, not a
      // top-level window.
      expect(
        text,
        contains(l10n.ssDegOutOfArc(
          fmt.format(windows[0].end.toLocal()),
          fmt.format(windows[1].start.toLocal()),
          '6m',
        )),
      );
      for (final w in windows) {
        expect(text, contains(fmt.format(w.start.toLocal())));
        expect(text, contains(fmt.format(w.end.toLocal())));
      }
      expect(
        text,
        contains(l10n.ssDegConjunctionRow(
            fmt.format(windows[1].conjunctions.single.toLocal()))),
      );
      // Sign-defined vocabulary must not leak into degree mode.
      for (final word in [
        l10n.ssPhaseRising,
        l10n.ssPhasePeak,
        l10n.ssPhaseSetting,
        l10n.ssPhaseSmallPanoti,
      ]) {
        expect(text, isNot(contains(word)));
      }
    });

    testWidgets('the bar carries a legend for its four shades', (tester) async {
      // The user had to ASK what the shades meant; both the card and
      // the detail view now say so under the bar.
      for (final detailed in [true, false]) {
        final text = await pump(tester, detailed: detailed);
        for (final label in [
          l10n.ssDegLegendApproaching,
          l10n.ssDegLegendConjunction,
          l10n.ssDegLegendSeparating,
          l10n.ssDegLegendOutOfArc,
        ]) {
          expect(text, contains(label), reason: 'detailed=$detailed');
        }
      }
    });

    testWidgets('the card shows only the window in progress', (tester) async {
      final text = await pump(tester, detailed: false);
      // The bar for the passage in progress spans its first entry to
      // its last exit; the next lap is not on the card.
      expect(text, contains(fmt.format(windows.first.start.toLocal())));
      expect(text, contains(fmt.format(windows[1].end.toLocal())));
      expect(text, isNot(contains(fmt.format(windows[2].start.toLocal()))));
      // No cycle sections on the card — that is the detail view's job.
      expect(text, isNot(contains(l10n.ssCycleHeading('1'))));
    });
  });

  // --- Detail view: the method selector -----------------------------------
  //
  // The detail screen owns a working config copy and hands modules an
  // onConfigChanged that persists back to the originating card. These
  // pump the real detailView with both bodies' data injected, so no
  // ephemeris is involved (see currentSaturnLongitudeProvider).

  group('detail method selector', () {
    const kundliId = 'k1';
    // Both bodies read the real clock for their "now", so the fixtures
    // are anchored to it — a hard-coded year would quietly stop
    // straddling today and turn these into no-ops.
    final today = DateTime.now().toUtc();

    final phases = [
      _phase(SadeSatiPhaseKind.rising, ZodiacSign.pisces,
          DateTime.utc(today.year - 1, 3), DateTime.utc(today.year + 1, 3)),
      _phase(SadeSatiPhaseKind.peak, ZodiacSign.aries,
          DateTime.utc(today.year + 1, 3), DateTime.utc(today.year + 3, 3)),
      _phase(SadeSatiPhaseKind.setting, ZodiacSign.taurus,
          DateTime.utc(today.year + 3, 3), DateTime.utc(today.year + 6, 3)),
    ];
    final degreeWindows = [
      window(DateTime.utc(today.year - 1, 3), DateTime.utc(today.year + 2, 9),
          conjunctions: [DateTime.utc(today.year, 4, 10)]),
    ];

    ModuleContext ctx({
      Map<String, dynamic> config = const {},
      void Function(Map<String, dynamic>)? onConfigChanged,
    }) =>
        ModuleContext(
          kundli: Kundli(
            id: kundliId,
            name: 'Test',
            relationTag: 'Self',
            birthUtc: DateTime.utc(2000, 1, 1),
            latitude: 18.52,
            longitude: 73.86,
            timezoneName: 'Asia/Kolkata',
            utcOffsetMinutes: 330,
            placeName: 'Pune',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          snapshot: _fixtureSnapshot(
            {for (final p in ashtakavargaPlanets) p: 0.0, Planet.moon: 100.0},
            0.0,
          ),
          chartStyle: ChartStyle.north,
          config: config,
          onConfigChanged: onConfigChanged,
        );

    Future<void> pumpDetail(WidgetTester tester, ModuleContext c) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sadeSatiPhasesProvider.overrideWith((ref, id) async => phases),
          sadeSatiDegreeWindowsProvider
              .overrideWith((ref, id) async => degreeWindows),
          // 12°30' past the natal Moon at 100°.
          currentSaturnLongitudeProvider
              .overrideWith((ref, ayanamsaId) => 112.5),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: Builder(
                  builder: (context) =>
                      const SadeSatiModule().detailView(context, c)),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    String rendered(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join(' | ');

    testWidgets('both chips are offered, classical selected by default',
        (tester) async {
      await pumpDetail(tester, ctx());
      expect(
          find.widgetWithText(ChoiceChip, l10n.ssMethodSigns), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, l10n.ssMethodDegrees),
          findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, l10n.ssMethodSigns));
      expect(chip.selected, true);
      // The classical body is what renders.
      expect(rendered(tester), contains(l10n.ssPhaseRising));
    });

    testWidgets('the classical bar carries a Rising/Peak/Setting legend',
        (tester) async {
      await pumpDetail(tester, ctx());
      final text = rendered(tester);
      for (final k in [
        SadeSatiPhaseKind.rising,
        SadeSatiPhaseKind.peak,
        SadeSatiPhaseKind.setting,
      ]) {
        expect(text, contains(k.label(l10n)));
      }
    });

    testWidgets('tapping the degree chip switches the body and persists',
        (tester) async {
      Map<String, dynamic>? persisted;
      await pumpDetail(tester, ctx(onConfigChanged: (c) => persisted = c));
      expect(rendered(tester), contains(l10n.ssPhasePeak));

      await tester.tap(find.widgetWithText(ChoiceChip, l10n.ssMethodDegrees));
      await tester.pumpAndSettle();

      final text = rendered(tester);
      // The degree body's status line and caption are up.
      expect(text, contains(l10n.ssDegCaption));
      expect(
        text,
        contains(l10n.ssDegStatusInPast(
            "12°30'",
            DateFormat('d MMM yyyy')
                .format(degreeWindows.single.end.toLocal()))),
      );
      // Sign-defined vocabulary is gone with the body that owned it.
      for (final word in [
        l10n.ssPhaseRising,
        l10n.ssPhasePeak,
        l10n.ssPhaseSetting,
      ]) {
        expect(text, isNot(contains(word)));
      }
      // And the choice went back to the originating card.
      expect(persisted, {'method': 'degrees'});
    });

    testWidgets('opened without a card, the selector still switches locally',
        (tester) async {
      // onConfigChanged null — Mahakosh/compare open modules with no
      // dashboard row behind them; the toggle must not become inert.
      await pumpDetail(tester, ctx());
      await tester.tap(find.widgetWithText(ChoiceChip, l10n.ssMethodDegrees));
      await tester.pumpAndSettle();
      expect(rendered(tester), contains(l10n.ssDegCaption));
      expect(rendered(tester), isNot(contains(l10n.ssPhaseRising)));
    });

    testWidgets('a card already configured for degrees opens in degree mode',
        (tester) async {
      await pumpDetail(tester, ctx(config: const {'method': 'degrees'}));
      final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, l10n.ssMethodDegrees));
      expect(chip.selected, true);
      expect(rendered(tester), contains(l10n.ssDegCaption));
    });
  });
}
