/// Screen 08 — Mahakosh Search. Combination query builder (atomic
/// filter chips, AND/OR combination, per-chip NOT) over the community
/// chart index, results below.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/astro/models.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../mahakosh/models.dart';
import '../mahakosh/report_chart.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';

class MahakoshSearchScreen extends ConsumerStatefulWidget {
  const MahakoshSearchScreen({super.key});

  @override
  ConsumerState<MahakoshSearchScreen> createState() =>
      _MahakoshSearchScreenState();
}

class _FilterEntry {
  _FilterEntry(this.filter);
  final AtomicFilter filter;
  bool negated = false;
}

class _MahakoshSearchScreenState extends ConsumerState<MahakoshSearchScreen> {
  final List<_FilterEntry> _filters = [];
  String _combineOp = 'AND';
  int? _total;
  List<MahakoshChartSummary> _results = [];

  // Default browse state: latest community charts, until a search runs.
  bool _searched = false;
  int? _communityTotal;
  List<MahakoshChartSummary> _recent = [];

  // Which browse tab is showing when not searching: 'browse' | 'bookmarks'.
  String _tab = 'browse';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecent());
  }

  Future<void> _loadRecent() async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null || !repo.isSignedIn) return;
    try {
      final res = await repo.recent();
      if (mounted) {
        setState(() {
          _communityTotal = res.total;
          _recent = res.results;
        });
      }
    } catch (_) {
      // Browse state is best-effort; search still works without it.
    }
  }

  FilterNode _buildTree() {
    final nodes = <FilterNode>[
      for (final e in _filters)
        e.negated ? GroupFilter('NOT', [e.filter]) : e.filter,
    ];
    if (nodes.length == 1) return nodes.first;
    return GroupFilter(_combineOp, nodes);
  }

  Future<void> _search() async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null || _filters.isEmpty) return;
    try {
      final res = await repo.search(_buildTree());
      setState(() {
        _searched = true;
        _total = res.total;
        _results = res.results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.msSearchFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mahakoshRepoProvider);
    final user = ref.watch(authUserProvider).value;

    return KJScaffold(
      section: KJSection.mahakosh,
      appBar: AppBar(
        title: Text(context.l10n.mahakoshTitle),
        actions: [
          if (repo != null && user != null)
            IconButton(
              tooltip: context.l10n.msFilterCharts,
              icon: _filters.isEmpty
                  ? const Icon(Icons.filter_list)
                  : Badge.count(
                      count: _filters.length,
                      child: const Icon(Icons.filter_list),
                    ),
              onPressed: _openQueryPanel,
            ),
        ],
      ),
      body: repo == null
          ? EmptyState(message: context.l10n.msBackendMissing)
          : user == null
              ? EmptyState(
                  message: context.l10n.msSignInPrompt,
                  actionLabel: context.l10n.signIn,
                  onAction: () => context.push('/signin'),
                )
              : _body(),
    );
  }

  Widget _body() {
    final bookmarked =
        ref.watch(mahakoshBookmarkCodesProvider).value ?? const <String>{};
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children:
          _searched ? _resultsSection(bookmarked) : _browseSection(bookmarked),
    );
  }

  TextStyle get _sectionLabelStyle => KJType.kicker();

  List<Widget> _resultsSection(Set<String> bookmarked) => [
        Row(
          children: [
            Expanded(
              child: Text(context.l10n.chartsMatch(_total ?? 0),
                  style: KJTheme.mono(size: 12, color: KJColors.inkSoft)),
            ),
            TextButton(
              onPressed: _openQueryPanel,
              child: Text(context.l10n.msFiltersCount('${_filters.length}')),
            ),
            TextButton(
              onPressed: () => setState(() {
                _filters.clear();
                _searched = false;
              }),
              child: Text(context.l10n.msClear),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final r in _results) _chartRow(r, bookmarked),
      ];

  List<Widget> _browseSection(Set<String> bookmarked) => [
        Row(
          children: [
            for (final t in [
              ('browse', context.l10n.msBrowse),
              ('bookmarks', context.l10n.msBookmarks),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t.$2),
                  selected: _tab == t.$1,
                  labelStyle: TextStyle(
                      color: _tab == t.$1 ? KJColors.paper : KJColors.ink),
                  onSelected: (_) => setState(() => _tab = t.$1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_tab == 'browse')
          ..._communityChildren(bookmarked)
        else
          ..._bookmarkChildren(bookmarked),
      ];

  List<Widget> _communityChildren(Set<String> bookmarked) => [
        Text(
          _communityTotal == null
              ? context.l10n.msCommunityCharts
              : context.l10n.msCommunityChartsCount(_communityTotal!),
          style: _sectionLabelStyle,
        ),
        const SizedBox(height: 10),
        if (_recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.l10n.msNoCharts,
              style: TextStyle(fontSize: 13, color: KJColors.inkSoft),
            ),
          ),
        for (final r in _recent) _chartRow(r, bookmarked),
      ];

  List<Widget> _bookmarkChildren(Set<String> bookmarked) {
    final async = ref.watch(mahakoshBookmarksProvider);
    return async.when(
      data: (list) => list.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.l10n.msNoBookmarks,
                  style: TextStyle(fontSize: 13, color: KJColors.inkSoft),
                ),
              ),
            ]
          : [
              Text(context.l10n.msBookmarked('${list.length}'),
                  style: _sectionLabelStyle),
              const SizedBox(height: 10),
              for (final b in list)
                b.chart != null
                    ? _chartRow(b.chart!, bookmarked)
                    : _unavailableBookmarkRow(b.mkCode),
            ],
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(context.l10n.msBookmarksError('$e'),
              style: TextStyle(fontSize: 13, color: KJColors.inkSoft)),
        ),
      ],
    );
  }

  Future<void> _toggleBookmark(String mkCode, bool currently) async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null) return;
    try {
      if (currently) {
        await repo.removeBookmark(mkCode);
      } else {
        await repo.addBookmark(mkCode);
      }
      ref.invalidate(mahakoshBookmarkCodesProvider);
      ref.invalidate(mahakoshBookmarksProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.msBookmarkError('$e'))));
      }
    }
  }

  /// A bookmark whose chart is no longer on Mahakosh — kept visible (not
  /// dropped) so it doesn't look like a bug, with a quick way to remove it.
  Widget _unavailableBookmarkRow(String mkCode) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(context.l10n.msChartCode(mkCode),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KJColors.inkSoft)),
          subtitle: Text(context.l10n.msNoLongerAvailable,
              style: TextStyle(fontSize: 12, color: KJColors.inkSoft)),
          trailing: IconButton(
            icon: Icon(Icons.bookmark, size: 20, color: KJColors.maroon),
            tooltip: context.l10n.msRemoveBookmark,
            visualDensity: VisualDensity.compact,
            onPressed: () => _toggleBookmark(mkCode, true),
          ),
        ),
      );

  Widget _chartRow(MahakoshChartSummary r, Set<String> bookmarked) {
    final isBm = bookmarked.contains(r.mkCode);
    final parts = [
      if (r.birthYear != null) 'b. ${r.birthYear}',
      if (r.locationGeneral.isNotEmpty) r.locationGeneral,
      if (r.yogaCount > 0) '${r.yogaCount} yogas',
      if (r.eventCount > 0) '${r.eventCount} events',
      DateFormat('MMM yyyy').format(r.createdAt),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(context.l10n.hcChartAnonymized(r.mkCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(parts.join(' · '), style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isBm ? Icons.bookmark : Icons.bookmark_border,
                  size: 20, color: isBm ? KJColors.maroon : KJColors.inkSoft),
              tooltip: isBm
                  ? context.l10n.msRemoveBookmark
                  : context.l10n.msBookmark,
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleBookmark(r.mkCode, isBm),
            ),
            PopupMenuButton<void>(
              tooltip: context.l10n.msMore,
              icon: Icon(Icons.more_vert, size: 20, color: KJColors.inkSoft),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  onTap: () => _hideChart(r),
                  child: Text(context.l10n.msHideFromView),
                ),
                PopupMenuItem(
                  onTap: () => showReportChartSheet(context, ref, r.mkCode,
                      onReported: () => _removeRow(r)),
                  child: Text(context.l10n.rdReport),
                ),
              ],
            ),
            Icon(Icons.chevron_right, size: 20, color: KJColors.inkSoft),
          ],
        ),
        onTap: () => context.push('/mahakosh/chart/${r.mkCode}'),
      ),
    );
  }

  /// Remove a chart from whichever list is currently showing it —
  /// shared by the hide and report flows below. Returns whether it was
  /// found in _results (vs. _recent), so callers can restore/reload the
  /// right list.
  bool _removeRow(MahakoshChartSummary r) {
    final inSearchResults = _searched && _results.contains(r);
    setState(() {
      if (inSearchResults) {
        _results.remove(r);
        if (_total != null) _total = _total! - 1;
      } else {
        _recent.remove(r);
        if (_communityTotal != null) _communityTotal = _communityTotal! - 1;
      }
    });
    return inSearchResults;
  }

  void _restoreRow(MahakoshChartSummary r, bool inSearchResults) {
    setState(() {
      if (inSearchResults) {
        _results.add(r);
        if (_total != null) _total = _total! + 1;
      } else {
        _recent.add(r);
        if (_communityTotal != null) _communityTotal = _communityTotal! + 1;
      }
    });
  }

  /// Hide a chart from THIS user's Mahakosh view only (§2.7a). Optimistic:
  /// removes it from whichever list is showing, then calls the RPC; reverts
  /// and re-shows an error if the call fails. The "Undo" snackbar action
  /// unhides it and reloads.
  Future<void> _hideChart(MahakoshChartSummary r) async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null) return;

    final inSearchResults = _removeRow(r);

    try {
      await repo.hideChart(r.mkCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.rdHidden(r.mkCode)),
        action: SnackBarAction(
          label: context.l10n.rdUndo,
          onPressed: () async {
            await repo.unhideChart(r.mkCode);
            if (inSearchResults) {
              await _search();
            } else {
              await _loadRecent();
            }
          },
        ),
      ));
    } catch (e) {
      _restoreRow(r, inSearchResults);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.rdHideError('$e'))));
      }
    }
  }

  Future<void> _openQueryPanel() async {
    final result = await showModalBottomSheet<(List<_FilterEntry>, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KJColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QueryPanel(initial: _filters, combineOp: _combineOp),
    );
    if (result == null) return;
    setState(() {
      _filters
        ..clear()
        ..addAll(result.$1);
      _combineOp = result.$2;
    });
    if (_filters.isEmpty) {
      setState(() => _searched = false);
    } else {
      await _search();
    }
  }
}

