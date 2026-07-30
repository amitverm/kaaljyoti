/// Riverpod wiring. Widgets invalidate the Future providers after
/// mutations (e.g. ref.invalidate(kundlisProvider)).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/admin_repository.dart';
import '../charts/chart_style.dart';
import '../core/astro/bhava_bala.dart';
import '../core/astro/compare.dart';
import '../core/astro/dasha/dasha.dart';
import '../core/astro/ephemeris_service.dart';
import '../core/astro/models.dart';
import '../core/astro/shadbala.dart';
import '../core/astro/snapshot_builder.dart';
import '../core/astro/transit_scan.dart';
import '../core/astro/varshphal.dart';
import '../core/constants.dart';
import '../core/date_format.dart';
import '../data/dashboard_repository.dart';
import '../data/export_repository.dart';
import '../data/kundli_event_repository.dart';
import '../data/kundli_repository.dart';
import '../data/models.dart';
import '../data/settings_repository.dart';
import '../mahakosh/compare_subject.dart';
import '../mahakosh/discussion_repository.dart';
import '../mahakosh/mahakosh_repository.dart';
import '../mahakosh/models.dart';
import '../mahakosh/research_repository.dart';
import '../services/place_lookup_service.dart';
import '../services/push_service.dart';
import '../services/sync_service.dart';
import '../widgetsystem/astro_module.dart';

// --- Repositories -----------------------------------------------------------

final kundliRepoProvider = Provider((ref) => KundliRepository());
final kundliEventRepoProvider = Provider((ref) => KundliEventRepository());
final dashboardRepoProvider = Provider((ref) => DashboardRepository());
final exportRepoProvider = Provider((ref) => ExportRepository());
final settingsRepoProvider = Provider((ref) => SettingsRepository());
final placeLookupProvider = Provider((ref) => PlaceLookupService());

// --- Backend (null when SUPABASE_URL/ANON_KEY not provided) ----------------

final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => kBackendConfigured ? Supabase.instance.client : null,
);

final mahakoshRepoProvider = Provider<MahakoshRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : MahakoshRepository(client);
});

/// A community (Mahakosh) chart fetched by MK code — including its life
/// events. Shared so callers can invalidate it after changing the chart's
/// events (otherwise the cached copy shows pre-change events).
final mahakoshChartProvider =
    FutureProvider.family<AnonymizedChart, String>((ref, mkCode) {
  final repo = ref.watch(mahakoshRepoProvider);
  if (repo == null) throw StateError('Backend not configured');
  return repo.fetchChart(mkCode);
});

/// MK codes the signed-in user has bookmarked — drives the star toggle on
/// chart rows and the detail screen. Invalidated after any bookmark change.
final mahakoshBookmarkCodesProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(mahakoshRepoProvider);
  if (repo == null) return {};
  return repo.bookmarkCodes();
});

/// The user's bookmarked community charts (for the Bookmarks tab). Entries
/// whose chart is null are bookmarks whose chart is no longer on Mahakosh.
final mahakoshBookmarksProvider =
    FutureProvider<List<BookmarkEntry>>((ref) async {
  final repo = ref.watch(mahakoshRepoProvider);
  if (repo == null) return [];
  return repo.bookmarks();
});

/// Mahakosh chart codes this device has opened, most recent first.
/// Device-local like the kundli recents — "what I was just looking at"
/// is a property of this device, not of the account, and keeping it off
/// the server means it needs no schema and leaks nothing about a user's
/// research interests.
class RecentMahakoshNotifier extends StateNotifier<List<String>> {
  RecentMahakoshNotifier(this._repo) : super(const []) {
    _repo.recentMahakoshCodes().then((codes) {
      if (!mounted) return;
      state = [...state, ...codes.where((c) => !state.contains(c))];
    });
  }

  final SettingsRepository _repo;

  void touch(String mkCode) {
    if (state.isNotEmpty && state.first == mkCode) return;
    final next = [mkCode, ...state.where((c) => c != mkCode)];
    state = next;
    _repo.setRecentMahakoshCodes(next);
  }

  /// Drops codes whose chart is gone — a hidden, reported or withdrawn
  /// chart must not keep a slot in the Recent tab.
  void forget(Iterable<String> codes) {
    final gone = codes.toSet();
    if (!state.any(gone.contains)) return;
    final next = state.where((c) => !gone.contains(c)).toList();
    state = next;
    _repo.setRecentMahakoshCodes(next);
  }
}

final recentMahakoshProvider =
    StateNotifierProvider<RecentMahakoshNotifier, List<String>>(
  (ref) => RecentMahakoshNotifier(ref.watch(settingsRepoProvider)),
);

final researchRepoProvider = Provider<ResearchRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : ResearchRepository(client);
});

final discussionRepoProvider = Provider<DiscussionRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : DiscussionRepository(client);
});

/// A chart's discussion thread, oldest first. Invalidated after any
/// comment write (add/edit/delete/report/block); autoDispose so
/// re-entering the screen always refetches — moderation actions land
/// from OTHER screens (admin queue) and other users, and a keep-alive
/// cache would show a stale thread on revisit.
final chartCommentsProvider = FutureProvider.autoDispose
    .family<List<ChartComment>, String>((ref, mkCode) async {
  final repo = ref.watch(discussionRepoProvider);
  if (repo == null) return [];
  return repo.comments(mkCode);
});

/// Visible-comment count for the Discussion entry card on the chart
/// screen. Kept separate from [chartCommentsProvider] so the dashboard
/// doesn't load whole threads just to label a card.
final chartCommentCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, mkCode) async {
  final repo = ref.watch(discussionRepoProvider);
  if (repo == null) return 0;
  return repo.commentCount(mkCode);
});

