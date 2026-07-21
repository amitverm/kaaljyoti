/// Bottom-sheet builder for one atomic Mahakosh filter — every type the
/// combination-search compiler supports (planet in house/sign/nakshatra,
/// yoga, life event, birth range). Shared by Mahakosh search and the
/// research-request criteria editor, so both offer the same vocabulary.
library;

import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import 'models.dart';

/// Shows the sheet and resolves to the built [AtomicFilter], or null if
/// dismissed.
Future<AtomicFilter?> showFilterBuilderSheet(BuildContext context) =>
    showModalBottomSheet<AtomicFilter>(
      context: context,
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      builder: (ctx) => const FilterBuilderSheet(),
    );

class FilterBuilderSheet extends StatefulWidget {
  const FilterBuilderSheet({super.key});

  @override
  State<FilterBuilderSheet> createState() => _FilterBuilderSheetState();
}

class _FilterBuilderSheetState extends State<FilterBuilderSheet> {
  String _type = 'planet_in_house';
  Planet _planet = Planet.mars;
  int _sign = 0;
  int _house = 7;
  int _nakshatra = 0;
  final _yogaController = TextEditingController();
  final _tagController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;

  /// Validation message shown INSIDE the sheet — a snackbar would render
  /// on the scaffold behind the modal barrier, invisible until the sheet
  /// closes.
  String? _error;

  static const _typeCodes = [
    'planet_in_house',
    'planet_in_sign',
    'planet_in_nakshatra',
    'yoga_present',
    'life_event',
    'birth_range',
  ];

  String _typeLabel(AppLocalizations l10n, String code) => switch (code) {
        'planet_in_house' => l10n.msTypePlanetInHouse,
        'planet_in_sign' => l10n.msTypePlanetInSign,
        'planet_in_nakshatra' => l10n.msTypePlanetInNakshatra,
        'yoga_present' => l10n.msTypeYogaPresent,
        'life_event' => l10n.msTypeLifeEvent,
        'birth_range' => l10n.msTypeBirthRange,
        _ => code,
      };

