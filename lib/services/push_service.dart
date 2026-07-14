/// Push-notification registration (FCM) — the delivery pipe for the
/// rows that land in public.notifications (see 0020/0021 and the
/// send-notification edge function).
///
/// Firebase here is a MESSAGE PIPE, not analytics: only firebase_core +
/// firebase_messaging are linked, and initialization is opt-in AT BUILD
/// TIME via --dart-define FIREBASE_* values (see env.example.json).
/// Without them — the default for the public AGPL repo and local dev —
/// no Firebase code runs and the app behaves exactly as before (in-app
/// bell only). Same gating philosophy as Sentry in main.dart.
///
/// Lifecycle: [PushService.start] after a signed-in session appears →
/// permission prompt (iOS) → upsert the FCM token into device_tokens
/// (owner-only RLS, 0021) and follow token rotations. [PushService.stop]
/// on sign-out deletes the token so a shared device stops receiving the
/// previous user's pushes.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../core/notification_routes.dart';

class PushService {
  PushService(this._client);
  final SupabaseClient _client;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openSub;
  bool _initialized = false;

  /// Set by the root app widget: receives the route for a tapped push
  /// (resolved via notificationRoute — same mapping as the in-app bell)
  /// and navigates. Kept as a callback so this service never needs a
  /// BuildContext or a router import.
  void Function(String route)? onOpenRoute;

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    final route = notificationRoute(
      (data['type'] as String?) ?? '',
      mkCode: data['mk_code'] as String?,
      requestId: data['request_id'] as String?,
    );
    if (route != null) onOpenRoute?.call(route);
  }

  /// API key + app id are per-platform (two registered Firebase apps);
  /// sender + project are shared. Configured = the pair for THIS
  /// platform is present, so an Android-only setup still works on
  /// Android while iOS stays bell-only, and vice versa.
  static String get _apiKey =>
      Platform.isIOS ? kFirebaseApiKeyIos : kFirebaseApiKeyAndroid;
  static String get _appId =>
      Platform.isIOS ? kFirebaseAppIdIos : kFirebaseAppIdAndroid;

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      kFirebaseSenderId.isNotEmpty &&
      kFirebaseProjectId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized || !isConfigured) return;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: kFirebaseSenderId,
        projectId: kFirebaseProjectId,
      ),
    );
    _initialized = true;
  }

  /// Register this device for the signed-in user. Safe to call on every
  /// session start; no-op when Firebase isn't configured or the user
  /// declines the permission prompt.
  Future<void> start() async {
    if (!isConfigured || _client.auth.currentUser == null) return;
    try {
      await _ensureInitialized();
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);

      await _tokenSub?.cancel();
      _tokenSub = messaging.onTokenRefresh.listen(_saveToken);

      // Tap-through routing. Three app states:
      //  * background -> onMessageOpenedApp fires on tap;
      //  * terminated -> the tapped message arrives as getInitialMessage
      //    right after launch;
      //  * foreground -> no tap involved; the in-app bell is the surface
      //    (iOS is told to still show banners so pushes aren't silently
      //    swallowed while the app is open).
      await _openSub?.cancel();
      _openSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);
      await messaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
    } catch (_) {
      // Push is best-effort — the in-app bell (polled notifications)
      // remains the fallback delivery path.
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('device_tokens').upsert({
      'token': token,
      'user_id': uid,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Unregister on sign-out: delete the token row (and drop the local
  /// FCM token so a later sign-in gets a fresh one).
  Future<void> stop() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    await _openSub?.cancel();
    _openSub = null;
    if (!isConfigured || !_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _client.from('device_tokens').delete().eq('token', token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Best-effort — worst case the send function prunes the dead token.
    }
  }
}
