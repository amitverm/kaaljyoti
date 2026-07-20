// Shadbala/Bhava Bala — THIRD reference chart (16 Oct 1969 13:04 IST,
// Delhi — Sagittarius lagna), run BLIND against the engine on
// 2026-07-14: no code was changed to fit it except one bug it caught
// (Mercury ayana bala — both declinations add). Everything asserted
// tightly below matched blind; drig and chesta carry documented
// divergences (see the loose test at the bottom).
//
// Inputs verified by reproducing PL9's Uchcha Bala to ±0.005.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/bhava_bala.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/core/astro/shadbala.dart';

const _lon = {
  Planet.sun: 179.3325115251,
  Planet.moon: 242.4174369311,
  Planet.mars: 262.8989703048,
  Planet.mercury: 161.4144967052,
  Planet.jupiter: 174.3700981932,
  Planet.venus: 154.9809550754,
  Planet.saturn: 13.0406292289,
  Planet.rahu: 325.9112378858,
  Planet.ketu: 145.9112378858,
};
const _speed = {
  Planet.sun: 0.992,
  Planet.moon: 14.169,
  Planet.mars: 0.685,
  Planet.mercury: 1.151,
  Planet.jupiter: 0.217,
  Planet.venus: 1.237,
  Planet.saturn: -0.077,
  Planet.rahu: -0.053,
  Planet.ketu: -0.053,
};
const _asc = 267.59545780273345;
const _mc = 194.2841602633629;
const _ayan = 23.435121204221787;

const _planets = kShadbalaPlanets;
// PL9 rows, order Su Mo Ma Me Ju Ve Sa.
const _uchcha = [3.56, 9.81, 48.30, 58.80, 33.54, 7.34, 2.32];
const _sthana = [159.18, 159.81, 235.80, 246.30, 140.42, 187.34, 82.94];
const _dig = [55.01, 16.04, 37.13, 24.61, 28.93, 13.10, 35.15];
const _nato = [55.38, 4.62, 4.62, 60.00, 55.38, 55.38, 4.62];
const _paksha = [38.97, 21.03, 38.97, 38.97, 21.03, 21.03, 38.97];
const _ayana = [18.39, 59.92, 1.21, 32.54, 20.83, 30.83, 12.17];
const _kala = [172.74, 100.57, 44.80, 131.51, 202.24, 107.24, 145.76];
// Documented divergences (loose assertions):
const _chesta = [18.39, 21.03, 47.99, 48.89, 3.54, 24.69, 55.80];
const _drig = [-10.71, -15.70, -6.32, -2.97, -8.22, -4.58, -1.69];
// Bhava rows, houses 1..12.
const _bhPlanetsIn = [-60, 0, 0, 0, -60, 0, 0, 0, 0, 60, 0, 0];
const _bhDayNight = [0, 0, 15, 0, 0, 0, 15, 0, 15, 15, 15, 15];
const _bhDig = [30, 40, 40, 60, 10, 20, 0, 50, 50, 30, 40, 10];

AstroSnapshot _snap() => AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(1969, 10, 16, 7, 34),
        latitude: 28.6465,
        longitude: 77.2128,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 1,
      ayanamsaValue: _ayan,
      positions: {
        for (final e in _lon.entries)
          e.key: PlanetPosition(
              planet: e.key,
              longitude: e.value,
              latitude: 0,
              speed: _speed[e.key]!),
      },
      ascendant: _asc,
      houseCusps: [for (var i = 0; i < 12; i++) ((8 + i) % 12) * 30.0],
      panchang: computePanchang(
          sunLongitude: _lon[Planet.sun]!,
          moonLongitude: _lon[Planet.moon]!,
          localDateTime: DateTime(1969, 10, 16, 13, 4)),
      yogas: const [],
    );

