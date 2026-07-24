/// Builds the shared per-chart [AstroSnapshot] — computed once per
/// chart, consumed by every widget, dasha calculator, PDF block, and
/// the Mahakosh index builder (brief §2.3, §2.8).
library;

import 'ephemeris_service.dart';
import 'models.dart';
import 'panchang.dart';
import 'yogas.dart';

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
    final riseJd = _eph.sunriseBefore(jd, birth.latitude, birth.longitude);
    final vedicWeekday = riseJd == null
        ? birth.localDateTime.weekday
        : EphemerisService.dateTimeFromJdUt(riseJd)
            .add(Duration(minutes: birth.utcOffsetMinutes))
            .weekday;

    final panchang = computePanchang(
      sunLongitude: positions[Planet.sun]!.longitude,
      moonLongitude: positions[Planet.moon]!.longitude,
      localDateTime: birth.localDateTime,
      vedicWeekday: vedicWeekday,
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