  static String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(context.l10n.msAddFilterTitle,
                      style: KJTheme.serif(size: 18))),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.cancel,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in _typeCodes)
                ChoiceChip(
                  label: Text(_typeLabel(context.l10n, code)),
                  selected: _type == code,
                  labelStyle: TextStyle(
                      fontSize: 12,
                      color: _type == code ? KJColors.paper : KJColors.ink),
                  onSelected: (_) => setState(() {
                    _type = code;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_type.startsWith('planet_'))
            DropdownButtonFormField<Planet>(
              value: _planet,
              decoration: InputDecoration(labelText: context.l10n.nrPlanet),
              items: [
                for (final p in Planet.values)
                  DropdownMenuItem(
                      value: p,
                      child: Text(p.label(context.l10n),
                          style: TextStyle(color: planetInk(p)))),
              ],
              onChanged: (p) => setState(() => _planet = p!),
            ),
          const SizedBox(height: 10),
          if (_type == 'planet_in_sign')
            DropdownButtonFormField<int>(
              value: _sign,
              decoration: InputDecoration(labelText: context.l10n.msSign),
              items: [
                for (final s in ZodiacSign.values)
                  DropdownMenuItem(
                      value: s.index, child: Text(s.label(context.l10n))),
              ],
              onChanged: (v) => setState(() => _sign = v!),
            ),
          if (_type == 'planet_in_house')
            DropdownButtonFormField<int>(
              value: _house,
              decoration:
                  InputDecoration(labelText: context.l10n.nrHouseFromLagna),
              items: [
                for (var h = 1; h <= 12; h++)
                  DropdownMenuItem(
                      value: h, child: Text(context.l10n.nrHouseN('$h'))),
              ],
              onChanged: (v) => setState(() => _house = v!),
            ),
          if (_type == 'planet_in_nakshatra')
            DropdownButtonFormField<int>(
              value: _nakshatra,
              decoration:
                  InputDecoration(labelText: context.l10n.labelNakshatra),
              items: [
                for (final n in Nakshatra.values)
                  DropdownMenuItem(
                      value: n.index, child: Text(n.label(context.l10n))),
              ],
              onChanged: (v) => setState(() => _nakshatra = v!),
            ),
          if (_type == 'yoga_present')
            TextField(
              controller: _yogaController,
              onChanged: (_) =>
                  _error == null ? null : setState(() => _error = null),
              decoration: InputDecoration(
                  labelText: context.l10n.msYogaCode,
                  helperText:
                      'e.g. gaja_kesari, raj_yoga, mangal_dosha, kaal_sarp'),
            ),
          if (_type == 'life_event')
            TextField(
              controller: _tagController,
              onChanged: (_) =>
                  _error == null ? null : setState(() => _error = null),
              decoration: InputDecoration(
                  labelText: context.l10n.msEventTag,
                  // Tags are free text from contributed charts' life events
                  // (event title or category), matched case-insensitively
                  // as a substring.
                  helperText: 'e.g. Marriage, Career, transplant'),
            ),
          if (_type == 'birth_range') ...[
            Text(context.l10n.msBornBetween,
                style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ?? DateTime(1980),
                        firstDate: DateTime(1800),
                        lastDate: DateTime(2100),
                        initialEntryMode: DatePickerEntryMode.input,
                      );
                      if (d != null) {
                        setState(() {
                          _dateFrom = d;
                          _error = null;
                        });
                      }
                    },
                    onLongPress: () => setState(() => _dateFrom = null),
                    child: Text(_dateFrom == null
                        ? context.l10n.msFromDate
                        : KJDate.date(_dateFrom!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dateTo ?? DateTime(2000),
                        firstDate: DateTime(1800),
                        lastDate: DateTime(2100),
                        initialEntryMode: DatePickerEntryMode.input,
                      );
                      if (d != null) {
                        setState(() {
                          _dateTo = d;
                          _error = null;
                        });
                      }
                    },
                    onLongPress: () => setState(() => _dateTo = null),
                    child: Text(_dateTo == null
                        ? context.l10n.msToDate
                        : KJDate.date(_dateTo!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(context.l10n.msLongPressClear,
                style: TextStyle(fontSize: 11, color: KJColors.inkSoft)),
          ],
          const SizedBox(height: 18),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _error!,
                style: TextStyle(
                    fontSize: 12.5,
                    color: KJColors.maroon,
                    fontWeight: FontWeight.w600),
              ),
            ),
          FilledButton(
            onPressed: () {
              if (_type == 'birth_range' &&
                  _dateFrom == null &&
                  _dateTo == null) {
                setState(() => _error = context.l10n.msSetDateBound);
                return;
              }
              // Text-backed filters need a value — an empty yoga code or
              // event tag would be a filter that matches nothing (and the
              // server rejects it anyway).
              if ((_type == 'yoga_present' &&
                      _yogaController.text.trim().isEmpty) ||
                  (_type == 'life_event' &&
                      _tagController.text.trim().isEmpty)) {
                setState(() => _error = context.l10n.msEnterValue);
                return;
              }
              final filter = switch (_type) {
                'planet_in_sign' =>
                  AtomicFilter(type: _type, planet: _planet.name, sign: _sign),
                'planet_in_house' => AtomicFilter(
                    type: _type, planet: _planet.name, house: _house),
                'planet_in_nakshatra' => AtomicFilter(
                    type: _type, planet: _planet.name, nakshatra: _nakshatra),
                'yoga_present' => AtomicFilter(
                    type: _type, yogaCode: _yogaController.text.trim()),
                'birth_range' => AtomicFilter(
                    type: _type,
                    dateFrom: _dateFrom == null ? null : _fmtDate(_dateFrom!),
                    dateTo: _dateTo == null ? null : _fmtDate(_dateTo!),
                  ),
                _ => AtomicFilter(
                    type: 'life_event', tag: _tagController.text.trim()),
              };
              Navigator.pop(context, filter);
            },
            child: Text(context.l10n.nrAdd),
          ),
        ],
      ),
    );
  }
}
