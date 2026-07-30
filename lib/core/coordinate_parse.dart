/// Flexible latitude/longitude parsing for manual place entry.
///
/// Astrology references print birth coordinates in DMS, not decimal —
/// "18N50'00", "72E50'00", "18º58'N" — so the manual-entry fields must
/// accept whatever a user copies out of a book or Parashara's Light,
/// alongside plain decimal degrees.
library;

/// Parses [input] as a latitude (`isLatitude: true`) or longitude.
///
/// Accepted forms (case-insensitive, symbols interchangeable):
///  * decimal degrees: `18.9667`, `-72.5`
///  * DMS with hemisphere letter before, between, or after the numbers:
///    `18N50'00`, `72E50'00`, `18º58'N`, `N 18 58 30`, `18°58'30"S`
///  * bare DMS separated by ° ' " : or spaces: `18 58 30` (sign from a
///    leading minus)
///
/// Returns decimal degrees (south/west negative), or null when the text
/// isn't parseable, mixes conflicting signs, uses the wrong axis letter
/// (an E/W in a latitude), or has minutes/seconds ≥ 60. Range (±90/±180)
/// is left to the caller, which already validates it.
double? parseCoordinate(String input, {required bool isLatitude}) {
  var s = input.trim().toUpperCase();
  if (s.isEmpty) return null;

  // Hemisphere letter: N/S for latitude, E/W for longitude. A letter from
  // the other axis means the value landed in the wrong field — reject so
  // the mistake surfaces instead of silently mis-signing a chart.
  final own = isLatitude ? 'NS' : 'EW';
  final other = isLatitude ? 'EW' : 'NS';
  int? hemisphereSign;
  final chars = s.split('');
  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    if (other.contains(c)) return null;
    if (own.contains(c)) {
      if (hemisphereSign != null) return null; // two hemisphere letters
      hemisphereSign = (c == 'N' || c == 'E') ? 1 : -1;
      chars[i] = ' ';
    }
  }
  s = chars.join();

  // A leading minus is the decimal-style sign; conflicting with an
  // explicit hemisphere letter is ambiguous — reject.
  var minusSign = 1;
  s = s.trim();
  if (s.startsWith('+')) s = s.substring(1);
  if (s.startsWith('-')) {
    if (hemisphereSign != null) return null;
    minusSign = -1;
    s = s.substring(1);
  }
  if (s.contains('-') || s.contains('+')) return null;

  // Degree/minute/second markers (and their unicode look-alikes) all
  // become plain separators; what remains must be 1–3 numbers.
  s = s.replaceAll(RegExp('[°º˚⁰*:\'′’"″”,;]'), ' ');
  final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty || parts.length > 3) return null;

  final numbers = <double>[];
  for (final p in parts) {
    final v = double.tryParse(p);
    if (v == null || v < 0) return null;
    numbers.add(v);
  }
  // Only the last component may carry a fraction ("18 58.5" is fine,
  // "18.5 30" is not).
  for (var i = 0; i < numbers.length - 1; i++) {
    if (numbers[i] != numbers[i].truncateToDouble()) return null;
  }
  if (numbers.length > 1 && numbers[1] >= 60) return null;
  if (numbers.length > 2 && numbers[2] >= 60) return null;

  final value = numbers[0] +
      (numbers.length > 1 ? numbers[1] / 60 : 0) +
      (numbers.length > 2 ? numbers[2] / 3600 : 0);
  return value * (hemisphereSign ?? minusSign);
}
