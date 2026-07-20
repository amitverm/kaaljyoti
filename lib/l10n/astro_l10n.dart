/// Locale-aware display names for the astro domain (brief §2.4).
///
/// The calculation layer (core/astro) is pure Dart and knows nothing
/// about locales — its enums keep their English `displayName`s for
/// tests and stable identifiers. THIS file is where an enum value or
/// panchang index becomes user-facing text: every lookup goes through
/// [AppLocalizations], so adding a language is exactly one new
/// app_<code>.arb — no code changes (the promise on @appTitle).
///
/// Widgets get [AppLocalizations] from `context.l10n`; the PDF exporter
/// has no BuildContext and receives the same object explicitly.
library;

import 'package:flutter/widgets.dart';

import '../charts/chart_style.dart';
import '../core/astro/dasha/dasha.dart';
import '../core/astro/dasha/yogini.dart';
import '../core/astro/divisional.dart';
import '../core/astro/guna_milan.dart';
import '../core/astro/jaimini_karaka.dart';
import '../core/astro/kota_chakra.dart';
import '../core/astro/maitri.dart';
import '../core/astro/models.dart';
import '../core/astro/muhurta.dart';
import '../core/astro/sarvatobhadra.dart';
import '../core/astro/special_lagna.dart';
import '../core/astro/transit_scan.dart';
import '../data/models.dart';
import '../mahakosh/models.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart'
    show AppLocalizations, lookupAppLocalizations;

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension PlanetL10n on Planet {
  String label(AppLocalizations l10n) => switch (this) {
        Planet.sun => l10n.planetSun,
        Planet.moon => l10n.planetMoon,
        Planet.mars => l10n.planetMars,
        Planet.mercury => l10n.planetMercury,
        Planet.jupiter => l10n.planetJupiter,
        Planet.venus => l10n.planetVenus,
        Planet.saturn => l10n.planetSaturn,
        Planet.rahu => l10n.planetRahu,
        Planet.ketu => l10n.planetKetu,
      };

  String abbrLabel(AppLocalizations l10n) => switch (this) {
        Planet.sun => l10n.planetAbbrSun,
        Planet.moon => l10n.planetAbbrMoon,
        Planet.mars => l10n.planetAbbrMars,
        Planet.mercury => l10n.planetAbbrMercury,
        Planet.jupiter => l10n.planetAbbrJupiter,
        Planet.venus => l10n.planetAbbrVenus,
        Planet.saturn => l10n.planetAbbrSaturn,
        Planet.rahu => l10n.planetAbbrRahu,
        Planet.ketu => l10n.planetAbbrKetu,
      };
}

extension ZodiacSignL10n on ZodiacSign {
  /// Everyday display name (en: the Western name — 'Aries'; hi: मेष).
  String label(AppLocalizations l10n) => switch (this) {
        ZodiacSign.aries => l10n.signAries,
        ZodiacSign.taurus => l10n.signTaurus,
        ZodiacSign.gemini => l10n.signGemini,
        ZodiacSign.cancer => l10n.signCancer,
        ZodiacSign.leo => l10n.signLeo,
        ZodiacSign.virgo => l10n.signVirgo,
        ZodiacSign.libra => l10n.signLibra,
        ZodiacSign.scorpio => l10n.signScorpio,
        ZodiacSign.sagittarius => l10n.signSagittarius,
        ZodiacSign.capricorn => l10n.signCapricorn,
        ZodiacSign.aquarius => l10n.signAquarius,
        ZodiacSign.pisces => l10n.signPisces,
      };

  /// Sanskrit rashi name in the locale's script (en: 'Mesha'; hi: मेष).
  String sanskritLabel(AppLocalizations l10n) => switch (this) {
        ZodiacSign.aries => l10n.signSanskritAries,
        ZodiacSign.taurus => l10n.signSanskritTaurus,
        ZodiacSign.gemini => l10n.signSanskritGemini,
        ZodiacSign.cancer => l10n.signSanskritCancer,
        ZodiacSign.leo => l10n.signSanskritLeo,
        ZodiacSign.virgo => l10n.signSanskritVirgo,
        ZodiacSign.libra => l10n.signSanskritLibra,
        ZodiacSign.scorpio => l10n.signSanskritScorpio,
        ZodiacSign.sagittarius => l10n.signSanskritSagittarius,
        ZodiacSign.capricorn => l10n.signSanskritCapricorn,
        ZodiacSign.aquarius => l10n.signSanskritAquarius,
        ZodiacSign.pisces => l10n.signSanskritPisces,
      };

  /// Both forms where both help — en: 'Mesha (Aries)'; hi collapses to
  /// just मेष (the locale's signNameFull pattern decides).
  String fullLabel(AppLocalizations l10n) =>
      l10n.signNameFull(sanskritLabel(l10n), label(l10n));

  /// Short token for dense tables ('Ar' / मेष) — NEVER slice the full
  /// name: substring breaks combining marks in Devanagari.
  String abbrLabel(AppLocalizations l10n) => switch (this) {
        ZodiacSign.aries => l10n.signAbbrAries,
        ZodiacSign.taurus => l10n.signAbbrTaurus,
        ZodiacSign.gemini => l10n.signAbbrGemini,
        ZodiacSign.cancer => l10n.signAbbrCancer,
        ZodiacSign.leo => l10n.signAbbrLeo,
        ZodiacSign.virgo => l10n.signAbbrVirgo,
        ZodiacSign.libra => l10n.signAbbrLibra,
        ZodiacSign.scorpio => l10n.signAbbrScorpio,
        ZodiacSign.sagittarius => l10n.signAbbrSagittarius,
        ZodiacSign.capricorn => l10n.signAbbrCapricorn,
        ZodiacSign.aquarius => l10n.signAbbrAquarius,
        ZodiacSign.pisces => l10n.signAbbrPisces,
      };
}

