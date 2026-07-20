/// Tajika positional relations (Charak): distance → category mapping,
/// symmetry, and the mutual-enemy conjunction of layers.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/tajika.dart';

void main() {
  test('distance → relation follows the Tajika table', () {
    const expected = {
      1: TajikaRelation.directEnemy,
      2: TajikaRelation.none,
      3: TajikaRelation.hiddenFriend,
      4: TajikaRelation.hiddenEnemy,
      5: TajikaRelation.directFriend,
      6: TajikaRelation.none,
      7: TajikaRelation.directEnemy,
      8: TajikaRelation.none,
      9: TajikaRelation.directFriend,
      10: TajikaRelation.hiddenEnemy,
      11: TajikaRelation.hiddenFriend,
      12: TajikaRelation.none,
    };
    expected.forEach((d, rel) {
      expect(tajikaRelationForDistance(d), rel, reason: 'distance $d');
    });
  });

  test('positional relations are symmetric', () {
    // Distance d one way pairs with 14−d (mod 12) the other way; every
    // category's pair maps to itself: (3,11), (5,9), (4,10), (1,7).
    for (var d = 1; d <= 12; d++) {
      final back = ((14 - d - 1) % 12) + 1;
      expect(tajikaRelationForDistance(d), tajikaRelationForDistance(back),
          reason: '$d vs $back');
    }
  });
}
