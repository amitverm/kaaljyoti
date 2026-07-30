/// Screen 08 — Mahakosh Search. Combination query builder (atomic
/// filter chips, AND/OR combination, per-chip NOT) over the community
/// chart index, results below.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../mahakosh/filter_builder_sheet.dart';
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

  /// Why the browse list is empty, when it's empty because of a failure
  /// rather than because the community is.
  String? _browseError;

  // Which browse tab is showing when not searching:
  // 'browse' | 'bookmarks' | 'recent'.
  String _tab = 'browse';

  /// Paging. Both lists are capped server-side, so before this the
  /// screen would announce "312 charts match" and then show 25 with no
  /// way to reach the rest.
  static const _pageSize = 25;
  bool _loadingMore = false;

  bool get _moreResults => _total != null && _results.length < _total!;
  bool get _moreCommunity =>
      _communityTotal != null && _recent.length < _communityTotal!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecent());
  }

  Future<void> _loadRecent() async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null || !repo.isSignedIn) return;
    try {
      final res = await repo.recent(limit: _pageSize);
      if (mounted) {
        setState(() {
          _browseError = null;
          _communityTotal = res.total;
          _recent = res.results;
        });
      }
    } catch (e) {
      // This used to swallow everything as "best-effort", which meant a
      // hard backend failure rendered as "no charts yet" — indisputably
      // worse than an error, because it looks like an empty community
      // rather than a broken screen.
      if (mounted) setState(() => _browseError = '$e');
    }
  }

  /// Fetches the next page of whichever list is showing and APPENDS it.
  /// Guarded against re-entry so a double tap can't duplicate a page.
  Future<void> _loadMore() async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      if (_searched) {
        final res = await repo.search(_buildTree(),
            limit: _pageSize, offset: _results.length);
        if (mounted) {
          setState(() {
            _total = res.total;
            // Guard against a shifting corpus handing back a row we
            // already show — a duplicate key would be visible.
            final seen = {for (final r in _results) r.mkCode};
            _results.addAll(res.results.where((r) => !seen.contains(r.mkCode)));
          });
        }
      } else {
        final res =
            await repo.recent(limit: _pageSize, offset: _recent.length);
        if (mounted) {
          setState(() {
            _communityTotal = res.total;
            final seen = {for (final r in _recent) r.mkCode};
            _recent.addAll(res.results.where((r) => !seen.contains(r.mkCode)));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.msLoadMoreError('$e'))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// "Showing n of N" plus the button that fetches the next page.
  Widget _loadMoreFooter(int shown, int total) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          children: [
            Text(
              context.l10n.msShowingOf('$shown', '$total'),
              style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
            ),
            const SizedBox(height: 6),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              OutlinedButton(
                onPressed: _loadMore,
                child: Text(context.l10n.msLoadMore),
              ),
          ],
        ),
      );

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
      // A fresh search always starts at page one.
      final res = await repo.search(_buildTree(), limit: _pageSize);
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
        if (_moreResults) _loadMoreFooter(_results.length, _total!),
      ];

  List<Widget> _browseSection(Set<String> bookmarked) => [
        Row(
          children: [
            for (final t in [
              ('browse', context.l10n.msBrowse),
              ('bookmarks', context.l10n.msBookmarks),
              ('recent', context.l10n.msRecent),
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
        else if (_tab == 'recent')
          ..._recentChildren(bookmarked)
        else
          ..._bookmarkChildren(bookmarked),
      ];

  /// Charts opened on this device, most recent first. The codes are
  /// device-local; the summaries are whatever the already-loaded browse
  /// and search lists happen to hold, so this costs no extra fetch.
  /// A code we have no summary for is shown as a plain code row rather
  /// than dropped — it is still a real chart the user can open.
  List<Widget> _recentChildren(Set<String> bookmarked) {
    final codes = ref.watch(recentMahakoshProvider);
    if (codes.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(context.l10n.msNoRecent,
              style: TextStyle(fontSize: 13, color: KJColors.inkSoft)),
        ),
      ];
    }
    final known = {
      for (final r in [..._recent, ..._results]) r.mkCode: r,
    };
    return [
      Text(context.l10n.msRecentCount('${codes.length}'),
          style: _sectionLabelStyle),
      const SizedBox(height: 10),
      for (final code in codes)
        known[code] != null
            ? _chartRow(known[code]!, bookmarked)
            : _codeOnlyRow(code),
    ];
  }

  /// A recently-opened chart we hold no summary for — still openable.
  Widget _codeOnlyRow(String mkCode) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(context.l10n.msChartCode(mkCode),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          onTap: () => _openChart(mkCode),
        ),
      );

  /// Opens a community chart and records the visit for the Recent tab.
  void _openChart(String mkCode) {
    ref.read(recentMahakoshProvider.notifier).touch(mkCode);
    context.push('/mahakosh/chart/$mkCode');
  }

  List<Widget> _communityChildren(Set<String> bookmarked) => [
        Text(
          _communityTotal == null
              ? context.l10n.msCommunityCharts
              : context.l10n.msCommunityChartsCount(_communityTotal!),
          style: _sectionLabelStyle,
        ),
        const SizedBox(height: 10),
        if (_browseError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.msBrowseError(_browseError!),
                  style: TextStyle(fontSize: 13, color: KJColors.inkSoft),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: _loadRecent,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          )
        else if (_recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.l10n.msNoCharts,
              style: TextStyle(fontSize: 13, color: KJColors.inkSoft),
            ),
          ),
        for (final r in _recent) _chartRow(r, bookmarked),
        if (_moreCommunity) _loadMoreFooter(_recent.length, _communityTotal!),
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

  /// A result row. Every chart in this corpus is anonymous, so the
  /// per-row "(anonymized)" suffix said nothing that the screen doesn't
  /// already say once — and the upload month and general location did
  /// no work in choosing between charts either. What's left is the code
  /// and the birth year, plus the yoga/event counts when a chart has
  /// them: in a research corpus those counts are the one thing that
  /// makes one record worth more than another.
  Widget _chartRow(MahakoshChartSummary r, Set<String> bookmarked) {
    final isBm = bookmarked.contains(r.mkCode);
    final parts = [
      if (r.birthYear != null) 'b. ${r.birthYear}',
      if (r.yogaCount > 0) context.l10n.msYogaCount('${r.yogaCount}'),
      if (r.eventCount > 0) context.l10n.msEventCount('${r.eventCount}'),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(context.l10n.msChartCode(r.mkCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: parts.isEmpty
            ? null
            : Text(parts.join(' · '), style: const TextStyle(fontSize: 12)),
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
            // No chevron: the tile is tappable, which already reads as
            // navigable, and a third trailing glyph on every row only
            // crowded the two that do something.
          ],
        ),
        onTap: () => _openChart(r.mkCode),
      ),
    );
  }

  /// Remove a chart from whichever list is currently showing it —
  /// shared by the hide and report flows below. Returns whether it was
  /// found in _results (vs. _recent), so callers can restore/reload the
  /// right list.
  bool _removeRow(MahakoshChartSummary r) {
    final inSearchResults = _searched && _results.contains(r);
    // A chart the user hid or reported must not survive in the Recent
    // tab, which would otherwise hand it straight back to them.
    ref.read(recentMahakoshProvider.notifier).forget([r.mkCode]);
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
    final filter = await showFilterBuilderSheet(context);
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