extension NakshatraL10n on Nakshatra {
  String label(AppLocalizations l10n) =>
      nakshatra28Label(l10n, index < 21 ? index : index + 1);

  String abbrLabel(AppLocalizations l10n) =>
      nakshatra28AbbrLabel(l10n, index < 21 ? index : index + 1);
}

/// Label for a 28-scheme nakshatra index (0 = Ashwini … 21 = Abhijit …
/// 27 = Revati; matches [Nakshatra28.names] order).
String nakshatra28Label(AppLocalizations l10n, int index28) => [
      l10n.nakshatraAshwini,
      l10n.nakshatraBharani,
      l10n.nakshatraKrittika,
      l10n.nakshatraRohini,
      l10n.nakshatraMrigashira,
      l10n.nakshatraArdra,
      l10n.nakshatraPunarvasu,
      l10n.nakshatraPushya,
      l10n.nakshatraAshlesha,
      l10n.nakshatraMagha,
      l10n.nakshatraPurvaPhalguni,
      l10n.nakshatraUttaraPhalguni,
      l10n.nakshatraHasta,
      l10n.nakshatraChitra,
      l10n.nakshatraSwati,
      l10n.nakshatraVishakha,
      l10n.nakshatraAnuradha,
      l10n.nakshatraJyeshtha,
      l10n.nakshatraMula,
      l10n.nakshatraPurvaAshadha,
      l10n.nakshatraUttaraAshadha,
      l10n.nakshatraAbhijit,
      l10n.nakshatraShravana,
      l10n.nakshatraDhanishta,
      l10n.nakshatraShatabhisha,
      l10n.nakshatraPurvaBhadrapada,
      l10n.nakshatraUttaraBhadrapada,
      l10n.nakshatraRevati,
    ][index28];

String nakshatra28AbbrLabel(AppLocalizations l10n, int index28) => [
      l10n.nakshatraAbbrAshwini,
      l10n.nakshatraAbbrBharani,
      l10n.nakshatraAbbrKrittika,
      l10n.nakshatraAbbrRohini,
      l10n.nakshatraAbbrMrigashira,
      l10n.nakshatraAbbrArdra,
      l10n.nakshatraAbbrPunarvasu,
      l10n.nakshatraAbbrPushya,
      l10n.nakshatraAbbrAshlesha,
      l10n.nakshatraAbbrMagha,
      l10n.nakshatraAbbrPurvaPhalguni,
      l10n.nakshatraAbbrUttaraPhalguni,
      l10n.nakshatraAbbrHasta,
      l10n.nakshatraAbbrChitra,
      l10n.nakshatraAbbrSwati,
      l10n.nakshatraAbbrVishakha,
      l10n.nakshatraAbbrAnuradha,
      l10n.nakshatraAbbrJyeshtha,
      l10n.nakshatraAbbrMula,
      l10n.nakshatraAbbrPurvaAshadha,
      l10n.nakshatraAbbrUttaraAshadha,
      l10n.nakshatraAbbrAbhijit,
      l10n.nakshatraAbbrShravana,
      l10n.nakshatraAbbrDhanishta,
      l10n.nakshatraAbbrShatabhisha,
      l10n.nakshatraAbbrPurvaBhadrapada,
      l10n.nakshatraAbbrUttaraBhadrapada,
      l10n.nakshatraAbbrRevati,
    ][index28];

/// Tithi label for a 0-based lunar-day index (0 = Shukla Pratipada …
/// 14 = Purnima … 29 = Amavasya) — mirrors [tithiNameFor].
String tithiLabelForIndex(AppLocalizations l10n, int index) {
  final names = [
    l10n.tithiPratipada,
    l10n.tithiDwitiya,
    l10n.tithiTritiya,
    l10n.tithiChaturthi,
    l10n.tithiPanchami,
    l10n.tithiShashthi,
    l10n.tithiSaptami,
    l10n.tithiAshtami,
    l10n.tithiNavami,
    l10n.tithiDashami,
    l10n.tithiEkadashi,
    l10n.tithiDwadashi,
    l10n.tithiTrayodashi,
    l10n.tithiChaturdashi,
  ];
  final i = index % 30;
  if (i == 14) return l10n.tithiPurnima;
  if (i == 29) return l10n.tithiAmavasya;
  return names[i % 15];
}

/// Paksha label for a tithi index — mirrors [pakshaFor].
String pakshaLabelForIndex(AppLocalizations l10n, int index) =>
    index % 30 < 15 ? l10n.pakshaShukla : l10n.pakshaKrishna;

