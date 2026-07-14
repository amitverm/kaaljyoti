/// The 28-nakshatra scheme (with Abhijit) used by the nakshatra
/// chakras — Kota, Sarvatobhadra, etc. The regular 27-scheme lives on
/// [Nakshatra]; this file only adds Abhijit and the index mapping.
///
/// Abhijit spans the last quarter of Uttara Ashadha plus the first
/// 1/15th of Shravana: 276°40′ – 280°53′20″ (the JHora convention).
/// Shravana is correspondingly truncated to start at 280°53′20″.
library;

import 'models.dart';

/// 0-based 28-scheme index: Ashwini 0 … Uttara Ashadha 20, Abhijit 21,
/// Shravana 22 … Revati 27.
class Nakshatra28 {
  Nakshatra28._();

  static const int abhijitIndex = 21;
  static const double abhijitStart = 276 + 40 / 60; // 276°40'
  static const double abhijitEnd = 280 + 53 / 60 + 20 / 3600; // 280°53'20"

  static const List<String> names = [
    'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
    'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni',
    'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha',
    'Jyeshtha', 'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Abhijit',
    'Shravana', 'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada',
    'Uttara Bhadrapada', 'Revati',
  ];

  static const List<String> abbrs = [
    'Ash', 'Bha', 'Kri', 'Roh', 'Mri', 'Ard', 'Pun', 'Pus', 'Asl', 'Mag',
    'PPh', 'UPh', 'Has', 'Chi', 'Swa', 'Vis', 'Anu', 'Jye', 'Mul', 'PSh',
    'USh', 'Abh', 'Shr', 'Dha', 'Sat', 'PBh', 'UBh', 'Rev',
  ];

  static int fromLongitude(double siderealLongitude) {
    var l = siderealLongitude % 360;
    if (l < 0) l += 360;
    if (l >= abhijitStart && l < abhijitEnd) return abhijitIndex;
    final n27 = (l / Nakshatra.span).floor() % 27;
    // 27-scheme indices ≥ 21 (Shravana onward) shift past Abhijit.
    return n27 >= 21 ? n27 + 1 : n27;
  }

  /// Count [from] → [to] inclusive, 1-based, wrapping over 28
  /// ("Janma = 1st").
  static int countFrom(int from, int to) => ((to - from + 28) % 28) + 1;
}
