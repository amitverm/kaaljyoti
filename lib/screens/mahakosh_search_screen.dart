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
  bool _searching = false;
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
    setState(() => _searching = true);
    try {
      final res = await repo.search(_buildTree());
      setState(() {
        _searched = true;
        _total = res.total;
        _results = res.results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mahakoshRepoProvider);
    final user = ref.watch(authUserProvider).value;

    return TEScaffold(
      section: TESection.mahakosh,
      appBar: AppBar(
        title: const Text('Mahakosh'),
        actions: [
          if (repo != null && user != null)
            IconButton(
              tooltip: 'Filter charts',
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
          ? const EmptyState(
              message:
                  'Mahakosh needs the backend configured (SUPABASE_URL / '
                  'SUPABASE_ANON_KEY). See supabase/README.md.')
          : user == null
              ? EmptyState(
                  message:
                      'Sign in to search the community research repository.',
                  actionLabel: 'Sign in',
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
      children: _searched
          ? _resultsSection(bookmarked)
          : _browseSection(bookmarked),
    );
  }

  TextStyle get _sectionLabelStyle => TEType.kicker();

  List<Widget> _resultsSection(Set<String> bookmarked) => [
        Row(
          children: [
            Expanded(
              child: Text('${_total ?? 0} charts match',
                  style: TETheme.mono(size: 12, color: TEColors.inkSoft)),
            ),
            TextButton(
              onPressed: _openQueryPanel,
              child: Text('Filters (${_filters.length})'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _filters.clear();
                _searched = false;
              }),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final r in _results) _chartRow(r, bookmarked),
      ];

  List<Widget> _browseSection(Set<String> bookmarked) => [
        Row(
          children: [
            for (final t in const [
              ('browse', 'Browse'),
              ('bookmarks', 'Bookmarks'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t.$2),
                  selected: _tab == t.$1,
                  labelStyle: TextStyle(
                      color: _tab == t.$1 ? TEColors.paper : TEColors.ink),
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
              ? 'COMMUNITY CHARTS'
              : 'COMMUNITY CHARTS · $_communityTotal contributed',
          style: _sectionLabelStyle,
        ),
        const SizedBox(height: 10),
        if (_recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No charts contributed yet — be the first: share a kundli '
              'from its Edit screen.',
              style: TextStyle(fontSize: 13, color: TEColors.inkSoft),
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
                  'No bookmarks yet. Tap the bookmark icon on any chart to '
                  'keep it here for quick access.',
                  style: TextStyle(fontSize: 13, color: TEColors.inkSoft),
                ),
              ),
            ]
          : [
              Text('BOOKMARKED · ${list.length}', style: _sectionLabelStyle),
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
          child: Text('Could not load bookmarks: $e',
              style: TextStyle(fontSize: 13, color: TEColors.inkSoft)),
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
            SnackBar(content: Text('Could not update bookmark: $e')));
      }
    }
  }

  /// A bookmark whose chart is no longer on Mahakosh — kept visible (not
  /// dropped) so it doesn't look like a bug, with a quick way to remove it.
  Widget _unavailableBookmarkRow(String mkCode) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text('Chart $mkCode',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TEColors.inkSoft)),
          subtitle: Text('No longer available on Mahakosh',
              style: TextStyle(fontSize: 12, color: TEColors.inkSoft)),
          trailing: IconButton(
            icon: Icon(Icons.bookmark, size: 20, color: TEColors.maroon),
            tooltip: 'Remove bookmark',
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
        title: Text('Chart ${r.mkCode} (anonymized)',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(parts.join(' · '),
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                  isBm ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: isBm ? TEColors.maroon : TEColors.inkSoft),
              tooltip: isBm ? 'Remove bookmark' : 'Bookmark',
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleBookmark(r.mkCode, isBm),
            ),
            PopupMenuButton<void>(
              tooltip: 'More',
              icon: Icon(Icons.more_vert, size: 20, color: TEColors.inkSoft),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  onTap: () => _hideChart(r),
                  child: const Text('Hide from my view'),
                ),
                PopupMenuItem(
                  onTap: () => showReportChartSheet(context, ref, r.mkCode,
                      onReported: () => _removeRow(r)),
                  child: const Text('Report...'),
                ),
              ],
            ),
            Icon(Icons.chevron_right, size: 20, color: TEColors.inkSoft),
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
        content: Text('Hidden Chart ${r.mkCode} from your view.'),
        action: SnackBarAction(
          label: 'Undo',
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not hide chart: $e')));
      }
    }
  }

  Future<void> _openQueryPanel() async {
    final result = await showModalBottomSheet<(List<_FilterEntry>, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TEColors.paper,
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
      for (final e in widget.initial) _FilterEntry(e.filter)..negated = e.negated,
    ];
    _combineOp = widget.combineOp;
  }

  Future<void> _addFilter() async {
    final filter = await showModalBottomSheet<AtomicFilter>(
      context: context,
      backgroundColor: TEColors.paper,
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
                    child:
                        Text('Filter charts', style: TETheme.serif(size: 18))),
                if (_filters.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_filters.clear),
                    child: const Text('Clear all'),
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
                    label:
                        Text('${e.negated ? 'NOT ' : ''}${e.filter.label}'),
                    labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: e.negated ? TEColors.maroon : TEColors.ink),
                    onPressed: () => setState(() => e.negated = !e.negated),
                    onDeleted: () => setState(() => _filters.remove(e)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add filter'),
                  onPressed: _addFilter,
                ),
              ],
            ),
            if (_filters.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text('Combine with',
                        style: TextStyle(
                            fontSize: 12.5, color: TEColors.inkSoft)),
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
                                  ? TEColors.paper
                                  : TEColors.ink),
                          onSelected: (_) => setState(() => _combineOp = op),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, (_filters, _combineOp)),
              child: Text(_filters.isEmpty
                  ? 'Clear filters & browse'
                  : 'Search charts'),
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

  static const _types = {
    'planet_in_house': 'Planet in house',
    'planet_in_sign': 'Planet in sign',
    'planet_in_nakshatra': 'Planet in nakshatra',
    'yoga_present': 'Yoga present',
    'life_event': 'Life event tag',
    'birth_range': 'Birth date',
  };

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
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
                  child: Text('Add filter', style: TETheme.serif(size: 18))),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types.entries)
                ChoiceChip(
                  label: Text(t.value),
                  selected: _type == t.key,
                  labelStyle: TextStyle(
                      fontSize: 12,
                      color:
                          _type == t.key ? TEColors.paper : TEColors.ink),
                  onSelected: (_) => setState(() => _type = t.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_type.startsWith('planet_'))
            DropdownButtonFormField<Planet>(
              value: _planet,
              decoration: const InputDecoration(labelText: 'Planet'),
              items: [
                for (final p in Planet.values)
                  DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName,
                          style: TextStyle(color: planetInk(p)))),
              ],
              onChanged: (p) => setState(() => _planet = p!),
            ),
          const SizedBox(height: 10),
          if (_type == 'planet_in_sign')
            DropdownButtonFormField<int>(
              value: _sign,
              decoration: const InputDecoration(labelText: 'Sign'),
              items: [
                for (final s in ZodiacSign.values)
                  DropdownMenuItem(
                      value: s.index, child: Text(s.western)),
              ],
              onChanged: (v) => setState(() => _sign = v!),
            ),
          if (_type == 'planet_in_house')
            DropdownButtonFormField<int>(
              value: _house,
              decoration:
                  const InputDecoration(labelText: 'House (from lagna)'),
              items: [
                for (var h = 1; h <= 12; h++)
                  DropdownMenuItem(value: h, child: Text('${h}H')),
              ],
              onChanged: (v) => setState(() => _house = v!),
            ),
          if (_type == 'planet_in_nakshatra')
            DropdownButtonFormField<int>(
              value: _nakshatra,
              decoration: const InputDecoration(labelText: 'Nakshatra'),
              items: [
                for (final n in Nakshatra.values)
                  DropdownMenuItem(
                      value: n.index, child: Text(n.displayName)),
              ],
              onChanged: (v) => setState(() => _nakshatra = v!),
            ),
          if (_type == 'yoga_present')
            TextField(
              controller: _yogaController,
              decoration: const InputDecoration(
                  labelText: 'Yoga code',
                  helperText:
                      'e.g. gaja_kesari, raj_yoga, mangal_dosha, kaal_sarp'),
            ),
          if (_type == 'life_event')
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                  labelText: 'Event tag',
                  helperText: 'e.g. marriage, career_change, transplant'),
            ),
          if (_type == 'birth_range') ...[
            Text('Born between (either side optional)',
                style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft)),
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
                        ? 'From date'
                        : TEDate.date(_dateFrom!)),
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
                    child: Text(
                        _dateTo == null ? 'To date' : TEDate.date(_dateTo!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Long-press a button to clear it.',
                style: TextStyle(fontSize: 11, color: TEColors.inkSoft)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              if (_type == 'birth_range' &&
                  _dateFrom == null &&
                  _dateTo == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Set at least one date bound.')));
                return;
              }
              final filter = switch (_type) {
                'planet_in_sign' => AtomicFilter(
                    type: _type, planet: _planet.name, sign: _sign),
                'planet_in_house' => AtomicFilter(
                    type: _type, planet: _planet.name, house: _house),
                'planet_in_nakshatra' => AtomicFilter(
                    type: _type,
                    planet: _planet.name,
                    nakshatra: _nakshatra),
                'yoga_present' => AtomicFilter(
                    type: _type,
                    yogaCode: _yogaController.text.trim()),
                'birth_range' => AtomicFilter(
                    type: _type,
                    dateFrom:
                        _dateFrom == null ? null : _fmtDate(_dateFrom!),
                    dateTo: _dateTo == null ? null : _fmtDate(_dateTo!),
                  ),
                _ => AtomicFilter(
                    type: 'life_event', tag: _tagController.text.trim()),
              };
              Navigator.pop(context, filter);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