/// Yoga label for a 0-based yoga index (0 = Vishkambha … 26 = Vaidhriti).
String yogaLabelForIndex(AppLocalizations l10n, int index) => [
      l10n.yogaVishkambha,
      l10n.yogaPriti,
      l10n.yogaAyushman,
      l10n.yogaSaubhagya,
      l10n.yogaShobhana,
      l10n.yogaAtiganda,
      l10n.yogaSukarma,
      l10n.yogaDhriti,
      l10n.yogaShula,
      l10n.yogaGanda,
      l10n.yogaVriddhi,
      l10n.yogaDhruva,
      l10n.yogaVyaghata,
      l10n.yogaHarshana,
      l10n.yogaVajra,
      l10n.yogaSiddhi,
      l10n.yogaVyatipata,
      l10n.yogaVariyan,
      l10n.yogaParigha,
      l10n.yogaShiva,
      l10n.yogaSiddha,
      l10n.yogaSadhya,
      l10n.yogaShubha,
      l10n.yogaShukla,
      l10n.yogaBrahma,
      l10n.yogaIndra,
      l10n.yogaVaidhriti,
    ][index % 27];

/// Karana label for a 0-based karana index within the lunation (0–59) —
/// mirrors the fixed/movable rule in [computePanchang].
String karanaLabelForIndex(AppLocalizations l10n, int index) {
  if (index == 0) return l10n.karanaKimstughna;
  if (index >= 57) {
    return [
      l10n.karanaShakuni,
      l10n.karanaChatushpada,
      l10n.karanaNaga
    ][index - 57];
  }
  return [
    l10n.karanaBava,
    l10n.karanaBalava,
    l10n.karanaKaulava,
    l10n.karanaTaitila,
    l10n.karanaGara,
    l10n.karanaVanija,
    l10n.karanaVishti,
  ][(index - 1) % 7];
}

/// Vara label; index matches the core `_varaNames` order
/// (0 = Somavara … 6 = Ravivara).
String varaLabelForIndex(AppLocalizations l10n, int index) => [
      l10n.varaSomavara,
      l10n.varaMangalavara,
      l10n.varaBudhavara,
      l10n.varaGuruvara,
      l10n.varaShukravara,
      l10n.varaShanivara,
      l10n.varaRavivara,
    ][index % 7];

extension VargaL10n on Varga {
  /// Sanskrit varga name in the locale's script (en: 'Navamsa'; hi: नवांश).
  String nameLabel(AppLocalizations l10n) => switch (this) {
        Varga.d1 => l10n.vargaNameD1,
        Varga.d2 => l10n.vargaNameD2,
        Varga.d3 => l10n.vargaNameD3,
        Varga.d4 => l10n.vargaNameD4,
        Varga.d7 => l10n.vargaNameD7,
        Varga.d9 => l10n.vargaNameD9,
        Varga.d10 => l10n.vargaNameD10,
        Varga.d12 => l10n.vargaNameD12,
        Varga.d16 => l10n.vargaNameD16,
        Varga.d20 => l10n.vargaNameD20,
        Varga.d24 => l10n.vargaNameD24,
        Varga.d27 => l10n.vargaNameD27,
        Varga.d30 => l10n.vargaNameD30,
        Varga.d40 => l10n.vargaNameD40,
        Varga.d45 => l10n.vargaNameD45,
        Varga.d60 => l10n.vargaNameD60,
      };

  /// Plain-language theme ('marriage & dharma' / विवाह और धर्म).
  String themeLabel(AppLocalizations l10n) => switch (this) {
        Varga.d1 => l10n.vargaThemeD1,
        Varga.d2 => l10n.vargaThemeD2,
        Varga.d3 => l10n.vargaThemeD3,
        Varga.d4 => l10n.vargaThemeD4,
        Varga.d7 => l10n.vargaThemeD7,
        Varga.d9 => l10n.vargaThemeD9,
        Varga.d10 => l10n.vargaThemeD10,
        Varga.d12 => l10n.vargaThemeD12,
        Varga.d16 => l10n.vargaThemeD16,
        Varga.d20 => l10n.vargaThemeD20,
        Varga.d24 => l10n.vargaThemeD24,
        Varga.d27 => l10n.vargaThemeD27,
        Varga.d30 => l10n.vargaThemeD30,
        Varga.d40 => l10n.vargaThemeD40,
        Varga.d45 => l10n.vargaThemeD45,
        Varga.d60 => l10n.vargaThemeD60,
      };

  /// 'Navamsa · D9' pattern — mirrors the enum's displayName.
  String displayLabel(AppLocalizations l10n) => '${nameLabel(l10n)} · $code';
}

extension SpecialLagnaKindL10n on SpecialLagnaKind {
  /// Lagna name in the locale's script (fixed term — transliterated).
  String label(AppLocalizations l10n) => switch (this) {
        SpecialLagnaKind.bhava => l10n.slBhava,
        SpecialLagnaKind.hora => l10n.slHora,
        SpecialLagnaKind.ghati => l10n.slGhati,
        SpecialLagnaKind.indu => l10n.slIndu,
        SpecialLagnaKind.sree => l10n.slSree,
      };

  /// Plain-language signification — translated copy.
  String meaningLabel(AppLocalizations l10n) => switch (this) {
        SpecialLagnaKind.bhava => l10n.slBhavaMeaning,
        SpecialLagnaKind.hora => l10n.slHoraMeaning,
        SpecialLagnaKind.ghati => l10n.slGhatiMeaning,
        SpecialLagnaKind.indu => l10n.slInduMeaning,
        SpecialLagnaKind.sree => l10n.slSreeMeaning,
      };
}

extension KarakaL10n on Karaka {
  /// Karaka name in the locale's script (fixed term — transliterated).
  String label(AppLocalizations l10n) => switch (this) {
        Karaka.atmakaraka => l10n.karakaAtmakaraka,
        Karaka.amatyakaraka => l10n.karakaAmatyakaraka,
        Karaka.bhratrukaraka => l10n.karakaBhratrukaraka,
        Karaka.matrukaraka => l10n.karakaMatrukaraka,
        Karaka.pitrukaraka => l10n.karakaPitrukaraka,
        Karaka.gnatikaraka => l10n.karakaGnatikaraka,
        Karaka.darakaraka => l10n.karakaDarakaraka,
      };

