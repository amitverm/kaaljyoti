/// Thin wrapper around the `sweph` FFI bindings. ALL Swiss Ephemeris
/// calls live in this file so any binding API drift is contained here.
///
/// Runs in full Swiss Ephemeris mode (SEFLG_SWIEPH): [init] stages the
/// bundled 1800–2400 CE data files (sepl/semo/seas_18.se1) into the
/// app-support directory on first launch. LICENSING: the Swiss
/// Ephemeris professional license is required for closed-source
/// distribution — internal testing only until it's obtained; flip
/// [useSwissEph] to false to fall back to Moshier (~0.1" planets).
library;

import 'package:sweph/sweph.dart';

import 'models.dart';

class EphemerisService {
  EphemerisService._();
  static final EphemerisService instance = EphemerisService._();

  static bool _initialized = false;
  static bool useSwissEph = true;

  static Future<void> init() async {
    if (_initialized) return;
    // Stage the ephemeris files sweph ships (planets/moon/asteroids
    // 1800–2400 CE + fixed stars + leap seconds). Copied once to
    // <ApplicationSupport>/ephe_files; later launches are instant.
    await Sweph.init(epheAssets: [
      'packages/sweph/assets/ephe/sepl_18.se1',
      'packages/sweph/assets/ephe/semo_18.se1',
      'packages/sweph/assets/ephe/seas_18.se1',
      'packages/sweph/assets/ephe/sefstars.txt',
      'packages/sweph/assets/ephe/seleapsec.txt',
    ]);
    _initialized = true;
  }

  SwephFlag get _baseFlags => (useSwissEph
          ? SwephFlag.SEFLG_SWIEPH
          : SwephFlag.SEFLG_MOSEPH) |
      SwephFlag.SEFLG_SPEED |
      SwephFlag.SEFLG_SIDEREAL;

  static const Map<Planet, HeavenlyBody> _bodies = {
    Planet.sun: HeavenlyBody.SE_SUN,
    Planet.moon: HeavenlyBody.SE_MOON,
    Planet.mars: HeavenlyBody.SE_MARS,
    Planet.mercury: HeavenlyBody.SE_MERCURY,
    Planet.jupiter: HeavenlyBody.SE_JUPITER,
    Planet.venus: HeavenlyBody.SE_VENUS,
    Planet.saturn: HeavenlyBody.SE_SATURN,
    Planet.rahu: HeavenlyBody.SE_TRUE_NODE,
  };

  double julianDayUt(DateTime utc) {
    final hour = utc.hour +
        utc.minute / 60.0 +
        utc.second / 3600.0 +
        utc.millisecond / 3.6e6;
    return Sweph.swe_julday(
        utc.year, utc.month, utc.day, hour, CalendarType.SE_GREG_CAL);
  }

  void _setSiderealMode(int ayanamsaId) {
    // SiderealMode wraps the raw SE_SIDM_* integer id directly.
    Sweph.swe_set_sid_mode(SiderealMode(ayanamsaId));
  }

  double ayanamsaValue(double jdUt, int ayanamsaId) {
    _setSiderealMode(ayanamsaId);
    return Sweph.swe_get_ayanamsa_ex_ut(jdUt, _baseFlags);
  }

  /// Sidereal positions for all nine grahas.
  Map<Planet, PlanetPosition> planetPositions(double jdUt, int ayanamsaId) {
    _setSiderealMode(ayanamsaId);
    final out = <Planet, PlanetPosition>{};
    for (final entry in _bodies.entries) {
      final r = Sweph.swe_calc_ut(jdUt, entry.value, _baseFlags);
      out[entry.key] = PlanetPosition(
        planet: entry.key,
        longitude: _norm(r.longitude),
        latitude: r.latitude,
        speed: r.speedInLongitude,
      );
    }
    // Ketu = Rahu + 180°, same speed profile.
    final rahu = out[Planet.rahu]!;
    out[Planet.ketu] = PlanetPosition(
      planet: Planet.ketu,
      longitude: _norm(rahu.longitude + 180),
      latitude: -rahu.latitude,
      speed: rahu.speed,
    );
    return out;
  }

  /// Sidereal ascendant + 12 house cusps. Whole-sign is the Vedic
  /// default at the app layer; cusps here come from the requested
  /// system (default Placidus 'P') for future house-system options.
  ({double ascendant, List<double> cusps}) housesAndAscendant(
    double jdUt,
    double latitude,
    double longitude,
    int ayanamsaId, {
    Hsys houseSystem = Hsys.P,
  }) {
    _setSiderealMode(ayanamsaId);
    final h = Sweph.swe_houses_ex(
        jdUt, _baseFlags, latitude, longitude, houseSystem);
    final asc = _norm(h.ascmc[0]);
    final cusps = <double>[
      for (var i = 1; i <= 12; i++) _norm(h.cusps[i]),
    ];
    return (ascendant: asc, cusps: cusps);
  }

