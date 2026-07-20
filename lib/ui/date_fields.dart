/// Unambiguous date entry: separate Day · Month (named, dropdown) ·
/// Year fields. Replaces the Material date picker's free-text input,
/// whose day/month ORDER follows the device locale — a phone set to
/// en_US silently reads "9/6/1990" as September 6th, and a swapped
/// birth date is a silently wrong chart. A named month cannot be
/// misread in either direction, and matches how practitioners say
/// dates ("9 June 1990"). A calendar button remains for picking.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/astro_l10n.dart';

class DateFieldsRow extends StatefulWidget {
  const DateFieldsRow({
    super.key,
    required this.initial,
    required this.onChanged,
    this.firstYear = 1800,
    this.lastYear = 2100,
  });

  final DateTime? initial;

  /// Fires with the parsed date, or null while the fields are
  /// incomplete or form an impossible date (Feb 30).
  final ValueChanged<DateTime?> onChanged;
  final int firstYear;
  final int lastYear;

  @override
  State<DateFieldsRow> createState() => _DateFieldsRowState();
}

class _DateFieldsRowState extends State<DateFieldsRow> {
  late final TextEditingController _day = TextEditingController(
      text: widget.initial == null ? '' : '${widget.initial!.day}');
  late final TextEditingController _year = TextEditingController(
      text: widget.initial == null ? '' : '${widget.initial!.year}');
  late int? _month = widget.initial?.month;

  @override
  void dispose() {
    _day.dispose();
    _year.dispose();
    super.dispose();
  }

  void _emit() {
    final day = int.tryParse(_day.text.trim());
    final year = int.tryParse(_year.text.trim());
    final month = _month;
    if (day == null ||
        month == null ||
        year == null ||
        year < widget.firstYear ||
        year > widget.lastYear) {
      widget.onChanged(null);
      return;
    }
    final d = DateTime(year, month, day);
    // DateTime normalizes overflow (Feb 30 → Mar 2) — reject that.
    widget.onChanged(
        (d.day == day && d.month == month && d.year == year) ? d : null);
  }

  void _setDate(DateTime d) {
    setState(() {
      _day.text = '${d.day}';
      _month = d.month;
      _year.text = '${d.year}';
    });
    widget.onChanged(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final monthFmt = DateFormat.MMMM(locale);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: TextField(
            controller: _day,
            decoration: InputDecoration(labelText: l10n.dfDay),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (_) => _emit(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _month,
            decoration: InputDecoration(labelText: l10n.dfMonth),
            isExpanded: true,
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(
                  value: m,
                  child: Text(monthFmt.format(DateTime(2000, m)),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (m) {
              setState(() => _month = m);
              _emit();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: TextField(
            controller: _year,
            decoration: InputDecoration(labelText: l10n.dfYear),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (_) => _emit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: l10n.dfPickFromCalendar,
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: widget.initial ?? DateTime(1990),
              firstDate: DateTime(widget.firstYear),
              lastDate: DateTime(widget.lastYear),
            );
            if (d != null) _setDate(d);
          },
        ),
      ],
    );
  }
}