  /// Plain-language significator role — translated copy.
  String signifiesLabel(AppLocalizations l10n) => switch (this) {
        Karaka.atmakaraka => l10n.karakaSignifiesAtma,
        Karaka.amatyakaraka => l10n.karakaSignifiesAmatya,
        Karaka.bhratrukaraka => l10n.karakaSignifiesBhratru,
        Karaka.matrukaraka => l10n.karakaSignifiesMatru,
        Karaka.pitrukaraka => l10n.karakaSignifiesPitru,
        Karaka.gnatikaraka => l10n.karakaSignifiesGnati,
        Karaka.darakaraka => l10n.karakaSignifiesDara,
      };
}

extension KotaRingL10n on KotaRing {
  String label(AppLocalizations l10n) => switch (this) {
        KotaRing.stambha => l10n.kotaRingStambha,
        KotaRing.madhya => l10n.kotaRingMadhya,
        KotaRing.prakara => l10n.kotaRingPrakara,
        KotaRing.bahya => l10n.kotaRingBahya,
      };
}

extension ChartStyleL10n on ChartStyle {
  String label(AppLocalizations l10n) => switch (this) {
        ChartStyle.north => l10n.styleNorthIndian,
        ChartStyle.south => l10n.styleSouthIndian,
        ChartStyle.circular => l10n.styleCircular,
      };
}

/// Lunar-month (maasa) name for a 0-based month index (0 = Chaitra …
/// 11 = Phalguna) — mirrors vikram_samvat.dart's `_masaNames`.
String masaLabelForIndex(AppLocalizations l10n, int monthIndex) => [
      l10n.masaChaitra,
      l10n.masaVaishakha,
      l10n.masaJyeshtha,
      l10n.masaAshadha,
      l10n.masaShravana,
      l10n.masaBhadrapada,
      l10n.masaAshwina,
      l10n.masaKartika,
      l10n.masaMargashirsha,
      l10n.masaPausha,
      l10n.masaMagha,
      l10n.masaPhalguna,
    ][monthIndex % 12];

/// Civil weekday name for [DateTime.weekday] (1 = Monday … 7 = Sunday).
String weekdayLabel(AppLocalizations l10n, int weekday) => [
      l10n.weekdayMonday,
      l10n.weekdayTuesday,
      l10n.weekdayWednesday,
      l10n.weekdayThursday,
      l10n.weekdayFriday,
      l10n.weekdaySaturday,
      l10n.weekdaySunday,
    ][(weekday - 1) % 7];

/// Compass direction name. Exhaustive over [Direction].
extension DirectionL10n on Direction {
  String label(AppLocalizations l10n) => switch (this) {
        Direction.east => l10n.dirEast,
        Direction.north => l10n.dirNorth,
        Direction.south => l10n.dirSouth,
        Direction.west => l10n.dirWest,
      };
}

/// Localized Sade Sati phase name. Exhaustive over [SadeSatiPhaseKind],
/// so core gaining a phase is a compile error rather than an English
/// word in a Hindi timeline. Shared by the Sade Sati module and the
/// Upcoming Events feed.
extension SadeSatiPhaseKindL10n on SadeSatiPhaseKind {
  String label(AppLocalizations l10n) => switch (this) {
        SadeSatiPhaseKind.rising => l10n.ssPhaseRising,
        SadeSatiPhaseKind.peak => l10n.ssPhasePeak,
        SadeSatiPhaseKind.setting => l10n.ssPhaseSetting,
        SadeSatiPhaseKind.smallPanoti => l10n.ssPhaseSmallPanoti,
      };
}

/// Localized display line for a gochar [TransitEvent] — the
/// presentation-side replacement for [TransitEvent.label] (which core
/// keeps rendering in English for tests and stable identifiers). The
/// event is already structured (planet/kind/sign/natalPoint/drishti),
/// so this is pure formatting. Shared by the Upcoming Events feed, its
/// PDF table, and anything else that renders a scan.
String transitEventLabel(AppLocalizations l10n, TransitEvent e) =>
    switch (e.kind) {
      TransitEventKind.ingress =>
        l10n.ueTransitIngress(e.planet.label(l10n), e.sign!.fullLabel(l10n)),
      TransitEventKind.aspect => e.drishti == 1
          ? l10n.ueTransitConjunct(
              e.planet.label(l10n), natalPointLabel(l10n, e.natalPoint!))
          : l10n.ueTransitDrishti(e.planet.label(l10n), '${e.drishti}',
              natalPointLabel(l10n, e.natalPoint!)),
    };

/// Localized name of a natal scan point. The scan keys its points by
/// stable English identifiers — `Planet.displayName` plus 'Lagna' (see
/// natalPointsFor in providers.dart) — so this reverse-maps them for
/// display, falling back to the raw key for anything unrecognized.
String natalPointLabel(AppLocalizations l10n, String key) {
  if (key == 'Lagna') return l10n.labelLagna;
  for (final p in Planet.values) {
    if (p.displayName == key) return p.label(l10n);
  }
  return key;
}

