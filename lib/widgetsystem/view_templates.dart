/// Dashboard view templates — preset widget arrangements offered when
/// creating a new view. Organised by system/method (not by persona):
/// Overview, Divisional, Dasha, Jaimini, KP, Strength, Chakras — plus a
/// Blank start. Each is fully editable after creation.
library;

import 'package:flutter/material.dart';

import '../data/dashboard_repository.dart' show SeedWidget;
import '../data/models.dart';

class ViewTemplate {
  const ViewTemplate({
    required this.key,
    required this.icon,
    required this.widgets,
  });

  /// Stable identifier and the ONLY source of a template's name — the
  /// display name and description live in app_<code>.arb and are read
  /// via templateName/templateDescription in astro_l10n.dart. Kept out
  /// of this file so there is one source of truth, not two to keep in
  /// sync. The English text is documented on the vt* keys in app_en.arb.
  final String key;
  final IconData icon;
  final List<SeedWidget> widgets;
}

const List<ViewTemplate> viewTemplates = [
  ViewTemplate(
    key: 'blank',
    icon: Icons.crop_free,
    widgets: [],
  ),
  ViewTemplate(
    key: 'overview',
    icon: Icons.dashboard_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'planetary_positions', span: CardSpan.full, config: {}),
      (widgetId: 'dasha', span: CardSpan.full, config: {}),
      (widgetId: 'panchang', span: CardSpan.half, config: {}),
      (widgetId: 'moon_nakshatra', span: CardSpan.half, config: {}),
      (widgetId: 'divisional', span: CardSpan.full, config: {'varga': 'd9'}),
      (widgetId: 'yogas', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    key: 'divisional',
    icon: Icons.grid_view,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'divisional', span: CardSpan.full, config: {'varga': 'd9'}),
      (widgetId: 'divisional', span: CardSpan.full, config: {'varga': 'd7'}),
      (widgetId: 'divisional', span: CardSpan.full, config: {'varga': 'd10'}),
      (widgetId: 'divisional', span: CardSpan.full, config: {'varga': 'd12'}),
    ],
  ),
  ViewTemplate(
    key: 'dasha',
    icon: Icons.timeline_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (
        widgetId: 'dasha',
        span: CardSpan.full,
        config: {'system': 'vimshottari'}
      ),
      (widgetId: 'dasha', span: CardSpan.full, config: {'system': 'yogini'}),
      (widgetId: 'dasha', span: CardSpan.full, config: {'system': 'jaimini'}),
      (widgetId: 'upcoming_events', span: CardSpan.full, config: {}),
      (widgetId: 'transit', span: CardSpan.full, config: {}),
      (widgetId: 'yogas', span: CardSpan.full, config: {}),
      (widgetId: 'sade_sati', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    key: 'jaimini',
    icon: Icons.auto_awesome_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'jaimini_lagna', span: CardSpan.half, config: {}),
      (widgetId: 'jaimini_karaka', span: CardSpan.half, config: {}),
      (widgetId: 'dasha', span: CardSpan.full, config: {'system': 'jaimini'}),
      (widgetId: 'jaimini_pada', span: CardSpan.full, config: {}),
      (widgetId: 'jaimini_aspect', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    key: 'kp',
    icon: Icons.calculate_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      // Cusp-based practice reads cuspal houses — the chalit chart is
      // seeded here (Placidus config to match), NOT in Overview: not
      // everyone uses chalit. The widget itself is system-neutral.
      (
        widgetId: 'chalit_chart',
        span: CardSpan.full,
        config: {'system': 'placidus'}
      ),
      (widgetId: 'kp', span: CardSpan.full, config: {}),
      (widgetId: 'kp_planets', span: CardSpan.full, config: {}),
      (widgetId: 'kp_significators', span: CardSpan.full, config: {}),
      (widgetId: 'kp_ruling', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    key: 'strength',
    icon: Icons.bar_chart,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'shadbala', span: CardSpan.full, config: {}),
      (widgetId: 'bhava_bala', span: CardSpan.full, config: {}),
      (widgetId: 'ashtakavarga', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    key: 'varshphal',
    icon: Icons.event_repeat_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal', span: CardSpan.full, config: {}),
      (
        widgetId: 'varshphal_divisional',
        span: CardSpan.full,
        config: {'varga': 'd9'}
      ),
      (widgetId: 'varshphal_dasha', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal_pancha_bala', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal_harsha_bala', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal_maitri', span: CardSpan.half, config: {}),
      (widgetId: 'varshphal_yogas', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal_sahams', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal_tripataki', span: CardSpan.full, config: {}),
      (widgetId: 'varshphal_maasa', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    key: 'chakras',
    icon: Icons.donut_large,
    widgets: [
      (widgetId: 'kota_chakra', span: CardSpan.full, config: {}),
      (widgetId: 'sarvatobhadra', span: CardSpan.full, config: {}),
      (widgetId: 'sudarshana', span: CardSpan.full, config: {}),
    ],
  ),
];
