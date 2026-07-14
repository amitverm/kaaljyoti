# Adding Yogas to the Detection Engine

A practical guide for adding new yogas/doshas yourself. The engine is a
rule pipeline in pure Dart — no Flutter, no network — so a new yoga is
usually 10–25 lines plus a test.

## Where things live

| File | Role |
|---|---|
| `lib/core/astro/yogas.dart` | The rules. `detectYogas()` runs every rule and returns `List<DetectedYoga>`. |
| `lib/core/astro/chart_facts.dart` | `ChartFacts` — precomputed structure (houses, lords, aspects, exchanges, benefic status). Rules read this instead of recomputing. |
| `lib/core/astro/models.dart` | `DetectedYoga` — the result record. |
| `lib/core/astro/dignity.dart` | `dignityOf()`, `exaltationSignOf()`, `isCombust()`. |
| `lib/modules/yogas_module.dart` | The widget. You normally don't touch it — new yogas appear automatically. |
| `test/widget_test.dart` | Reference-chart tests. Every new rule gets a positive and a negative case. |

## The three iron rules

1. **Codes are frozen.** A `code` (e.g. `gaja_kesari`) is stored in the
   Mahakosh index when a chart is contributed. Never rename or reuse a
   code, never change what an existing code means. Adding new codes is
   always safe.
2. **Always fill `participants`.** The Yogas widget flags a yoga as
   "active" by intersecting `participants` with the running dasha
   lords (Vimshottari planet, or Chara rashi lord/occupants). A yoga
   with an empty participants list can never light up.
3. **Pick a `category` from the fixed set** — it drives grouping and
   ordering in the widget: `Raj`, `Dhana`, `Vipreet Raj`,
   `Parivartana`, `Mahapurusha`, `Chandra`, `Other`, `Dosha`.
   (A new category string won't crash — it lands under "Other" — but
   add it to `_categoryOrder` in `yogas_module.dart` if you want it as
   its own group.)

## The DetectedYoga record

```dart
DetectedYoga(
  code: 'amara',            // stable snake_case id, never reused
  name: 'Amara Yoga',       // display name
  detail: 'Jupiter in ...', // one line saying WHY it fired
  category: 'Other',
  participants: [Planet.jupiter],
)
```

One rule may add several entries (each Raj pair is its own entry) —
that is fine and intended.

## ChartFacts cheat sheet

Inside `detectYogas()` a `ChartFacts f` is already built. Everything
is whole-sign and 1-based:

```dart
f.houseOf(Planet.mars)          // Mars' house from lagna, 1..12
f.houseFrom(anchorSignIdx, p)   // house from any anchor sign (e.g. Moon)
f.lordOf(5)                     // lord of the 5th house
f.signOfHouse(9)                // ZodiacSign in the 9th
f.conjunct(a, b)                // same sign
f.aspects(a, b)                 // graha drishti, incl. Ma 4/8, Ju 5/9, Sa 3/10
f.mutualAspect(a, b)
f.exchange(a, b)                // parivartana between two grahas
f.connection(a, b)              // 'exchange' | 'conjunction' | 'mutual aspect' | null
f.inKendraFrom(signIdx, p)
ChartFacts.kendras / trikonas / dusthanas   // {1,4,7,10} / {1,5,9} / {6,8,12}

// Conditional benefic/malefic (classical):
f.moonWaxing                    // Sun–Moon elongation < 180°
f.mercuryAfflicted              // Mercury sharing a sign with Sa/Ma/Ra/Ke
f.yogaBenefics                  // [Ju, Ve, (Me if clean), (Mo if waxing)]
f.isYogaMalefic(p)

// From dignity.dart:
dignityOf(positions[p]!)        // exalted / debilitated / ownSign / none
exaltationSignOf(p)             // sign-level exaltation lookup
```

Also available in scope: `positions` (the raw
`Map<Planet, PlanetPosition>`), `lagnaSignIdx`, `moonIdx`,
`houseFromLagna(lon)`, `houseFromMoon(lon)`, and `names(list)` which
joins planet display names.