/// Localized yoga/dosha name, keyed by the rule engine's STABLE code
/// (codes are Mahakosh index identifiers and never change — see the
/// header of core/astro/yogas.dart). A code without a yn* entry falls
/// back to the engine's English [DetectedYoga.name], so a
/// contributor-added yoga degrades to English rather than blank until
/// its translations land (docs/adding-yogas.md + adding-a-language.md).
///
/// TODO(l10n): [DetectedYoga.detail] is still composed in English by
/// the engine; localizing it needs structured params on DetectedYoga.
String yogaName(AppLocalizations l10n, DetectedYoga y) => switch (y.code) {
      'gaja_kesari' => l10n.ynGajaKesari,
      'durudhara' => l10n.ynDurudhara,
      'sunapha' => l10n.ynSunapha,
      'anapha' => l10n.ynAnapha,
      'kemadruma' => l10n.ynKemadruma,
      'ubhayachari' => l10n.ynUbhayachari,
      'vesi' => l10n.ynVesi,
      'vasi' => l10n.ynVasi,
      'adhi_yoga' => l10n.ynAdhi,
      'amala' => l10n.ynAmala,
      'shakata' => l10n.ynShakata,
      'budha_aditya' => l10n.ynBudhaAditya,
      'chandra_mangala' => l10n.ynChandraMangala,
      'raj_yoga' => l10n.ynRaj,
      'yogakaraka' => l10n.ynYogakaraka,
      'dhana_yoga' => l10n.ynDhana,
      'neecha_bhanga' => l10n.ynNeechaBhanga,
      'lakshmi_yoga' => l10n.ynLakshmi,
      'saraswati_yoga' => l10n.ynSaraswati,
      'parvata_yoga' => l10n.ynParvata,
      'kahala_yoga' => l10n.ynKahala,
      'rajju_yoga' => l10n.ynRajju,
      'musala_yoga' => l10n.ynMusala,
      'nala_yoga' => l10n.ynNala,
      'mangal_dosha' => l10n.ynMangalDosha,
      'guru_chandal' => l10n.ynGuruChandal,
      'vish_yoga' => l10n.ynVish,
      'angarak_dosha' => l10n.ynAngarak,
      'grahan_dosha' => l10n.ynGrahan,
      'kaal_sarp' => l10n.ynKaalSarp,
      'kaal_sarp_partial' => l10n.ynKaalSarpPartial,
      'parivartana_dainya' => l10n.ynParivartanaDainya,
      'parivartana_khala' => l10n.ynParivartanaKhala,
      'parivartana_maha' => l10n.ynParivartanaMaha,
      'harsha' => l10n.ynHarsha,
      'sarala' => l10n.ynSarala,
      'vimala' => l10n.ynVimala,
      'ruchaka' => l10n.ynRuchaka,
      'bhadra' => l10n.ynBhadra,
      'hamsa' => l10n.ynHamsa,
      'malavya' => l10n.ynMalavya,
      'shasha' => l10n.ynShasha,
      _ => y.name,
    };

/// Localized display for a stored relation tag ('Client', 'Self', …) —
/// the stored value stays English (it's persisted on the kundli row);
/// unknown values pass through unchanged.
String relationTagLabel(AppLocalizations l10n, String tag) => switch (tag) {
      'Client' => l10n.relationClient,
      'Self' => l10n.relationSelf,
      'Spouse' => l10n.relationSpouse,
      'Family' => l10n.relationFamily,
      'Friend' => l10n.relationFriend,
      'Other' => l10n.relationOther,
      'Prashna' => l10n.tagPrashna,
      _ => tag,
    };

extension DashaSystemL10n on DashaSystem {
  String label(AppLocalizations l10n) => switch (this) {
        DashaSystem.vimshottari => l10n.dashaSystemVimshottari,
        DashaSystem.yogini => l10n.dashaSystemYogini,
        DashaSystem.jaimini => l10n.dashaSystemJaimini,
      };

  String subtitleLabel(AppLocalizations l10n) => switch (this) {
        DashaSystem.vimshottari => l10n.dashaSystemVimshottariSubtitle,
        DashaSystem.yogini => l10n.dashaSystemYoginiSubtitle,
        DashaSystem.jaimini => l10n.dashaSystemJaiminiSubtitle,
      };
}

/// Dasha level names, 1 = mahadasha … 5 = pran dasha — mirrors
/// [kDashaLevelNames] / [kDashaLevelNamesPlural].
String dashaLevelLabel(AppLocalizations l10n, int level,
    {bool plural = false}) {
  final singular = [
    l10n.dashaLevelMaha,
    l10n.dashaLevelAntar,
    l10n.dashaLevelPratyantar,
    l10n.dashaLevelSookshma,
    l10n.dashaLevelPran,
  ];
  final plurals = [
    l10n.dashaLevelMahaPlural,
    l10n.dashaLevelAntarPlural,
    l10n.dashaLevelPratyantarPlural,
    l10n.dashaLevelSookshmaPlural,
    l10n.dashaLevelPranPlural,
  ];
  return (plural ? plurals : singular)[level - 1];
}

/// Yogini lord label by sequence position (0 = Mangala … 7 = Sankata;
/// matches [YoginiCalculator.sequence]).
String yoginiLabelForIndex(AppLocalizations l10n, int index) => [
      l10n.yoginiMangala,
      l10n.yoginiPingala,
      l10n.yoginiDhanya,
      l10n.yoginiBhramari,
      l10n.yoginiBhadrika,
      l10n.yoginiUlka,
      l10n.yoginiSiddha,
      l10n.yoginiSankata,
    ][index % 8];

