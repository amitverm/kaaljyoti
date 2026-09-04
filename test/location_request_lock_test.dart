/// Two overlapping location requests must never overlap their permission
/// prompts: geolocator's Android permission manager holds one pending
/// callback, and a second prompt makes it answer the same method-channel
/// reply twice — fatal `IllegalStateException: Reply already submitted`
/// (KAALJYOTI-PROD-V).
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:kaaljyoti/services/current_location_service.dart';
import 'package:kaaljyoti/services/location_request_lock.dart';
import 'package:kaaljyoti/services/location_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  LocationPermission permission = LocationPermission.denied;
  int requestCalls = 0;
  int inFlight = 0;
  int maxInFlight = 0;
  final pendingRequests = <Completer<void>>[];

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCalls++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    final completer = Completer<void>();
    pendingRequests.add(completer);
    await completer.future;
    inFlight--;
    permission = LocationPermission.whileInUse;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      Position(
        longitude: 77.2,
        latitude: 28.6,
        timestamp: DateTime.utc(2026),
        accuracy: 100,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // LocationService also asks the device for its IANA timezone; on the
  // host VM that plugin doesn't exist.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter_timezone'),
    (call) async => 'Asia/Kolkata',
  );

  group('withLocationLock', () {
    test('runs bodies one after another, in order', () async {
      final log = <String>[];
      final gate = Completer<void>();
      final first = withLocationLock(() async {
        log.add('first start');
        await gate.future;
        log.add('first end');
        return 1;
      });
      final second = withLocationLock(() async {
        log.add('second start');
        return 2;
      });
      await Future<void>.delayed(Duration.zero);
      expect(log, ['first start']);
      gate.complete();
      expect(await first, 1);
      expect(await second, 2);
      expect(log, ['first start', 'first end', 'second start']);
    });

    test('a failing body releases the lock and only fails its own caller',
        () async {
      final failing = withLocationLock<int>(() async => throw StateError('x'));
      final next = withLocationLock(() async => 'ok');
      await expectLater(failing, throwsStateError);
      expect(await next, 'ok');
    });
  });

  group('permission prompts are serialised across both services', () {
    late _FakeGeolocator fake;

    setUp(() {
      fake = _FakeGeolocator();
      GeolocatorPlatform.instance = fake;
    });

    test('Today auto-detect racing a "use current location" tap', () async {
      final auto = CurrentLocationService.detect();
      final tap = CurrentLocationService.detect();
      await Future<void>.delayed(Duration.zero);

      // Only one prompt is open; the second caller is queued behind it.
      expect(fake.requestCalls, 1);
      expect(fake.pendingRequests, hasLength(1));

      fake.pendingRequests.single.complete();
      final places = await Future.wait([auto, tap]);

      expect(places.every((p) => p != null), isTrue);
      expect(fake.maxInFlight, 1);
      // The queued caller found the permission already granted and never
      // needed a prompt of its own.
      expect(fake.requestCalls, 1);
    });

    test('a Prashna cast waits for Today\'s prompt instead of overlapping it',
        () async {
      final today = CurrentLocationService.detect();
      final prashna = LocationService().currentPlace();
      await Future<void>.delayed(Duration.zero);
      expect(fake.requestCalls, 1);

      fake.pendingRequests.single.complete();
      expect(await today, isNotNull);
      final place = await prashna;
      expect(place.latitude, 28.6);
      expect(fake.maxInFlight, 1);
      expect(fake.requestCalls, 1);
    });
  });
}