  /// Julian day (UT) of the last sunrise at or before [jdUt] for the
  /// given place — the Vedic day anchor for Bhava/Hora/Ghati lagnas.
  ///
  /// Uses the Hindu convention (disc center, no refraction —
  /// SE_BIT_HINDU_RISING), matching Jagannatha Hora's default. Returns
  /// null only in degenerate cases (circumpolar sun).
  double? sunriseBefore(double jdUt, double latitude, double longitude) {
    final epheFlag =
        useSwissEph ? SwephFlag.SEFLG_SWIEPH : SwephFlag.SEFLG_MOSEPH;
    var start = jdUt - 2;
    double? last;
    for (var i = 0; i < 5; i++) {
      final r = Sweph.swe_rise_trans(
        start,
        HeavenlyBody.SE_SUN,
        epheFlag,
        RiseSetTransitFlag.SE_CALC_RISE |
            RiseSetTransitFlag.SE_BIT_HINDU_RISING,
        GeoPosition(longitude, latitude),
        0,
        0,
      );
      if (r == null || r > jdUt) break;
      last = r;
      start = r + 1e-5;
    }
    return last;
  }

  /// Next sunrise/sunset (Hindu convention: disc center, no
  /// refraction) strictly after [jdUt], as a Julian day, or null in
  /// circumpolar edge cases.
  double? sunEventAfter(double jdUt, double latitude, double longitude,
      {required bool rise}) {
    final epheFlag =
        useSwissEph ? SwephFlag.SEFLG_SWIEPH : SwephFlag.SEFLG_MOSEPH;
    return Sweph.swe_rise_trans(
      jdUt,
      HeavenlyBody.SE_SUN,
      epheFlag,
      (rise
              ? RiseSetTransitFlag.SE_CALC_RISE
              : RiseSetTransitFlag.SE_CALC_SET) |
          RiseSetTransitFlag.SE_BIT_HINDU_RISING,
      GeoPosition(longitude, latitude),
      0,
      0,
    );
  }

  /// Sunrise and sunset (Hindu convention) for the calendar day
  /// [dayUtc] falls on, at the given place — the Muhurta screen's
  /// single entry point for a chosen date+place (the Today screen's
  /// "now"-anchored [sunriseBefore]/[sunEventAfter] pair predate this
  /// and are left as-is). Anchored at local noon so [dayUtc] can be
  /// any instant on the intended calendar day. Throws in degenerate
  /// (circumpolar) cases where no rise/set exists.
  ({DateTime rise, DateTime set}) sunRiseSet(
      DateTime dayUtc, double latitude, double longitude) {
    final noon = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day, 12);
    final jdNoon = julianDayUt(noon);
    final riseJd = sunriseBefore(jdNoon, latitude, longitude) ??
        sunriseBefore(jdNoon - 1, latitude, longitude);
    final setJd = riseJd == null
        ? null
        : sunEventAfter(riseJd, latitude, longitude, rise: false);
    if (riseJd == null || setJd == null) {
      throw StateError(
          'No sunrise/sunset for this day/place (circumpolar?).');
    }
    return (
      rise: dateTimeFromJdUt(riseJd).toLocal(),
      set: dateTimeFromJdUt(setJd).toLocal(),
    );
  }

  /// Inverse of [julianDayUt] — a Julian day (UT) back to a UTC
  /// DateTime.
  static DateTime dateTimeFromJdUt(double jdUt) =>
      DateTime.fromMillisecondsSinceEpoch(
        ((jdUt - 2440587.5) * 86400000).round(),
        isUtc: true,
      );

  /// TROPICAL heliocentric longitudes of the five tara grahas —
  /// the Sighrochcha inputs for Shadbala's Cheshta Bala (validated
  /// against the PL9 fixture; see shadbala.dart). NOT sidereal: the
  /// Cheshta Kendra is a difference of two tropical quantities, so the
  /// ayanamsa cancels and must not be applied to only one side.
  Map<Planet, double> helioTropicalLongitudes(double jdUt) {
    final flags = (useSwissEph
            ? SwephFlag.SEFLG_SWIEPH
            : SwephFlag.SEFLG_MOSEPH) |
        SwephFlag.SEFLG_HELCTR;
    const five = [
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];
    return {
      for (final p in five)
        p: _norm(Sweph.swe_calc_ut(jdUt, _bodies[p]!, flags).longitude),
    };
  }

  /// Sidereal longitude of the Sun at [jdUt].
  double sunLongitude(double jdUt, int ayanamsaId) {
    _setSiderealMode(ayanamsaId);
    final r = Sweph.swe_calc_ut(jdUt, HeavenlyBody.SE_SUN, _baseFlags);
    return _norm(r.longitude);
  }

  /// Sidereal Sun and Moon longitudes at [jdUt] — a two-body shortcut
  /// for the lunar-month / new-moon searches, which don't need the
  /// full graha set that [planetPositions] computes.
  ({double sun, double moon}) sunMoonLongitudes(double jdUt, int ayanamsaId) {
    _setSiderealMode(ayanamsaId);
    return (
      sun: _norm(Sweph.swe_calc_ut(jdUt, HeavenlyBody.SE_SUN, _baseFlags)
          .longitude),
      moon: _norm(Sweph.swe_calc_ut(jdUt, HeavenlyBody.SE_MOON, _baseFlags)
          .longitude),
    );
  }

  static double _norm(double deg) {
    var d = deg % 360;
    if (d < 0) d += 360;
    return d;
  }
}
