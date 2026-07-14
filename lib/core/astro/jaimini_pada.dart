/// Arudha Padas (1P–12P) — the classical Jaimini "image" points, one
/// per house, computed per Shri K.N. Rao ("Jaimini's Chara Dasha",
/// p. 46; also the 1P/2P notation used there and in Parashar Light):
///
///  1. Count the signs from the house to its lord's sign (n; 0 if the
///     lord sits in the house itself).
///  2. The pada is n signs further on FROM the lord's sign — as far
///     from the lord as the lord is from the house.
///  3. NO exceptions: a lord in its own sign makes the house itself
///     the pada, and padas falling in the 1st or 7th from the house
///     stay where they fall. (Other schools redirect these to the
///     10th; K.N. Rao rejects both exceptions and so do we.)
///
/// 1P is the Arudha Lagna (AL), the single most widely used Jaimini
/// point — how the person/matter "appears" to the world, as distinct
/// from the true (Rashi) Lagna.
///
/// Uses the single traditional sign lord ([ZodiacSign.lord] — Mars for
/// Scorpio, Saturn for Aquarius), matching the rest of the app's
/// lordship convention outside the dasha layer.
library;

import 'divisional.dart';
import 'models.dart';

class ArudhaPada {
  const ArudhaPada({required this.house, required this.sign});

  /// The bhava (1-12, whole-sign from the lagna in use) this pada
  /// belongs to.
  final int house;
  final ZodiacSign sign;

  /// Short chart-overlay code: '1P' … '12P'.
  String get code => '${house}P';

  String get label => house == 1 ? 'Arudha Lagna (1P)' : '${house}P';
}

/// Computes 1P–12P from an arbitrary [lagna] and a lord→sign lookup, so
/// the same rule serves the rashi chart and every varga.
///
/// K.N. Rao rule, no exceptions: pada = (2·lord − house) mod 12.
List<ArudhaPada> arudhaPadasFromLagna(
  ZodiacSign lagna,
  ZodiacSign Function(Planet lord) signOf,
) {
  final out = <ArudhaPada>[];
  for (var h = 1; h <= 12; h++) {
    final sign = ZodiacSign.values[(lagna.index + h - 1) % 12];
    final lordSign = signOf(sign.lord);
    out.add(ArudhaPada(
      house: h,
      sign: ZodiacSign.values[(2 * lordSign.index - sign.index + 24) % 12],
    ));
  }
  return out;
}

/// Computes 1P–12P for the rashi (D1) chart of [snapshot].
List<ArudhaPada> arudhaPadas(AstroSnapshot snapshot) => arudhaPadasFromLagna(
      snapshot.lagnaSign,
      (lord) => snapshot.positions[lord]!.sign,
    );

/// Computes 1P–12P within [varga], from the varga's own lagna and the
/// varga positions of the sign lords (not an overlay of D1 padas).
List<ArudhaPada> vargaArudhaPadas(AstroSnapshot snapshot, Varga varga) =>
    arudhaPadasFromLagna(
      vargaLagna(snapshot, varga),
      (lord) => vargaSign(varga, snapshot.positions[lord]!.longitude),
    );

/// Sign → pada codes ('7P', '12P', …) in house order, for the chart
/// painters' grey pada overlay.
Map<ZodiacSign, List<String>> padaLabelsBySign(List<ArudhaPada> padas) {
  final map = <ZodiacSign, List<String>>{};
  for (final p in padas) {
    (map[p.sign] ??= []).add(p.code);
  }
  return map;
}
