/// Krishnamurti Paddhati (KP) engine. Pure Dart — no Flutter imports.
///
/// KP divides each nakshatra (13°20') into 9 unequal "subs" in
/// Vimshottari proportion (years/120), starting from the nakshatra's
/// own star lord — the classic 249-sub zodiac. Sub-subs repeat the
/// same division inside a sub, starting from the sub lord.
///
/// Houses use the PLACIDUS cusps (KP convention): a planet belongs to
/// the cusp-to-cusp span it falls in, NOT its whole-sign house. The
/// snapshot already carries Placidus cusps ([AstroSnapshot.houseCusps],
/// computed via Swiss Ephemeris `swe_houses_ex` system 'P').
///
/// NOTE on ayanamsa: KP practitioners use the Krishnamurti ayanamsa
/// (Swiss Ephemeris id 5, or 45 for Krishnamurti-Senthilathiban). The
/// engine works with whatever ayanamsa the kundli is configured with;
/// the widget surfaces a hint when it isn't a KP ayanamsa.
library;

import 'dasha/vimshottari.dart';
import 'models.dart';

/// The full KP lord chain at a sidereal longitude.
class KpLords {
  const KpLords({
    required this.nakshatra,
    required this.signLord,
    required this.starLord,
    required this.subLord,
    required this.subSubLord,
  });

  final Nakshatra nakshatra;
  final Planet signLord; // lord of the rashi the longitude falls in
  final Planet starLord; // lord of the nakshatra (Vimshottari)
  final Planet subLord; // KP sub lord (249-division)
  final Planet subSubLord; // KP sub-sub lord

  factory KpLords.fromLongitude(double siderealLongitude) {
    var lon = siderealLongitude % 360;
    if (lon < 0) lon += 360;

    final nak = Nakshatra.fromLongitude(lon);
    final within = lon % Nakshatra.span;

    final (subLord, subStart, subSpan) =
        _divide(within, Nakshatra.span, nak.index % 9);
    final subIdx =
        VimshottariCalculator.sequence.indexWhere((e) => e.$1 == subLord);
    final (subSubLord, _, _) = _divide(within - subStart, subSpan, subIdx);

    return KpLords(
      nakshatra: nak,
      signLord: ZodiacSign.fromLongitude(lon).lord,
      starLord: nak.lord,
      subLord: subLord,
      subSubLord: subSubLord,
    );
  }

  /// Splits [total] into 9 Vimshottari-proportional segments starting
  /// at sequence index [startIdx]; returns the segment containing
  /// [offset] as (lord, segmentStart, segmentLength).
  static (Planet, double, double) _divide(
      double offset, double total, int startIdx) {
    var acc = 0.0;
    for (var i = 0; i < 9; i++) {
      final (lord, years) =
          VimshottariCalculator.sequence[(startIdx + i) % 9];
      final seg = total * (years / VimshottariCalculator.totalYears);
      if (offset < acc + seg || i == 8) return (lord, acc, seg);
      acc += seg;
    }
    throw StateError('unreachable');
  }
}

/// One house cusp with its KP lord chain.
class KpCusp {
  const KpCusp({required this.house, required this.longitude, required this.lords});
  final int house; // 1–12
  final double longitude; // sidereal (Placidus cusp)
  final KpLords lords;
}

/// One graha with its KP lord chain and Placidus house occupancy.
class KpPlanet {
  const KpPlanet({
    required this.planet,
    required this.position,
    required this.lords,
    required this.house,
  });

  final Planet planet;
  final PlanetPosition position;
  final KpLords lords;
  final int house; // Placidus cusp-span house, 1–12
}

/// The four significator grades of a house (strongest first is D→A in
/// judgment, but conventionally listed A→D):
///  A — planets in the star of the house's occupants
///  B — occupants of the house
///  C — planets in the star of the house's owner (cusp-sign lord)
///  D — the owner itself
class KpHouseSignificators {
  const KpHouseSignificators({
    required this.house,
    required this.inStarOfOccupants,
    required this.occupants,
    required this.inStarOfOwner,
    required this.owner,
  });

  final int house;
  final List<Planet> inStarOfOccupants; // A
  final List<Planet> occupants; // B
  final List<Planet> inStarOfOwner; // C
  final Planet owner; // D
}

/// Ruling planets at a moment of judgment.
class KpRulingPlanets {
  const KpRulingPlanets({
    required this.dayLord,
    required this.lagnaSignLord,
    required this.lagnaStarLord,
    required this.lagnaSubLord,
    required this.moonSignLord,
    required this.moonStarLord,
    required this.moonSubLord,
  });

  final Planet dayLord;
  final Planet lagnaSignLord;
  final Planet lagnaStarLord;
  final Planet lagnaSubLord;
  final Planet moonSignLord;
  final Planet moonStarLord;
  final Planet moonSubLord;