/// The user's chosen discussion display name (null until first set —
/// the composer prompts for it before the first comment ever posts).
final myDisplayNameProvider = FutureProvider<String?>((ref) async {
  // Re-fetch on auth changes so a sign-out clears the cached name.
  ref.watch(authUserProvider);
  final repo = ref.watch(discussionRepoProvider);
  if (repo == null) return null;
  return repo.myDisplayName();
});

final syncServiceProvider = Provider<SyncService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? null
      : SyncService(client, ref.watch(kundliRepoProvider),
          ref.watch(kundliEventRepoProvider));
});

final adminRepoProvider = Provider<AdminRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AdminRepository(client);
});

/// Keeps personal kundlis in sync across devices without any manual
/// step: pulls whenever a signed-in session appears (fresh sign-in OR an
/// app launch that restored a session) and subscribes to server-side
/// changes so a kundli synced on one device shows up on the others live.
/// Something must keep this alive — the root app widget watches it.
final liveSyncProvider = Provider<void>((ref) {
  final sync = ref.watch(syncServiceProvider);
  // Rebuild whenever the signed-in user changes so we (re)subscribe for
  // the new user and stop for none.
  final user = ref.watch(authUserProvider).valueOrNull;
  if (sync == null || user == null) return;

  sync.start(() {
    ref.invalidate(kundlisProvider);
    // Events sync inside the kundli payload — refresh any open Events screen
    // too (invalidating the family clears every per-kundli instance).
    ref.invalidate(kundliEventsProvider);
  });
  ref.onDispose(sync.stop);
});

final pushServiceProvider = Provider<PushService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : PushService(client);
});

/// Registers this device for push whenever a signed-in session appears
/// and unregisters (token row deleted) on sign-out / user switch. Inert
/// unless the FIREBASE_* build defines are present — see push_service.dart.
/// The root app widget keeps this alive alongside [liveSyncProvider].
final pushRegistrationProvider = Provider<void>((ref) {
  final push = ref.watch(pushServiceProvider);
  final user = ref.watch(authUserProvider).valueOrNull;
  if (push == null || user == null) return;
  push.start();
  ref.onDispose(() => push.stop());
});

/// Current auth user (null = signed out or backend unconfigured).
final authUserProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(null);
  return client.auth.onAuthStateChange
      .map((e) => e.session?.user)
      .distinct((a, b) => a?.id == b?.id);
});

/// Whether the signed-in user is an admin (drives the hidden Admin nav
/// entry — see admin_repository.dart's doc comment for the actual
/// security model, which does NOT depend on this provider). Re-checked
/// whenever auth state changes.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  ref.watch(authUserProvider);
  if (repo == null) return false;
  return repo.isAdmin();
});

// --- Kundlis ----------------------------------------------------------------

/// The user's saved kundlis. Deliberately [KundliRepository.saved] and
/// not `all()`: an un-kept instant Prashna exists as a row but must not
/// appear in a list the user reads as "my charts".
final kundlisProvider = FutureProvider<List<Kundli>>(
  (ref) => ref.watch(kundliRepoProvider).saved(),
);

/// The kundli whose dashboard is active.
final activeKundliIdProvider = StateProvider<String?>((ref) => null);

// --- Kundli list state ------------------------------------------------------
// Everything the home screen needs to make a library of several hundred
// charts findable: ordering, pinning, recency, search, and filtering.

/// What a filter chip stands for. Relation tags come from the closed set
/// on the kundli row; labels are user-created.
enum KundliFilterKind { relation, label }

typedef KundliFilter = ({KundliFilterKind kind, String value});

/// Free-text query over name, note, place, labels, and relation tag.
final kundliSearchProvider = StateProvider<String>((ref) => '');

/// The single active filter chip, or null for "All".
final kundliFilterProvider = StateProvider<KundliFilter?>((ref) => null);

class KundliSortNotifier extends StateNotifier<KundliSort> {
  KundliSortNotifier(this._repo) : super(KundliSort.recent) {
    // Don't clobber a choice made before prefs finished loading — the
    // list is interactive from the first frame, and the stored value
    // resolving late would silently revert the user's pick.
    // `mounted` because the container can be torn down while the prefs
    // read is still in flight — writing state then throws.
    _repo.kundliSort().then((s) {
      if (mounted && !_chosen) state = s;
    });
  }

  final SettingsRepository _repo;
  bool _chosen = false;

  void select(KundliSort sort) {
    _chosen = true;
    state = sort;
    _repo.setKundliSort(sort);
  }
}

final kundliSortProvider =
    StateNotifierProvider<KundliSortNotifier, KundliSort>(
  (ref) => KundliSortNotifier(ref.watch(settingsRepoProvider)),
);

class KundliDensityNotifier extends StateNotifier<KundliDensity> {
  KundliDensityNotifier(this._repo) : super(KundliDensity.comfortable) {
    _repo.kundliDensity().then((d) {
      if (mounted && !_chosen) state = d;
    });
  }

  final SettingsRepository _repo;
  bool _chosen = false;

  void select(KundliDensity density) {
    _chosen = true;
    state = density;
    _repo.setKundliDensity(density);
  }
}

final kundliDensityProvider =
    StateNotifierProvider<KundliDensityNotifier, KundliDensity>(
  (ref) => KundliDensityNotifier(ref.watch(settingsRepoProvider)),
);

/// Pinned kundli ids. Uncapped — the astrologer decides what they keep
/// at the top, and a cap only bites the users with the biggest libraries.
class PinnedKundlisNotifier extends StateNotifier<Set<String>> {
  PinnedKundlisNotifier(this._repo) : super(const {}) {
    _repo.pinnedKundliIds().then((ids) {
      // Don't clobber a pin made before prefs finished loading.
      if (mounted && state.isEmpty) state = ids.toSet();
    });
  }

