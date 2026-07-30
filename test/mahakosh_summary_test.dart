/// MahakoshChartSummary decoding. The yoga/event counts reach the client
/// in two different shapes and used to be read as neither, so every row
/// silently reported zero — a chart with one recorded event showed no
/// event count at all.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/mahakosh/models.dart';

Map<String, dynamic> _base() => {
      'mk_code': 'MK-4831',
      'birth_year': 1995,
      'location_general': 'Rajasthan, India',
      'ayanamsa_id': 1,
      'created_at': '2026-07-01T00:00:00Z',
    };

void main() {
  group('counts from the search function', () {
    test('reads life_event_count, the key the server actually sends', () {
      // The edge function selects `count(*) as life_event_count`; the
      // client used to look for `event_count` and always got zero.
      final s = MahakoshChartSummary.fromJson({
        ..._base(),
        'yoga_count': 3,
        'life_event_count': 1,
      });
      expect(s.eventCount, 1);
      expect(s.yogaCount, 3);
    });

    test('still honours a plain event_count if one ever appears', () {
      final s = MahakoshChartSummary.fromJson({..._base(), 'event_count': 5});
      expect(s.eventCount, 5);
    });
  });

  group('counts embedded by PostgREST', () {
    test('reads the [{count: n}] shape browse and bookmarks return', () {
      final s = MahakoshChartSummary.fromJson({
        ..._base(),
        'chart_yogas': [
          {'count': 2}
        ],
        'life_events': [
          {'count': 1}
        ],
      });
      expect(s.yogaCount, 2);
      expect(s.eventCount, 1);
    });

    test('reads a to-one {count: n} shape too', () {
      final s = MahakoshChartSummary.fromJson({
        ..._base(),
        'life_events': {'count': 4},
      });
      expect(s.eventCount, 4);
    });

    test('an empty embed means zero, not a crash', () {
      final s = MahakoshChartSummary.fromJson({
        ..._base(),
        'life_events': <dynamic>[],
      });
      expect(s.eventCount, 0);
    });
  });

  group('robustness', () {
    test('absent counts default to zero', () {
      final s = MahakoshChartSummary.fromJson(_base());
      expect(s.eventCount, 0);
      expect(s.yogaCount, 0);
    });

    test('a malformed count costs the count, never the row', () {
      // A count is decoration; the chart must still be listable.
      final s = MahakoshChartSummary.fromJson({
        ..._base(),
        'life_events': 'not a count',
        'yoga_count': 'nonsense',
      });
      expect(s.eventCount, 0);
      expect(s.yogaCount, 0);
      expect(s.mkCode, 'MK-4831');
    });

    test('the rest of the summary still decodes', () {
      final s = MahakoshChartSummary.fromJson(_base());
      expect(s.mkCode, 'MK-4831');
      expect(s.birthYear, 1995);
      expect(s.locationGeneral, 'Rajasthan, India');
      expect(s.createdAt.year, 2026);
    });

    test('a single event renders as a count of one', () {
      // The reported case: one chart, one event, nothing shown.
      final s = MahakoshChartSummary.fromJson({
        ..._base(),
        'life_events': [
          {'count': 1}
        ],
      });
      expect(s.eventCount, greaterThan(0),
          reason: 'the row only shows the count when it is > 0');
    });
  });
}