  /// [ascendant]/[moonLongitude] sidereal at the judgment instant;
  /// [localWeekday] is DateTime.weekday (1 = Monday … 7 = Sunday).
  /// Day-lord convention: civil weekday (matches the panchang vara
  /// convention used elsewhere in the app).
  factory KpRulingPlanets.compute({
    required double ascendant,
    required double moonLongitude,
    required int localWeekday,
  }) {
    const byWeekday = {
      DateTime.sunday: Planet.sun,
      DateTime.monday: Planet.moon,
      DateTime.tuesday: Planet.mars,
      DateTime.wednesday: Planet.mercury,
      DateTime.thursday: Planet.jupiter,
      DateTime.friday: Planet.venus,
      DateTime.saturday: Planet.saturn,
    };
    final asc = KpLords.fromLongitude(ascendant);
    final moon = KpLords.fromLongitude(moonLongitude);
    return KpRulingPlanets(
      dayLord: byWeekday[localWeekday]!,
      lagnaSignLord: asc.signLord,
      lagnaStarLord: asc.starLord,
      lagnaSubLord: asc.subLord,
      moonSignLord: moon.signLord,
      moonStarLord: moon.starLord,
      moonSubLord: moon.subLord,
    );
  }

  /// Distinct ruling planets in traditional citation order.
  List<Planet> get distinct {
    final seen = <Planet>{};
    return [
      lagnaSignLord, lagnaStarLord, lagnaSubLord, //
      moonSignLord, moonStarLord, moonSubLord, dayLord,
    ].where(seen.add).toList();
  }
}

/// Full KP analysis of a chart: cusp and planet lord chains plus
/// significators, computed once and cached by the KP widget.
class KpChart {
  KpChart(this.snapshot) {
    cusps = [
      for (var i = 0; i < 12; i++)
        KpCusp(
          house: i + 1,
          longitude: snapshot.houseCusps[i],
          lords: KpLords.fromLongitude(snapshot.houseCusps[i]),
        ),
    ];

    planets = [
      for (final pos in snapshot.positions.values)
        KpPlanet(
          planet: pos.planet,
          position: pos,
          lords: KpLords.fromLongitude(pos.longitude),
          house: houseOf(pos.longitude),
        ),
    ];

    final occupantsByHouse = <int, List<Planet>>{
      for (var h = 1; h <= 12; h++) h: [],
    };
    for (final p in planets) {
      occupantsByHouse[p.house]!.add(p.planet);
    }

    Planet starLordOf(Planet p) =>
        planets.firstWhere((e) => e.planet == p).lords.starLord;

    significators = [
      for (var h = 1; h <= 12; h++)
        () {
          final occupants = occupantsByHouse[h]!;
          final owner = cusps[h - 1].lords.signLord;
          return KpHouseSignificators(
            house: h,
            inStarOfOccupants: [
              for (final p in planets)
                if (occupants.contains(starLordOf(p.planet))) p.planet,
            ],
            occupants: occupants,
            inStarOfOwner: [
              for (final p in planets)
                if (starLordOf(p.planet) == owner) p.planet,
            ],
            owner: owner,
          );
        }(),
    ];
  }

  final AstroSnapshot snapshot;
  late final List<KpCusp> cusps;
  late final List<KpPlanet> planets;
  late final List<KpHouseSignificators> significators;

  /// Placidus house (1–12) containing a sidereal longitude: the
  /// cusp-to-cusp span it falls in (KP convention, unlike the app's
  /// whole-sign [AstroSnapshot.houseOf]).
  int houseOf(double longitude) {
    var lon = longitude % 360;
    if (lon < 0) lon += 360;
    for (var i = 0; i < 12; i++) {
      final a = snapshot.houseCusps[i];
      final b = snapshot.houseCusps[(i + 1) % 12];
      final inSpan = a <= b ? (lon >= a && lon < b) : (lon >= a || lon < b);
      if (inSpan) return i + 1;
    }
    return 12; // numerically unreachable; guards float edge cases
  }

  /// Houses a planet signifies, weakest-to-strongest KP order:
  /// (1) houses occupied by its star lord, (2) houses owned by its
  /// star lord, (3) the house it occupies, (4) houses it owns.
  /// Returned as a de-duplicated, sorted list.
  List<int> housesSignifiedBy(Planet planet) {
    final me = planets.firstWhere((e) => e.planet == planet);
    final star = planets.firstWhere((e) => e.planet == me.lords.starLord);
    final out = <int>{star.house, me.house};
    for (final c in cusps) {
      if (c.lords.signLord == star.planet) out.add(c.house);
      if (c.lords.signLord == planet) out.add(c.house);
    }
    return out.toList()..sort();
  }
}
