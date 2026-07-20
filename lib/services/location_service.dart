/// Current-location resolution for "use current location" (birth
/// entry) and instant Prashna kundlis. Coarse accuracy is plenty —
/// astrology needs city-level precision. Reverse geocoding via
/// BigDataCloud's keyless client endpoint; IANA timezone from the
/// device (for a chart cast at the current location, device tz is
/// the location tz).
library;

import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'place_lookup_service.dart';

class LocationDenied implements Exception {
  const LocationDenied(this.permanently);
  final bool permanently;
}

class LocationService {
  /// Resolve the device's current position into a [PlaceResult].
  Future<PlaceResult> currentPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationDenied(false);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationDenied(false);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationDenied(true);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // city-level is enough
      ),
    ).timeout(const Duration(seconds: 15));

    final tz = await FlutterTimezone.getLocalTimezone();
    final (name, admin, country) =
        await _reverseGeocode(position.latitude, position.longitude);

    return PlaceResult(
      name: name,
      admin: admin,
      country: country,
      latitude: position.latitude,
      longitude: position.longitude,
      timezoneName: tz,
    );
  }

  Future<(String, String, String)> _reverseGeocode(
      double lat, double lon) async {
    try {
      final uri =
          Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client'
              '?latitude=$lat&longitude=$lon&localityLanguage=en');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final locality = (body['city'] as String?)?.isNotEmpty == true
            ? body['city'] as String
            : (body['locality'] as String?) ?? '';
        return (
          locality.isEmpty ? 'Current location' : locality,
          (body['principalSubdivision'] as String?) ?? '',
          (body['countryName'] as String?) ?? '',
        );
      }
    } catch (_) {
      // Fall through to coordinate label.
    }
    return (
      '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}',
      '',
      '',
    );
  }
}
