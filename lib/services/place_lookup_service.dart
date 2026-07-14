/// Place typeahead: name → lat/long + IANA timezone (Open-Meteo
/// geocoding, free & keyless), then the historical UTC offset at the
/// birth instant via the tz database (handles old DST rules).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tzdata;
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
