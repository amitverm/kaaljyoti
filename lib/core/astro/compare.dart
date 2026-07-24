/// Kundli Compare similarity engine (spec §4) — pure functions, no
/// Flutter imports, testable like the rest of core/astro.
///
/// The engine answers one question: given 2–4 selected charts, what do
/// they SHARE? It emits a flat list of [CompareFinding]s across four
/// groups — lagna/Moon factors, planet placements, dignities & motion,
/// and life-event correlations. Every rule fires the same way: gather a
/// value per subject, group by that value, and emit a finding for each
/// value shared by ≥2 subjects (fast-mover transits are the one stricter
/// case — see below). No scoring or weights in v1; ordering is
/// full-matches-first within a fixed group order.
///
/// Layering: the engine consumes a light [CompareChart] (ascendant +
/// longitudes) for placement rules 1–6, an optional [AstroSnapshot] for
/// dasha (rule 7 and event dasha), and an injected [PositionsAt] source
/// for event-date transits. The Mahakosh/local subject adapters
/// (lib/mahakosh/compare_subject.dart) build the [CompareEntry] inputs —
/// core never depends on the data/mahakosh layers.
library;

import 'dasha/dasha.dart';
import 'dasha/dasha_registry.dart';
import 'dignity.dart';
import 'models.dart';
import 'transit_scan.dart' show SadeSatiPhaseKind;
import 'transit.dart' show currentTransitPositions;

/// All nine grahas' sidereal longitudes at an instant (UTC) — the sky at
/// an event date. Injected so tests use synthetic motion and production
/// wires the Swiss Ephemeris (see [ephemerisPositionsAt]), mirroring the
/// [LongitudeAt] pattern in transit_scan.dart.
typedef PositionsAt = Map<Planet, double> Function(DateTime utc);

/// Production [PositionsAt] over the live ephemeris, using [ayanamsaId]
/// so transit signs match the natal chart being compared.
PositionsAt ephemerisPositionsAt(int ayanamsaId) => (utc) => {
      for (final e in currentTransitPositions(ayanamsaId: ayanamsaId, at: utc)
          .entries)
        e.key: e.value.longitude,
    };

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// A positions-only view of a chart: enough for placement rules 1–6 and
/// event-transit house math, without a full [AstroSnapshot]. Both local
/// kundlis and Mahakosh charts (including legacy positions-only ones)
/// can produce this.
class CompareChart {
  const CompareChart({
    required this.ascendant,
    required this.longitudes,
    this.speeds,
  });

  /// Sidereal longitude of the lagna.
  final double ascendant;

  /// Sidereal longitude per graha (all nine expected).
  final Map<Planet, double> longitudes;

  /// deg/day per graha; negative = retrograde. Null when unknown — legacy
  /// Mahakosh charts store only longitudes, so their retrograde state
  /// (rule 6) is unavailable rather than wrong.
  final Map<Planet, double>? speeds;

  ZodiacSign get lagnaSign => ZodiacSign.fromLongitude(ascendant);
  Nakshatra get lagnaNakshatra => Nakshatra.fromLongitude(ascendant);

  double lonOf(Planet p) => longitudes[p]!;
  ZodiacSign signOf(Planet p) => ZodiacSign.fromLongitude(longitudes[p]!);
  Nakshatra nakOf(Planet p) => Nakshatra.fromLongitude(longitudes[p]!);
  int padaOf(Planet p) => Nakshatra.padaFromLongitude(longitudes[p]!);

  ZodiacSign get moonSign => signOf(Planet.moon);
  Nakshatra get moonNakshatra => nakOf(Planet.moon);

  /// Whole-sign house (1–12) a sidereal longitude falls in, counted from
  /// the lagna sign (Vedic default) — mirrors [AstroSnapshot.houseOf].
  int houseOf(double longitude) =>
      _wholeSignHouse(longitude, lagnaSign);

