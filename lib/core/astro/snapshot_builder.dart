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

    final jd = _eph.julianDayUt(birth.dateTimeUtc);
    final positions = _eph.planetPositions(jd, ayanamsaId);
    final houses = _eph.housesAndAscendant(
      jd,
      birth.latitude,
      birth.longitude,
      ayanamsaId,
    );

    final panchang = computePanchang(
      sunLongitude: positions[Planet.sun]!.longitude,
      moonLongitude: positions[Planet.moon]!.longitude,
      localDateTime: birth.localDateTime,
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