/// Localized lord label for a dasha period — the presentation-side
/// replacement for [DashaPeriod.lordLabel] (which core renders in
/// English because systems differ in lord type):
///   • Jaimini rashi periods → the localized sign ('Mesha (Aries)' /
///     मेष via the locale's signNameFull pattern);
///   • Yogini periods → localized Yogini name + ruler, recovered from
///     [YoginiCalculator.sequence] (the name itself isn't structured on the
///     period);
///   • Vimshottari (plain planet lords) → the localized graha name.
/// Falls back to the raw label for anything unrecognized.
String dashaLordLabel(AppLocalizations l10n, DashaPeriod p) {
  final sign = p.sign;
  if (sign != null) return sign.fullLabel(l10n);
  final planet = p.planet;
  if (planet != null) {
    final yoginiIdx = YoginiCalculator.sequence
        .indexWhere((e) => p.lordLabel.startsWith('${e.$1} '));
    if (yoginiIdx >= 0) {
      return '${yoginiLabelForIndex(l10n, yoginiIdx)} '
          '(${planet.label(l10n)})';
    }
    return planet.label(l10n);
  }
  return p.lordLabel;
}

/// Short localized lord token for dense timelines — abbr counterpart
/// of [dashaLordLabel].
String dashaLordAbbr(AppLocalizations l10n, DashaPeriod p) {
  final sign = p.sign;
  if (sign != null) return sign.abbrLabel(l10n);
  final planet = p.planet;
  if (planet != null) {
    final yoginiIdx = YoginiCalculator.sequence
        .indexWhere((e) => p.lordLabel.startsWith('${e.$1} '));
    if (yoginiIdx >= 0) return yoginiLabelForIndex(l10n, yoginiIdx);
    return planet.abbrLabel(l10n);
  }
  return p.lordLabel;
}

extension PanchadhaMaitriL10n on PanchadhaMaitri {
  String tierLabel(AppLocalizations l10n) => switch (this) {
        PanchadhaMaitri.atiMitra => l10n.maitriAtiMitra,
        PanchadhaMaitri.mitra => l10n.maitriMitra,
        PanchadhaMaitri.sama => l10n.maitriSama,
        PanchadhaMaitri.satru => l10n.maitriSatru,
        PanchadhaMaitri.atiSatru => l10n.maitriAtiSatru,
      };

  String glossLabel(AppLocalizations l10n) => switch (this) {
        PanchadhaMaitri.atiMitra => l10n.maitriAtiMitraGloss,
        PanchadhaMaitri.mitra => l10n.maitriMitraGloss,
        PanchadhaMaitri.sama => l10n.maitriSamaGloss,
        PanchadhaMaitri.satru => l10n.maitriSatruGloss,
        PanchadhaMaitri.atiSatru => l10n.maitriAtiSatruGloss,
      };

  String abbrLabel(AppLocalizations l10n) => switch (this) {
        PanchadhaMaitri.atiMitra => l10n.maitriAtiMitraAbbr,
        PanchadhaMaitri.mitra => l10n.maitriMitraAbbr,
        PanchadhaMaitri.sama => l10n.maitriSamaAbbr,
        PanchadhaMaitri.satru => l10n.maitriSatruAbbr,
        PanchadhaMaitri.atiSatru => l10n.maitriAtiSatruAbbr,
      };
}

extension PlanetaryRelL10n on PlanetaryRel {
  String label(AppLocalizations l10n) => switch (this) {
        PlanetaryRel.friend => l10n.relFriend,
        PlanetaryRel.neutral => l10n.relNeutral,
        PlanetaryRel.enemy => l10n.relEnemy,
      };

  String abbrLabel(AppLocalizations l10n) => switch (this) {
        PlanetaryRel.friend => l10n.relFriendAbbr,
        PlanetaryRel.neutral => l10n.relNeutralAbbr,
        PlanetaryRel.enemy => l10n.relEnemyAbbr,
      };
}

/// Choghadiya slot name. Exhaustive over [Choghadiya] — auspiciousness
/// lives on the enum, so the two can't drift apart.
extension ChoghadiyaL10n on Choghadiya {
  String label(AppLocalizations l10n) => switch (this) {
        Choghadiya.udveg => l10n.choghadiyaUdveg,
        Choghadiya.char => l10n.choghadiyaChar,
        Choghadiya.labh => l10n.choghadiyaLabh,
        Choghadiya.amrit => l10n.choghadiyaAmrit,
        Choghadiya.kaal => l10n.choghadiyaKaal,
        Choghadiya.shubh => l10n.choghadiyaShubh,
        Choghadiya.rog => l10n.choghadiyaRog,
      };
}

extension TaraBalaResultL10n on TaraBalaResult {
  /// NOT named `label` — the enum already declares a `label` getter,
  /// and a type's own member always wins over an extension.
  String taraLabel(AppLocalizations l10n) => switch (this) {
        TaraBalaResult.janma => l10n.taraJanma,
        TaraBalaResult.sampat => l10n.taraSampat,
        TaraBalaResult.vipat => l10n.taraVipat,
        TaraBalaResult.kshema => l10n.taraKshema,
        TaraBalaResult.pratyari => l10n.taraPratyari,
        TaraBalaResult.sadhaka => l10n.taraSadhaka,
        TaraBalaResult.vadha => l10n.taraVadha,
        TaraBalaResult.mitra => l10n.taraMitra,
        TaraBalaResult.ativadha => l10n.taraAtiMitra,
      };
}

