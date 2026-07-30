/// AppNotification payload decoding. `payload` is a jsonb column, but
/// the moderate-* edge functions wrote a double-encoded STRING into it,
/// so a single such row made an `as Map` cast throw and took down the
/// whole notifications screen.
///
/// The edge functions are fixed (::jsonb), but rows written before that
/// are still in the database, so the client has to keep reading them.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/mahakosh/models.dart';

Map<String, dynamic> _row(Object? payload) => {
      'id': 'n1',
      'type': 'report_actioned',
      'payload': payload,
      'read': false,
      'created_at': '2026-07-28T10:00:00Z',
    };

void main() {
  test('decodes the normal jsonb object', () {
    final n = AppNotification.fromJson(_row({'mk_code': 'MK-1', 'x': 2}));
    expect(n.payload['mk_code'], 'MK-1');
    expect(n.payload['x'], 2);
  });

  test('decodes a double-encoded string payload', () {
    // The exact shape the moderate-* functions produced.
    final n = AppNotification.fromJson(
        _row('{"report_id":"r1","mk_code":"MK-1","reason":"spam"}'));
    expect(n.payload['mk_code'], 'MK-1');
    expect(n.payload['reason'], 'spam');
  });

  test('a bad payload costs the payload, never the notification', () {
    // One malformed row must not take the screen down with it.
    final n = AppNotification.fromJson(_row('not json at all'));
    expect(n.payload, isEmpty);
    expect(n.id, 'n1');
    expect(n.type, 'report_actioned');
  });

  test('a null payload reads as empty', () {
    expect(AppNotification.fromJson(_row(null)).payload, isEmpty);
  });

  test('a non-object JSON payload reads as empty', () {
    // '"just a string"' and '[1,2]' are valid JSON but not payloads.
    expect(AppNotification.fromJson(_row('"just a string"')).payload, isEmpty);
    expect(AppNotification.fromJson(_row('[1,2]')).payload, isEmpty);
  });

  test('the rest of the notification still decodes', () {
    final n = AppNotification.fromJson(_row('bad'));
    expect(n.read, isFalse);
    expect(n.createdAt.year, 2026);
  });
}
