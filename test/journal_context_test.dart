/// The astro context frozen onto a journal entry.
///
/// Two properties matter more than the numbers here. The persisted keys
/// must be STABLE identifiers — an entry written in the Hindi locale has
/// to read correctly in English years later, so nothing localized may
/// reach the JSON. And decoding must be TOTAL — a truncated, foreign or
/// future-versioned context downgrades the entry to "no chips", never to
/// an exception on a screen the astrologer needs.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/dasha/dasha.dart';
import 'package:kaaljyoti/core/astro/journal_context.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

/// A natal chart with the Moon in Pushya (100°) — Vimshottari therefore
/// opens in Saturn's mahadasha, which is what the chain assertions lean on.
AstroSnapshot _natal(DateTime birthUtc) {
  const longs = {
    Planet.sun: 10.0,
    Planet.moon: 100.0,
    Planet.mars: 220.0,
    Planet.mercury: 25.0,
    Planet.jupiter: 130.0,
    Planet.venus: 355.0,
    Planet.saturn: 300.0,
    Planet.rahu: 180.0,
    Planet.ketu: 0.0,
  };
  return AstroSnapshot(
    birth: BirthData(
      dateTimeUtc: birthUtc,
      latitude: 28.6,
      longitude: 77.2,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
    ),
    ayanamsaId: 1,
    ayanamsaValue: 24.1,
    positions: {
      for (final e in longs.entries)
        e.key: PlanetPosition(
            planet: e.key, longitude: e.value, latitude: 0, speed: 1),
    },
    ascendant: 95.0,
    houseCusps: List.filled(12, 0.0),
    panchang: computePanchang(
        sunLongitude: 10, moonLongitude: 100, localDateTime: DateTime(1992)),
    yogas: const [],
  );
}

/// A stand-in for the Swiss Ephemeris — the native library cannot load in
/// host `flutter test`, and the mapping under test is longitude → sign,
/// not the longitudes themselves.
Map<Planet, PlanetPosition> _fixedSky(DateTime at, int ayanamsaId) => {
      for (final e in const {
        Planet.sun: 5.0, // Aries
        Planet.moon: 100.0, // Cancer / Pushya
        Planet.mars: 35.0, // Taurus
        Planet.mercury: 65.0, // Gemini
        Planet.jupiter: 95.0, // Cancer
        Planet.venus: 125.0, // Leo
        Planet.saturn: 155.0, // Virgo
        Planet.rahu: 185.0, // Libra
        Planet.ketu: 5.0, // Aries
      }.entries)
        e.key: PlanetPosition(
            planet: e.key, longitude: e.value, latitude: 0, speed: 1),
    };

JournalContext _sample() => JournalContext(
      dashaSystem: DashaSystem.vimshottari,
      chain: [
        JournalDashaStep(
          level: 1,
          planet: Planet.saturn,
          start: DateTime.utc(2020, 5, 1),
          end: DateTime.utc(2039, 5, 1),
        ),
        const JournalDashaStep(level: 2, planet: Planet.venus),
        const JournalDashaStep(level: 3, planet: Planet.moon),
      ],
      sky: const {
        Planet.sun: ZodiacSign.pisces,
        Planet.jupiter: ZodiacSign.gemini,
      },
      moonSign: ZodiacSign.cancer,
      moonNakshatra: Nakshatra.pushya,
    );

