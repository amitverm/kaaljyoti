/// All v1 dasha calculators, keyed by system.
library;

import 'dasha.dart';
import 'jaimini.dart';
import 'vimshottari.dart';
import 'yogini.dart';

final Map<DashaSystem, DashaCalculator> dashaCalculators = {
  DashaSystem.vimshottari: VimshottariCalculator(),
  DashaSystem.yogini: YoginiCalculator(),
  DashaSystem.jaimini: JaiminiCharaCalculator(),
};
