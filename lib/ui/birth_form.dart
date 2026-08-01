/// The pieces the two birth-data forms share — Birth Details Entry
/// (creating a chart) and Kundli Details (editing one).
///
/// They ask the same four questions and carry the same risk: a chart
/// whose birth data is subtly wrong is not obviously wrong, it is just
/// inexplicable. So the error-proofing has to be identical on both, and
/// identical is only durable if it is one implementation. This file is
/// that implementation; the screens keep their own layout and their own
/// extra affordances.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../services/place_lookup_service.dart';

/// A UTC offset as `+05:30` / `-03:30`.
///
/// Always signed and always padded: an astrologer reading back a chart
/// needs to see at a glance that Kolkata in 1943 resolved to +06:30 and
/// not +05:30, and a bare "5.5" or "330" says that to nobody.
String formatUtcOffset(int offsetMinutes) {
  final sign = offsetMinutes < 0 ? '-' : '+';
  final abs = offsetMinutes.abs();
  final h = (abs ~/ 60).toString().padLeft(2, '0');
  final m = (abs % 60).toString().padLeft(2, '0');
  return '$sign$h:$m';
}

/// The zone half of the summary: `IST +05:30`, or `+06:30` when the zone
/// has no abbreviation for that instant.
String formatZoneLabel(int offsetMinutes, String? abbreviation) {
  final offset = formatUtcOffset(offsetMinutes);
  return abbreviation == null ? offset : '$abbreviation $offset';
}

/// The live one-line confirmation shown above the primary button:
/// `Sat, 9 Jun 1990 · 23:02 (11:02 PM) · Kolkata · IST +05:30`
///
/// EXISTS TO CATCH ERRORS BEFORE THEY BECOME CHARTS. Three of the four
/// parts are things a practitioner can get subtly wrong and not notice
/// until the chart is inexplicable: a 24-hour time typed as if it were
/// 12-hour (hence BOTH notations, side by side, every time), the wrong
/// city out of a typeahead list, and — the one nobody can be expected to
/// know — a historical offset that is not today's. Kolkata births
/// between 1942 and 1945 resolve to +06:30; the app knew that already
/// but said so nowhere. This is global-births audit item (c), and it
/// applies at edit as much as at entry: a chart cast years ago with a
/// mistyped year has the same problem, and the edit screen is where
/// someone goes to look.
///
/// The weekday is the fifth check and the cheapest one: clients state
/// births as "a Tuesday in June" far more reliably than they state the
/// date, so a typo in the day or year usually shows up here first.
///
/// Date formatting follows the app-wide preference, so the line reads
/// the way every other date in the app reads.
///
/// [weekday] is the CIVIL weekday of the entered date — deliberately NOT
/// the vara, which is sunrise-bounded and for a pre-sunrise birth names
/// the previous day. This line verifies what was TYPED; the vara belongs
/// to the chart and is computed there (see snapshot_builder). Do not
/// "correct" this to vara: it would make a correctly-typed 3 a.m. birth
/// look mistyped.
String composeBirthSummary({
  required String weekday,
  required DateTime date,
  required int hour,
  required int minute,
  required String placeShortName,
  required int offsetMinutes,
  String? abbreviation,
}) {
  final at = DateTime(date.year, date.month, date.day, hour, minute);
  return [
    // Comma, not a middot: the weekday is a property OF the date, not a
    // fifth independent fact sitting beside it.
    '$weekday, ${KJDate.date(date)}',
    '${DateFormat('HH:mm').format(at)} (${DateFormat('h:mm a').format(at)})',
    placeShortName,
    formatZoneLabel(offsetMinutes, abbreviation),
  ].join(' · ');
}