  int houseOfPlanet(Planet p) => houseOf(longitudes[p]!);

  /// Dignity via [dignityOf] as-is (§4.2 rule 5) — carries the same
  /// value users see elsewhere in the app; speed is irrelevant to it.
  PlanetDignity dignity(Planet p) => dignityOf(
        PlanetPosition(planet: p, longitude: longitudes[p]!, latitude: 0, speed: 0),
      );

  /// Retrograde state, or null when unknown (no stored speed).
  bool? isRetrograde(Planet p) {
    final s = speeds?[p];
    return s == null ? null : s < 0;
  }
}

/// A unified life event the engine correlates (spec §4.4). [category] is
/// the stable enum code ('marriage', 'childbirth', … or 'other');
/// [customTag] carries the free-text label for 'other' events so two
/// unrelated custom events don't falsely correlate. Date resolution
/// honours [precision] ('exact' | 'month' | 'year' | 'age').
class CompareEvent {
  const CompareEvent({
    required this.category,
    this.customTag,
    this.date,
    this.precision = 'exact',
    this.ageYears,
    this.isHealth = false,
  });

  final String category;
  final String? customTag;
  final DateTime? date;
  final String precision;
  final int? ageYears;
  final bool isHealth;
}

/// One subject as the engine sees it. [chart] is always present;
/// [snapshot] is null for legacy Mahakosh charts (no birth instant), so
/// dasha-based rules skip them gracefully. [birthYear] anchors age-only
/// events.
class CompareEntry {
  const CompareEntry({
    required this.id,
    required this.displayName,
    required this.chart,
    required this.events,
    this.snapshot,
    this.birthYear,
  });

  final String id;
  final String displayName;
  final CompareChart chart;
  final List<CompareEvent> events;
  final AstroSnapshot? snapshot;
  final int? birthYear;
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

/// A single shared factor across ≥2 subjects (spec §4.1). [group] is one
/// of 'lagnaMoon' | 'placements' | 'dignity' | 'events'; [key] is a
/// stable id (e.g. 'graha-sign:saturn:pisces'); [params] carries display
/// values for l10n interpolation; [subjectIds] are the charts sharing it;
/// [strength] equals subjectIds.length (the sort key). [eventDetails] is
/// populated only for the 'events' group (the expandable detail sheet).
class CompareFinding {
  const CompareFinding({
    required this.group,
    required this.key,
    required this.params,
    required this.subjectIds,
    required this.strength,
    this.eventDetails,
  });

  final String group;
  final String key;
  final Map<String, String> params;
  final List<String> subjectIds;
  final int strength;
  final List<CompareEventDetail>? eventDetails;
}

/// Per-subject event breakdown behind an event finding — everything the
/// detail sheet shows (spec §4.3): date/precision, MD/AD lords (null =
/// "—"), the full nine-graha transit grid as house-from-Moon and
/// house-from-lagna, and the Sade Sati phase.
class CompareEventDetail {
  const CompareEventDetail({
    required this.subjectId,
    required this.category,
    required this.precision,
    required this.approximate,
    required this.transitHousesFromMoon,
    required this.transitHousesFromLagna,
    this.date,
    this.ageYears,
    this.mdLord,
    this.mdLordLabel,
    this.adLord,
    this.adLordLabel,
    this.sadeSatiPhase,
  });

  final String subjectId;
  final String category;
  final String precision;

  /// True for year/age precision (computed at mid-year) — the AD lord is
  /// suppressed and findings are flagged approximate.
  final bool approximate;

  /// Transit house per graha, whole-sign, from the natal Moon / lagna.
  final Map<Planet, int> transitHousesFromMoon;
  final Map<Planet, int> transitHousesFromLagna;

  final DateTime? date;
  final int? ageYears;

  /// Stable lord key (Planet.name or ZodiacSign.name); null when the
  /// selected system yields no period for the date (e.g. Chara past its
  /// single cycle, or a legacy chart with no birth instant).
  final String? mdLord;
  final String? mdLordLabel;
  final String? adLord;
  final String? adLordLabel;

