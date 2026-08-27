/// Ephemeris — a standalone reference section (menu entry): daily graha
/// longitudes for a whole month, in nirayan (any ayanamsa) or sayan
/// (tropical) values, with day-accurate ingress/station notes. Pure
/// tabulated data for practitioners who want to check the numbers
/// themselves — kundli-independent, so it lives beside Muhurta rather
/// than inside any chart.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/astro/ayanamsa.dart';
import '../core/astro/ephemeris_table.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../data/settings_repository.dart';
import '../modules/common.dart' show retroMark;
import '../l10n/astro_l10n.dart';
import '../services/current_location_service.dart';
import '../services/place_lookup_service.dart';
import '../state/providers.dart';

class EphemerisScreen extends ConsumerStatefulWidget {
  const EphemerisScreen({super.key});

  @override
  ConsumerState<EphemerisScreen> createState() => _EphemerisScreenState();
}

class _EphemerisScreenState extends ConsumerState<EphemerisScreen> {
  late int _year;
  late int _month;
  EphemerisSystem _system = EphemerisSystem.nirayan;

  /// Null until the user picks one — the app-wide default applies.
  int? _ayanamsaOverride;

  // The ~250 sweph calls per month are a few milliseconds of FFI —
  // fine synchronously (transit scans do far more) — but not free, so
  // the last table is memoized against its inputs.
  EphemerisMonth? _table;
  (int, int, EphemerisSystem, int, double?, double?)? _tableKey;

  /// Frozen-panes scaffolding: the pinned planet-header row and the
  /// table body are two separate horizontal scroll views. The body is
  /// the one the user drags; the header follows it via [_syncHeader]
  /// (its own physics are disabled, so no feedback loop).
  final _hHead = ScrollController();
  final _hBody = ScrollController();

  static const double _dateColWidth = 52;
  static const double _cellWidth = 116;
  static const double _headerHeight = 30;