/// Localized display for a life-event category. The enum's own English
/// `label` stays the stored/logic value; this is display only.
String eventCategoryLabel(AppLocalizations l10n, EventCategory c) =>
    switch (c) {
      EventCategory.marriage => l10n.evCatMarriage,
      EventCategory.childbirth => l10n.evCatChildbirth,
      EventCategory.relationship => l10n.evCatRelationship,
      EventCategory.career => l10n.evCatCareer,
      EventCategory.education => l10n.evCatEducation,
      EventCategory.health => l10n.evCatHealth,
      EventCategory.relocation => l10n.evCatRelocation,
      EventCategory.bereavement => l10n.evCatBereavement,
      EventCategory.accident => l10n.evCatAccident,
      EventCategory.financial => l10n.evCatFinancial,
      EventCategory.spiritual => l10n.evCatSpiritual,
      EventCategory.other => l10n.evCatOther,
    };

/// Localized display for a Mahakosh filter chip. The model's own
/// English `label` getter stays available for logs/tests; this is the
/// display path. Sign/nakshatra numbers are shown as 1-based indices
/// (not names) — matching how the filter is stored and queried.
String mahakoshFilterLabel(AppLocalizations l10n, AtomicFilter f) =>
    switch (f.type) {
      'planet_in_sign' => l10n.fltPlanetInSign('${f.planet}', '${f.sign! + 1}'),
      'planet_in_house' => l10n.fltPlanetInHouse('${f.planet}', '${f.house}'),
      'planet_in_nakshatra' =>
        l10n.fltPlanetInNakshatra('${f.planet}', '${f.nakshatra! + 1}'),
      'yoga_present' => l10n.fltYoga('${f.yogaCode}'),
      'life_event' => l10n.fltEvent('${f.tag}'),
      // The span is punctuation-only structured text; only the leading
      // "Born" word is localized here (no English un-baking).
      'birth_range' => l10n.fltBorn(f.birthRangeSpan),
      _ => f.type,
    };

/// Localized koota names. Exhaustive over [Koota] — no passthrough, so
/// adding a koota to core is a compile error here rather than a stray
/// English word in a Hindi table.
///
/// TODO(l10n): KootaScore.note is still core-rendered English (the varna
/// and yoni names in guna_milan.dart) — same shape as the yoga-name gap,
/// and it needs the same treatment as [Koota] got.
extension KootaL10n on Koota {
  String label(AppLocalizations l10n) => switch (this) {
        Koota.varna => l10n.akKootaVarna,
        Koota.vashya => l10n.akKootaVashya,
        Koota.tara => l10n.akKootaTara,
        Koota.yoni => l10n.akKootaYoni,
        Koota.grahaMaitri => l10n.akKootaGrahaMaitri,
        Koota.gana => l10n.akKootaGana,
        Koota.bhakoot => l10n.akKootaBhakoot,
        Koota.nadi => l10n.akKootaNadi,
      };
}

/// Localized match-quality band. Exhaustive over [GunaVerdict].
extension GunaVerdictL10n on GunaVerdict {
  String label(AppLocalizations l10n) => switch (this) {
        GunaVerdict.notRecommended => l10n.akVerdictNotRecommended,
        GunaVerdict.average => l10n.akVerdictAverage,
        GunaVerdict.good => l10n.akVerdictGood,
        GunaVerdict.excellent => l10n.akVerdictExcellent,
      };
}

/// Localized display for a report reason key (kReportReasons).
String reportReasonLabel(AppLocalizations l10n, String key) => switch (key) {
      'deanonymization' => l10n.reportDeanonymization,
      'health_privacy' => l10n.reportHealthPrivacy,
      'harassment' => l10n.reportHarassment,
      'spam' => l10n.reportSpam,
      'other' => l10n.reportOther,
      _ => key,
    };

/// Localized name/description for a dashboard [ViewTemplate], keyed on
/// its stable `key`. Falls back to the English source for an unknown key.
String templateName(AppLocalizations l10n, String key) => switch (key) {
      'blank' => l10n.vtBlank,
      'overview' => l10n.vtOverview,
      'divisional' => l10n.vtDivisional,
      'dasha' => l10n.vtDasha,
      'jaimini' => l10n.vtJaimini,
      'kp' => l10n.vtKp,
      'varshphal' => l10n.vtVarshphal,
      'strength' => l10n.vtStrength,
      'chakras' => l10n.vtChakras,
      _ => key,
    };

String templateDescription(AppLocalizations l10n, String key) => switch (key) {
      'blank' => l10n.vtBlankDesc,
      'overview' => l10n.vtOverviewDesc,
      'divisional' => l10n.vtDivisionalDesc,
      'dasha' => l10n.vtDashaDesc,
      'jaimini' => l10n.vtJaiminiDesc,
      'kp' => l10n.vtKpDesc,
      'varshphal' => l10n.vtVarshphalDesc,
      'strength' => l10n.vtStrengthDesc,
      'chakras' => l10n.vtChakrasDesc,
      _ => '',
    };

