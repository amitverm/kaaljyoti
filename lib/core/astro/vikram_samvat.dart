/// Vikram Samvat lunar month (maasa) + year, derived from the new
/// moons bracketing a given instant.
///
/// The amanta month is named for the solar sign (rashi) the Sun holds
/// at the new moon (amavasya) that starts it; the year rolls over at
/// Chaitra Shukla Pratipada. Purnimanta output is the same computation
/// with the Krishna (waning) fortnight relabelled to the following
/// month — the North-Indian convention. Adhik (leap) months are
/// detected when a lunar month contains no solar-sign ingress.
library;

import 'ephemeris_service.dart';

/// Which fortnight-to-month convention names the month.
enum MasaSystem {
  /// Month ends at Amavasya (Gujarat, most of the South).
  amanta,

  /// Month ends at Purnima (Vikram Samvat across North India).
  purnimanta;

  static MasaSystem byName(String? name) => MasaSystem.values.firstWhere(
        (s) => s.name == name,
        orElse: () => MasaSystem.purnimanta,
      );
}

/// Lunar month names, Chaitra = 0 … Phalguna = 11.
const List<String> _masaNames = [
  'Chaitra', 'Vaishakha', 'Jyeshtha', 'Ashadha',
  'Shravana', 'Bhadrapada', 'Ashwina', 'Kartika',
  'Margashirsha', 'Pausha', 'Magha', 'Phalguna',
];

/// The lunar month and Vikram Samvat year for an instant.
class VikramMasa {
  const VikramMasa({
    required this.monthIndex,
    required this.monthName,
    required this.isAdhik,
    required this.samvatYear,
    required this.system,
  });

  /// 0 = Chaitra … 11 = Phalguna.
  final int monthIndex;
  final String monthName;

  /// True for an adhik (extra/leap) month — one with no solar ingress.
  final bool isAdhik;

  /// Vikram Samvat year (Gregorian year of the Chaitra that began this
  /// lunar year, + 57).
  final int samvatYear;
  final MasaSystem system;

  /// e.g. "Ashadha", "Adhik Shravana".
  String get displayName => isAdhik ? 'Adhik $monthName' : monthName;
}

double _norm(double d) {
  var x = d % 360;
  if (x < 0) x += 360;
  return x;
}

/// Sun–Moon elongation (0–360) at [jd].
double _elong(EphemerisService svc, double jd, int ayanamsaId) {
  final sm = svc.sunMoonLongitudes(jd, ayanamsaId);
  return _norm(sm.moon - sm.sun);
}

/// Elongation mapped to (−180, 180], continuous and monotone-increasing
/// through the new moon (where it crosses 0 upward); the discontinuity
/// sits at the full moon, safely away from the roots we bracket.
double _phase(double elong) => ((elong + 180) % 360) - 180;

/// Solar sign (0 = Mesha … 11 = Meena) at [jd].
int _rashi(EphemerisService svc, double jd, int ayanamsaId) =>
    (svc.sunLongitude(jd, ayanamsaId) / 30).floor() % 12;

/// Mean synodic elongation rate (°/day) — used only to seed the search.
const double _elongRate = 360 / 29.530588;

/// The new moon nearest [estimateJd], by bracketing the upward zero
/// crossing of [_phase] and bisecting to ~sub-second precision.
double _newMoonNear(EphemerisService svc, int ayanamsaId, double estimateJd) {
  var lo = estimateJd - 3, hi = estimateJd + 3;
  var gLo = _phase(_elong(svc, lo, ayanamsaId));
  var gHi = _phase(_elong(svc, hi, ayanamsaId));
  for (var i = 0; gLo > 0 && i < 8; i++) {
    lo -= 2;
    gLo = _phase(_elong(svc, lo, ayanamsaId));
  }
  for (var i = 0; gHi < 0 && i < 8; i++) {
    hi += 2;
    gHi = _phase(_elong(svc, hi, ayanamsaId));
  }
  for (var i = 0; i < 34; i++) {
    final mid = (lo + hi) / 2;
    if (_phase(_elong(svc, mid, ayanamsaId)) <= 0) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// Computes the Vikram Samvat month + year for [jd] (a UT Julian day),
/// given the requested naming [system] and whether [jd] falls in the
/// Krishna (waning) paksha.
VikramMasa computeVikramMasa(
  EphemerisService svc,
  double jd,
  int ayanamsaId, {
  required bool krishnaPaksha,
  required MasaSystem system,
}) {
  final e = _elong(svc, jd, ayanamsaId);
  // The amavasya that started the current amanta month, and the next.
  final startNM = _newMoonNear(svc, ayanamsaId, jd - e / _elongRate);
  final endNM = _newMoonNear(svc, ayanamsaId, jd + (360 - e) / _elongRate);

  final startRashi = _rashi(svc, startNM, ayanamsaId);
  var monthIndex = (startRashi + 1) % 12;
  // No solar ingress within the month → adhik (leap) maasa.
  final isAdhik = startRashi == _rashi(svc, endNM, ayanamsaId);

  // Purnimanta: the waning fortnight belongs to the *next* month.
  if (system == MasaSystem.purnimanta && krishnaPaksha) {
    monthIndex = (monthIndex + 1) % 12;
  }

  // Year rolls at Chaitra (Sun in Meena at its starting amavasya).
  // Walk new moons back to that Chaitra; its Gregorian year + 57 = V.S.
  var chaitraNM = startNM;
  for (var i = 0;
      _rashi(svc, chaitraNM, ayanamsaId) != 11 && i < 14;
      i++) {
    chaitraNM = _newMoonNear(svc, ayanamsaId, chaitraNM - 29.530588);
  }
  final chaitraYear =
      EphemerisService.dateTimeFromJdUt(chaitraNM).toLocal().year;

  return VikramMasa(
    monthIndex: monthIndex,
    monthName: _masaNames[monthIndex],
    isAdhik: isAdhik,
    samvatYear: chaitraYear + 57,
    system: system,
  );
}
