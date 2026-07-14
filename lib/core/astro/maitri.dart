/// Panchadha Maitri — the fivefold compound relationship (Ati Mitra …
/// Ati Satru) that one graha holds toward another, combining the fixed
/// Naisargika (natural) friendship table with the chart-specific
/// Tatkalika (temporary) relationship.
///
/// The two primitives — [naturalRelOf] and [temporaryRelOf] — already
/// live (validated) in shadbala.dart, where they drive Saptavargaja
/// Bala's dignity score. This file is the public compound layer the
/// Panchadha Maitri widget renders. shadbala.dart keeps its own parallel
/// mapping of the same tier to a *strength number* in Virupas
/// (`_compoundVirupas`), a Shadbala-only concern; the tier itself is
/// derived here from the shared primitives so the classical rule has one
/// home. Pure Dart — no Flutter — like the rest of core/astro.
library;

import 'models.dart';
import 'shadbala.dart' show PlanetaryRel, naturalRelOf, temporaryRelOf;

export 'shadbala.dart'
    show PlanetaryRel, kShadbalaPlanets, naturalRelOf, temporaryRelOf;

/// The five tiers of compound relationship, strongest friend first.
enum PanchadhaMaitri {
  atiMitra('Ati Mitra', 'Great friend', 'AM'),
  mitra('Mitra', 'Friend', 'Mi'),
  sama('Sama', 'Neutral', 'Sm'),
  satru('Satru', 'Enemy', 'St'),
  atiSatru('Ati Satru', 'Great enemy', 'AS');

  const PanchadhaMaitri(this.label, this.english, this.abbr);

  final String label; // Sanskrit tier name
  final String english; // plain-language gloss
  final String abbr; // 2-char grid/table token
}

int _relValue(PlanetaryRel r) => switch (r) {
      PlanetaryRel.friend => 1,
      PlanetaryRel.neutral => 0,
      PlanetaryRel.enemy => -1,
    };

/// Compound tier from a (natural, temporary) pair. Temporary is only
/// ever friend/enemy (never neutral — see [temporaryRelOf]), so the
/// combined −2…+2 score maps exactly onto the five tiers.
PanchadhaMaitri compoundMaitri(PlanetaryRel natural, PlanetaryRel temporary) =>
    switch (_relValue(natural) + _relValue(temporary)) {
      2 => PanchadhaMaitri.atiMitra,
      1 => PanchadhaMaitri.mitra,
      0 => PanchadhaMaitri.sama,
      -1 => PanchadhaMaitri.satru,
      _ => PanchadhaMaitri.atiSatru,
    };

/// The three relationship layers between [from] and [to] in [snapshot],
/// read as "how [from] regards [to]" — all three are one-directional
/// (the natural table is asymmetric, and the temporary rule counts signs
/// from [from]'s placement), so the full grid is intentionally not
/// mirror-symmetric.
class MaitriRelation {
  const MaitriRelation({
    required this.natural,
    required this.temporary,
    required this.compound,
  });

  final PlanetaryRel natural;
  final PlanetaryRel temporary;
  final PanchadhaMaitri compound;
}

MaitriRelation maitriBetween(Planet from, Planet to, AstroSnapshot snapshot) {
  final natural = naturalRelOf(from, to);
  final temporary = temporaryRelOf(
    snapshot.positions[from]!.sign,
    snapshot.positions[to]!.sign,
  );
  return MaitriRelation(
    natural: natural,
    temporary: temporary,
    compound: compoundMaitri(natural, temporary),
  );
}