/// Localized text for one Sarvatobhadra Chakra grid cell.
///
/// Nakshatra and rashi cells go through the shared abbreviation tables
/// (which also fixes a latent bug: the core [SbcCell.display] sliced
/// `rashi.western.substring(0,3)`, which shreds combining marks in
/// Devanagari). The vowel/consonant/tithiVara cells still show core's
/// romanized IAST label.
///
/// TODO(l10n): the akshara cells (16 vowels, ~20 consonants) and the 5
/// tithi-Vara cells are romanized IAST — an authentic Hindi SBC shows
/// them in Devanagari (अ, क, …) and native weekday/tithi-group names.
/// That is a fixed ~40-entry grid mapping, worth its own pass.
String sbcCellLabel(AppLocalizations l10n, SbcCell cell) => switch (cell.type) {
      SbcCellType.nakshatra => nakshatra28AbbrLabel(l10n, cell.nak28!),
      SbcCellType.rashi => cell.rashi!.abbrLabel(l10n),
      _ => cell.label,
    };

/// Localized widget-library category heading, keyed on the stable
/// English category string on [ModuleMeta] (used raw for grouping and
/// search; localized only for display).
String moduleCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'Today' => l10n.mcToday,
      'Chart & Grahas' => l10n.mcChartGrahas,
      'Divisional Charts' => l10n.mcDivisional,
      'Timing & Dashas' => l10n.mcTiming,
      'Jaimini' => l10n.mcJaimini,
      'Strength & Doshas' => l10n.mcStrength,
      'Chakra' => l10n.mcChakra,
      'KP (Krishnamurti)' => l10n.mcKp,
      'Varshphal' => l10n.mcVarshphal,
      _ => category,
    };

/// Localized title for an [AppNotification], keyed on its stable [type].
/// The title used to be an English getter on the model; this is the
/// presentation-layer replacement so notifications read in the UI locale.
String notificationTitle(AppLocalizations l10n, AppNotification n) =>
    switch (n.type) {
      'request_match_new' => l10n.ntRequestMatchNew,
      'your_chart_matched' => l10n.ntYourChartMatched,
      'request_approved' => l10n.ntRequestApproved,
      'request_rejected' => l10n.ntRequestRejected,
      'report_actioned' => l10n.ntReportActioned,
      'report_dismissed' => l10n.ntReportDismissed,
      'comment_reply' => l10n.ntCommentReply(
          (n.payload['author_name'] as String?) ?? l10n.ntSomeone),
      'chart_comment' =>
        l10n.ntChartComment((n.payload['mk_code'] as String?) ?? ''),
      'comment_held' => l10n.ntCommentHeld,
      'comment_removed' => l10n.ntCommentRemoved,
      'comment_restored' => l10n.ntCommentRestored,
      _ => l10n.ntGeneric,
    };

/// Placeholder text for a non-visible comment, keyed on [ChartComment.status].
String commentPlaceholder(AppLocalizations l10n, String status) =>
    switch (status) {
      'deleted' => l10n.dsPlaceholderDeleted,
      'removed' => l10n.dsPlaceholderRemoved,
      'held' => l10n.dsPlaceholderHeld,
      _ => '',
    };

/// The author name to show for a comment. A real display name renders
/// verbatim (UGC); the deleted-account and missing-profile fallbacks are
/// localized. [ChartComment.authorName] is empty only in those two cases
/// (real display names are never empty), disambiguated by [authorId].
String commentAuthor(AppLocalizations l10n, ChartComment c) =>
    c.authorName.isNotEmpty
        ? c.authorName
        : (c.authorId == null ? l10n.dsAuthorDeleted : l10n.dsAuthorAnonymous);

/// Localized saham name by its stable engine key (core/astro/
/// sahams.dart); unknown keys fall back to the raw key.
String sahamLabel(AppLocalizations l10n, String key) => switch (key) {
      'punya' => l10n.sahamPunya,
      'guru' => l10n.sahamGuru,
      'vidya' => l10n.sahamVidya,
      'yasha' => l10n.sahamYasha,
      'mitra' => l10n.sahamMitra,
      'mahatmya' => l10n.sahamMahatmya,
      'asha' => l10n.sahamAsha,
      'samartha' => l10n.sahamSamartha,
      'bhratri' => l10n.sahamBhratri,
      'gaurava' => l10n.sahamGaurava,
      'pitri' => l10n.sahamPitri,
      'raja' => l10n.sahamRaja,
      'matri' => l10n.sahamMatri,
      'putra' => l10n.sahamPutra,
      'jeeva' => l10n.sahamJeeva,
      'roga' => l10n.sahamRoga,
      'karma' => l10n.sahamKarma,
      'manmatha' => l10n.sahamManmatha,
      'kali' => l10n.sahamKali,
      'kshama' => l10n.sahamKshama,
      'shastra' => l10n.sahamShastra,
      'bandhu' => l10n.sahamBandhu,
      'mrityu' => l10n.sahamMrityu,
      'deshantara' => l10n.sahamDeshantara,
      'artha' => l10n.sahamArtha,
      'paradara' => l10n.sahamParadara,
      'anyakarma' => l10n.sahamAnyakarma,
      'vanika' => l10n.sahamVanika,
      'karyasiddhi' => l10n.sahamKaryasiddhi,
      'vivaha' => l10n.sahamVivaha,
      'prasava' => l10n.sahamPrasava,
      'santaapa' => l10n.sahamSantaapa,
      'shraddha' => l10n.sahamShraddha,
      'preeti' => l10n.sahamPreeti,
      'jadya' => l10n.sahamJadya,
      'vyapara' => l10n.sahamVyapara,
      'paneeyapaata' => l10n.sahamPaneeyapaata,
      'shatru' => l10n.sahamShatru,
      'jalapatha' => l10n.sahamJalapatha,
      'bandhana' => l10n.sahamBandhana,
      'labha' => l10n.sahamLabha,
      _ => key,
    };
