/// PACE — the four Parashari channels through which one graha
/// influences another: Position, Aspect, Conjunction, Exchange.
///
/// Aspect reuses graha_drishti.dart and conjunction/exchange follow the
/// same definitions the yoga rule engine uses (chart_facts.dart), so a
/// PACE card and a detected yoga can never tell different stories.
///
/// POSITION is deliberately not "sign and house" — those already sit on
/// the Planetary Positions card, and repeating them would make this
/// widget a duplicate. Here Position is what the placement MEANS:
/// dignity (exalted / own / debilitated) and the nature of the bhava
/// (kendra, trikona, dusthana, upachaya).
///
/// Pure Dart, no Flutter.
library;

import 'chart_facts.dart';
import 'dignity.dart';
import 'graha_drishti.dart';
import 'models.dart';

/// The classical nature of a bhava. A house can be several at once —
/// the 1st is both kendra and trikona, the 10th both kendra and
/// upachaya — so this is a set, not a single label.
enum BhavaNature { kendra, trikona, dusthana, upachaya }

const _kendras = {1, 4, 7, 10};
const _trikonas = {1, 5, 9};
const _dusthanas = {6, 8, 12};
const _upachayas = {3, 6, 10, 11};

Set<BhavaNature> bhavaNatureOf(int house) => {
      if (_kendras.contains(house)) BhavaNature.kendra,
      if (_trikonas.contains(house)) BhavaNature.trikona,
      if (_dusthanas.contains(house)) BhavaNature.dusthana,
      if (_upachayas.contains(house)) BhavaNature.upachaya,
    };

/// What one graha's placement amounts to.
class Position {
  const Position({
    required this.sign,
    required this.house,
    required this.dignity,
    required this.nature,
    required this.lordOf,
  });

  final ZodiacSign sign;
  final int house;
  final PlanetDignity dignity;
  final Set<BhavaNature> nature;

  /// Houses this graha lords, ascending. Empty for Rahu and Ketu, which
  /// own no sign. "The 10th lord sits in the 6th" is a core reading, and
  /// it is invisible unless lordship sits beside placement.
  final List<int> lordOf;
}

/// A bhava, its lord, and where that lord went — the house-first view of
/// the same fact [Position.lordOf] gives graha-first.
class BhavaLord {
  const BhavaLord({
    required this.house,
    required this.lord,
    required this.lordSign,
    required this.lordHouse,
  });

  final int house;
  final Planet lord;
  final ZodiacSign lordSign;

  /// The house the lord occupies. Equal to [house] when the lord sits in
  /// its own bhava.
  final int lordHouse;

  bool get isInOwnBhava => house == lordHouse;
}

/// Everything acting on one graha, by channel.
class PaceEntry {
  const PaceEntry({
    required this.graha,
    required this.position,
    required this.aspectedBy,
    required this.conjunctWith,
    required this.exchangeWith,
  });

  final Planet graha;
  final Position position;

  /// Grahas casting drishti onto this one.
  final List<Drishti> aspectedBy;

  /// Grahas sharing its sign.
  final List<Planet> conjunctWith;

  /// Parivartana partner, when this graha is in one. Exchange is rare —
  /// most charts have none — so callers render this row only when set.
  final Planet? exchangeWith;

  /// True when nothing at all acts on this graha. Worth surfacing: an
  /// unaspected, unconjunct graha reads very differently from a busy one.
  bool get isUntouched =>
      aspectedBy.isEmpty && conjunctWith.isEmpty && exchangeWith == null;

  /// Influences ordered by classical strength — exchange outranks
  /// conjunction outranks aspect (the sambandha hierarchy already
  /// encoded in [ChartFacts.connection]).
  int get influenceCount =>
      aspectedBy.length + conjunctWith.length + (exchangeWith == null ? 0 : 1);
}

/// PACE for every graha in a chart.
class PaceTable {
  PaceTable({
    required this.positions,
    required double ascendant,
    this.includeNodes = false,
  })  : _facts = ChartFacts(positions: positions, ascendant: ascendant),
        _drishti = GrahaDrishtiTable(
          positions: positions,
          ascendant: ascendant,
          includeNodes: includeNodes,
        ) {
    for (final graha in positions.keys) {
      final pos = positions[graha]!;
      final house = _drishti.houseOf(graha);
      _entries[graha] = PaceEntry(
        graha: graha,
        position: Position(
          sign: pos.sign,
          house: house,
          dignity: dignityOf(pos),
          nature: bhavaNatureOf(house),
          lordOf: [
            for (var h = 1; h <= 12; h++)
              if (_facts.lordOf(h) == graha) h,
          ],
        ),
        aspectedBy: _drishti.receivedBy(graha),
        conjunctWith: [
          for (final other in positions.keys)
            if (other != graha && _facts.conjunct(graha, other)) other,
        ],
        exchangeWith: () {
          for (final other in positions.keys) {
            if (other != graha && _facts.exchange(graha, other)) return other;
          }
          return null;
        }(),
      );
    }
  }

  final Map<Planet, PlanetPosition> positions;
  final bool includeNodes;
  final ChartFacts _facts;
  final GrahaDrishtiTable _drishti;
  final Map<Planet, PaceEntry> _entries = {};

  PaceEntry? entryFor(Planet p) => _entries[p];

  /// Entries in canonical graha order.
  List<PaceEntry> get entries => [
        for (final p in Planet.values)
          if (_entries[p] != null) _entries[p]!,
      ];

  /// Every parivartana in the chart, each pair once. Usually empty.
  List<(Planet, Planet)> get exchanges {
    final seen = <String>{};
    final out = <(Planet, Planet)>[];
    for (final e in entries) {
      final other = e.exchangeWith;
      if (other == null) continue;
      final key = ([e.graha.index, other.index]..sort()).join('-');
      if (!seen.add(key)) continue;
      out.add((e.graha, other));
    }
    return out;
  }

  bool get hasExchange => exchanges.isNotEmpty;

  /// Every bhava's lord and where it went, houses 1–12 in order.
  ///
  /// A lord absent from [positions] is skipped rather than guessed —
  /// that can't happen for a natal chart (all seven classical grahas are
  /// always present), but a partial chart must not crash the card.
  List<BhavaLord> get bhavaLords => [
        for (var h = 1; h <= 12; h++)
          if (positions[_facts.lordOf(h)] != null)
            BhavaLord(
              house: h,
              lord: _facts.lordOf(h),
              lordSign: positions[_facts.lordOf(h)]!.sign,
              lordHouse: _drishti.houseOf(_facts.lordOf(h)),
            ),
      ];
}
