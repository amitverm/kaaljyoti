/// Panchang (five limbs) computation from sidereal Sun/Moon longitudes.
library;

import 'models.dart';

const List<String> _tithiNames = [
  'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami',
  'Shashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
  'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi', 'Purnima',
  'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami',
  'Shashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
  'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi', 'Amavasya',
];

/// Tithi name for a 0-based lunar-day index (0 = Shukla Pratipada …
/// 14 = Purnima … 29 = Amavasya). Wraps modulo 30.
String tithiNameFor(int index) => _tithiNames[index % 30];

/// Paksha (fortnight) for a tithi index: the first 15 are Shukla
/// (waxing), the rest Krishna (waning).
String pakshaFor(int index) => index % 30 < 15 ? 'Shukla' : 'Krishna';

const List<String> _yogaNames = [
  'Vishkambha', 'Priti', 'Ayushman', 'Saubhagya', 'Shobhana',
  'Atiganda', 'Sukarma', 'Dhriti', 'Shula', 'Ganda',
  'Vriddhi', 'Dhruva', 'Vyaghata', 'Harshana', 'Vajra',
  'Siddhi', 'Vyatipata', 'Variyan', 'Parigha', 'Shiva',
  'Siddha', 'Sadhya', 'Shubha', 'Shukla', 'Brahma',
  'Indra', 'Vaidhriti',
];

const List<String> _movableKaranas = [
  'Bava', 'Balava', 'Kaulava', 'Taitila', 'Gara', 'Vanija', 'Vishti',
];

const List<String> _varaNames = [
  'Somavara', 'Mangalavara', 'Budhavara', 'Guruvara',
  'Shukravara', 'Shanivara', 'Ravivara',
];

PanchangData computePanchang({
  required double sunLongitude,
  required double moonLongitude,
  required DateTime localDateTime,
}) {
  final elong = _norm(moonLongitude - sunLongitude);

  final tithiIndex = (elong / 12).floor().clamp(0, 29);
  final paksha = tithiIndex < 15 ? 'Shukla' : 'Krishna';

  final yogaIndex =
      (_norm(sunLongitude + moonLongitude) / (360 / 27)).floor().clamp(0, 26);

  // Karana: half-tithis. 60 karanas per lunation; 4 fixed, 56 from the
  // 7 movable ones repeating. Fixed: Shakuni(57), Chatushpada(58),
  // Naga(59), Kimstughna(0).
  final karanaIndex = (elong / 6).floor().clamp(0, 59);
  final String karana;
  if (karanaIndex == 0) {
    karana = 'Kimstughna';
  } else if (karanaIndex >= 57) {
    karana = const ['Shakuni', 'Chatushpada', 'Naga'][karanaIndex - 57];
  } else {
    karana = _movableKaranas[(karanaIndex - 1) % 7];
  }

  return PanchangData(
    tithiIndex: tithiIndex,
    tithiName: _tithiNames[tithiIndex],
    paksha: paksha,
    nakshatra: Nakshatra.fromLongitude(moonLongitude),
    pada: Nakshatra.padaFromLongitude(moonLongitude),
    yogaIndex: yogaIndex,
    yogaName: _yogaNames[yogaIndex],
    karanaName: karana,
    vara: _varaNames[localDateTime.weekday - 1],
  );
}

double _norm(double deg) {
  var d = deg % 360;
  if (d < 0) d += 360;
  return d;
}
