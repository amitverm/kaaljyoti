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
    required this.name,
    required this.description,
    required this.icon,
    required this.widgets,
  });

  final String name;
  final String description;
  final IconData icon;
  final List<SeedWidget> widgets;
}

const List<ViewTemplate> viewTemplates = [
  ViewTemplate(
    name: 'Blank',
    description: 'Start empty and add widgets yourself',
    icon: Icons.crop_free,
    widgets: [],
  ),
  ViewTemplate(
    name: 'Overview',
    description: 'Chart, dasha, panchang, positions — the full picture',
    icon: Icons.dashboard_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'planetary_positions', span: CardSpan.full, config: {}),
      (widgetId: 'dasha', span: CardSpan.full, config: {}),
      (widgetId: 'panchang', span: CardSpan.half, config: {}),
      (widgetId: 'moon_nakshatra', span: CardSpan.half, config: {}),
      (
        widgetId: 'divisional',
        span: CardSpan.full,
        config: {'varga': 'd9'}
      ),
      (widgetId: 'yogas', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    name: 'Divisional Focus',
    description: 'D1 with the D9, D7, D10 and D12 vargas',
    icon: Icons.grid_view,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (
        widgetId: 'divisional',
        span: CardSpan.full,
        config: {'varga': 'd9'}
      ),
      (
        widgetId: 'divisional',
        span: CardSpan.full,
        config: {'varga': 'd7'}
      ),
      (
        widgetId: 'divisional',
        span: CardSpan.full,
        config: {'varga': 'd10'}
      ),
      (
        widgetId: 'divisional',
        span: CardSpan.full,
        config: {'varga': 'd12'}
      ),
    ],
  ),
  ViewTemplate(
    name: 'Dasha',
    description: 'All dasha systems with events, transit and timing',
    icon: Icons.timeline_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (
        widgetId: 'dasha',
        span: CardSpan.full,
        config: {'system': 'vimshottari'}
      ),
      (
        widgetId: 'dasha',
        span: CardSpan.full,
        config: {'system': 'yogini'}
      ),
      (
        widgetId: 'dasha',
        span: CardSpan.full,
        config: {'system': 'jaimini'}
      ),
      (widgetId: 'upcoming_events', span: CardSpan.full, config: {}),
      (widgetId: 'transit', span: CardSpan.full, config: {}),
      (widgetId: 'yogas', span: CardSpan.full, config: {}),
      (widgetId: 'sade_sati', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    name: 'Jaimini',
    description: 'Karakas, Padas, Rashi aspects, and Chara dasha',
    icon: Icons.auto_awesome_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'jaimini_lagna', span: CardSpan.half, config: {}),
      (widgetId: 'jaimini_karaka', span: CardSpan.half, config: {}),
      (
        widgetId: 'dasha',
        span: CardSpan.full,
        config: {'system': 'jaimini'}
      ),
      (widgetId: 'jaimini_pada', span: CardSpan.full, config: {}),
      (widgetId: 'jaimini_aspect', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    name: 'KP',
    description: 'Krishnamurti Paddhati — cusps, planets, significators',
    icon: Icons.calculate_outlined,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'kp', span: CardSpan.full, config: {}),
      (widgetId: 'kp_planets', span: CardSpan.full, config: {}),
      (widgetId: 'kp_significators', span: CardSpan.full, config: {}),
      (widgetId: 'kp_ruling', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    name: 'Strength & Balas',
    description: 'Shadbala, Bhava Bala and Ashtakavarga strength',
    icon: Icons.bar_chart,
    widgets: [
      (widgetId: 'birth_chart', span: CardSpan.full, config: {}),
      (widgetId: 'shadbala', span: CardSpan.full, config: {}),
      (widgetId: 'bhava_bala', span: CardSpan.full, config: {}),
      (widgetId: 'ashtakavarga', span: CardSpan.full, config: {}),
    ],
  ),
  ViewTemplate(
    name: 'Chakras',
    description: 'Kota, Sarvatobhadra and Sudarshana chakras',
    icon: Icons.donut_large,
    widgets: [
      (widgetId: 'kota_chakra', span: CardSpan.full, config: {}),
      (widgetId: 'sarvatobhadra', span: CardSpan.full, config: {}),
      (widgetId: 'sudarshana', span: CardSpan.full, config: {}),
    ],
  ),
];