  /// Place for the lagna column — the ascendant, unlike the grahas, is
  /// place-dependent, so the column only appears once this resolves
  /// (device location if known, else the app default; same concept as
  /// Today/Muhurta).
  TodayPlace? _place;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _hBody.addListener(_syncHeader);
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    final place = await ref.read(settingsRepoProvider).todayPlace();
    if (mounted) setState(() => _place = place);
  }

  Future<void> _pickPlace() async {
    final picked = await showDialog<TodayPlace>(
      context: context,
      builder: (_) => const _EphemerisPlacePickerDialog(),
    );
    if (picked == null || !mounted) return;
    setState(() => _place = picked);
  }

  void _syncHeader() {
    if (_hHead.hasClients && _hHead.offset != _hBody.offset) {
      _hHead.jumpTo(_hBody.offset);
    }
  }

  @override
  void dispose() {
    _hBody.removeListener(_syncHeader);
    _hHead.dispose();
    _hBody.dispose();
    super.dispose();
  }

  /// Fixed row heights keep the frozen date column and the scrolling
  /// body aligned — they live in separate widgets, so intrinsic sizing
  /// can't couple them. Scaled with the text scaler so accessibility
  /// font sizes don't clip the two-line cells.
  double _rowHeight(EphemerisSystem system) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return (system == EphemerisSystem.nirayan ? 48.0 : 34.0) * scale;
  }

  int get _ayanamsaId =>
      _ayanamsaOverride ??
      ref.watch(defaultAyanamsaProvider).value ??
      Ayanamsa.lahiri.id;

  EphemerisMonth _tableFor(int ayanamsaId) {
    final key = (_year, _month, _system, ayanamsaId, _place?.latitude,
        _place?.longitude);
    if (_tableKey != key) {
      _table = computeEphemerisMonth(
        year: _year,
        month: _month,
        system: _system,
        ayanamsaId: ayanamsaId,
        latitude: _place?.latitude,
        longitude: _place?.longitude,
      );
      _tableKey = key;
    }
    return _table!;
  }

  void _step(int months) {
    setState(() {
      final m = DateTime(_year, _month + months);
      _year = m.year;
      _month = m.month;
    });
  }

  /// Direct month+year jump — chevrons alone would mean hundreds of
  /// taps to reach an old year. Same named-month + numeric-year idiom
  /// as [DateFieldsRow] (birth entry); year range is the bundled
  /// Swiss Ephemeris files' 1800–2400 CE.
  Future<void> _pickMonth() async {
    final locale = Localizations.localeOf(context).toString();
    final monthFmt = DateFormat.MMMM(locale);
    var month = _month;
    final yearCtrl = TextEditingController(text: '$_year');
    final picked = await showDialog<(int, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final year = int.tryParse(yearCtrl.text.trim());
          final valid = year != null && year >= 1800 && year <= 2400;
          return AlertDialog(
            title: Text(ctx.l10n.epGoToMonth),
            content: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: month,
                    decoration:
                        InputDecoration(labelText: ctx.l10n.dfMonth),
                    isExpanded: true,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(monthFmt.format(DateTime(2000, m)),
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (m) => month = m ?? month,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: yearCtrl,
                    decoration: InputDecoration(labelText: ctx.l10n.dfYear),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) => setLocal(() {}),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ctx.l10n.cancel)),
              TextButton(
                onPressed:
                    valid ? () => Navigator.pop(ctx, (month, year)) : null,
                child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
              ),
            ],
          );
        },
      ),
    );
    yearCtrl.dispose();
    if (picked != null) {
      setState(() {
        _month = picked.$1;
        _year = picked.$2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ayanamsaId = _ayanamsaId;
    final table = _tableFor(ayanamsaId);
    final now = DateTime.now();
    final todayDay =
        (now.year == _year && now.month == _month) ? now.day : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.epTitle)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _controls(l10n, ayanamsaId),
                  const SizedBox(height: 4),
                  _infoLines(l10n, table),
                ],
              ),
            ),
          ),
          // The group scopes the pinned header to the table: it stays
          // put while table rows scroll under it, then pushes off with
          // the table (instead of hovering over the events footer).
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate(
                    height: _headerHeight,
                    child: _headerRow(l10n,
                        hasAsc: table.days.isNotEmpty &&
                            table.days.first.ascendant != null),
                  ),
                ),
                SliverToBoxAdapter(child: _tableBody(l10n, table, todayDay)),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
            sliver: SliverToBoxAdapter(
              child: table.events.isEmpty
                  ? const SizedBox.shrink()
                  : _eventsCard(l10n, table),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(AppLocalizations l10n, int ayanamsaId) {
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateTime(_year, _month));
    final now = DateTime.now();
    final onCurrentMonth = _year == now.year && _month == now.month;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _step(-1),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickMonth,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            monthLabel,
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.arrow_drop_down,
                              size: 20, color: KJColors.inkSoft),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _step(1),
                ),
                IconButton(
                  icon: const Icon(Icons.today_outlined, size: 20),
                  tooltip: l10n.epBackToCurrentMonth,
                  onPressed: onCurrentMonth
                      ? null
                      : () => setState(() {
                            _year = now.year;
                            _month = now.month;
                          }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ChoiceChips, not SegmentedButton — the app-wide picker
            // idiom (chart style, etc.); the chip theme carries the
            // maroon selection color.
            Wrap(
              spacing: 8,
              children: [
                for (final (system, label) in [
                  (EphemerisSystem.nirayan, l10n.epNirayan),
                  (EphemerisSystem.sayan, l10n.epSayan),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _system == system,
                    labelStyle: TextStyle(
                        color: _system == system
                            ? KJColors.paper
                            : KJColors.ink),
                    onSelected: (_) => setState(() => _system = system),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // The lagna column's place — everything else in the table
            // is place-independent.
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: _pickPlace,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place_outlined,
                          size: 14, color: KJColors.maroon),
                      const SizedBox(width: 3),
                      Text(
                        '${l10n.labelAscendant} · '
                        '${_place?.name.split(',').first ?? '…'}',
                        style:
                            KJTheme.mono(size: 11.5, color: KJColors.maroon),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_system == EphemerisSystem.nirayan) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                // The app default resolves async after first build; the
                // key remounts the field so initialValue takes effect.
                key: ValueKey(ayanamsaId),
                initialValue: ayanamsaId,
                decoration: InputDecoration(
                  labelText: l10n.beSectionAyanamsa,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final a in Ayanamsa.all)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (id) => setState(() => _ayanamsaOverride = id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoLines(AppLocalizations l10n, EphemerisMonth table) {
    // 00:00 UT is one global instant — 05:30 IST, the printed-Indian-
    // ephemeris reference. Outside IST that label misleads, so the line
    // switches to the user's own clock (date included: west of UTC the
    // instant falls on the previous local day).
    final localFirst = DateTime.utc(table.year, table.month, 1).toLocal();
    final isIst =
        localFirst.timeZoneOffset == const Duration(hours: 5, minutes: 30);
    final lines = [
      isIst
          ? l10n.epReferenceTime
          : l10n.epReferenceTimeLocal(
              DateFormat('d MMM HH:mm').format(localFirst)),
      if (table.ayanamsaOnFirst != null)
        l10n.epAyanamsaOnFirst(
          Ayanamsa.byId(table.ayanamsaId).name,
          formatDegree(table.ayanamsaOnFirst!),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Text(line,
                style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft)),
        ],
      ),
    );
  }

  /// The pinned header: a blank corner over the frozen date column,
  /// then the lagna (when a place is set) and planet abbreviations in
  /// a follower scroll view.
  Widget _headerRow(AppLocalizations l10n, {required bool hasAsc}) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: KJColors.paper,
        border: Border(bottom: BorderSide(color: KJColors.hairline)),
      ),
      child: Row(
        children: [
          const SizedBox(width: _dateColWidth),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _hHead,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    if (hasAsc)
                      SizedBox(
                        width: _cellWidth,
                        child: _headCell(l10n.labelAscendant,
                            color: KJColors.maroon),
                      ),
                    for (final p in Planet.values)
                      SizedBox(
                        width: _cellWidth,
                        child: _headCell(p.abbrLabel(l10n),
                            color: planetInk(p)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableBody(
      AppLocalizations l10n, EphemerisMonth table, int? todayDay) {
    final rowH = _rowHeight(table.system);
    final weekdayFmt = DateFormat('EE');
    BoxDecoration rowDeco(bool isToday) => BoxDecoration(
          color: isToday
              ? Color.alphaBlend(
                  KJColors.maroon.withValues(alpha: 0.07), KJColors.paper)
              : KJColors.paper,
          border: Border(top: BorderSide(color: KJColors.hairline)),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frozen date column.
        Column(
          children: [
            for (final day in table.days)
              Container(
                width: _dateColWidth,
                height: rowH,
                decoration: rowDeco(day.day == todayDay),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${day.day}',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: day.day == todayDay
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: day.day == todayDay
                                ? KJColors.maroon
                                : KJColors.ink)),
                    Text(
                        weekdayFmt.format(
                            DateTime(table.year, table.month, day.day)),
                        style: TextStyle(
                            fontSize: 9.5, color: KJColors.inkSoft)),
                  ],
                ),
              ),
          ],
        ),
        Expanded(
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _hBody,
              child: Column(
                children: [
                  for (var i = 0; i < table.days.length; i++)
                    Container(
                      height: rowH,
                      decoration:
                          rowDeco(table.days[i].day == todayDay),
                      child: Row(
                        children: [
                          if (table.days[i].ascendant != null)
                            _valueCell(
                              l10n,
                              longitude: table.days[i].ascendant!,
                              changed: i > 0 &&
                                  ZodiacSign.fromLongitude(table
                                          .days[i - 1].ascendant!) !=
                                      ZodiacSign.fromLongitude(
                                          table.days[i].ascendant!),
                              withNakshatra:
                                  table.system == EphemerisSystem.nirayan,
                            ),
                          for (final planet in Planet.values)
                            _valueCell(
                              l10n,
                              longitude:
                                  table.days[i].positions[planet]!.longitude,
                              // ® is suppressed for the nodes — retro by
                              // definition, and the true node's daily
                              // wobble would flicker the mark on and off
                              // — matching the painters, the OS widget,
                              // and the PDF.
                              retro: table
                                      .days[i].positions[planet]!.isRetrograde &&
                                  planet != Planet.rahu &&
                                  planet != Planet.ketu,
                              // Ingress mark: the sign differs from
                              // yesterday's row.
                              changed: i > 0 &&
                                  table.days[i - 1].positions[planet]!
                                          .sign !=
                                      table
                                          .days[i].positions[planet]!.sign,
                              // Every graha gets its nakshatra-pada line
                              // (the star lord matters for all of them
                              // in KP work) — but nirayan-only:
                              // nakshatras are sidereal by definition,
                              // so deriving one from a tropical
                              // longitude would be astrologically wrong.
                              withNakshatra:
                                  table.system == EphemerisSystem.nirayan,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One table cell — a graha's or the lagna's longitude. Signs-passed
  /// notation of the printed ephemerides: 3ˢ14°33'52" = three full
  /// signs traversed + 14°33'52" into the fourth (Cancer). The sign is
  /// implicit in the count, which frees room for seconds.
  Widget _valueCell(AppLocalizations l10n,
      {required double longitude,
      bool retro = false,
      required bool changed,
      required bool withNakshatra}) {
    final signsPassed = longitude ~/ 30;
    final base = KJTheme.mono(
      size: 11.5,
      color: changed ? KJColors.maroon : null,
    );
    return SizedBox(
      width: _cellWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$signsPassedˢ${formatDegree(longitude)}',
                  style: changed
                      ? base.copyWith(fontWeight: FontWeight.w700)
                      : base,
                ),
                // Shared app-wide marker: 1.5× the digits — the ®
                // glyph is designed superscript-small, and at text
                // size it is illegible (device QA).
                if (retro) retroMark(11.5),
              ]),
            ),
            if (withNakshatra)
              Text(
                  '${Nakshatra.fromLongitude(longitude).abbrLabel(l10n)} '
                  '${Nakshatra.padaFromLongitude(longitude)}',
                  style:
                      TextStyle(fontSize: 9.5, color: KJColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _eventsCard(AppLocalizations l10n, EphemerisMonth table) {
    String label(EphemerisEvent e) => switch (e.kind) {
          EphemerisEventKind.ingress => l10n.ueTransitIngress(
              e.planet.label(l10n), e.sign!.fullLabel(l10n)),
          EphemerisEventKind.stationRetrograde =>
            l10n.epStationRetrograde(e.planet.label(l10n)),
          EphemerisEventKind.stationDirect =>
            l10n.epStationDirect(e.planet.label(l10n)),
        };
    final dayFmt = DateFormat('d EE');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.epEventsHeader,
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.1,
                    color: KJColors.inkSoft,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final e in table.events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        dayFmt.format(
                            DateTime(table.year, table.month, e.day)),
                        style:
                            KJTheme.mono(size: 11, color: KJColors.inkSoft),
                      ),
                    ),
                    Expanded(
                      child: Text(label(e),
                          style: TextStyle(
                              fontSize: 12.5,
                              color: planetInk(e.planet),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headCell(String t, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: color ?? KJColors.inkSoft,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

/// Place picker for the lagna column — mirrors the Muhurta/Today
/// dialog (current location or search), kept as a separate small copy
/// so this screen has no dependency on those screens' private widgets.
class _EphemerisPlacePickerDialog extends ConsumerStatefulWidget {
  const _EphemerisPlacePickerDialog();

  @override
  ConsumerState<_EphemerisPlacePickerDialog> createState() =>
      _EphemerisPlacePickerDialogState();
}

class _EphemerisPlacePickerDialogState
    extends ConsumerState<_EphemerisPlacePickerDialog> {
  final _controller = TextEditingController();
  List<PlaceResult> _results = const [];
  Timer? _debounce;
  bool _locating = false;
  bool _locateFailed = false;
  bool _searchFailed = false;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locateFailed = false;
    });
    final detected = await CurrentLocationService.detect();
    if (!mounted) return;
    if (detected != null) {
      Navigator.pop(context, detected);
    } else {
      setState(() {
        _locating = false;
        _locateFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await ref.read(placeLookupProvider).search(q);
        if (mounted) {
          setState(() {
            _results = results;
            _searchFailed = false;
          });
        }
      } catch (_) {
        // Offline / dead network: surface inline rather than letting
        // the exception escape the Timer callback and get reported as
        // a crash.
        if (mounted) {
          setState(() {
            _results = const [];
            _searchFailed = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.epAscPlace),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location, color: KJColors.maroon),
              title: Text(
                _locating
                    ? context.l10n.muLocating
                    : context.l10n.muUseCurrentLocation,
                style: TextStyle(color: KJColors.maroon, fontSize: 14),
              ),
              subtitle: _locateFailed
                  ? Text(
                      context.l10n.muLocationError,
                      style: const TextStyle(fontSize: 11),
                    )
                  : null,
              onTap: _locating ? null : _useCurrentLocation,
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration:
                  InputDecoration(hintText: context.l10n.muSearchCity),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 8),
            if (_searchFailed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(context.l10n.placeSearchOffline,
                    style:
                        TextStyle(fontSize: 12, color: KJColors.inkSoft)),
              ),
            for (final r in _results.take(6))
              ListTile(
                dense: true,
                title: Text(r.displayName),
                onTap: () => Navigator.pop(
                  context,
                  TodayPlace(
                    name: r.displayName,
                    latitude: r.latitude,
                    longitude: r.longitude,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}

/// Fixed-extent pinned header for the ephemeris table (planet row).
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
