/// The module registry — the single list the dashboard, Arrange
/// customizer, and PDF exporter all loop over (brief §2.8).
library;

import '../modules/ashtakavarga_module.dart';
import '../modules/bhava_bala_module.dart';
import '../modules/birth_chart_module.dart';
import '../modules/dasha_module.dart';
import '../modules/divisional_module.dart';
import '../modules/jaimini_aspect_module.dart';
import '../modules/jaimini_karaka_module.dart';
import '../modules/jaimini_lagna_module.dart';
import '../modules/jaimini_pada_module.dart';
import '../modules/kota_chakra_module.dart';
import '../modules/kp_module.dart';
import '../modules/moon_nakshatra_module.dart';
import '../modules/panchadha_maitri_module.dart';
import '../modules/sarvatobhadra_module.dart';
import '../modules/shadbala_module.dart';
import '../modules/sudarshana_module.dart';
import '../modules/panchang_module.dart';
import '../modules/planetary_positions_module.dart';
import '../modules/sade_sati_module.dart';
import '../modules/special_lagna_module.dart';
import '../modules/transit_module.dart';
import '../modules/upcoming_events_module.dart';
import '../modules/yogas_module.dart';
import 'astro_module.dart';

const List<AstroModule> _allModules = [
  BirthChartModule(),
  DashaModule(),
  PanchangModule(),
  MoonNakshatraModule(),
  PlanetaryPositionsModule(),
  DivisionalChartModule(),
  SpecialLagnaModule(),
  AshtakavargaModule(),
  PanchadhaMaitriModule(),
  YogasModule(),
  TransitModule(),
  KpCuspsModule(),
  KpPlanetsModule(),
  KpSignificatorsModule(),
  KpRulingPlanetsModule(),
  JaiminiKarakaModule(),
  JaiminiAspectModule(),
  JaiminiPadaModule(),
  JaiminiLagnaModule(),
  SarvatobhadraModule(),
  KotaChakraModule(),
  SudarshanaModule(),
  UpcomingEventsModule(),
  SadeSatiModule(),
  ShadbalaModule(),
  BhavaBalaModule(),
];

final Map<String, AstroModule> moduleRegistry = {
  for (final m in _allModules) m.meta.id: m,
};

AstroModule? moduleById(String id) => moduleRegistry[id];
