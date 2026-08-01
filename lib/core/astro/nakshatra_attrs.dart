/// Per-nakshatra devata (presiding deity) and symbol — the classical
/// attributes a printed panchang prints beside a janma nakshatra.
///
/// Identity, not display text: both enums are named in English here for
/// stable identifiers and tests, and the presentation layer translates
/// them (l10n/astro_l10n.dart), exactly as [Choghadiya] and [Yoni] do.
///
/// The Vimshottari star lord is deliberately NOT redeclared here — it
/// already lives on the enum as [Nakshatra.lord], and a second copy of
/// the 9-lord cycle is a second thing to keep correct.
library;

import 'models.dart';

/// Presiding deity, one per nakshatra.
///
/// DECLARATION ORDER IS THE LOOKUP: value `i` belongs to
/// `Nakshatra.values[i]`. Keeping the pairing positional (rather than a
/// 27-entry map) is what makes it impossible for the two lists to drift
/// apart by one — a missing entry is a shorter enum, which
/// [deityOf] turns into a range error rather than a silently wrong
/// deity.
enum NakshatraDeity {
  ashwiniKumaras,
  yama,
  agni,
  brahma,
  soma,
  rudra,
  aditi,
  brihaspati,
  nagas,
  pitris,
  bhaga,
  aryaman,
  savitar,
  tvashtar,
  vayu,
  indraAgni,
  mitra,
  indra,
  nirriti,
  apas,
  vishvedevas,
  vishnu,
  vasus,
  varuna,
  ajaEkapada,
  ahirBudhnya,
  pushan,
}

/// Traditional symbol, one per nakshatra. Same positional pairing with
/// [Nakshatra] as [NakshatraDeity].
enum NakshatraSymbol {
  horseHead,
  yoni,
  razor,
  cart,
  deerHead,
  teardrop,
  bowAndQuiver,
  cowUdder,
  coiledSerpent,
  throne,
  frontLegsOfCot,
  backLegsOfCot,
  hand,
  pearl,
  youngSprout,
  triumphalArch,
  lotus,
  earring,
  tiedRoots,
  fan,
  elephantTusk,
  threeFootprints,
  drum,
  emptyCircle,
  frontOfFuneralCot,
  backOfFuneralCot,
  fish,
}

NakshatraDeity deityOf(Nakshatra n) => NakshatraDeity.values[n.index];

NakshatraSymbol symbolOf(Nakshatra n) => NakshatraSymbol.values[n.index];