/// The combination-query builder, shown as a bottom sheet from the app-bar
/// filter button. Manages a working copy of the filter list and returns
/// (filters, combineOp) when the user taps Search.
class _QueryPanel extends StatefulWidget {
  const _QueryPanel({required this.initial, required this.combineOp});
  final List<_FilterEntry> initial;
  final String combineOp;

  @override
  State<_QueryPanel> createState() => _QueryPanelState();
}

class _QueryPanelState extends State<_QueryPanel> {
  late List<_FilterEntry> _filters;
  late String _combineOp;

  @override
  void initState() {
    super.initState();
    _filters = [
      for (final e in widget.initial)
        _FilterEntry(e.filter)..negated = e.negated,
    ];
    _combineOp = widget.combineOp;
  }

  Future<void> _addFilter() async {
    final filter = await showModalBottomSheet<AtomicFilter>(
      context: context,
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      builder: (ctx) => const _FilterBuilderSheet(),
    );
    if (filter != null) {
      setState(() => _filters.add(_FilterEntry(filter)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(context.l10n.msFilterCharts,
                        style: KJTheme.serif(size: 18))),
                if (_filters.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_filters.clear),
                    child: Text(context.l10n.msClearAll),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _filters)
                  InputChip(
                    label: Text('${e.negated ? context.l10n.msNot : ''}'
                        '${mahakoshFilterLabel(context.l10n, e.filter)}'),
                    labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: e.negated ? KJColors.maroon : KJColors.ink),
                    onPressed: () => setState(() => e.negated = !e.negated),
                    onDeleted: () => setState(() => _filters.remove(e)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(context.l10n.addFilter),
                  onPressed: _addFilter,
                ),
              ],
            ),
            if (_filters.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text(context.l10n.msCombineWith,
                        style:
                            TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
                    const SizedBox(width: 10),
                    for (final op in ['AND', 'OR'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(op),
                          selected: _combineOp == op,
                          labelStyle: TextStyle(
                              fontSize: 12,
                              color: _combineOp == op
                                  ? KJColors.paper
                                  : KJColors.ink),
                          onSelected: (_) => setState(() => _combineOp = op),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context, (_filters, _combineOp)),
              child: Text(_filters.isEmpty
                  ? context.l10n.msClearFiltersBrowse
                  : context.l10n.msSearchCharts),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBuilderSheet extends StatefulWidget {
  const _FilterBuilderSheet();

  @override
  State<_FilterBuilderSheet> createState() => _FilterBuilderSheetState();
}

class _FilterBuilderSheetState extends State<_FilterBuilderSheet> {
  String _type = 'planet_in_house';
  Planet _planet = Planet.mars;
  int _sign = 0;
  int _house = 7;
  int _nakshatra = 0;
  final _yogaController = TextEditingController();
  final _tagController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
                  onSelected: (_) => setState(() => _type = code),
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
              decoration: InputDecoration(
                  labelText: context.l10n.msYogaCode,
                  helperText:
                      'e.g. gaja_kesari, raj_yoga, mangal_dosha, kaal_sarp'),
            ),
          if (_type == 'life_event')
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                  labelText: context.l10n.msEventTag,
                  helperText: 'e.g. marriage, career_change, transplant'),
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
                      if (d != null) setState(() => _dateFrom = d);
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
                      if (d != null) setState(() => _dateTo = d);
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
          FilledButton(
            onPressed: () {
              if (_type == 'birth_range' &&
                  _dateFrom == null &&
                  _dateTo == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.msSetDateBound)));
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
