// Kundli Compare engine tests (spec §6) — synthetic charts built from
// raw longitudes (à la jaimini_chara_test), a faked transit-position
// source, and a fixed `now`, so no real ephemeris/FFI is touched.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/compare.dart';
import 'package:kaaljyoti/core/astro/dasha/dasha.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/core/astro/transit_scan.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/mahakosh/compare_subject.dart';
import 'package:kaaljyoti/mahakosh/models.dart';

// A deterministic "today" for rule 7.
final _now = DateTime.utc(2010, 1, 1);

/// Every graha, so a synthetic chart is complete. Callers override a few.
const _baseLongs = <Planet, double>{
  Planet.sun: 95, // Cancer
  Planet.moon: 5, // Aries / Ashwini
  Planet.mars: 155, // Virgo
  Planet.mercury: 245, // Sagittarius
  Planet.jupiter: 275, // Capricorn
  Planet.venus: 200, // Libra
  Planet.saturn: 350, // Pisces
  Planet.rahu: 65, // Gemini
  Planet.ketu: 245, // Sagittarius
};

AstroSnapshot _snapshot({
  required double ascendant,
  required Map<Planet, double> longs,
  DateTime? birthUtc,
}) =>
    AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: birthUtc ?? DateTime.utc(1980, 1, 1, 6, 0),
        latitude: 28.6,
        longitude: 77.2,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 24.1,
      positions: {
        for (final e in longs.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: ascendant,
      houseCusps: List.filled(12, 0.0),
      panchang: computePanchang(
          sunLongitude: 10, moonLongitude: 100, localDateTime: DateTime(1980)),
      yogas: const [],
    );

CompareChart _chart(double ascendant, Map<Planet, double> longs) =>
    CompareChart(ascendant: ascendant, longitudes: longs);

/// Full (dasha-capable) entry from raw longitudes.
CompareEntry _entry(
  String id, {
  required double ascendant,
  required Map<Planet, double> longs,
  List<CompareEvent> events = const [],
  DateTime? birthUtc,
  bool withSnapshot = true,
  int? birthYear,
}) =>
    CompareEntry(
      id: id,
      displayName: id,
      chart: _chart(ascendant, longs),
      events: events,
      snapshot: withSnapshot
          ? _snapshot(ascendant: ascendant, longs: longs, birthUtc: birthUtc)
          : null,
      birthYear: birthYear ?? (birthUtc ?? DateTime.utc(1980)).year,
    );

/// A fake sky: fixed positions regardless of date.
PositionsAt _fixedSky(Map<Planet, double> lons) => (_) => lons;

/// A fake sky that varies by year.
PositionsAt _skyByYear(Map<int, Map<Planet, double>> byYear,
        {Map<Planet, double> fallback = const {}}) =>
    (utc) => byYear[utc.year] ?? fallback;

CompareEvent _marriage(
        {DateTime? date, String precision = 'exact', int? age}) =>
    CompareEvent(
        category: 'marriage', date: date, precision: precision, ageYears: age);

CompareFinding? _find(List<CompareFinding> fs, String key) =>
    fs.where((f) => f.key == key).firstOrNull;

void main() {
  group('planted-overlap pair (§6)', () {
    // A and B share Moon nakshatra (Bharani), Saturn sign (Pisces), and a
    // marriage under Venus MD with Saturn transiting the 8th from Moon —
    // but differ in lagna, so no lagna finding.
    final longs = {..._baseLongs, Planet.moon: 14.0, Planet.saturn: 340.0};
    final marriage = _marriage(date: DateTime(1998, 6, 15));

    final findings = computeCompareFindings(
      subjects: [
        _entry('A', ascendant: 15, longs: longs, events: [marriage]), // Aries
        _entry('B', ascendant: 45, longs: longs, events: [marriage]), // Taurus
      ],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      // Saturn in Scorpio (220°) → 8th from an Aries Moon.
      transitPositions: _fixedSky({
        ..._baseLongs,
        Planet.saturn: 220.0,
      }),
    );

    test('shared Moon nakshatra found', () {
      expect(_find(findings, 'moon-nak:bharani')?.strength, 2);
    });
    test('shared Saturn sign found', () {
      expect(_find(findings, 'graha-sign:saturn:pisces')?.strength, 2);
    });
    test('marriage under Venus MD found', () {
      expect(_find(findings, 'event-md:marriage:venus')?.strength, 2);
    });
    test('Saturn transit 8th-from-Moon found', () {
      expect(
          _find(findings, 'event-transit:marriage:saturn:moon:8')?.strength, 2);
    });
    test('no shared lagna sign (differ)', () {
      expect(findings.where((f) => f.key.startsWith('lagna-sign')), isEmpty);
    });
  });

  test('no-overlap pair → only neutral rows (§6)', () {
    // B is A mirrored: planets opposite (+180), lagna +150 — so every
    // sign, house, Moon/lagna factor differs, and a shared career event
    // has different MD lords and mismatched transits.
    final bLongs = {
      for (final e in _baseLongs.entries) e.key: (e.value + 180) % 360,
    };
    final career = CompareEvent(
        category: 'career', date: DateTime(1983, 1, 1), precision: 'year');

    final findings = computeCompareFindings(
      subjects: [
        _entry('A', ascendant: 15, longs: _baseLongs, events: [career]),
        _entry('B', ascendant: 165, longs: bLongs, events: [career]),
      ],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      transitPositions: _fixedSky(_baseLongs),
    );

    // Nothing in the static groups.
    expect(
        findings.where((f) => f.group != 'events'), isEmpty,
        reason: findings.map((f) => f.key).join(', '));
    // Exactly one events finding: the neutral career row.
    final events = findings.where((f) => f.group == 'events').toList();
    expect(events.length, 1);
    expect(events.single.key, 'event-neutral:career');
    expect(events.single.strength, 2);
  });

  group('fast-mover noise guard (§6)', () {
    Map<Planet, double> longs() => {..._baseLongs, Planet.moon: 5.0}; // Aries
    List<CompareFinding> run(List<CompareEntry> subjects, PositionsAt sky) =>
        computeCompareFindings(
          subjects: subjects,
          dashaSystem: DashaSystem.vimshottari,
          now: _now,
          transitPositions: sky,
        );

    test('2-of-3 Venus match emits nothing', () {
      final findings = run([
        _entry('A',
            ascendant: 15,
            longs: longs(),
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
        _entry('B',
            ascendant: 15,
            longs: longs(),
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
        _entry('C',
            ascendant: 15,
            longs: longs(),
            withSnapshot: false,
            events: [_marriage(date: DateTime(1999, 6, 15))]),
      ],
          _skyByYear({
            1998: {..._baseLongs, Planet.venus: 45.0}, // Taurus → 2nd
            1999: {..._baseLongs, Planet.venus: 75.0}, // Gemini → 3rd
          }));
      expect(
          findings.where(
              (f) => f.key.startsWith('event-transit:marriage:venus')),
          isEmpty);
    });

    test('3-of-3 exact Venus match emits', () {
      final findings = run([
        for (final id in ['A', 'B', 'C'])
          _entry(id,
              ascendant: 15,
              longs: longs(),
              withSnapshot: false,
              events: [_marriage(date: DateTime(1998, 6, 15))]),
      ],
          _fixedSky({..._baseLongs, Planet.venus: 45.0})); // Taurus → 2nd
      expect(_find(findings, 'event-transit:marriage:venus:moon:2')?.strength,
          3);
    });
  });

  test('age-precision event → approximate MD, no AD (§6)', () {
    final longs = {..._baseLongs, Planet.moon: 14.0}; // Bharani → Venus MD
    final findings = computeCompareFindings(
      subjects: [
        _entry('A',
            ascendant: 15,
            longs: longs,
            birthYear: 1980,
            events: [_marriage(precision: 'age', age: 18)]),
        _entry('B',
            ascendant: 15,
            longs: longs,
            birthYear: 1980,
            events: [_marriage(precision: 'age', age: 18)]),
      ],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      transitPositions: _fixedSky(_baseLongs),
    );
    expect(_find(findings, 'event-md:marriage:venus')?.strength, 2);
    expect(findings.where((f) => f.key.startsWith('event-ad:')), isEmpty);
    // The detail is flagged approximate with no AD lord.
    final md = _find(findings, 'event-md:marriage:venus')!;
    expect(md.eventDetails!.every((d) => d.approximate && d.adLord == null),
        isTrue);
  });

  test('legacy Mahakosh subject → placement + transit, dasha "—" (§6)', () {
    final longs = {..._baseLongs, Planet.moon: 5.0, Planet.saturn: 340.0};
    final local = LocalSubject(
      kundli: Kundli(
        id: 'k1',
        name: 'Local',
        relationTag: 'Self',
        birthUtc: DateTime.utc(1980, 1, 1),
        latitude: 28.6,
        longitude: 77.2,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
        placeName: 'Delhi',
        createdAt: DateTime.utc(1980),
        updatedAt: DateTime.utc(1980),
      ),
      snapshot: _snapshot(ascendant: 15, longs: longs),
      kundliEvents: [
        KundliEvent(
          id: 'e1',
          kundliId: 'k1',
          category: 'marriage',
          eventDate: DateTime(1998, 6, 15),
          createdAt: DateTime.utc(1998),
          updatedAt: DateTime.utc(1998),
        ),
      ],
    );
    final legacy = MahakoshSubject(
      mkChart: AnonymizedChart(
        mkCode: 'MK-1',
        birthYear: 1980,
        locationGeneral: 'North India',
        ayanamsaId: 1,
        ascendant: 15,
        longitudes: {for (final e in longs.entries) e.key.name: e.value},
        createdAt: DateTime.utc(2020),
        events: const [
          (
            tag: 'Marriage',
            date: '1998-06-15',
            precision: 'exact',
            ageYears: null,
            isHealth: false,
          ),
        ],
      ),
      // Legacy: no rebuilt snapshot.
    );

    final findings = computeCompareFindings(
      subjects: [local.toEntry(), legacy.toEntry()],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      transitPositions: _fixedSky({..._baseLongs, Planet.saturn: 220.0}),
    );

    expect(_find(findings, 'graha-sign:saturn:pisces')?.strength, 2);
    expect(
        _find(findings, 'event-transit:marriage:saturn:moon:8')?.strength, 2);
    // No cross-chart dasha finding: the legacy chart has no lord.
    expect(findings.where((f) => f.key.startsWith('event-md:')), isEmpty);
    // The legacy subject's event detail shows "—" (null) lords.
    final transit = _find(findings, 'event-transit:marriage:saturn:moon:8')!;
    final mkDetail =
        transit.eventDetails!.firstWhere((d) => d.subjectId == 'mk:MK-1');
    expect(mkDetail.mdLord, isNull);
    expect(mkDetail.adLord, isNull);
  });

  test('Rahu–Ketu emitted as one axis finding (§4.3.5)', () {
    final longs = {..._baseLongs, Planet.moon: 5.0}; // Aries
    final findings = computeCompareFindings(
      subjects: [
        _entry('A',
            ascendant: 15,
            longs: longs,
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
        _entry('B',
            ascendant: 15,
            longs: longs,
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
      ],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      transitPositions: _fixedSky({
        ..._baseLongs,
        Planet.rahu: 65.0, // Gemini → 3rd from Aries Moon
        Planet.ketu: 245.0, // Sagittarius → 9th
      }),
    );
    // One axis finding per frame; never a standalone node transit row.
    expect(_find(findings, 'event-transit:marriage:rahuketu:moon:3')?.strength,
        2);
    expect(findings.where((f) => f.key.startsWith('event-transit:marriage:ketu:')),
        isEmpty);
    expect(findings.where((f) => f.key.startsWith('event-transit:marriage:rahu:')),
        isEmpty);
  });

  test('Chara event past the single cycle → "—" (regression guard §6)', () {
    // Jaimini Chara generates one cycle; an event centuries out finds no
    // period → null lords, a neutral row, and no throw.
    final aLongs = {..._baseLongs, Planet.moon: 5.0}; // Aries Moon
    final bLongs = {
      for (final e in _baseLongs.entries) e.key: (e.value + 180) % 360,
    };
    final far = CompareEvent(
        category: 'spiritual',
        date: DateTime(2200, 1, 1),
        precision: 'exact');

    final findings = computeCompareFindings(
      subjects: [
        _entry('A', ascendant: 15, longs: aLongs, events: [far]),
        _entry('B', ascendant: 165, longs: bLongs, events: [far]),
      ],
      dashaSystem: DashaSystem.jaimini,
      now: _now,
      transitPositions: _fixedSky(_baseLongs),
    );

    final neutral = _find(findings, 'event-neutral:spiritual');
    expect(neutral, isNotNull);
    expect(neutral!.eventDetails!.every((d) => d.mdLord == null), isTrue);
  });

  test('chart missing a graha participates without crashing (§4.2 guard)', () {
    // Both charts omit Ketu entirely (a legacy/partial chart). The engine
    // must not throw, must still emit findings for present grahas, and must
    // simply have no Ketu finding.
    final longs = {..._baseLongs, Planet.moon: 14.0, Planet.saturn: 340.0}
      ..remove(Planet.ketu);

    late final List<CompareFinding> findings;
    expect(() {
      findings = computeCompareFindings(
        subjects: [
          _entry('A', ascendant: 15, longs: longs),
          _entry('B', ascendant: 15, longs: longs),
        ],
        dashaSystem: DashaSystem.vimshottari,
        now: _now,
        transitPositions: _fixedSky(_baseLongs),
      );
    }, returnsNormally);

    // Present grahas still match…
    expect(_find(findings, 'graha-sign:saturn:pisces')?.strength, 2);
    // …but the absent Ketu never yields a placement/dignity finding.
    expect(findings.where((f) => f.key.contains(':ketu:')), isEmpty);
  });

  test('chart missing the Moon skips Moon rules but keeps the rest (§4.2 guard)',
      () {
    // A has no Moon; B has one. Moon-based findings simply don't appear,
    // and nothing throws.
    final aLongs = {..._baseLongs, Planet.saturn: 340.0}..remove(Planet.moon);
    final bLongs = {..._baseLongs, Planet.saturn: 340.0, Planet.moon: 14.0};

    late final List<CompareFinding> findings;
    expect(() {
      findings = computeCompareFindings(
        subjects: [
          _entry('A', ascendant: 15, longs: aLongs, withSnapshot: false),
          _entry('B', ascendant: 15, longs: bLongs, withSnapshot: false),
        ],
        dashaSystem: DashaSystem.vimshottari,
        now: _now,
        transitPositions: _fixedSky(_baseLongs),
      );
    }, returnsNormally);

    // Saturn still matches; no Moon sign/nakshatra finding (only one has it).
    expect(_find(findings, 'graha-sign:saturn:pisces')?.strength, 2);
    expect(findings.where((f) => f.key.startsWith('moon-')), isEmpty);
  });

  test('Moon never emits an event-transit finding, even on a unanimous exact '
      'match — but stays in the detail grid (§4.3)', () {
    final longs = {..._baseLongs, Planet.moon: 5.0}; // Aries
    // Identical charts, same exact-dated marriage, and a fixed sky: this is
    // the unanimous, exact-dated case that WOULD surface a fast mover.
    final findings = computeCompareFindings(
      subjects: [
        _entry('A',
            ascendant: 15,
            longs: longs,
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
        _entry('B',
            ascendant: 15,
            longs: longs,
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
      ],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      transitPositions: _fixedSky({
        ..._baseLongs,
        Planet.moon: 5.0, // transiting Moon → 1st from natal Aries Moon
        Planet.venus: 45.0, // Taurus → 2nd (a fast mover that DOES surface)
      }),
    );

    // A fast mover still surfaces on the unanimous exact match…
    expect(_find(findings, 'event-transit:marriage:venus:moon:2')?.strength, 2);
    // …but the Moon-as-planet never does, in either frame.
    expect(findings.where((f) => f.key.startsWith('event-transit:marriage:moon:')),
        isEmpty);

    // The Moon still appears in the per-event detail grid (day-level).
    final venus = _find(findings, 'event-transit:marriage:venus:moon:2')!;
    final detail = venus.eventDetails!.first;
    expect(detail.transitHousesFromMoon.containsKey(Planet.moon), isTrue);
    expect(detail.transitHousesFromLagna.containsKey(Planet.moon), isTrue);
  });

  test('sanity: Sade Sati phase surfaces on shared category', () {
    // Saturn in the 8th (Scorpio) from an Aries Moon is the 4th/8th
    // dhaiya — a shared "smallPanoti" finding.
    final longs = {..._baseLongs, Planet.moon: 5.0};
    final findings = computeCompareFindings(
      subjects: [
        _entry('A',
            ascendant: 15,
            longs: longs,
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
        _entry('B',
            ascendant: 15,
            longs: longs,
            withSnapshot: false,
            events: [_marriage(date: DateTime(1998, 6, 15))]),
      ],
      dashaSystem: DashaSystem.vimshottari,
      now: _now,
      transitPositions: _fixedSky({..._baseLongs, Planet.saturn: 220.0}),
    );
    expect(
        _find(findings, 'event-sadesati:marriage:${SadeSatiPhaseKind.smallPanoti.name}')
            ?.strength,
        2);
  });
}