  final SadeSatiPhaseKind? sadeSatiPhase;
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// Compute every shared factor across [subjects] (spec §4.2/§4.3).
///
/// [dashaSystem] selects the system for rule 7 and event-dasha; [now] is
/// the reference instant for "current mahadasha today" (a parameter, so
/// tests are deterministic); [transitPositions] samples the sky at each
/// event date (inject a fake in tests, [ephemerisPositionsAt] in prod).
///
/// Never throws on missing data: subjects without a snapshot skip
/// dasha rules, unresolvable events are ignored, and out-of-range dasha
/// lookups become null ("—").
List<CompareFinding> computeCompareFindings({
  required List<CompareEntry> subjects,
  required DashaSystem dashaSystem,
  required DateTime now,
  required PositionsAt transitPositions,
}) {
  final total = subjects.length;
  final findings = <CompareFinding>[];
  if (total < 2) return findings;

  findings.addAll(_lagnaMoonFindings(subjects));
  findings.addAll(_placementFindings(subjects));
  findings.addAll(_dashaTodayFindings(subjects, dashaSystem, now));
  findings.addAll(_dignityFindings(subjects));
  findings.addAll(
      _eventFindings(subjects, dashaSystem, transitPositions, total));

  const groupOrder = {'lagnaMoon': 0, 'placements': 1, 'dignity': 2, 'events': 3};
  findings.sort((a, b) {
    final g = groupOrder[a.group]!.compareTo(groupOrder[b.group]!);
    if (g != 0) return g;
    // Full matches (all selected charts) before partial.
    final af = a.strength == total ? 0 : 1;
    final bf = b.strength == total ? 0 : 1;
    if (af != bf) return af - bf;
    final s = b.strength.compareTo(a.strength);
    if (s != 0) return s;
    return a.key.compareTo(b.key);
  });
  return findings;
}

/// Group [subjects] by [valueOf] and emit a finding per value shared by
/// ≥2 subjects. [paramsOf] and [keyOf] receive the shared value.
List<CompareFinding> _byValue<T>(
  List<CompareEntry> subjects,
  String group,
  T? Function(CompareEntry) valueOf,
  String Function(T) keyOf,
  Map<String, String> Function(T) paramsOf,
) {
  final buckets = <T, List<String>>{};
  for (final s in subjects) {
    final v = valueOf(s);
    if (v == null) continue;
    buckets.putIfAbsent(v, () => []).add(s.id);
  }
  final out = <CompareFinding>[];
  buckets.forEach((v, ids) {
    if (ids.length < 2) return;
    out.add(CompareFinding(
      group: group,
      key: keyOf(v),
      params: paramsOf(v),
      subjectIds: ids,
      strength: ids.length,
    ));
  });
  return out;
}

// --- §4.2 rules 1–2: lagna & Moon --------------------------------------------

List<CompareFinding> _lagnaMoonFindings(List<CompareEntry> subjects) {
  final out = <CompareFinding>[];

  out.addAll(_byValue<ZodiacSign>(subjects, 'lagnaMoon',
      (s) => s.chart.lagnaSign,
      (v) => 'lagna-sign:${v.name}', (v) => {'sign': v.western}));
  out.addAll(_byValue<Nakshatra>(subjects, 'lagnaMoon',
      (s) => s.chart.lagnaNakshatra,
      (v) => 'lagna-nak:${v.name}', (v) => {'nakshatra': v.displayName}));
  out.addAll(_byValue<ZodiacSign>(subjects, 'lagnaMoon',
      (s) => s.chart.moonSign,
      (v) => 'moon-sign:${v.name}', (v) => {'sign': v.western}));

  // Moon nakshatra, then pada ONLY within a shared nakshatra (§4.2.2).
  final nakBuckets = <Nakshatra, List<CompareEntry>>{};
  for (final s in subjects) {
    nakBuckets.putIfAbsent(s.chart.moonNakshatra, () => []).add(s);
  }
  nakBuckets.forEach((nak, group) {
    if (group.length < 2) return;
    out.add(CompareFinding(
      group: 'lagnaMoon',
      key: 'moon-nak:${nak.name}',
      params: {'nakshatra': nak.displayName},
      subjectIds: [for (final s in group) s.id],
      strength: group.length,
    ));
    // Pada sub-groups within this shared nakshatra.
    out.addAll(_byValue<int>(group, 'lagnaMoon',
        (s) => s.chart.padaOf(Planet.moon),
        (p) => 'moon-pada:${nak.name}:$p',
        (p) => {'nakshatra': nak.displayName, 'pada': '$p'}));
  });

  return out;
}

// --- §4.2 rules 3–4: per-graha sign & house ----------------------------------

List<CompareFinding> _placementFindings(List<CompareEntry> subjects) {
  final out = <CompareFinding>[];
  for (final p in Planet.values) {
    out.addAll(_byValue<ZodiacSign>(subjects, 'placements',
        (s) => s.chart.signOf(p),
        (v) => 'graha-sign:${p.name}:${v.name}',
        (v) => {'planet': p.displayName, 'sign': v.western}));
    out.addAll(_byValue<int>(subjects, 'placements',
        (s) => s.chart.houseOfPlanet(p),
        (h) => 'graha-house:${p.name}:$h',
        (h) => {'planet': p.displayName, 'house': '$h'}));
  }
  return out;
}

// --- §4.2 rule 7: current mahadasha lord today -------------------------------

List<CompareFinding> _dashaTodayFindings(
    List<CompareEntry> subjects, DashaSystem system, DateTime now) {
  return _byValue<String>(subjects, 'placements', (s) {
    if (s.snapshot == null) return null;
    final md = _dashaFor(s, system).currentMahadasha(now);
    return _lordKey(md);
  }, (lord) => 'dasha-today:$lord', (lord) {
    return {'lord': lord, 'system': system.name};
  });
}

// --- §4.2 rules 5–6: dignities & motion --------------------------------------

List<CompareFinding> _dignityFindings(List<CompareEntry> subjects) {
  final out = <CompareFinding>[];
  for (final p in Planet.values) {
    // Shared dignity state (exalted / debilitated / own sign); 'none'
    // (and the nodes, always none) are not a finding.
    out.addAll(_byValue<PlanetDignity>(subjects, 'dignity', (s) {
      final d = s.chart.dignity(p);
      return d == PlanetDignity.none ? null : d;
    }, (d) => 'graha-dignity:${p.name}:${d.name}',
        (d) => {'planet': p.displayName, 'dignity': d.name}));

    // Shared retrogrades. Only subjects whose retrograde state is KNOWN
    // and true participate; unknown (legacy) never blocks or joins.
    final retro = [
      for (final s in subjects)
        if (s.chart.isRetrograde(p) == true) s.id
    ];
    if (retro.length >= 2) {
      out.add(CompareFinding(
        group: 'dignity',
        key: 'graha-retro:${p.name}',
        params: {'planet': p.displayName},
        subjectIds: retro,
        strength: retro.length,
      ));
    }
  }
  return out;
}

// --- §4.3: life-event correlation --------------------------------------------

/// Slow movers emitted as headline transit rows on ≥2 match (§4.3.4);
/// Rahu/Ketu are a single axis (§4.3.5), handled via [Planet.rahu].
const _slowSingles = [Planet.saturn, Planet.jupiter];

/// Fast movers (Sun→Venus, Mars included — spec lists slow movers as
/// Saturn/Jupiter/nodes only) surface as findings ONLY on a unanimous,
/// exact-dated match across every selected chart.
const _fastMovers = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.venus,
];

List<CompareFinding> _eventFindings(
  List<CompareEntry> subjects,
  DashaSystem system,
  PositionsAt transitPositions,
  int total,
) {
  // Build every (subject, event) detail, bucketed by category key.
  final byCat = <String, List<({String subjectId, CompareEventDetail d})>>{};
  final catParams = <String, Map<String, String>>{};

  for (final s in subjects) {
    for (final e in s.events) {
      final resolved = _resolveEventDate(e, s.birthYear);
      if (resolved == null) continue;
      final catKey = _categoryKey(e);
      catParams.putIfAbsent(catKey, () => _categoryParams(e));
      final detail = _buildDetail(s, e, resolved, system, transitPositions);
      byCat.putIfAbsent(catKey, () => []).add((subjectId: s.id, d: detail));
    }
  }

  final out = <CompareFinding>[];
  byCat.forEach((catKey, rows) {
    final subjectsWithCat = {for (final r in rows) r.subjectId};
    if (subjectsWithCat.length < 2) return; // §4.3: category on ≥2 charts

    final params = catParams[catKey]!;
    final catFindings = <CompareFinding>[];
    List<CompareEventDetail> detailsFor(Set<String> ids) =>
        [for (final r in rows) if (ids.contains(r.subjectId)) r.d];

    void emit(String key, Set<String> ids, Map<String, String> extra) {
      catFindings.add(CompareFinding(
        group: 'events',
        key: key,
        params: {...params, ...extra},
        subjectIds: ids.toList(),
        strength: ids.length,
        eventDetails: detailsFor(ids),
      ));
    }

    // 1–2. MD / AD lord matches.
    _lordBuckets(rows, (d) => d.mdLord).forEach((lord, ids) {
      if (ids.length >= 2) {
        emit('event-md:$catKey:$lord', ids, {'lord': lord});
      }
    });
    _lordBuckets(rows, (d) => d.adLord).forEach((lord, ids) {
      if (ids.length >= 2) {
        emit('event-ad:$catKey:$lord', ids, {'lord': lord});
      }
    });

    // 3. Sade Sati phase (Saturn vs natal Moon).
    final sade = <SadeSatiPhaseKind, Set<String>>{};
    for (final r in rows) {
      final ph = r.d.sadeSatiPhase;
      if (ph != null) sade.putIfAbsent(ph, () => {}).add(r.subjectId);
    }
    sade.forEach((phase, ids) {
      if (ids.length >= 2) {
        emit('event-sadesati:$catKey:${phase.name}', ids, {'phase': phase.name});
      }
    });

    // 4. Transit house matches — slow movers on ≥2, fast on unanimous.
    for (final frame in const ['moon', 'lagna']) {
      Map<Planet, int> housesOf(CompareEventDetail d) =>
          frame == 'moon' ? d.transitHousesFromMoon : d.transitHousesFromLagna;

      for (final p in _slowSingles) {
        final byHouse = <int, Set<String>>{};
        for (final r in rows) {
          final h = housesOf(r.d)[p];
          if (h != null) byHouse.putIfAbsent(h, () => {}).add(r.subjectId);
        }
        byHouse.forEach((house, ids) {
          if (ids.length >= 2) {
            emit('event-transit:$catKey:${p.name}:$frame:$house', ids,
                {'planet': p.displayName, 'frame': frame, 'house': '$house'});
          }
        });
      }

      // Rahu/Ketu as ONE axis finding (§4.3.5), keyed on Rahu's house.
      final byAxis = <int, ({Set<String> ids, int ketuHouse})>{};
      for (final r in rows) {
        final rh = housesOf(r.d)[Planet.rahu];
        final kh = housesOf(r.d)[Planet.ketu];
        if (rh == null || kh == null) continue;
        final cur = byAxis[rh];
        byAxis[rh] = (ids: {...?cur?.ids, r.subjectId}, ketuHouse: kh);
      }
      byAxis.forEach((rahuHouse, v) {
        if (v.ids.length >= 2) {
          emit('event-transit:$catKey:rahuketu:$frame:$rahuHouse', v.ids, {
            'frame': frame,
            'rahuHouse': '$rahuHouse',
            'ketuHouse': '${v.ketuHouse}',
          });
        }
      });

      // Fast movers: only a unanimous, exact-dated match surfaces.
      if (subjectsWithCat.length == total &&
          rows.every((r) => !r.d.approximate)) {
        for (final p in _fastMovers) {
          final byHouse = <int, Set<String>>{};
          for (final r in rows) {
            final h = housesOf(r.d)[p];
            if (h != null) byHouse.putIfAbsent(h, () => {}).add(r.subjectId);
          }
          byHouse.forEach((house, ids) {
            if (ids.length == total) {
              emit('event-transit:$catKey:${p.name}:$frame:$house', ids,
                  {'planet': p.displayName, 'frame': frame, 'house': '$house'});
            }
          });
        }
      }
    }

    // 5. Neutral row: category shared but nothing matched — a verified
    // negative is information for research (§4.3).
    if (catFindings.isEmpty) {
      out.add(CompareFinding(
        group: 'events',
        key: 'event-neutral:$catKey',
        params: params,
        subjectIds: subjectsWithCat.toList(),
        strength: subjectsWithCat.length,
        eventDetails: detailsFor(subjectsWithCat),
      ));
    } else {
      out.addAll(catFindings);
    }
  });

  return out;
}

/// Group subject ids by a lord key extracted from each detail (skipping
/// nulls).
Map<String, Set<String>> _lordBuckets(
  List<({String subjectId, CompareEventDetail d})> rows,
  String? Function(CompareEventDetail) lordOf,
) {
  final out = <String, Set<String>>{};
  for (final r in rows) {
    final lord = lordOf(r.d);
    if (lord != null) out.putIfAbsent(lord, () => {}).add(r.subjectId);
  }
  return out;
}

CompareEventDetail _buildDetail(
  CompareEntry s,
  CompareEvent e,
  ({DateTime date, bool approximate}) resolved,
  DashaSystem system,
  PositionsAt transitPositions,
) {
  // Dasha (§4.3.1–2): needs a full snapshot. Chara past its single cycle
  // (or any out-of-range lookup) yields an empty chain → null lords.
  String? mdLord, mdLabel, adLord, adLabel;
  if (s.snapshot != null) {
    final chain = _dashaFor(s, system).chainAt(resolved.date);
    final md = chain.isNotEmpty ? chain[0] : null;
    final ad = chain.length > 1 ? chain[1] : null;
    mdLord = _lordKey(md);
    mdLabel = _lordLabel(md);
    // AD only for exact/month precision — mid-year approximations can't
    // pin the antardasha (it may change within the year).
    if (!resolved.approximate) {
      adLord = _lordKey(ad);
      adLabel = _lordLabel(ad);
    }
  }

  // Transits (§4.3): the sky at the event date, as whole-sign houses from
  // the natal Moon and lagna. Works for legacy charts too.
  final sky = transitPositions(resolved.date);
  final moonSign = s.chart.moonSign;
  final lagnaSign = s.chart.lagnaSign;
  final fromMoon = <Planet, int>{};
  final fromLagna = <Planet, int>{};
  for (final p in Planet.values) {
    final lon = sky[p];
    if (lon == null) continue;
    final sign = ZodiacSign.fromLongitude(lon);
    fromMoon[p] = _relHouse(sign, moonSign);
    fromLagna[p] = _relHouse(sign, lagnaSign);
  }
  final satLon = sky[Planet.saturn];
  final sade = satLon == null
      ? null
      : _sadePhase(ZodiacSign.fromLongitude(satLon), moonSign);

  return CompareEventDetail(
    subjectId: s.id,
    category: e.category,
    precision: e.precision,
    approximate: resolved.approximate,
    date: resolved.date,
    ageYears: e.ageYears,
    mdLord: mdLord,
    mdLordLabel: mdLabel,
    adLord: adLord,
    adLordLabel: adLabel,
    transitHousesFromMoon: fromMoon,
    transitHousesFromLagna: fromLagna,
    sadeSatiPhase: sade,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _dashaCache = Expando<Map<DashaSystem, DashaResult>>();

/// Dasha result for [s] under [system], memoised per subject snapshot.
DashaResult _dashaFor(CompareEntry s, DashaSystem system) {
  final snap = s.snapshot!;
  final cache = _dashaCache[snap] ??= <DashaSystem, DashaResult>{};
  return cache[system] ??= dashaCalculators[system]!.calculate(snap);
}

String? _lordKey(DashaPeriod? p) => p?.planet?.name ?? p?.sign?.name;
String? _lordLabel(DashaPeriod? p) => p?.planet?.displayName ?? p?.sign?.western;

int _wholeSignHouse(double longitude, ZodiacSign from) {
  final signIdx = (((longitude % 360) + 360) % 360 ~/ 30).toInt() % 12;
  return ((signIdx - from.index + 12) % 12) + 1;
}

int _relHouse(ZodiacSign sign, ZodiacSign from) =>
    ((sign.index - from.index + 12) % 12) + 1;

/// Saturn's Sade Sati / dhaiya phase relative to the natal Moon sign,
/// mirroring the mapping in transit_scan.dart's sadeSatiPhases.
SadeSatiPhaseKind? _sadePhase(ZodiacSign saturnSign, ZodiacSign moonSign) {
  final rel = (saturnSign.index - moonSign.index + 12) % 12;
  return switch (rel) {
    11 => SadeSatiPhaseKind.rising,
    0 => SadeSatiPhaseKind.peak,
    1 => SadeSatiPhaseKind.setting,
    3 || 7 => SadeSatiPhaseKind.smallPanoti,
    _ => null,
  };
}

/// Category grouping key: known categories group by their code so a local
/// 'marriage' and a Mahakosh 'Marriage' correlate; 'other' events split
/// by their custom tag so unrelated custom events don't.
String _categoryKey(CompareEvent e) {
  if (e.category == 'other') {
    final t = e.customTag?.trim().toLowerCase();
    return (t != null && t.isNotEmpty) ? 'other:$t' : 'other';
  }
  return e.category;
}

Map<String, String> _categoryParams(CompareEvent e) => {
      'category': e.category,
      if (e.category == 'other' &&
          (e.customTag?.trim().isNotEmpty ?? false))
        'tag': e.customTag!.trim(),
    };

/// Resolve an event to a datable instant + approximate flag (§4.3):
/// exact/month use the stored date; year uses mid-year; age uses
/// birthYear + age at mid-year. Null when nothing resolves.
({DateTime date, bool approximate})? _resolveEventDate(
    CompareEvent e, int? birthYear) {
  switch (e.precision) {
    case 'exact':
    case 'month':
      if (e.date != null) {
        return (
          date: DateTime.utc(e.date!.year, e.date!.month, e.date!.day),
          approximate: false,
        );
      }
      break;
    case 'year':
      if (e.date != null) {
        return (date: DateTime.utc(e.date!.year, 7, 1), approximate: true);
      }
      break;
    case 'age':
      if (e.ageYears != null && birthYear != null) {
        return (
          date: DateTime.utc(birthYear + e.ageYears!, 7, 1),
          approximate: true,
        );
      }
      break;
  }
  // Fallbacks when precision and available data disagree.
  if (e.ageYears != null && birthYear != null) {
    return (
      date: DateTime.utc(birthYear + e.ageYears!, 7, 1),
      approximate: true,
    );
  }
  if (e.date != null) {
    return (
      date: DateTime.utc(e.date!.year, e.date!.month, e.date!.day),
      approximate: e.precision == 'year',
    );
  }
  return null;
}