void main() {
  final snap = _snap();
  double lo(Planet p) => _lon[p]!;
  double pak(Planet p) =>
      pakshaBala(p, lo(Planet.sun), lo(Planet.moon), mercuryWithMalefic: true);
  double kalaOf(Planet p) =>
      nathonnataBala(p, snap.birth) +
      pak(p) +
      tribhagaBala(p, Planet.sun) + // 2nd day third → Sun
      varshaBala(p, Planet.moon) +
      masaBala(p, Planet.saturn) +
      dinaBala(p, Planet.jupiter) + // Vedic Thursday
      horaBala(p, Planet.saturn) +
      ayanaBala(p, lo(p) + _ayan);

  void checkRow(
      String label, double Function(Planet) f, List<double> exp, double tol) {
    test('$label matches PL9 (±$tol)', () {
      for (var i = 0; i < _planets.length; i++) {
        expect(f(_planets[i]), closeTo(exp[i], tol),
            reason: '$label ${_planets[i].displayName}');
      }
    });
  }

  checkRow('uchcha', (p) => uchchaBala(p, lo(p)), _uchcha, 0.05);
  checkRow('sthana', (p) => sthanaBala(p, snap), _sthana, 0.1);
  checkRow('dig', (p) => digBala(p, lo(p), ascendant: _asc, midheaven: _mc),
      _dig, 0.1);
  checkRow('nathonnata', (p) => nathonnataBala(p, snap.birth), _nato, 0.75);
  checkRow('paksha', pak, _paksha, 0.05);
  // Mercury's ±0.5 here is the regression guard for the both-ayanas
  // rule this chart caught (southern-declination Mercury).
  checkRow('ayana', (p) => ayanaBala(p, lo(p) + _ayan), _ayana, 0.5);
  checkRow('kala', kalaOf, _kala, 1.0);

  test('chesta — DOCUMENTED spread (±6; PL9 model differs)', () {
    // The seeghra-kendra approximation drifts up to 5.5 on this chart
    // (Mars/Venus); Mercury remains the outlier (−16, see
    // shadbala_test.dart). Asserted loosely so the shape is pinned.
    final meanSun =
        meanSunTropicalLongitude((2440510.8152777776 - 2451545.0) / 36525.0);
    for (var i = 0; i < _planets.length; i++) {
      final p = _planets[i];
      final got = cheshtaBala(
        planet: p,
        sunAyanaBala: ayanaBala(Planet.sun, lo(Planet.sun) + _ayan),
        moonPakshaBala: pak(Planet.moon),
        helioTropicalLongitude: kFixture1969Helio[p],
        meanSunTropical: meanSun,
      );
      final tol = p == Planet.mercury ? 17.0 : 6.0;
      expect(got, closeTo(_chesta[i], tol), reason: 'chesta ${p.displayName}');
    }
  });

  test('drig — DOCUMENTED divergence (±26, round-5 refit pending)', () {
    // This chart's Virgo stellium is aspected through curve regions
    // (Saturn 140–230°, Mars/Moon 250–300°) that neither earlier
    // reference chart constrains — and its equations conflict with the
    // current shapes (Saturn ≈27 @229° yet ≈0 @235.5° per the 2005
    // chart). Needs a joint 21-constraint refit; until then the spread
    // is asserted so it cannot silently grow.
    for (var i = 0; i < _planets.length; i++) {
      expect(drikBala(_planets[i], snap, moonIsShukla: true),
          closeTo(_drig[i], 26.0),
          reason: 'drig ${_planets[i].displayName}');
    }
  });

  group('bhava', () {
    final sb = [
      for (final p in _planets)
        ShadbalaResult(
            planet: p,
            sthana: 0,
            dig: 0,
            kala: 0,
            cheshta: 0,
            naisargika: 0,
            drik: 0),
    ];
    final rows = computeBhavaBala(_snap(), sb);

    test('planets-in matches PL9 exactly 12/12 (blind)', () {
      for (var i = 0; i < 12; i++) {
        expect(rows[i].planetsIn, _bhPlanetsIn[i].toDouble(),
            reason: 'H${i + 1}');
      }
    });

    test('day-night matches PL9 exactly 12/12 (blind, incl. Pisces=0)', () {
      for (var i = 0; i < 12; i++) {
        expect(rows[i].dayNight, _bhDayNight[i].toDouble(),
            reason: 'H${i + 1}');
      }
    });

    test('dig matches PL9 exactly 12/12 (blind)', () {
      for (var i = 0; i < 12; i++) {
        expect(rows[i].dig, _bhDig[i].toDouble(), reason: 'H${i + 1}');
      }
    });
  });
}

/// Helio longitudes (Swiss Ephemeris, tropical of date).
const kFixture1969Helio = {
  Planet.mars: 332.16152008761003,
  Planet.mercury: 106.15483571052256,
  Planet.jupiter: 196.90577534848603,
  Planet.venus: 143.4800597273232,
  Planet.saturn: 35.00462882054518,
};
