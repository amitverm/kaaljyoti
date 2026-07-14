/// Detects the device's current location for Today's panchang place.
///
/// Coarse accuracy is deliberately enough — one minute of sunrise is
/// ~18 km of longitude — and every failure path (services off,
/// permission denied, timeout, aircraft mode) returns null so the
/// caller falls back to the saved/default city and the "set your
/// city" nudge.
library;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/settings_repository.dart';

class CurrentLocationService {
  CurrentLocationService._();

  static Future<TodayPlace?> detect() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 12));

      // Best-effort city name via the OS geocoder; coordinates matter,
      // the label is cosmetic.
      var name = 'Current location';
      try {
        final marks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final m = marks.first;
          name = [
            if ((m.locality ?? '').isNotEmpty)
              m.locality!
            else if ((m.subAdministrativeArea ?? '').isNotEmpty)
              m.subAdministrativeArea!,
            if ((m.administrativeArea ?? '').isNotEmpty)
              m.administrativeArea!,
          ].join(', ');
          if (name.isEmpty) name = 'Current location';
        }
      } catch (_) {}

      return TodayPlace(
        name: name,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