  final SettingsRepository _repo;

  bool isPinned(String id) => state.contains(id);

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    _set(next);
  }

  void addAll(Iterable<String> ids) => _set({...state, ...ids});

  void removeAll(Iterable<String> ids) =>
      _set({...state}..removeAll(ids.toSet()));

  void _set(Set<String> ids) {
    state = ids;
    _repo.setPinnedKundliIds(ids.toList(growable: false));
  }
}

final pinnedKundlisProvider =
    StateNotifierProvider<PinnedKundlisNotifier, Set<String>>(
  (ref) => PinnedKundlisNotifier(ref.watch(settingsRepoProvider)),
);

/// Opened-kundli ids, most recent first. Drives both the recents strip
/// and the default sort.
class RecentKundlisNotifier extends StateNotifier<List<String>> {
  RecentKundlisNotifier(this._repo) : super(const []) {
    _repo.recentKundliIds().then((ids) {
      // Merge rather than assign: a kundli opened before prefs resolved
      // must stay at the head.
      if (!mounted) return;
      state = [...state, ...ids.where((id) => !state.contains(id))];
    });
  }

  final SettingsRepository _repo;

  /// Records an open. Idempotent per position — re-opening the head of
  /// the list writes nothing.
  void touch(String id) {
    if (state.isNotEmpty && state.first == id) return;
    final next = [id, ...state.where((e) => e != id)];
    state = next;
    _repo.setRecentKundliIds(next);
  }

  /// Drops deleted kundlis, so they can't hold a slot in the strip.
  void forget(Iterable<String> ids) {
    final gone = ids.toSet();
    if (!state.any(gone.contains)) return;
    final next = state.where((id) => !gone.contains(id)).toList();
    state = next;
    _repo.setRecentKundliIds(next);
  }
}

final recentKundlisProvider =
    StateNotifierProvider<RecentKundlisNotifier, List<String>>(
  (ref) => RecentKundlisNotifier(ref.watch(settingsRepoProvider)),
);

/// Everything the list screen renders, resolved in one place so the
/// widget tree stays a pure function of it.
class KundliListData {
  const KundliListData({
    required this.pinned,
    required this.others,
    required this.recents,
    required this.labels,
    required this.relationTags,
    required this.totalCount,
  });

  /// Pinned matches, in the active sort order.
  final List<Kundli> pinned;

  /// Everything else that survived search + filter, in sort order.
  final List<Kundli> others;

  /// Head of the recents list — the strip. Excludes pinned charts,
  /// which already have a permanent home above.
  final List<Kundli> recents;

  /// Every label in use across the whole library, alphabetical — the
  /// filter chip source. Computed over all kundlis, not the filtered
  /// set, so selecting a chip never removes the other chips.
  final List<String> labels;

  /// Relation tags actually in use, so the chip row doesn't offer
  /// "Spouse" to someone who has none.
  final List<String> relationTags;

  /// Size of the library before search/filter — for the "n of m" line.
  final int totalCount;

  int get visibleCount => pinned.length + others.length;
  bool get isEmpty => visibleCount == 0;
}

/// Lowercase + strip Latin diacritics so "Renée" matches "renee". Indian
/// names are routinely typed both ways.
String normalizeForSearch(String input) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÑÇ';
  const to = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString().toLowerCase().trim();
}

final kundliListDataProvider = Provider<AsyncValue<KundliListData>>((ref) {
  final async = ref.watch(kundlisProvider);
  final query = normalizeForSearch(ref.watch(kundliSearchProvider));
  final filter = ref.watch(kundliFilterProvider);
  final sort = ref.watch(kundliSortProvider);
  final pinnedIds = ref.watch(pinnedKundlisProvider);
  final recentIds = ref.watch(recentKundlisProvider);

  return async.whenData((all) {
    final labels = <String>{for (final k in all) ...k.labels}.toList()..sort();
    final relationTags = <String>{for (final k in all) k.relationTag}.toList()
      ..sort();

    bool matchesFilter(Kundli k) => switch (filter) {
          null => true,
          (kind: KundliFilterKind.relation, value: final v) =>
            k.relationTag == v,
          (kind: KundliFilterKind.label, value: final v) =>
            k.labels.contains(v),
        };

    bool matchesQuery(Kundli k) {
      if (query.isEmpty) return true;
      final haystack = normalizeForSearch([
        k.name,
        k.note ?? '',
        k.placeName,
        k.relationTag,
        ...k.labels,
      ].join(' '));
      // Every whitespace-separated term must appear, so "sharma pune"
      // narrows instead of widening.
      return query.split(RegExp(r'\s+')).every(haystack.contains);
    }

    final matched = [
      for (final k in all)
        if (matchesFilter(k) && matchesQuery(k)) k,
    ];

    // Unseen kundlis sort after every seen one under `recent`.
    final recentRank = {
      for (var i = 0; i < recentIds.length; i++) recentIds[i]: i,
    };
    int compare(Kundli a, Kundli b) {
      final primary = switch (sort) {
        KundliSort.recent => () {
            final ra = recentRank[a.id] ?? recentIds.length;
            final rb = recentRank[b.id] ?? recentIds.length;
            return ra != rb
                ? ra.compareTo(rb)
                : b.createdAt.compareTo(a.createdAt);
          }(),
        // Newest first — the old list was created_at ASC, which buried
        // the chart you just cast at the bottom.
        KundliSort.added => b.createdAt.compareTo(a.createdAt),
        KundliSort.name =>
          normalizeForSearch(a.name).compareTo(normalizeForSearch(b.name)),
        KundliSort.birth => a.birthUtc.compareTo(b.birthUtc),
      };
      if (primary != 0) return primary;
      // Dart's List.sort is NOT stable, so equal keys would let rows
      // swap places between rebuilds — very visible on a list where most
      // charts share a creation date (an import) or have never been
      // opened. Break every tie deterministically.
      final byName =
          normalizeForSearch(a.name).compareTo(normalizeForSearch(b.name));
      return byName != 0 ? byName : a.id.compareTo(b.id);
    }

    matched.sort(compare);

    final byId = {for (final k in all) k.id: k};
    return KundliListData(
      pinned: [
        for (final k in matched)
          if (pinnedIds.contains(k.id)) k,
      ],
      others: [
        for (final k in matched)
          if (!pinnedIds.contains(k.id)) k,
      ],
      recents: [
        for (final id in recentIds)
          if (byId[id] != null && !pinnedIds.contains(id)) byId[id]!,
      ],
      labels: labels,
      relationTags: relationTags,
      totalCount: all.length,
    );
  });
});

