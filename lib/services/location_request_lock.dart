/// One location request at a time, app-wide.
///
/// geolocator's Android permission manager keeps a single pending
/// callback. Two overlapping `requestPermission()` calls (Today's
/// first-run auto-detect racing a "use current location" tap, or a
/// Prashna cast) make Android deliver two permission results to the
/// same method-channel reply, which is a fatal
/// `IllegalStateException: Reply already submitted`
/// (KAALJYOTI-PROD-V). Serialising every permission-plus-position
/// sequence through this lock means the second caller simply waits for
/// the first and then sees the permission already granted.
library;

import 'dart:async';

Future<void> _tail = Future.value();

/// Runs [body] after every previously scheduled body has completed
/// (successfully or not). Errors propagate to the caller only.
Future<T> withLocationLock<T>(Future<T> Function() body) {
  final previous = _tail;
  final completer = Completer<void>();
  _tail = completer.future;
  return previous.then((_) => body()).whenComplete(completer.complete);
}
