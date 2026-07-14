/// Ayanamsa catalog. IDs are Swiss Ephemeris sidereal-mode constants
/// (SE_SIDM_*). Lahiri is the app-wide default; per-kundli override
/// supported (brief §2.1, screen 03/15).
library;

class Ayanamsa {
  const Ayanamsa(this.id, this.name, {this.quickPick = false});
  final int id; // SE_SIDM_* value
  final String name;
  final bool quickPick; // surfaced as a pill chip at onboarding

  static const lahiri = Ayanamsa(1, 'Lahiri', quickPick: true);

  /// Subset surfaced in v1 UI; the full 47 live behind "More…".
  /// IDs follow Swiss Ephemeris SE_SIDM_* numbering.
  static const List<Ayanamsa> all = [
    Ayanamsa(0, 'Fagan-Bradley', quickPick: true),
    lahiri,
    Ayanamsa(2, 'De Luce'),
    Ayanamsa(3, 'Raman', quickPick: true),
    Ayanamsa(4, 'Ushashashi'),
    Ayanamsa(5, 'Krishnamurti (KP)', quickPick: true),
    Ayanamsa(6, 'Djwhal Khul'),
    Ayanamsa(7, 'Yukteshwar'),
    Ayanamsa(8, 'J.N. Bhasin'),
    Ayanamsa(9, 'Babylonian (Kugler 1)'),
    Ayanamsa(10, 'Babylonian (Kugler 2)'),
    Ayanamsa(11, 'Babylonian (Kugler 3)'),
    Ayanamsa(12, 'Babylonian (Huber)'),
    Ayanamsa(13, 'Babylonian (Eta Piscium)'),
    Ayanamsa(14, 'Babylonian (Aldebaran 15 Tau)'),
    Ayanamsa(15, 'Hipparchos'),
    Ayanamsa(16, 'Sassanian'),
    Ayanamsa(17, 'Galactic Center 0 Sag'),
    Ayanamsa(18, 'J2000'),
    Ayanamsa(19, 'J1900'),
    Ayanamsa(20, 'B1950'),
    Ayanamsa(21, 'Suryasiddhanta'),
    Ayanamsa(22, 'Suryasiddhanta (mean Sun)'),
    Ayanamsa(23, 'Aryabhata'),
    Ayanamsa(24, 'Aryabhata (mean Sun)'),
    Ayanamsa(25, 'SS Revati'),
    Ayanamsa(26, 'SS Citra'),
    Ayanamsa(27, 'True Chitra', quickPick: true),
    Ayanamsa(28, 'True Revati'),
    Ayanamsa(29, 'True Pushya (PVRN Rao)'),
    Ayanamsa(30, 'Galactic (Gil Brand)'),
    Ayanamsa(31, 'Galactic Equator (IAU 1958)'),
    Ayanamsa(32, 'Galactic Equator'),
    Ayanamsa(33, 'Galactic Equator mid-Mula'),
    Ayanamsa(34, 'Skydram (Mardyks)'),
    Ayanamsa(35, 'True Mula (Chandra Hari)'),
    Ayanamsa(36, 'Dhruva Galactic Center'),
    Ayanamsa(37, 'Aryabhata 522'),
    Ayanamsa(38, 'Babylonian (Britton)'),
    Ayanamsa(39, 'Vedic Sheoran'),
    Ayanamsa(40, 'Cochrane (Gal.Center 0 Cap)'),
    Ayanamsa(41, 'Galactic Equator (Fiorenza)'),
    Ayanamsa(42, 'Vettius Valens'),
    Ayanamsa(43, 'Lahiri 1940'),
    Ayanamsa(44, 'Lahiri VP285'),
    Ayanamsa(45, 'Krishnamurti-Senthilathiban'),
    Ayanamsa(46, 'Lahiri ICRC'),
  ];

  static Ayanamsa byId(int id) =>
      all.firstWhere((a) => a.id == id, orElse: () => lahiri);

  static List<Ayanamsa> get quickPicks =>
      all.where((a) => a.quickPick).toList();
}
