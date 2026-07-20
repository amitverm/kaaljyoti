/// The P0 timezone regression (found 2026-07-15): the app bundled the
/// TRIMMED tz dataset (`latest.dart`, 431 zones), which is missing
/// CURRENT zones the Open-Meteo geocoder actually returns — so
/// `tz.getLocation` threw and chart creation crashed for those
/// birthplaces. These tests pin the fix (`latest_all.dart`) by
/// resolving a corpus of geocoder-returned zones, including every zone
/// the global-births audit verified live against Open-Meteo, with
/// Asia/Kolkata as the control that made India-only testing blind to
/// the bug.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/services/place_lookup_service.dart';

/// Zones verified live as Open-Meteo responses in the global-births
/// audit — every one of these was MISSING from the trimmed dataset.
const auditMissingZones = [
  'Asia/Yangon', // ~5M people
  'America/Ciudad_Juarez', // ~1.5M — split from Ojinaga in tzdb 2022g
  'Asia/Barnaul',
  'Asia/Tomsk',
  'Asia/Atyrau',
  'America/Punta_Arenas',
  'America/Nuuk',
  'Asia/Famagusta',
];

/// A broad world corpus of zones the geocoder returns for major cities.
const worldZones = [
  'Asia/Kolkata', // the control — present even in the trimmed set
  'Asia/Karachi',
  'Asia/Kathmandu', // :45 offset
  'Asia/Colombo',
  'Asia/Dhaka',
  'Asia/Dubai',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Asia/Tehran',
  'Australia/Sydney',
  'Australia/Eucla', // +08:45 oddity
  'Pacific/Auckland',
  'Pacific/Chatham', // :45 offset
  'Europe/London',
  'Europe/Berlin',
  'Europe/Moscow',
  'Africa/Lagos',
  'Africa/Nairobi',
  'Africa/Johannesburg',
  'America/New_York',
  'America/Chicago',
  'America/Los_Angeles',
  'America/Mexico_City',
  'America/Sao_Paulo',
  'America/Argentina/Buenos_Aires',
  'America/St_Johns', // -x:30 offset
];

void main() {
  final svc = PlaceLookupService();

  test('every audit-verified geocoder zone resolves (the P0 crash)', () {
    for (final zone in auditMissingZones) {
      final r = svc.resolveLocalTime(zone, DateTime(1990, 8, 15, 10, 30));
      expect(r.utc.isUtc, true, reason: zone);
    }
  });

  test('world corpus resolves with sane offsets', () {
    for (final zone in worldZones) {
      final r = svc.resolveLocalTime(zone, DateTime(2000, 6, 1, 12, 0));
      expect(r.offsetMinutes.abs() <= 14 * 60, true,
          reason: '$zone gave ${r.offsetMinutes}min');
    }
  });

  test('historic offsets survive the dataset switch', () {
    // Kolkata control: modern IST +05:30…
    final ist =
        svc.resolveLocalTime('Asia/Kolkata', DateTime(1990, 8, 15, 10, 30));
    expect(ist.offsetMinutes, 330);
    // …and the 1943 War Time interval (+06:30), the audit's verified
    // historic case — trimmed vs full datasets share history for zones
    // both carry; this pins that the switch changed nothing for them.
    final warTime =
        svc.resolveLocalTime('Asia/Kolkata', DateTime(1943, 6, 1, 12, 0));
    expect(warTime.offsetMinutes, 390);
    // Yangon's +06:30 — a zone the trimmed set lacked entirely.
    final yangon =
        svc.resolveLocalTime('Asia/Yangon', DateTime(2000, 1, 1, 12, 0));
    expect(yangon.offsetMinutes, 390);
  });
}