void main() {
  test('the encoded payload uses stable identifiers only', () {
    final json = jsonDecode(_sample().encode()) as Map<String, Object?>;

    expect(json['v'], kJournalContextVersion);
    final dasha = json['dasha'] as Map<String, Object?>;
    expect(dasha['system'], 'vimshottari');

    final chain = (dasha['chain'] as List).cast<Map<String, Object?>>();
    expect(chain.map((s) => s['lord']), ['saturn', 'venus', 'moon']);
    expect(chain.map((s) => s['level']), [1, 2, 3]);
    // ISO-8601 in UTC — a local-time string would silently shift when the
    // entry is read on a device in another zone.
    expect(chain.first['start'], '2020-05-01T00:00:00.000Z');

    expect(json['sky'], {'sun': 'pisces', 'jupiter': 'gemini'});
    expect(json['moon'], {'sign': 'cancer', 'nakshatra': 'pushya'});

    // Nothing display-facing: no 'Saturn', no 'शनि', no 'Mahadasha'.
    final raw = _sample().encode();
    for (final label in ['Saturn', 'Cancer', 'Pushya', 'Mahadasha']) {
      expect(raw, isNot(contains(label)), reason: label);
    }
  });

  test('encode → decode is lossless', () {
    final decoded = JournalContext.decode(_sample().encode())!;

    expect(decoded.dashaSystem, DashaSystem.vimshottari);
    expect([for (final s in decoded.chain) s.planet],
        [Planet.saturn, Planet.venus, Planet.moon]);
    expect(decoded.chain.first.level, 1);
    expect(decoded.chain.first.start, DateTime.utc(2020, 5, 1));
    expect(decoded.chain.first.end, DateTime.utc(2039, 5, 1));
    expect(decoded.sky[Planet.jupiter], ZodiacSign.gemini);
    expect(decoded.moonSign, ZodiacSign.cancer);
    expect(decoded.moonNakshatra, Nakshatra.pushya);
  });

  test('sign-lorded chain steps survive the round trip', () {
    // Vimshottari is what the app captures today, but the shape carries
    // rashi lords so a Jaimini context wouldn't need a schema bump.
    const step = JournalDashaStep(level: 1, sign: ZodiacSign.libra);
    const ctx =
        JournalContext(dashaSystem: DashaSystem.jaimini, chain: [step]);
    final decoded = JournalContext.decode(ctx.encode())!;
    expect(decoded.chain.single.sign, ZodiacSign.libra);
    expect(decoded.chain.single.planet, isNull);
  });

  group('capture', () {
    final birth = DateTime.utc(1992, 1, 15, 6, 30);

    test('records the chain running on the ENTRY date, not on birth', () {
      final early = buildJournalContext(
        snapshot: _natal(birth),
        at: DateTime.utc(1993, 6, 1),
        skyAt: _fixedSky,
      );
      final late_ = buildJournalContext(
        snapshot: _natal(birth),
        at: DateTime.utc(2026, 3, 14),
        skyAt: _fixedSky,
      );

      expect(early.chain.first.planet, Planet.saturn,
          reason: 'Moon in Pushya opens the Saturn mahadasha');
      // 34 years on, the chain must have moved — a context computed at
      // birth (or at "now" for a backdated entry) would not.
      expect(late_.chain.first.planet, isNot(Planet.saturn));
      expect(late_.chain.map((s) => s.planet),
          isNot(early.chain.map((s) => s.planet)));
    });

    test('captures three levels, chronologically nested', () {
      final ctx = buildJournalContext(
        snapshot: _natal(birth),
        at: DateTime.utc(2026, 3, 14),
        skyAt: _fixedSky,
      );

      expect(ctx.dashaSystem, DashaSystem.vimshottari);
      expect(ctx.chain.map((s) => s.level), [1, 2, 3],
          reason: 'maha, antar, pratyantar — deeper periods turn over daily');
      for (final s in ctx.chain) {
        expect(s.start!.isBefore(DateTime.utc(2026, 3, 14)), isTrue);
        expect(s.end!.isAfter(DateTime.utc(2026, 3, 14)), isTrue);
      }
      // Each level sits inside its parent.
      expect(ctx.chain[1].start!.isBefore(ctx.chain[0].start!), isFalse);
      expect(ctx.chain[2].end!.isAfter(ctx.chain[1].end!), isFalse);
    });

    test('captures the sky and the Moon for the entry date', () {
      final ctx = buildJournalContext(
        snapshot: _natal(birth),
        at: DateTime.utc(2026, 3, 14),
        skyAt: _fixedSky,
      );

      expect(ctx.sky, hasLength(9));
      expect(ctx.sky[Planet.saturn], ZodiacSign.virgo);
      expect(ctx.sky[Planet.jupiter], ZodiacSign.cancer);
      expect(ctx.moonSign, ZodiacSign.cancer);
      expect(ctx.moonNakshatra, Nakshatra.pushya);

      // And the captured context survives the trip through storage.
      final decoded = JournalContext.decode(ctx.encode())!;
      expect(decoded.sky, ctx.sky);
      expect(
          decoded.chain.map((s) => s.planet), ctx.chain.map((s) => s.planet));
    });

    test('a date outside the dasha range still yields a usable context', () {
      // 200 years on there is no Vimshottari period left (the cycle is
      // 120 years). The sky is still meaningful, so the entry keeps it.
      final ctx = buildJournalContext(
        snapshot: _natal(birth),
        at: DateTime.utc(2192),
        skyAt: _fixedSky,
      );
      expect(ctx.chain, isEmpty);
      expect(ctx.sky, hasLength(9));
      expect(JournalContext.decode(ctx.encode()), isNotNull);
    });
  });

  group('decoding never throws', () {
    test('null and blank input yield null', () {
      expect(JournalContext.decode(null), isNull);
      expect(JournalContext.decode(''), isNull);
      expect(JournalContext.decode('   '), isNull);
    });

    test('malformed and foreign JSON yield null', () {
      for (final bad in [
        '{"v":1,"sky":',
        'not json at all',
        '[1,2,3]',
        '"a string"',
        '{}',
        '{"v":"one"}',
      ]) {
        expect(JournalContext.decode(bad), isNull, reason: bad);
      }
    });

    test('a newer schema version is refused rather than misread', () {
      final future = jsonEncode({
        'v': kJournalContextVersion + 1,
        'moon': {'sign': 'cancer'},
      });
      expect(JournalContext.decode(future), isNull);
    });

    test('unknown enum names are dropped, the rest still reads', () {
      final mixed = jsonEncode({
        'v': 1,
        'dasha': {
          'system': 'someFutureSystem',
          'chain': [
            {'level': 1, 'lord': 'saturn'},
            {'level': 2, 'lord': 'planetX'}, // unknown graha
            {'lord': 'venus'}, // no level — not a usable step
            'nonsense',
          ],
        },
        'sky': {'sun': 'pisces', 'sun2': 'ophiuchus', 'moon': 'notASign'},
        'moon': {'sign': 'cancer', 'nakshatra': 'notANakshatra'},
      });

      final ctx = JournalContext.decode(mixed)!;
      expect(ctx.dashaSystem, isNull);
      expect(ctx.chain, hasLength(2));
      expect(ctx.chain[1].planet, isNull, reason: 'unknown lord drops out');
      expect(ctx.sky, {Planet.sun: ZodiacSign.pisces});
      expect(ctx.moonSign, ZodiacSign.cancer);
      expect(ctx.moonNakshatra, isNull);
    });

    test('a context with nothing usable left reads as no context', () {
      final empty = jsonEncode({
        'v': 1,
        'sky': {'sun2': 'ophiuchus'},
      });
      expect(JournalContext.decode(empty), isNull,
          reason: 'an empty context and a missing one are the same thing');
    });
  });
}
