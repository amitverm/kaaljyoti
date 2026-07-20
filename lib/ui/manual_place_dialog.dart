/// Manual place entry — the escape hatch when the geocoder can't find
/// a birthplace (small villages, dead network). Name + decimal
/// latitude/longitude + an IANA timezone picked from the bundled full
/// tz database. Returns a [PlaceResult] via `Navigator.pop`, so callers
/// treat it exactly like a geocoder hit.
library;

import 'package:flutter/material.dart';

import '../l10n/astro_l10n.dart';
import '../services/place_lookup_service.dart';

class ManualPlaceDialog extends StatefulWidget {
  const ManualPlaceDialog({
    super.key,
    required this.lookup,
    this.initialName = '',
  });

  final PlaceLookupService lookup;
  final String initialName;

  @override
  State<ManualPlaceDialog> createState() => _ManualPlaceDialogState();
}

class _ManualPlaceDialogState extends State<ManualPlaceDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _tzController = TextEditingController();
  final _tzFocus = FocusNode();
  String? _timezone;
  bool _tzEditedManually = false;
  String? _error;

  late final List<String> _zones = widget.lookup.allTimezoneNames();

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    _tzController.dispose();
    _tzFocus.dispose();
    super.dispose();
  }

  /// Timezone follows the coordinates automatically (offline polygon
  /// lookup) as soon as both parse — the user only ever touches the
  /// zone field to OVERRIDE, and an override stops the auto-fill.
  void _deriveTimezone() {
    if (_tzEditedManually) return;
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      return;
    }
    final zone = widget.lookup.timezoneForLatLng(lat, lon);
    if (zone != null && zone != _timezone) {
      setState(() {
        _timezone = zone;
        _tzController.text = zone;
      });
    }
  }

  void _submit() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    final tzName = _timezone;
    final valid = name.isNotEmpty &&
        lat != null &&
        lat >= -90 &&
        lat <= 90 &&
        lon != null &&
        lon >= -180 &&
        lon <= 180 &&
        tzName != null &&
        widget.lookup.isValidTimezone(tzName);
    if (!valid) {
      setState(() => _error = l10n.beManualInvalid);
      return;
    }
    Navigator.pop(
      context,
      PlaceResult(
        name: name,
        admin: '',
        country: '',
        latitude: lat,
        longitude: lon,
        timezoneName: tzName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.beManualEntry),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.placeOfBirth),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lat,
                    decoration: InputDecoration(
                      labelText: l10n.beLatitudeLabel,
                      hintText: '31.3260',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    onChanged: (_) => _deriveTimezone(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lon,
                    decoration: InputDecoration(
                      labelText: l10n.beLongitudeLabel,
                      hintText: '75.5762',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    onChanged: (_) => _deriveTimezone(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Auto-filled from the coordinates; typing here overrides
            // (autocomplete over the full IANA list — 'kolkata' matches
            // Asia/Kolkata case-insensitively anywhere in the name).
            RawAutocomplete<String>(
              textEditingController: _tzController,
              focusNode: _tzFocus,
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<String>.empty();
                return _zones.where((z) => z.toLowerCase().contains(q));
              },
              onSelected: (z) => setState(() {
                _timezone = z;
                _tzEditedManually = true;
              }),
              fieldViewBuilder: (context, controller, focus, onSubmit) =>
                  TextField(
                controller: controller,
                focusNode: focus,
                decoration: InputDecoration(
                  labelText: l10n.beTimezoneLabel,
                  hintText: 'Asia/Kolkata',
                  helperText: _timezone,
                ),
                onChanged: (_) {
                  // Typing invalidates the previous pick (auto or
                  // chosen) until a new suggestion is selected.
                  setState(() {
                    _timezone = null;
                    _tzEditedManually = true;
                  });
                },
              ),
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 200, maxWidth: 280),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final o in options)
                          ListTile(
                            dense: true,
                            title: Text(o),
                            onTap: () => onSelected(o),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.5)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
