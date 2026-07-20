/// Presentation-layer label mappings that replace engine-rendered
/// English (transitEventLabel, yogaName). These pin two promises:
///
///  • EN PARITY — for the English locale the localized output is
///    byte-identical to the engine's own label, so swapping call sites
///    from `e.label`/`y.name` to the l10n helpers changed nothing for
///    English users.
///  • COVERAGE — every yoga code the rule engine can emit has a yn*
///    ARB entry (the fallback is for future contributor-added codes,
///    not for shipped ones).
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/transit_scan.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';

/// Every code `detectYogas` can emit (core/astro/yogas.dart). A new
/// engine yoga must be added here AND get yn* entries in every ARB —
/// this list is the tripwire.
const engineYogaCodes = [
  'gaja_kesari',
  'durudhara',
  'sunapha',
  'anapha',
  'kemadruma',
  'ubhayachari',
  'vesi',
  'vasi',
  'adhi_yoga',
  'amala',
  'shakata',
  'budha_aditya',
  'chandra_mangala',
  'raj_yoga',
  'yogakaraka',
  'dhana_yoga',
  'neecha_bhanga',
  'lakshmi_yoga',
  'saraswati_yoga',
  'parvata_yoga',
  'kahala_yoga',
  'rajju_yoga',
  'musala_yoga',
  'nala_yoga',
  'mangal_dosha',
  'guru_chandal',
  'vish_yoga',
  'angarak_dosha',
  'grahan_dosha',
  'kaal_sarp',
  'kaal_sarp_partial',
  'parivartana_dainya',
  'parivartana_khala',
  'parivartana_maha',
  'harsha',
  'sarala',
  'vimala',
  'ruchaka',
  'bhadra',
  'hamsa',
  'malavya',
  'shasha',
];

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final hi = lookupAppLocalizations(const Locale('hi'));
  final t = DateTime.utc(2026, 1, 1);

  group('transitEventLabel', () {
    final ingress = TransitEvent(
      planet: Planet.jupiter,
      kind: TransitEventKind.ingress,
      time: t,
      sign: ZodiacSign.aries,
    );
    final conjunct = TransitEvent(
      planet: Planet.saturn,
      kind: TransitEventKind.aspect,
      time: t,
      natalPoint: 'Moon',
      drishti: 1,
    );
    final drishti = TransitEvent(
      planet: Planet.saturn,
      kind: TransitEventKind.aspect,
      time: t,
      natalPoint: 'Lagna',
      drishti: 3,
    );

    test('English output is byte-identical to the engine label', () {
      expect(transitEventLabel(en, ingress), ingress.label);
      expect(transitEventLabel(en, conjunct), conjunct.label);
      expect(transitEventLabel(en, drishti), drishti.label);
    });

    test('Hindi localizes the planet, sign, and natal point', () {
      expect(transitEventLabel(hi, ingress), contains(hi.planetJupiter));
      expect(transitEventLabel(hi, conjunct), contains(hi.planetMoon));
      // 'Lagna' is a scan-map key, not display text — it must come out
      // as the localized Lagna label, never the raw key.
      expect(transitEventLabel(hi, drishti), contains(hi.labelLagna));
    });
  });

  group('yogaName', () {
    test('every engine code has a mapping in every shipped locale', () {
      for (final code in engineYogaCodes) {
        final probe = DetectedYoga(code: code, name: '⟂unmapped⟂');
        for (final l10n in [en, hi]) {
          expect(yogaName(l10n, probe), isNot('⟂unmapped⟂'),
              reason: '$code unmapped for ${l10n.localeName}');
        }
      }
    });

    test('an unknown code falls back to the engine name', () {
      const contributed =
          DetectedYoga(code: 'shubha_kartari', name: 'Shubha Kartari Yoga');
      expect(yogaName(en, contributed), 'Shubha Kartari Yoga');
      expect(yogaName(hi, contributed), 'Shubha Kartari Yoga');
    });
  });
}
