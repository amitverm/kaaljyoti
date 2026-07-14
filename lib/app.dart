import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/theme.dart';
import 'state/providers.dart';
import 'screens/admin_screen.dart';
import 'screens/arrange_screen.dart';
import 'screens/ashtakoota_screen.dart';
import 'screens/birth_entry_screen.dart';
import 'screens/contribute_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/discussion_screen.dart';
import 'screens/hidden_charts_screen.dart';
import 'screens/kundli_edit_screen.dart';
import 'screens/kundli_events_screen.dart';
import 'screens/kundli_list_screen.dart';
import 'screens/mahakosh_chart_screen.dart';
import 'screens/mahakosh_search_screen.dart';
import 'screens/module_detail_screen.dart';
import 'screens/muhurta_screen.dart';
import 'screens/new_request_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/pdf_export_screen.dart';
import 'screens/request_detail_screen.dart';
import 'screens/research_board_screen.dart';
import 'screens/respond_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/today_screen.dart';

/// Landing-tab order (matches the nav pill). Switching tabs slides the
/// incoming screen in from the side it sits on relative to the current
/// tab — tap something to your left, it arrives from the left.
int _currentNavIndex = 0;
bool _navFromLeft = false;

Page<void> _navPage(GoRouterState state, Widget child, int index) {
  // pageBuilder runs on every router rebuild, not once per navigation —
  // so direction state may only change when the tab actually changes,
  // and the SAME transition page must be returned on rebuilds (the
  // completed animation simply doesn't replay).
  if (index != _currentNavIndex) {
    _navFromLeft = index < _currentNavIndex;
    _currentNavIndex = index;
  }
  final fromLeft = _navFromLeft;
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: Offset(fromLeft ? -1 : 1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
      child: child,
    ),
  );
}

final _router = GoRouter(
  // The daily-use screen greets first; Home (kundlis) is one tap away.
  initialLocation: '/today',
  routes: [
    GoRoute(
      path: '/today',
      pageBuilder: (_, state) => _navPage(state, const TodayScreen(), 0),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (_, state) => _navPage(state, const KundliListScreen(), 1),
    ),
    GoRoute(
      path: '/new',
      builder: (_, state) => BirthEntryScreen(
        prashna: state.uri.queryParameters['prashna'] == '1',
      ),
    ),
    GoRoute(
      path: '/kundli/:id',
      builder: (_, state) =>
          DashboardScreen(kundliId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/kundli/:id/edit',
      builder: (_, state) =>
          KundliEditScreen(kundliId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/kundli/:id/events',
      builder: (_, state) =>
          KundliEventsScreen(kundliId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/kundli/:id/arrange/:viewId',
      builder: (_, state) => ArrangeScreen(
        kundliId: state.pathParameters['id']!,
        viewId: state.pathParameters['viewId']!,
      ),
    ),
    GoRoute(
      path: '/kundli/:id/module/:moduleId',
      builder: (_, state) => ModuleDetailScreen(
        kundliId: state.pathParameters['id']!,
        moduleId: state.pathParameters['moduleId']!,
        // The dashboard passes the tapped card's own per-instance
        // config (e.g. which varga a Divisional Chart card is set to)
        // via `extra` — without it the detail view has no way to know
        // WHICH of possibly several same-module cards was tapped, and
        // falls back to that module's default config every time.
        initialConfig: state.extra as Map<String, dynamic>?,
        // The instance + view ids let the detail screen write config
        // changes (chart style, dasha system, extras…) straight back to
        // the dashboard widget row, so the card and detail stay in sync.
        instanceId: state.uri.queryParameters['instance'],
        viewId: state.uri.queryParameters['view'],
      ),
    ),
    GoRoute(
      path: '/kundli/:id/export',
      builder: (_, state) =>
          PdfExportScreen(kundliId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/kundli/:id/contribute',
      builder: (_, state) =>
          ContributeScreen(kundliId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/mahakosh',
      pageBuilder: (_, state) =>
          _navPage(state, const MahakoshSearchScreen(), 2),
    ),
    GoRoute(
      path: '/mahakosh/chart/:mk',
      builder: (_, state) =>
          MahakoshChartScreen(mkCode: state.pathParameters['mk']!),
    ),
    GoRoute(
      path: '/mahakosh/chart/:mk/discussion',
      builder: (_, state) =>
          DiscussionScreen(mkCode: state.pathParameters['mk']!),
    ),
    GoRoute(
        path: '/mahakosh/hidden',
        builder: (_, __) => const HiddenChartsScreen()),
    GoRoute(
      path: '/research',
      pageBuilder: (_, state) =>
          _navPage(state, const ResearchBoardScreen(), 3),
    ),
    GoRoute(
      path: '/menu',
      pageBuilder: (_, state) => _navPage(state, const MenuScreen(), 4),
    ),
    GoRoute(
        path: '/research/new', builder: (_, __) => const NewRequestScreen()),
    GoRoute(
      path: '/research/:id',
      builder: (_, state) =>
          RequestDetailScreen(requestId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/research/:id/respond',
      builder: (_, state) =>
          RespondScreen(requestId: state.pathParameters['id']!),
    ),
    GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/muhurta', builder: (_, __) => const MuhurtaScreen()),
    GoRoute(
        path: '/ashtakoota', builder: (_, __) => const AshtakootaScreen()),
    GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    // Not in TENavPill/any visible nav — reachable only via the
    // conditional "Admin" tile on the Menu, itself shown only when
    // isAdminProvider resolves true. The screen re-checks admin status
    // itself; see admin_screen.dart's doc comment for the real (server-
    // side) security boundary.
    GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
  ],
);

class ThirdEyeApp extends ConsumerWidget {
  const ThirdEyeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    // Load & track the app-wide date format so every screen/module renders
    // the user's chosen style; changes flip the ValueKey below and rebuild.
    final dateFormat = ref.watch(dateFormatProvider);

    // Drive live cross-device kundli sync for the app's whole lifetime
    // (pull on launch/sign-in + realtime subscription). Watching it here
    // keeps the provider alive.
    ref.watch(liveSyncProvider);
    ref.watch(pushRegistrationProvider);
    // Tapped push notifications navigate through the same router as
    // everything else; PushService resolves the route (shared with the
    // in-app bell via notificationRoute) and calls back here.
    ref.read(pushServiceProvider)?.onOpenRoute = _router.push;

    // Apply palette + font mode BEFORE the tree builds — widgets and
    // painters read TEColors/TETheme statics at build/paint time.
    TEColors.current = TEPalette.byName(appearance.paletteName);
    TETheme.useSerif = appearance.serifHeadings;

    return MaterialApp.router(
      // Changing the key forces a full rebuild so every screen picks
      // up the new palette immediately.
      key: ValueKey(
          '${appearance.paletteName}_${appearance.serifHeadings}_${dateFormat.name}'),
      title: 'Kaal Jyoti',
      theme: TETheme.build(
        palette: TEColors.current,
        serifHeadings: appearance.serifHeadings,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(appearance.textScale),
        ),
        child: child ?? const SizedBox(),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Honour the phone's English region (en-US, en-GB, en-IN, …) so the
      // date picker's input field uses the user's expected date order.
      supportedLocales: const [
        Locale('en'),
        Locale('en', 'GB'),
        Locale('en', 'IN'),
        Locale('en', 'AU'),
        Locale('en', 'CA'),
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        // Pass the device locale straight through for any English region so
        // MaterialLocalizations formats dates the way the user's phone does.
        if (deviceLocale != null && deviceLocale.languageCode == 'en') {
          return deviceLocale;
        }
        return const Locale('en');
      },
    );
  }
}