/// Life events recorded on a kundli, chronologically. Invalidated after any
/// add/edit/delete on the Events screen.
final kundliEventsProvider = FutureProvider.family<List<KundliEvent>, String>(
  (ref, kundliId) => ref.watch(kundliEventRepoProvider).forKundli(kundliId),
);

/// Route id prefix for a Mahakosh community chart viewed through the
/// normal kundli machinery. These charts are NOT in local storage — they
/// live server-side and are recomputed on-device — so the id encodes the
/// mk_code and [resolveKundli] rebuilds an in-memory (synthetic) Kundli.
const kMahakoshKundliPrefix = 'mk_';

bool isMahakoshKundliId(String id) => id.startsWith(kMahakoshKundliPrefix);

/// Builds the in-memory Kundli that represents a Mahakosh community chart
/// so the shared dashboard/detail/export machinery can treat it like any
/// other kundli. The ayanamsa is pinned to the chart's own so the
/// recomputed snapshot matches how it was contributed (not the viewer's
/// default). Nothing here is persisted — the chart stays read-only,
/// server-owned, and anonymized (birth time withheld).
Kundli syntheticKundliForChart(AnonymizedChart chart) => Kundli(
      id: '$kMahakoshKundliPrefix${chart.mkCode}',
      name: 'Chart ${chart.mkCode}',
      relationTag: 'Mahakosh',
      birthUtc: chart.birthUtc!,
      latitude: chart.latitude ?? 0,
      longitude: chart.longitude ?? 0,
      timezoneName: chart.timezoneName ?? 'UTC',
      utcOffsetMinutes: chart.utcOffsetMinutes ?? 0,
      placeName: chart.placeName ?? chart.locationGeneral,
      ayanamsaOverrideId: chart.ayanamsaId,
      createdAt: chart.createdAt,
      updatedAt: chart.createdAt,
    );

/// Resolves a kundli id to a Kundli: local storage first, then — for a
/// Mahakosh id — the server chart rebuilt in memory. Returns null when
/// neither yields a chart with usable birth data.
Future<Kundli?> resolveKundli(Ref ref, String id) async {
  // Read both providers synchronously up front (before any await) so the
  // dependency is registered correctly and we never call ref.watch across
  // an async gap.
  final kundliRepo = ref.watch(kundliRepoProvider);
  final mahakoshRepo = ref.watch(mahakoshRepoProvider);

  final local = await kundliRepo.byId(id);
  if (local != null) return local;

  if (isMahakoshKundliId(id) && mahakoshRepo != null) {
    final chart = await mahakoshRepo
        .fetchChart(id.substring(kMahakoshKundliPrefix.length));
    if (chart.hasBirthData) return syntheticKundliForChart(chart);
  }
  return null;
}

/// A specific kundli by id (route-driven screens use this — never the
/// "active" fallback, which can point at a different kundli). Resolves
/// Mahakosh community charts too.
final kundliByIdProvider = FutureProvider.family<Kundli?, String>(
  (ref, id) => resolveKundli(ref, id),
);

final activeKundliProvider = FutureProvider<Kundli?>((ref) async {
  final id = ref.watch(activeKundliIdProvider);
  if (id == null) {
    final all = await ref.watch(kundlisProvider.future);
    return all.isEmpty ? null : all.first;
  }
  return ref.watch(kundliRepoProvider).byId(id);
});

// --- Settings ---------------------------------------------------------------

final defaultAyanamsaProvider = FutureProvider<int>(
  (ref) => ref.watch(settingsRepoProvider).defaultAyanamsaId(),
);

/// Appearance (text scale, font style, palette) — synchronous state so
/// theme changes apply instantly; loaded from prefs at startup and
/// persisted on every change.
class AppearanceNotifier extends StateNotifier<AppearanceSettings> {
  AppearanceNotifier(this._repo) : super(const AppearanceSettings()) {
    _repo.appearance().then((a) => state = a);
  }

  final SettingsRepository _repo;

