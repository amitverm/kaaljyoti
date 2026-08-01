/// The astro context frozen onto a journal entry: which Vimshottari
/// periods were running on the entry's date, and where the grahas stood
/// in the sky that day.
///
/// Two rules shape this file.
///
/// 1. **Stable keys only.** Everything persisted here is an enum `.name`
///    or an ISO-8601 timestamp — never localized display text. The entry
///    outlives the language the app happened to be in when it was
///    written, and a Hindi-locale entry must still read correctly in
///    English (and vice versa). Rendering localizes at draw time via the
///    helpers in l10n/astro_l10n.dart.
/// 2. **Decoding never throws.** Context is an enrichment, not the
///    content: an entry whose `context_json` is missing, truncated, or
///    written by a future schema still renders — just without chips. So
///    [decode] returns null rather than raising, and unknown enum names
///    are dropped instead of failing the whole parse.
library;

import 'dart:convert';

import 'dasha/dasha.dart';
import 'dasha/dasha_registry.dart';
import 'ephemeris_service.dart';
import 'models.dart';

/// Current payload schema. Bumped only on a breaking shape change;
/// [JournalContext.fromJson] refuses versions it does not understand
/// rather than guessing at an unfamiliar layout.
const int kJournalContextVersion = 1;

/// One level of the running dasha chain (1 = mahadasha, 2 = antardasha, …).
/// [planet] and [sign] are alternatives — Vimshottari lords are planets,
/// but the shape leaves room for the sign-based systems.
class JournalDashaStep {
  const JournalDashaStep({
    required this.level,
    this.planet,
    this.sign,
    this.start,
    this.end,
  });

  final int level;
  final Planet? planet;
  final ZodiacSign? sign;
  final DateTime? start;
  final DateTime? end;

  Map<String, Object?> toJson() => {
        'level': level,
        if (planet != null) 'lord': planet!.name,
        if (sign != null) 'sign': sign!.name,
        if (start != null) 'start': start!.toUtc().toIso8601String(),
        if (end != null) 'end': end!.toUtc().toIso8601String(),
      };

  static JournalDashaStep? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final level = raw['level'];
    if (level is! int) return null;
    return JournalDashaStep(
      level: level,
      planet: _byName(Planet.values, raw['lord']),
      sign: _byName(ZodiacSign.values, raw['sign']),
      start: _parseDate(raw['start']),
      end: _parseDate(raw['end']),
    );
  }
}

/// The snapshot of "what was running" on a journal entry's date.
class JournalContext {
  const JournalContext({
    this.dashaSystem,
    this.chain = const [],
    this.sky = const {},
    this.moonSign,
    this.moonNakshatra,
  });

  /// The dasha system the [chain] came from — recorded so a later change
  /// of default system doesn't silently relabel old entries.
  final DashaSystem? dashaSystem;

  /// Running periods, outermost first: maha, antar, pratyantar.
  final List<JournalDashaStep> chain;

  /// Transit sign per graha on the entry's date.
  final Map<Planet, ZodiacSign> sky;

  final ZodiacSign? moonSign;
  final Nakshatra? moonNakshatra;

  bool get isEmpty =>
      chain.isEmpty && sky.isEmpty && moonSign == null && moonNakshatra == null;

  Map<String, Object?> toJson() => {
        'v': kJournalContextVersion,
        if (dashaSystem != null || chain.isNotEmpty)
          'dasha': {
            if (dashaSystem != null) 'system': dashaSystem!.name,
            'chain': [for (final s in chain) s.toJson()],
          },
        if (sky.isNotEmpty)
          'sky': {
            for (final e in sky.entries) e.key.name: e.value.name,
          },
        if (moonSign != null || moonNakshatra != null)
          'moon': {
            if (moonSign != null) 'sign': moonSign!.name,
            if (moonNakshatra != null) 'nakshatra': moonNakshatra!.name,
          },
      };

  String encode() => jsonEncode(toJson());

  /// Parse a stored `context_json`. Returns null for null/blank input and
  /// for anything that isn't a context this build understands — callers
  /// render the entry regardless.
  static JournalContext? decode(String? jsonText) {
    if (jsonText == null || jsonText.trim().isEmpty) return null;
    try {
      return fromJson(jsonDecode(jsonText));
    } catch (_) {
      return null;
    }
  }

  static JournalContext? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final v = raw['v'];
    if (v is! int || v > kJournalContextVersion) return null;

    final dasha = raw['dasha'];
    final chainRaw = dasha is Map ? dasha['chain'] : null;
    final chain = <JournalDashaStep>[];
    if (chainRaw is List) {
      for (final s in chainRaw) {
        final step = JournalDashaStep.fromJson(s);
        if (step != null) chain.add(step);
      }
    }

    final sky = <Planet, ZodiacSign>{};
    final skyRaw = raw['sky'];
    if (skyRaw is Map) {
      for (final e in skyRaw.entries) {
        final planet = _byName(Planet.values, e.key);
        final sign = _byName(ZodiacSign.values, e.value);
        if (planet != null && sign != null) sky[planet] = sign;
      }
    }

    final moon = raw['moon'];
    final context = JournalContext(
      dashaSystem:
          dasha is Map ? _byName(DashaSystem.values, dasha['system']) : null,
      chain: chain,
      sky: sky,
      moonSign: moon is Map ? _byName(ZodiacSign.values, moon['sign']) : null,
      moonNakshatra:
          moon is Map ? _byName(Nakshatra.values, moon['nakshatra']) : null,
    );
    return context.isEmpty ? null : context;
  }
}

/// Sidereal positions of the nine grahas at an instant, for a given
/// ayanamsa. Injectable so [buildJournalContext] can be exercised without
/// the native Swiss Ephemeris, which host `flutter test` cannot load.
typedef SkyAt = Map<Planet, PlanetPosition> Function(
    DateTime at, int ayanamsaId);

Map<Planet, PlanetPosition> _ephemerisSky(DateTime at, int ayanamsaId) {
  final eph = EphemerisService.instance;
  return eph.planetPositions(eph.julianDayUt(at.toUtc()), ayanamsaId);
}

/// Compute the context for [at] from a chart's birth [snapshot].
///
/// The dasha chain comes from the natal snapshot (periods are a lifetime
/// timeline — only the lookup date changes), while the sky is recomputed
/// for the entry's own instant, at the chart's ayanamsa so it lines up
/// with everything else the astrologer sees for that kundli.
///
/// Runs on the main isolate: sweph is not thread-safe, so this must never
/// be moved into an Isolate.
JournalContext buildJournalContext({
  required AstroSnapshot snapshot,
  required DateTime at,
  SkyAt? skyAt,
  DashaSystem system = DashaSystem.vimshottari,
}) {
  final result = dashaCalculators[system]!.calculate(snapshot);
  // Three levels is what a practitioner writes down ("Sa–Ve–Mo"); deeper
  // periods turn over within a day and would date the entry, not describe it.
  final chain = result.chainAt(at).take(3);

  final positions = (skyAt ?? _ephemerisSky)(at, snapshot.ayanamsaId);
  final moon = positions[Planet.moon];

  return JournalContext(
    dashaSystem: system,
    chain: [
      for (final p in chain)
        JournalDashaStep(
          level: p.level,
          planet: p.planet,
          sign: p.sign,
          start: p.start,
          end: p.end,
        ),
    ],
    sky: {
      for (final e in positions.entries) e.key: e.value.sign,
    },
    moonSign: moon?.sign,
    moonNakshatra: moon?.nakshatra,
  );
}

T? _byName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

DateTime? _parseDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw) : null;
