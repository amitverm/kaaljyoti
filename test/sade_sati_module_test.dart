// Sade Sati card-fix pure-function tests (Round 2, Task 8) — cycle
// merging, duration text, and Ashtakavarga severity tagging. No
// ephemeris/FFI: severity tests build a minimal fixed AstroSnapshot
// (only the fields Ashtakavarga actually reads: positions + ascendant).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/ashtakavarga.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/transit_scan.dart';
import 'package:kaaljyoti/modules/sade_sati_module.dart';

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
}