  void update(AppearanceSettings a) {
    state = a;
    _repo.setAppearance(a);
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceNotifier, AppearanceSettings>(
  (ref) => AppearanceNotifier(ref.watch(settingsRepoProvider)),
);

/// App-wide date format. Mirrors its value into `KJDate.pref` (the
/// context-free source of truth used by every screen and module) both at
/// startup and on change. The app root watches this provider and includes it
/// in its rebuild key, so changing the format re-renders all dates instantly.
class DateFormatNotifier extends StateNotifier<DateFormatPref> {
  DateFormatNotifier(this._repo) : super(KJDate.pref) {
    _repo.dateFormat().then((p) {
      KJDate.pref = p;
      state = p;
    });
  }

  final SettingsRepository _repo;

  void update(DateFormatPref pref) {
    KJDate.pref = pref;
    state = pref;
    _repo.setDateFormat(pref);
  }
}

final dateFormatProvider =
    StateNotifierProvider<DateFormatNotifier, DateFormatPref>(
  (ref) => DateFormatNotifier(ref.watch(settingsRepoProvider)),
);

/// App language — 'system' (follow device locale) or a language code
/// ('en', 'hi'). The app root watches this and passes the forced locale
/// to MaterialApp, so changing it re-renders every screen instantly.
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(this._repo) : super('system') {
    _repo.language().then((code) => state = code);
  }

  final SettingsRepository _repo;

  void update(String code) {
    state = code;
    _repo.setLanguage(code);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(ref.watch(settingsRepoProvider)),
);

// --- Snapshot (computed once per chart, shared everywhere) ------------------

final _snapshotBuilder = SnapshotBuilder();

final snapshotProvider =
    FutureProvider.family<AstroSnapshot, String>((ref, kundliId) async {
  final kundli = await resolveKundli(ref, kundliId);
  if (kundli == null) throw StateError('Kundli not found');
  final int defaultAyanamsa = await ref.watch(defaultAyanamsaProvider.future);
  final int ayanamsa = kundli.ayanamsaOverrideId ?? defaultAyanamsa;
  return _snapshotBuilder.build(kundli.toBirthData(), ayanamsa);
});

/// Module context for a kundli — memoizes dasha trees per snapshot.
final moduleContextProvider =
    FutureProvider.family<ModuleContext, String>((ref, kundliId) async {
  final kundli = await resolveKundli(ref, kundliId);
  if (kundli == null) throw StateError('Kundli not found');
  final snapshot = await ref.watch(snapshotProvider(kundliId).future);
  final style = ChartStyle.values.firstWhere(
    (s) => s.name == kundli.chartStyle,
    orElse: () => ChartStyle.north,
  );
  return ModuleContext(
    kundli: kundli,
    snapshot: snapshot,
    chartStyle: style,
    anonymized: isMahakoshKundliId(kundliId),
  );
});

// --- Gochar scan (shared by the Gochar module and Upcoming Events) ---------

/// One year's Varshphal: the sidereal solar-return instant, the varsha
/// chart (a full snapshot cast at that instant, at the BIRTH place, in
/// the kundli's own ayanamsa), and the Muntha. Memoized per
/// (kundli, varsha year) — the widget's prev/next stepper revisits
/// years freely without recomputing.
class VarshphalData {
  const VarshphalData({
    required this.varshaYear,
    required this.returnUtc,
    required this.snapshot,
    required this.muntha,
    required this.munthaDegreeInSign,
    required this.dayPravesha,
    required this.natalLagna,
  });

  final int varshaYear;
  final DateTime returnUtc;
  final AstroSnapshot snapshot;
  final ZodiacSign muntha;

  /// Whether the varsha pravesha fell between sunrise and sunset at the
  /// birth place — drives Harsha Bala, the Tri-Rashi Pati and the
  /// Dina-Ratri Pati. Defaults to day in degenerate (polar) cases.
  final bool dayPravesha;

  /// Natal lagna — the Janma Lagna Pati among the office-bearers.
  final ZodiacSign natalLagna;

  /// Muntha's degree within its sign — the natal ascendant's
  /// degree-in-sign carried into the advanced sign (the Muntha starts
  /// AT the lagna and moves exactly one sign per completed year, so at
  /// each varsha pravesh its in-sign degree is the natal lagna's).
  final double munthaDegreeInSign;

  /// Muntha's house in the varsha chart (whole sign from varsha lagna).
  int get munthaHouse =>
      ((muntha.index - snapshot.lagnaSign.index + 12) % 12) + 1;
}

final varshphalProvider =
    FutureProvider.family<VarshphalData, (String kundliId, int varshaYear)>(
        (ref, key) async {
  final (kundliId, year) = key;
  final natal = await ref.watch(snapshotProvider(kundliId).future);
  final birth = natal.birth;
  final returnUtc = solarReturnUtc(
    birthUtc: birth.dateTimeUtc,
    natalSunLongitude: natal.positions[Planet.sun]!.longitude,
    varshaYear: year,
    ayanamsaId: natal.ayanamsaId,
  );
  // Offset at the RETURN instant (DST zones differ from birth's own).
  final offset = ref
      .read(placeLookupProvider)
      .offsetMinutesAtUtc(birth.timezoneName, returnUtc);
  final snap = await _snapshotBuilder.build(
    BirthData(
      dateTimeUtc: returnUtc,
      latitude: birth.latitude,
      longitude: birth.longitude,
      timezoneName: birth.timezoneName,
      utcOffsetMinutes: offset,
    ),
    natal.ayanamsaId,
  );
  // Day/night at the pravesha instant, birth place (Hindu sunrise
  // convention, same as the rest of the app).
  var dayPravesha = true;
  try {
    final svc = EphemerisService.instance;
    final jd = svc.julianDayUt(returnUtc);
    final rise = svc.sunriseBefore(jd, birth.latitude, birth.longitude);
    final set = rise == null
        ? null
        : svc.sunEventAfter(rise, birth.latitude, birth.longitude, rise: false);
    if (set != null) dayPravesha = jd < set;
  } catch (_) {}
  return VarshphalData(
    varshaYear: year,
    returnUtc: returnUtc,
    snapshot: snap,
    muntha: munthaSign(natal.lagnaSign, year),
    munthaDegreeInSign: natal.ascendant % 30,
    dayPravesha: dayPravesha,
    natalLagna: natal.lagnaSign,
  );
});

/// One maasa (monthly) chart within a varsha — pravesha instant and a
/// full snapshot at the birth place, memoized per (kundli, year, month).
class MaasaPraveshData {
  const MaasaPraveshData({
    required this.month,
    required this.praveshUtc,
    required this.snapshot,
    required this.dayPravesha,
  });

  final int month; // 1-12 within the varsha
  final DateTime praveshUtc;
  final AstroSnapshot snapshot;
  final bool dayPravesha;
}

final maasaPraveshProvider = FutureProvider.family<MaasaPraveshData,
    (String kundliId, int varshaYear, int month)>((ref, key) async {
  final (kundliId, year, month) = key;
  final varsha = await ref.watch(varshphalProvider((kundliId, year)).future);
  final natal = await ref.watch(snapshotProvider(kundliId).future);
  final birth = natal.birth;
  final praveshUtc = maasaPraveshUtc(
    varshaPraveshUtc: varsha.returnUtc,
    natalSunLongitude: natal.positions[Planet.sun]!.longitude,
    month: month,
    ayanamsaId: natal.ayanamsaId,
  );
  final offset = ref
      .read(placeLookupProvider)
      .offsetMinutesAtUtc(birth.timezoneName, praveshUtc);
  final snap = await _snapshotBuilder.build(
    BirthData(
      dateTimeUtc: praveshUtc,
      latitude: birth.latitude,
      longitude: birth.longitude,
      timezoneName: birth.timezoneName,
      utcOffsetMinutes: offset,
    ),
    natal.ayanamsaId,
  );
  var day = true;
  try {
    final svc = EphemerisService.instance;
    final jd = svc.julianDayUt(praveshUtc);
    final rise = svc.sunriseBefore(jd, birth.latitude, birth.longitude);
    final set = rise == null
        ? null
        : svc.sunEventAfter(rise, birth.latitude, birth.longitude, rise: false);
    if (set != null) day = jd < set;
  } catch (_) {}
  return MaasaPraveshData(
      month: month, praveshUtc: praveshUtc, snapshot: snap, dayPravesha: day);
});

/// Natal reference points for a transit scan: the 9 grahas + Lagna.
Map<String, double> natalPointsFor(AstroSnapshot s) => {
      for (final p in s.positions.values) p.planet.displayName: p.longitude,
      'Lagna': s.ascendant,
    };

/// Gochar (transit) events for a kundli over the next [months] from
/// now. Memoized per (kundli, months) — the Gochar module and the
/// Upcoming Events feed both watch this SAME provider so the scan
/// (scanGochar) runs once per window, not once per module (brief:
/// "never scan in build()"; a 12-month scan is fast but must not
/// repeat on every rebuild or be duplicated across widgets).
final gocharEventsProvider =
    FutureProvider.family<List<TransitEvent>, (String kundliId, int months)>(
        (ref, key) async {
  final (kundliId, months) = key;
  final snapshot = await ref.watch(snapshotProvider(kundliId).future);
  final now = DateTime.now().toUtc();
  final to =
      DateTime.utc(now.year, now.month + months, now.day, now.hour, now.minute);
  return scanGochar(
    natalPoints: natalPointsFor(snapshot),
    from: now,
    to: to,
    ayanamsaId: snapshot.ayanamsaId,
  );
});

/// Full-lifetime Sade Sati phases (birth → birth+100y) for a kundli.
/// Memoized per kundli — computed ONCE and shared by both the Sade
/// Sati tracker (which shows the whole lifetime) and the Upcoming
/// Events feed (which clips this same series to its own window),
/// rather than each re-running [sadeSatiPhases].
final sadeSatiPhasesProvider =
    FutureProvider.family<List<SadeSatiPhase>, String>((ref, kundliId) async {
  final snapshot = await ref.watch(snapshotProvider(kundliId).future);
  final birth = snapshot.birth.dateTimeUtc;
  return sadeSatiPhases(
    moonSign: snapshot.moonSign,
    from: birth,
    to: birth.add(const Duration(days: 36525)), // ~100 solar years
    ayanamsaId: snapshot.ayanamsaId,
  );
});

/// The degree-based reading of the same span: every stretch where
/// transiting Saturn is within 45° of the natal Moon's exact longitude.
/// A SEPARATE provider rather than a flag on [sadeSatiPhasesProvider]
/// so a dashboard showing only the classical method never pays for the
/// second scan — and so a dashboard showing both memoizes each once.
final sadeSatiDegreeWindowsProvider =
    FutureProvider.family<List<SadeSatiDegreeWindow>, String>(
        (ref, kundliId) async {
  final snapshot = await ref.watch(snapshotProvider(kundliId).future);
  final birth = snapshot.birth.dateTimeUtc;
  return sadeSatiDegreeWindows(
    natalMoonLon: snapshot.positions[Planet.moon]!.longitude,
    from: birth,
    to: birth.add(const Duration(days: 36525)), // ~100 solar years
    ayanamsaId: snapshot.ayanamsaId,
  );
});

/// Shadbala (six-fold planetary strength) for every graha in a kundli.
/// Memoized per kundli — the computation runs two backward ephemeris
/// scans plus a full dignity/aspect pass per graha, so it must not
/// re-run on every rebuild (see shadbala.dart's [computeShadbala] doc).
final shadbalaProvider =
    FutureProvider.family<List<ShadbalaResult>, String>((ref, kundliId) async {
  final snapshot = await ref.watch(snapshotProvider(kundliId).future);
  return computeShadbala(snapshot);
});

/// Bhava Bala — a hard dependency on [shadbalaProvider] (Bhavadhipati
/// Bala reuses each house lord's TOTAL Shadbala), so it awaits that
/// provider rather than recomputing Shadbala itself.
final bhavaBalaProvider =
    FutureProvider.family<List<BhavaBalaResult>, String>((ref, kundliId) async {
  final snapshot = await ref.watch(snapshotProvider(kundliId).future);
  final shadbala = await ref.watch(shadbalaProvider(kundliId).future);
  return computeBhavaBala(snapshot, shadbala);
});

// --- Ephemeral UI state that must survive navigation -------------------------

/// The Birth Chart's "view from" rotation set by double-tapping a
/// house, per kundli — null means view from the true lagna. Lives in a
/// provider (like the transit scrub below) so the dashboard card and
/// the detail view stay in sync and the rotation survives navigation.
final chartViewFromProvider =
    StateProvider.family<ZodiacSign?, String>((ref, kundliId) => null);

/// Same double-tap "view from" rotation for the OTHER whole-sign chart
/// widgets (divisional, varshphal). Keyed '<kundliId>#<scope>' — e.g.
/// '<id>#d9', '<id>#varshphal' — so each widget rotates independently
/// of the Birth Chart and of each other, but still survives navigation.
final widgetViewFromProvider =
    StateProvider.family<ZodiacSign?, String>((ref, key) => null);

/// Chalit's rotate-by-cusp, set by double-tapping a house (houses are
/// cusp-bounded, so rotation is a HOUSE number, not a sign). Null = the
/// natural view from house 1.
final chalitViewHouseProvider =
    StateProvider.family<int?, String>((ref, kundliId) => null);

/// The varsha year the WHOLE Varshphal dashboard shows, per kundli —
/// null = the varsha running today. The Varshphal Chart's stepper
/// writes it; every varsha widget (divisionals, dashas, bala, sahams…)
/// reads it, so the entire suite flips year together. A per-widget year
/// would let a D9 silently show a different varsha than the chart
/// beside it — a wrong-reading hazard, not a feature.
final varshphalYearProvider =
    StateProvider.family<int?, String>((ref, kundliId) => null);

/// The transit "as of" instant a user scrubbed to, per kundli — null
/// means live. Lives in a provider rather than widget State so it (a)
/// survives the dashboard being remounted when returning from a detail
/// screen, and (b) is SHARED between the dashboard card and the detail
/// view: scrubbing in one is reflected in the other.
final transitFixedTimeProvider =
    StateProvider.family<DateTime?, String>((ref, kundliId) => null);

/// Last dashboard scroll offset per view — restored when the widget
/// grid remounts after returning from a detail screen, so the board
/// doesn't jump back to the top.
final dashboardScrollOffsetProvider =
    StateProvider.family<double, String>((ref, viewId) => 0);

// --- Dashboard views ---------------------------------------------------------

/// GLOBAL dashboard views — one set of layouts applied to whichever
/// kundli (or Mahakosh chart) is open.
final dashboardViewsProvider = FutureProvider<List<DashboardView>>(
  (ref) => ref.watch(dashboardRepoProvider).views(),
);

final activeViewIdProvider = StateProvider<String?>((ref) => null);

final viewWidgetsProvider = FutureProvider.family<List<PlacedWidget>, String>(
  (ref, viewId) => ref.watch(dashboardRepoProvider).widgetsFor(viewId),
);

// --- Kundli Compare (spec §3–§5) --------------------------------------------

/// One selected chart in the comparison, resolved to what it can
/// contribute (spec §4.4). [subject] is null when the chart is
/// unavailable (a removed local kundli or an unreachable/withdrawn
/// bookmark) — the screen still renders, showing the chip/tab disabled.
/// [kundliId] is the id used to build a full [ModuleContext] for the
/// chart tab (a local id, or 'mk_<code>' for a full-birth bookmark);
/// null for a legacy (positions-only) bookmark, which renders [chart]
/// instead. [limited] marks that positions-only case.
class CompareSlot {
  const CompareSlot({
    required this.ref,
    required this.label,
    required this.isMahakosh,
    this.subject,
    this.kundliId,
    this.chart,
    this.ayanamsaId,
    this.limited = false,
    this.unavailable = false,
  });

  final String ref; // local kundli id | 'mk:<code>'
  final String label; // kundli name | MK code
  final bool isMahakosh;
  final CompareSubject? subject;
  final String? kundliId;
  final CompareChart? chart;
  final int? ayanamsaId;
  final bool limited;
  final bool unavailable;
}

/// Encode a Mahakosh bookmark reference for the compare set.
String compareMkRef(String mkCode) => 'mk:$mkCode';

bool isCompareMkRef(String ref) => ref.startsWith('mk:');

/// The ordered set of subject refs in the current comparison (spec
/// §3.2), prefs-persisted so reopening /compare restores it. Capped at
/// four charts, enforced at add time.
class CompareSetNotifier extends StateNotifier<List<String>> {
  CompareSetNotifier(this._repo) : super(const []) {
    _repo.compareSet().then((refs) {
      // Don't clobber refs added before prefs finished loading.
      if (state.isEmpty) state = refs;
    });
  }

  final SettingsRepository _repo;
  static const maxCharts = 4;

  /// Adds a ref; returns false (and no-ops) when the 4-chart cap is hit.
  bool add(String ref) {
    if (state.contains(ref)) return true;
    if (state.length >= maxCharts) return false;
    _set([...state, ref]);
    return true;
  }

  /// Adds several refs, stopping at the cap; returns how many were added.
  int addAll(Iterable<String> refs) {
    final next = [...state];
    var added = 0;
    for (final r in refs) {
      if (next.length >= maxCharts) break;
      if (next.contains(r)) continue;
      next.add(r);
      added++;
    }
    if (added > 0) _set(next);
    return added;
  }

  void remove(String ref) => _set(state.where((r) => r != ref).toList());

  void reorder(int oldIndex, int newIndex) {
    final next = [...state];
    if (newIndex > oldIndex) newIndex--;
    next.insert(newIndex.clamp(0, next.length), next.removeAt(oldIndex));
    _set(next);
  }

  void clear() => _set(const []);

  void _set(List<String> refs) {
    state = refs;
    _repo.setCompareSet(refs);
  }
}

final compareSetProvider =
    StateNotifierProvider<CompareSetNotifier, List<String>>(
  (ref) => CompareSetNotifier(ref.watch(settingsRepoProvider)),
);

/// The dasha system used for event correlation + "current mahadasha"
/// (spec §2, §4.2.7), prefs-persisted per the resolution in §8.2.
class CompareDashaNotifier extends StateNotifier<DashaSystem> {
  CompareDashaNotifier(this._repo) : super(DashaSystem.vimshottari) {
    _repo.compareDashaSystem().then((name) => state = DashaSystem.values
        .firstWhere((s) => s.name == name,
            orElse: () => DashaSystem.vimshottari));
  }

  final SettingsRepository _repo;

  void select(DashaSystem system) {
    state = system;
    _repo.setCompareDashaSystem(system.name);
  }
}

final compareDashaSystemProvider =
    StateNotifierProvider<CompareDashaNotifier, DashaSystem>(
  (ref) => CompareDashaNotifier(ref.watch(settingsRepoProvider)),
);

/// The active dashboard view SHARED across all compare tabs (spec §3.3
/// locked context), prefs-persisted so a comparison reopens on the same
/// view. Distinct from [activeViewIdProvider] so opening compare doesn't
/// disturb the home dashboard's own selection.
class CompareViewNotifier extends StateNotifier<String?> {
  CompareViewNotifier(this._repo) : super(null) {
    _repo.compareViewId().then((v) {
      if (state == null) state = v;
    });
  }

  final SettingsRepository _repo;

  void select(String? viewId) {
    state = viewId;
    _repo.setCompareViewId(viewId);
  }
}

final compareViewIdProvider =
    StateNotifierProvider<CompareViewNotifier, String?>(
  (ref) => CompareViewNotifier(ref.watch(settingsRepoProvider)),
);

/// Resolves the compare set's refs into [CompareSlot]s (spec §4.4):
/// local kundlis via [kundlisProvider] + [snapshotProvider] +
/// [kundliEventsProvider]; Mahakosh codes via [mahakoshChartProvider]
/// (fetched on selection, session-cached), with full-birth charts
/// getting a snapshot built through the existing [snapshotProvider]
/// path (which pins the chart's own ayanamsa). Unreachable charts and
/// removed kundlis become disabled slots rather than failing the screen.
final compareSubjectsProvider = FutureProvider<List<CompareSlot>>((ref) async {
  final refs = ref.watch(compareSetProvider);
  final slots = <CompareSlot>[];
  for (final r in refs) {
    if (isCompareMkRef(r)) {
      final code = r.substring(3);
      try {
        final chart = await ref.watch(mahakoshChartProvider(code).future);
        if (chart.hasBirthData) {
          final id = '$kMahakoshKundliPrefix$code';
          final snap = await ref.watch(snapshotProvider(id).future);
          slots.add(CompareSlot(
            ref: r,
            label: code,
            isMahakosh: true,
            subject: MahakoshSubject(mkChart: chart, snapshot: snap),
            kundliId: id,
            ayanamsaId: chart.ayanamsaId,
          ));
        } else {
          final subject = MahakoshSubject(mkChart: chart);
          slots.add(CompareSlot(
            ref: r,
            label: code,
            isMahakosh: true,
            subject: subject,
            chart: subject.chart,
            limited: true,
            ayanamsaId: chart.ayanamsaId,
          ));
        }
      } catch (_) {
        slots.add(CompareSlot(
            ref: r, label: code, isMahakosh: true, unavailable: true));
      }
    } else {
      final all = await ref.watch(kundlisProvider.future);
      final k = all.where((x) => x.id == r).firstOrNull;
      if (k == null) {
        slots.add(CompareSlot(
            ref: r, label: r, isMahakosh: false, unavailable: true));
        continue;
      }
      try {
        final snap = await ref.watch(snapshotProvider(r).future);
        final events = await ref.watch(kundliEventsProvider(r).future);
        slots.add(CompareSlot(
          ref: r,
          label: k.name,
          isMahakosh: false,
          subject:
              LocalSubject(kundli: k, snapshot: snap, kundliEvents: events),
          kundliId: r,
          ayanamsaId: snap.ayanamsaId,
        ));
      } catch (_) {
        slots.add(CompareSlot(
            ref: r, label: k.name, isMahakosh: false, unavailable: true));
      }
    }
  }
  return slots;
});

/// The similarity findings for the current comparison (spec §4.5) —
/// async so tab switching never jank-blocks, memoized by Riverpod on
/// its dependencies (the subject set + dasha system; event lists ride
/// inside the subjects). `now` is read here at the provider layer, and
/// [ephemerisPositionsAt] samples the sky at each event date. Returns
/// empty for fewer than two computable subjects (the screen shows the
/// empty state).
final compareFindingsProvider =
    FutureProvider<List<CompareFinding>>((ref) async {
  final slots = await ref.watch(compareSubjectsProvider.future);
  final system = ref.watch(compareDashaSystemProvider);
  final subjects = [
    for (final s in slots)
      if (s.subject != null) s.subject!,
  ];
  if (subjects.length < 2) return const [];
  // One transit ayanamsa for the whole set — the viewer's default. Signs
  // (and thus houses-from-Moon/lagna) are stable across the small ayanamsa
  // spread; degree-level differences are flagged on the Similarities tab.
  final ayanamsaId = await ref.watch(defaultAyanamsaProvider.future);
  return computeCompareFindings(
    subjects: [for (final s in subjects) s.toEntry()],
    dashaSystem: system,
    now: DateTime.now(),
    transitPositions: ephemerisPositionsAt(ayanamsaId),
  );
});
