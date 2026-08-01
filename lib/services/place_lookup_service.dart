/// Place typeahead: name → lat/long + IANA timezone (Open-Meteo
/// geocoding, free & keyless), then the historical UTC offset at the
/// birth instant via the tz database (handles old DST rules).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
// latest_all (596 zones), NOT latest (431): the trimmed set is missing
// CURRENT zones our own geocoder returns — Asia/Yangon (~5M people),
// America/Ciudad_Juarez, Barnaul, Tomsk, Atyrau, Punta_Arenas, Nuuk,
// Famagusta… — and a missing zone made tz.getLocation throw, killing
// chart creation for those birthplaces entirely (P0, found 2026-07-15;
// India-only testing never caught it because Asia/Kolkata IS in the
// trimmed set). Costs +114KB. See test/place_timezone_test.dart.
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.admin,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezoneName,
  });

  final String name;
  final String admin;
  final String country;
  final double latitude;
  final double longitude;
  final String timezoneName;

  /// Empty parts are dropped rather than joined: the geocoder can return
  /// a place with no country (or no name), and the old form emitted a
  /// dangling "Pune, " for those. Dropping them also lets
  /// [placeFromStoredName] round-trip a stored place string exactly.
  String get displayName =>
      [name, admin, country].where((p) => p.isNotEmpty).join(', ');
}

/// Rebuilds a [PlaceResult] from what a saved kundli stores: the place
/// STRING plus its coordinates and zone.
///
/// The split is chosen so [PlaceResult.displayName] reconstitutes
/// [placeName] character for character — re-picking a recent place must
/// save the same text the earlier chart carries, or the two charts would
/// disagree about a place the user believes is one place. [name] takes
/// the first segment so the summary line's short name is the city.
PlaceResult placeFromStoredName({
  required String placeName,
  required double latitude,
  required double longitude,
  required String timezoneName,
}) {
  final parts = [
    for (final p in placeName.split(',')) p.trim(),
  ]..removeWhere((p) => p.isEmpty);
  return PlaceResult(
    name: parts.isEmpty ? placeName.trim() : parts.first,
    admin:
        parts.length > 2 ? parts.sublist(1, parts.length - 1).join(', ') : '',
    country: parts.length > 1 ? parts.last : '',
    latitude: latitude,
    longitude: longitude,
    timezoneName: timezoneName,
  );
}

class PlaceLookupService {
  static bool _tzReady = false;

  static void _ensureTz() {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
  }

  Future<List<PlaceResult>> search(String query) async {
    if (query.trim().length < 2) return [];
    final uri = Uri.parse(kGeocodingEndpoint).replace(queryParameters: {
      'name': query.trim(),
      'count': '8',
      'language': 'en',
      'format': 'json',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] as List?) ?? [];
    return [
      for (final r in results.cast<Map<String, dynamic>>())
        PlaceResult(
          name: (r['name'] as String?) ?? '',
          admin: (r['admin1'] as String?) ?? '',
          country: (r['country'] as String?) ?? '',
          latitude: (r['latitude'] as num).toDouble(),
          longitude: (r['longitude'] as num).toDouble(),
          timezoneName: (r['timezone'] as String?) ?? 'UTC',
        ),
    ];
  }

  /// All IANA zone names in the bundled (full) tz database, sorted —
  /// backs the manual place entry's timezone picker. The geocoder is a
  /// single point of failure for chart creation (an unfound village
  /// blocks the kundli entirely), so manual entry must not depend on it.
  List<String> allTimezoneNames() {
    _ensureTz();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  bool isValidTimezone(String name) {
    _ensureTz();
    return tz.timeZoneDatabase.locations.containsKey(name);
  }

  /// IANA zone for a coordinate — offline polygon lookup
  /// (lat_lng_to_timezone), so manual place entry can derive the zone
  /// from lat/long instead of asking the user for it. Returns null if
  /// the mapped name isn't in our tz database (dataset drift) — the
  /// caller keeps its manual override field for that case.
  String? timezoneForLatLng(double latitude, double longitude) {
    final name = tzmap.latLngToTimezoneString(latitude, longitude);
    return isValidTimezone(name) ? name : null;
  }

  /// UTC offset (minutes) in [timezoneName] at a given UTC instant —
  /// the inverse direction of [resolveLocalTime] (used e.g. for the
  /// varsha pravesh instant, whose offset may differ from birth's own
  /// when the zone has DST).
  int offsetMinutesAtUtc(String timezoneName, DateTime utc) {
    _ensureTz();
    return tz.TZDateTime.from(utc, tz.getLocation(timezoneName))
        .timeZoneOffset
        .inMinutes;
  }

  /// UTC offset (minutes) in [timezoneName] at the given LOCAL wall
  /// time, plus the resolved UTC instant and the zone's abbreviation at
  /// that instant.
  ///
  /// [abbreviation] is null when the zone has no real abbreviation for
  /// that moment — see [zoneAbbreviation]. Callers that show it must
  /// then fall back to the bare offset rather than inventing a name.
  ({int offsetMinutes, DateTime utc, String? abbreviation}) resolveLocalTime(
    String timezoneName,
    DateTime localWallTime,
  ) {
    _ensureTz();
    final location = tz.getLocation(timezoneName);
    final local = tz.TZDateTime(
      location,
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
    );
    return (
      offsetMinutes: local.timeZoneOffset.inMinutes,
      utc: local.toUtc(),
      abbreviation: zoneAbbreviation(local.timeZoneName),
    );
  }
}

/// A zone's abbreviation, or null when tz has none for that instant.
///
/// The tz database reports either a real abbreviation ("IST", "EDT",
/// "GMT", "JST") or a NUMERIC stand-in when the zone has never had a
/// letter form — "+0630" for 1943 Kolkata war time and for Yangon,
/// "+0845" for Eucla. The numeric form is not an abbreviation; showing
/// it as one would put "+0630 +06:30" on screen, and inventing a letter
/// name for it would be worse. Null means "say the offset alone".
String? zoneAbbreviation(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return null;
  return (name.startsWith('+') || name.startsWith('-')) ? null : name;
}
