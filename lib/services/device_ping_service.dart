/// The app's telemetry. All of it. This file is the whole thing.
///
/// Kaal Jyoti has no analytics SDK, no crash reporter, no event stream
/// and no session tracking. What it has is this: at most once a day, a
/// device sends three numbers and a random id to one RPC, so the author
/// can answer "is anyone using this, and how much is being made with
/// it" without instrumenting a single user action.
///
/// WHAT IS SENT (in full — there is no second payload anywhere):
///   * install_id — a uuid v4 minted on this device the first time this
///     runs, derived from NOTHING: no hardware id, no advertising id, no
///     account, no hash of any of those. Reinstalling mints a new one.
///   * kundlis_created_total — how many kundlis have been created on
///     this device, ever, including deleted ones.
///   * kundlis_current — how many are on it right now.
///
/// WHAT IS DELIBERATELY NOT SENT: no user id, no email, no session, no
/// IP recorded server-side, no platform, no app version, no locale, no
/// timezone, no device model, no screen viewed, no button pressed, and
/// nothing whatsoever about any chart — not a name, not a date, not a
/// place, not a count broken down by anything. The server cannot tell
/// two installs apart except by a random number they chose themselves,
/// and cannot tell an install from a person at all. See
/// 0030_device_analytics.sql for the same contract said in SQL.
///
/// HOW OFTEN: at most daily, PLUS shortly after a kundli is created or
/// deleted on this device (debounced by [kDevicePingDebounce], so a bulk
/// delete is one ping and not fifty). The payload does not change — it
/// is still the same three numbers going to the same single-row upsert,
/// and there is still no per-event record anywhere. What does change,
/// and is acknowledged rather than glossed: the server's last_seen for
/// an install can now line up with the minute a chart was made or
/// removed on it. That is the price of counts that are current within a
/// minute rather than within a day, and it was weighed and accepted. It
/// remains an install that cannot be tied to a person, an account, or
/// any other device.
///
/// The ping is sent SIGNED OUT as well as signed in — that is the point.
/// Kundlis that sync are already counted exactly (0029's registry); the
/// users this exists to see are the ones who never sign in.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/kundli_repository.dart';
import '../data/settings_repository.dart';

/// At most one ping a day. Frequent enough that "active in the last 30
/// days" means something, rare enough that a chatty user costs one
/// request per day and no more.
const Duration kDevicePingInterval = Duration(hours: 24);

/// How long [DevicePingService.pingSoon] waits before acting, restarting
/// on every fresh call. Long enough that the things users do in bursts —
/// importing a library, multi-selecting forty charts and deleting them,
/// discarding several Prashnas in a row — collapse into ONE ping instead
/// of one per row. Short enough that "the counts are current" still
/// means minutes.
const Duration kDevicePingDebounce = Duration(seconds: 30);

/// Is a ping due, given the throttle AND the dirty flag?
///
/// Separate from [devicePingIsDue] rather than folded into it: that
/// function answers a question about time and stays answerable with two
/// arguments and no context. This one is the policy — "a device that
/// knows its numbers moved does not wait for the clock" — and having it
/// here as a pure combinator is what lets the policy be tested without a
/// Supabase client.
bool devicePingIsDueNow({
  required bool countersDirty,
  required DateTime? lastPingAt,
  required DateTime now,
}) =>
    countersDirty || devicePingIsDue(lastPingAt: lastPingAt, now: now);

/// Is a ping due? Pure, so the decision is testable without a clock, a
/// network, or a database.
///
/// A [lastPingAt] in the FUTURE counts as due: the device clock moved
/// backwards (travel, manual change, a restored backup), and treating a
/// negative interval as "not yet" would silence the device until real
/// time caught up — potentially forever.
bool devicePingIsDue({required DateTime? lastPingAt, required DateTime now}) {
  if (lastPingAt == null) return true;
  final since = now.difference(lastPingAt);
  return since.isNegative || since >= kDevicePingInterval;
}

class DevicePingService {
  DevicePingService(
    this._client, {
    KundliRepository? kundlis,
    SettingsRepository? settings,
    DateTime Function()? now,
    bool? debugBuild,
    Duration? debounce,
  })  : _kundlis = kundlis ?? KundliRepository(),
        _settings = settings ?? SettingsRepository(),
        _now = now ?? DateTime.now,
        _debugBuild = debugBuild ?? kDebugMode,
        _debounce = debounce ?? kDevicePingDebounce;

  final SupabaseClient _client;
  final KundliRepository _kundlis;
  final SettingsRepository _settings;
  final DateTime Function() _now;
  final bool _debugBuild;
  final Duration _debounce;

  Timer? _pending;

  /// Send today's ping if one is due. Safe to call on every launch and
  /// every resume — the throttle lives in here, not in the caller.
  ///
  /// The whole body is swallowed. Launching offline is a normal state
  /// for this app, not an error (the same guard sync_service.start uses
  /// for its opening pull), and a failed count is not something a user
  /// should ever be told about, let alone shown.
  Future<void> pingIfDue() async {
    // Development runs must not land in the numbers. A single afternoon
    // of hot restarts would otherwise outnumber a week of real installs,
    // and the debug device's counter is full of test charts besides.
    if (_debugBuild) return;
    try {
      if (!devicePingIsDueNow(
        // A local count that has moved is due regardless of the clock —
        // that is the whole of the event-triggered path. It is a
        // separate read from the timestamp below and stays out of the
        // pure time function.
        countersDirty: await _settings.countersDirty(),
        lastPingAt: await _settings.lastPingAt(),
        now: _now(),
      )) {
        return;
      }

      final current = await _kundlis.savedCount();
      // Seeds on the very first ping of an install that may already hold
      // a library — "at least this many were created here".
      final createdTotal =
          await _settings.kundlisCreatedTotal(() async => current);

      await _client.rpc('record_device_ping', params: {
        'p_install_id': await _settings.installId(),
        'p_created_total': createdTotal,
        'p_current': current,
      });

      // Both only after the RPC returns. Recording the attempt instead
      // would let one offline launch eat the day's ping, and clearing
      // the dirty flag before a failed send would throw away the one
      // record that a change is still owed to the server.
      //
      // The remaining window is a change landing DURING the RPC: it is
      // included in nothing, and clearing the flag here forgets it.
      // Harmless, and deliberately not locked against — created_total is
      // monotonic server-side via greatest(), so a re-report of the same
      // number changes nothing, and current is overwritten wholesale by
      // the next ping, so it self-corrects within a day at worst.
      await _settings.setLastPingAt(_now());
      await _settings.setCountersDirty(false);
    } catch (_) {}
  }

  /// Ask for a ping shortly. Debounced: every call restarts the timer,
  /// so N calls in a burst produce one ping [_debounce] after the last
  /// of them.
  ///
  /// Built to be called carelessly. Any screen, any frequency, no
  /// awaiting, no ordering requirements, nothing to dispose at the call
  /// site — the same fire-and-forget shape as the `pushAll()` calls it
  /// sits beside. The dirty flag is what actually guarantees delivery;
  /// this only decides how soon.
  void pingSoon() {
    if (_debugBuild) return;
    _pending?.cancel();
    _pending = Timer(_debounce, () {
      _pending = null;
      unawaited(pingIfDue());
    });
  }

  /// Drop a scheduled ping. Called from the provider's onDispose — the
  /// service outlives no more than the container that made it, and a
  /// timer firing into a torn-down client is nobody's idea of telemetry.
  /// The dirty flag survives, so the ping is not lost, only deferred.
  void dispose() {
    _pending?.cancel();
    _pending = null;
  }
}
