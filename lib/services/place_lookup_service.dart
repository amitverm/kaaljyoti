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

  String get displayName =>
      [name, if (admin.isNotEmpty) admin, country].join(', ');
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
  /// time, plus the resolved UTC instant.
  ({int offsetMinutes, DateTime utc}) resolveLocalTime(
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
    );
  }
}
