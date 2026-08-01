/// Builds the shared per-chart [AstroSnapshot] — computed once per
/// chart, consumed by every widget, dasha calculator, PDF block, and
/// the Mahakosh index builder (brief §2.3, §2.8).
library;

import 'ephemeris_service.dart';
import 'models.dart';
import 'panchang.dart';
import 'vikram_samvat.dart';
import 'yogas.dart';

/// The Vedic day around an instant — the sunrise that began it, the
/// sunset that closes its daylight, and the sunrise that ends it — in
/// the PLACE's local wall clock. Null when there is no sunrise at all
/// (circumpolar); [sunset]/[nextSunrise] are individually null when the
/// sun rose but does not set within the search.
///
/// The three lookups arrive as closures rather than being called on an
/// [EphemerisService] directly. The native Swiss Ephemeris cannot load
/// under headless `flutter test`, so this seam is the only way the
/// ordering rule below (rise ≤ instant < next rise, rise < set < next
/// rise) is testable at all — the same inject-don't-call convention
/// core/astro/muhurta.dart and the transit-scan engine follow.
({DateTime sunrise, DateTime? sunset, DateTime? nextSunrise})? vedicDayWindow({
  required double jdUt,
  required int utcOffsetMinutes,
  required double? Function(double jdUt) sunriseBefore,
  required double? Function(double jdUt, {required bool rise}) sunEventAfter,
}) {
  final riseJd = sunriseBefore(jdUt);
  if (riseJd == null) return null;
  final setJd = sunEventAfter(riseJd, rise: false);
  // Chained off the SUNSET, not off the sunrise: `sunEventAfter` returns
  // the next event strictly after its argument, and a search seeded at
  // the sunrise itself can hand back that same sunrise on a rounding
  // tie. Sunset always sits safely between the two.
  final nextRiseJd =
      setJd == null ? null : sunEventAfter(setJd, rise: true);
  DateTime local(double jd) => EphemerisService.dateTimeFromJdUt(jd)
      .add(Duration(minutes: utcOffsetMinutes));
  return (
    sunrise: local(riseJd),
    sunset: setJd == null ? null : local(setJd),
    nextSunrise: nextRiseJd == null ? null : local(nextRiseJd),
  );
}

class SnapshotBuilder {
  SnapshotBuilder({EphemerisService? ephemeris})
      : _eph = ephemeris ?? EphemerisService.instance;

  final EphemerisService _eph;

  Future<AstroSnapshot> build(BirthData birth, int ayanamsaId) async {
    await EphemerisService.init();
    return buildSync(birth, ayanamsaId);
  }

  /// Synchronous core of [build] — for callers that already run after
  /// ephemeris init (the PDF exporter's varsha chart), mirroring the
  /// computeShadbala/computeShadbalaSync split.
  AstroSnapshot buildSync(BirthData birth, int ayanamsaId) {
    final jd = _eph.julianDayUt(birth.dateTimeUtc);
    final positions = _eph.planetPositions(jd, ayanamsaId);
    final houses = _eph.housesAndAscendant(
      jd,
      birth.latitude,
      birth.longitude,
      ayanamsaId,
    );

    // Vara is sunrise-bounded: a pre-sunrise birth belongs to the
    // previous Vedic day. Take the weekday of the sunrise that begins
    // the birth's Vedic day (the last sunrise at/before the birth
    // instant), in birth-place local time. Falls back to the civil
    // weekday in degenerate (circumpolar) cases.
    final window = vedicDayWindow(
      jdUt: jd,
      utcOffsetMinutes: birth.utcOffsetMinutes,
      sunriseBefore: (j) =>
          _eph.sunriseBefore(j, birth.latitude, birth.longitude),
      sunEventAfter: (j, {required rise}) =>
          _eph.sunEventAfter(j, birth.latitude, birth.longitude, rise: rise),
    );
    final vedicWeekday =
        window?.sunrise.weekday ?? birth.localDateTime.weekday;

    var panchang = computePanchang(
      sunLongitude: positions[Planet.sun]!.longitude,
      moonLongitude: positions[Planet.moon]!.longitude,
      localDateTime: birth.localDateTime,
      vedicWeekday: vedicWeekday,
    );

    // The maasa is named from the new moons bracketing the birth, so it
    // needs no place and is resolved even for a circumpolar birth whose
    // sunrise came back null. Stored under AMANTA naming; the reader
    // picks purnimanta/amanta at display time.
    //
    // This is the most expensive line in the build — bracketing new
    // moons and walking back to Chaitra costs a few hundred two-body
    // lookups, against ~10 for everything above it. It stays here
    // rather than on the reader because the snapshot is built ONCE per
    // chart and shared, whereas a module would pay it on every rebuild.
    final masa = computeVikramMasa(
      _eph,
      jd,
      ayanamsaId,
      krishnaPaksha: panchang.tithiIndex >= 15,
      system: MasaSystem.amanta,
    );
    panchang = panchang.withVedicDay(
      sunrise: window?.sunrise,
      sunset: window?.sunset,
      nextSunrise: window?.nextSunrise,
      amantaMonthIndex: masa.monthIndex,
      isAdhikMaasa: masa.isAdhik,
      samvatYear: masa.samvatYear,
    );

    final yogas = detectYogas(
      positions: positions,
      ascendant: houses.ascendant,
    );

    return AstroSnapshot(
      birth: birth,
      ayanamsaId: ayanamsaId,
      ayanamsaValue: _eph.ayanamsaValue(jd, ayanamsaId),
      positions: positions,
      ascendant: houses.ascendant,
      houseCusps: houses.cusps,
      panchang: panchang,
      yogas: yogas,
    );
  }
}
