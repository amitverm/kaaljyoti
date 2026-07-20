/// Karakamsha Lagna — the defining special ascendant of the Jaimini
/// system (alongside the Rashi and Navamsha lagnas): the Navamsha
/// (D9) sign occupied by the Atmakaraka, the "soul significator" that
/// heads the Sapta Karaka scheme. Used throughout Jaimini technique
/// for soul-purpose / dharma readings, distinct from the birth (Rashi)
/// lagna used for the rest of the chart.
///
/// v1 covers Karakamsha only — the one universally-agreed Jaimini
/// lagna. Other special lagnas some traditions also fold into Jaimini
/// work (Hora Lagna, Ghatika Lagna, Varnada Lagna, …) are candidates
/// for a later pass, not implemented here.
library;

import 'divisional.dart';
import 'jaimini_karaka.dart';
import 'models.dart';

class KarakamshaLagna {
  const KarakamshaLagna({required this.atmakaraka, required this.sign});

  /// The Atmakaraka — the graha whose Navamsha sign IS the Karakamsha.
  final Planet atmakaraka;
  final ZodiacSign sign;
}

KarakamshaLagna karakamshaLagna(AstroSnapshot snapshot) {
  final karakas = saptaKarakas(snapshot.positions);
  final ak =
      karakas.entries.firstWhere((e) => e.value == Karaka.atmakaraka).key;
  final sign = navamsaSign(snapshot.positions[ak]!.longitude);
  return KarakamshaLagna(atmakaraka: ak, sign: sign);
}