/// Resolve the entered values and compose the summary, or null while
/// anything needed is missing.
///
/// Takes a zone NAME rather than a [PlaceResult] because the two screens
/// hold their place differently: entry always has a freshly picked
/// result, edit may still be on the one stored with the kundli. Both
/// must resolve through the same call the save path uses, or the line
/// would be confirming something other than what gets written.
///
/// A zone missing from the tz dataset throws in here (the old P0) —
/// that must cost the summary line and never the form.
String? birthResolutionSummary({
  required PlaceLookupService lookup,
  required AppLocalizations l10n,
  required String name,
  required DateTime? date,
  required TimeOfDay? time,
  required String? timezoneName,
  required String? placeShortName,
}) {
  if (date == null || time == null) return null;
  if (name.trim().isEmpty) return null;
  if (timezoneName == null || timezoneName.isEmpty) return null;
  if (placeShortName == null || placeShortName.isEmpty) return null;
  try {
    final resolved = lookup.resolveLocalTime(
      timezoneName,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    return composeBirthSummary(
      // The app's own weekday names (astro_l10n) — not a second set from
      // intl's date symbols. Short form: the whole confirmation has to
      // fit on one line, and Today and Muhurta keep the full names where
      // the day IS the subject.
      weekday: weekdayAbbrLabel(l10n, date.weekday),
      date: date,
      hour: time.hour,
      minute: time.minute,
      placeShortName: placeShortName,
      offsetMinutes: resolved.offsetMinutes,
      abbreviation: resolved.abbreviation,
    );
  } catch (_) {
    return null;
  }
}

/// The city out of a stored "Kolkata, West Bengal, India" — the summary
/// has to stay one line, and the full string is already in the field.
String shortPlaceName(String placeName) {
  final first = placeName.split(',').first.trim();
  return first.isEmpty ? placeName.trim() : first;
}

/// The four inputs a chart cannot be built without, IN FORM ORDER.
///
/// The ordering is load-bearing: [firstMissingBirthField] returns the
/// first of these that is absent, and that is what the form scrolls to.
/// Sending someone to the last empty box when three above it are also
/// empty is worse than saying nothing.
enum BirthField { name, date, time, place }

/// Which required inputs are missing.
///
/// [place] being non-null is separate from "the place text is non-empty"
/// on purpose: typing "Kolk" and pressing the button is the single most
/// common way these forms fail, and the field looks filled in when it
/// happens. A place counts only once one has been picked from the list,
/// entered manually, or (when editing) left as the stored one.
Set<BirthField> missingBirthFields({
  required String name,
  required DateTime? date,
  required Object? time,
  required Object? place,
}) =>
    {
      if (name.trim().isEmpty) BirthField.name,
      if (date == null) BirthField.date,
      if (time == null) BirthField.time,
      if (place == null) BirthField.place,
    };

/// The topmost missing field, or null when the form is complete.
BirthField? firstMissingBirthField(Set<BirthField> missing) {
  for (final f in BirthField.values) {
    if (missing.contains(f)) return f;
  }
  return null;
}

/// Scroll targets, reconstructible from the enum value alone so the
/// scroll code can reach `currentContext` and tests can find the field
/// without a second key per input.
GlobalObjectKey birthFieldKey(BirthField field) => GlobalObjectKey(field);

/// The birth time as a form FIELD rather than a button.
///
/// It sits directly under the date row holding the other half of the
/// same fact, so reading as a different KIND of control made the pair
/// look unrelated — and an OutlinedButton has nowhere to put a label or
/// an error. The tap behaviour is the keypad-first picker: birth times
/// are exact and the dial snaps to five minutes.
class TimeFieldTile extends StatelessWidget {
  const TimeFieldTile({
    super.key,
    required this.time,
    required this.label,
    required this.onPick,
    this.errorText,
  });

  final TimeOfDay? time;
  final String label;
  final ValueChanged<TimeOfDay> onPick;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? const TimeOfDay(hour: 6, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.schedule_outlined),
            errorText: errorText,
          ),
          // Floats the label down into the box while empty, exactly as
          // an untouched TextField does.
          isEmpty: time == null,
          child: Text(time == null ? '' : time!.format(context)),
        ),
      );
}

/// The pinned bottom bar: the live summary, then the primary action.
///
/// Pinned rather than the last row of the scroll because both forms are
/// long and get longer as they are filled in — the primary action
/// drifting further away the more work you do is exactly backwards.
/// Same Material + hairline + SafeArea shell as the Notifications
/// screen's bottom option, so the three read as one idiom.
///
/// Deliberately takes ONE action. A destructive button beside the
/// primary one, in a bar the thumb rests on, is a misclick trap; delete
/// lives in the header menu instead.
class PinnedActionBar extends StatelessWidget {
  const PinnedActionBar({
    super.key,
    required this.actionLabel,
    required this.onAction,
    this.summary,
    this.summaryKey,
  });

  final String actionLabel;

  /// Null disables the button (a save already in flight).
  final VoidCallback? onAction;
  final String? summary;
  final Key? summaryKey;

  @override
  Widget build(BuildContext context) => Material(
        color: KJColors.paper,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, color: KJColors.hairline),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (summary != null) ...[
                      Text(
                        summary!,
                        key: summaryKey,
                        textAlign: TextAlign.center,
                        style:
                            KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
