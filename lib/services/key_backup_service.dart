/// Cross-device backup of the SQLCipher passphrase via Google Block Store
/// (Android only). The primary copy lives in the platform keystore through
/// flutter_secure_storage, but the Keystore is device-bound: when Auto
/// Backup restored the DB to a new phone the key wasn't there and the DB
/// was unreadable (KAALJYOTI-PROD-E). Block Store data is end-to-end
/// encrypted with the user's lockscreen and travels with cloud backup and
/// device-to-device transfer, so the key arrives WITH the database.
///
/// Every failure mode (no Play Services, no lockscreen, iOS — where the
/// Keychain already rides iCloud backup) degrades to "not available";
/// callers fall back to AppDb's quarantine-and-recreate recovery.
library;

import 'dart:io';

import 'package:flutter/services.dart';

class KeyBackupService {
  static const _channel = MethodChannel('kaaljyoti/blockstore');

  /// The passphrase a previous device stored, or null when Block Store
  /// has nothing for us (fresh account, unsupported device, iOS).
  Future<String?> read() async {
    if (!Platform.isAndroid) return null;
    try {
      final value = await _channel.invokeMethod<String>('read');
      return (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      return null;
    }
  }

  /// True when Block Store accepted the passphrase.
  Future<bool> write(String passphrase) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel
              .invokeMethod<bool>('write', {'value': passphrase}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