## Worked example: adding Amara Yoga

*Rule (Phaladeepika): benefics in the 10th from lagna while malefics
occupy... — for the example we use a simplified form: Jupiter in the
10th from the lagna.*

**1. Add the rule to `yogas.dart`** — put it near the section it
belongs to (Chandra yogas together, doshas together, etc.):

```dart
// Amara: Jupiter in the 10th from lagna (simplified Phaladeepika).
if (f.houseOf(Planet.jupiter) == 10) {
  yogas.add(const DetectedYoga(
    code: 'amara',
    name: 'Amara Yoga',
    detail: 'Jupiter in the 10th from lagna',
    category: 'Other',
    participants: [Planet.jupiter],
  ));
}
```

**2. Add a test to `test/widget_test.dart`.** Build positions with a
tiny helper (longitude = signIndex × 30 + degrees; Aries = 0):

```dart
test('amara yoga', () {
  PlanetPosition at(Planet p, double lon) =>
      PlanetPosition(planet: p, longitude: lon, latitude: 0, speed: 1);
  // Capricorn lagna (275°); Libra = 10th house; Jupiter at Libra 15°.
  final yogas = detectYogas(
    positions: { /* all nine planets */ Planet.jupiter: at(Planet.jupiter, 195), ... },
    ascendant: 275,
  );
  expect(yogas.where((y) => y.code == 'amara').length, 1);
});
```

All nine planets must be present in the map — the engine assumes a
complete chart. Also add the new code to the reference-chart test's
"absent" list if it should NOT fire there, and re-check that test's
total count.

**3. Run** `flutter analyze && flutter test`. Done — the widget, PDF
export, dasha filters and Mahakosh indexing all pick the yoga up with
no further changes.

## Adding a table-driven series (many yogas at once)

For things like Saravali's two-planet conjunction yogas, don't write
21 if-blocks — write one loop over a table:

```dart
const dvigraha = <(Planet, Planet, String, String)>[
  (Planet.sun, Planet.moon, 'surya_chandra', 'Surya-Chandra Yoga'),
  // ...
];
for (final (a, b, code, name) in dvigraha) {
  if (f.conjunct(a, b)) {
    yogas.add(DetectedYoga(
      code: code, name: name,
      detail: '${a.displayName} and ${b.displayName} conjunct',
      category: 'Other', participants: [a, b],
    ));
  }
}
```

## Gotchas learned the hard way

- **Parivartana-like rules: iterate planets, not house pairs.** With
  dual lordship, a house-pair loop attributes the exchange to signs
  neither planet occupies. Use the houses the planets actually sit in.
- **Dedupe multi-emitting rules** with a seen-set keyed on the sorted
  participant pair, or one conjunction will fire once per house pair
  that shares lords.
- **Emitting more entries under an existing code is fine** (we did it
  for `raj_yoga`); changing an existing code's *conditions* to fire on
  charts it previously didn't (or vice versa) should be avoided —
  contributed Mahakosh charts keep their old code lists.
- **Rahu/Ketu**: no drishti in `f.aspects`, no dignity in
  `dignityOf` — deliberate, matching the rest of the app. If a rule
  needs node aspects (some traditions give Rahu 5/7/9), compute it
  locally in the rule.
- **Cancellations belong in the rule, stated in `detail`** — see
  Kemadruma (suppressed when cancelled) vs Mangal Dosha (fires with a
  "mitigated" note). Choose per yoga: suppress if the cancellation
  nullifies, annotate if it merely weakens.
- The dashboard card shows only the top 6 (`_cardCap` in
  `yogas_module.dart`), most-relevant first — a long catalogue will
  not flood the dashboard.

## Verifying without running the app

The repo's tests replicate hand-checked charts. For a new rule it's
worth reproducing the arithmetic once in any scripting language (we
use quick Python one-liners: `house = ((signIdx - lagnaIdx) % 12) + 1`
etc.) against a chart from Parashar's Light or JHora before pinning
the Dart test.
