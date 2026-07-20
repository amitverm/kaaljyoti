/// The `pdf` package draws glyphs in logical order with no shaping, so
/// lib/pdf/devanagari.dart pre-shapes Hindi at the string level: known
/// conjunct cores collapse to pre-baked PUA glyphs (generated font +
/// map, tool/gen_devanagari_font.py) and the pre-base matra ि is
/// reordered before its base. These tests pin both transforms, the
/// degrade path, and two invariants that keep the fix honest:
///
///  * every shipped Hindi string renders with no visible halant — a
///    translator introducing an exotic core fails CI with instructions
///    to regenerate, instead of silently shipping typewriter Hindi;
///  * every PDF widget goes through the lib/pdf/pw.dart facade, since
///    the transform only fires there.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/pdf/devanagari.dart';
import 'package:kaaljyoti/pdf/devanagari_conjuncts.g.dart';

String pua(String core) => devanagariConjuncts[core]!;

void main() {
  group('conjunct substitution', () {
    test('collapses two-consonant cores to their baked glyph', () {
      expect(devanagariVisualOrder('शुक्र'), 'शु${pua('क्र')}');
      expect(devanagariVisualOrder('स्वामी'), '${pua('स्व')}ामी');
      expect(devanagariVisualOrder('सूर्य'), 'सू${pua('र्य')}');
      expect(devanagariVisualOrder('अप्रैल'), 'अ${pua('प्र')}ैल');
    });

    test('a word of chained cores substitutes each one', () {
      expect(devanagariVisualOrder('प्रत्यन्तर्दशा'),
          '${pua('प्र')}${pua('त्य')}${pua('न्त')}${pua('र्द')}शा');
    });

    test('corpus long cores match longest-first', () {
      // स्त्र is a 3-consonant core from the corpus — it must win over
      // the स्त prefix.
      expect(devanagariVisualOrder('शास्त्र'), 'शा${pua('स्त्र')}');
    });

    test('an unmapped long core degrades to prefix + visible halant', () {
      // क्क्क is in nobody's corpus: longest mapped prefix क्क is
      // substituted and the tail stays readable typewriter.
      expect(devanagariVisualOrder('क्क्क'), '${pua('क्क')}्क');
    });

    test('base+matra ligatures collapse (रु रू दृ हृ…)', () {
      // गुरु was printing र with a detached hook: रु is a GSUB base
      // form, not a mark attachment.
      expect(devanagariVisualOrder('गुरु'), 'गु${pua('रु')}');
      expect(devanagariVisualOrder('स्वरूप'), '${pua('स्व')}${pua('रू')}प');
      expect(devanagariVisualOrder('शृंखला'), '${pua('शृ')}ंखला');
      expect(devanagariVisualOrder('हृदय'), '${pua('हृ')}दय');
      // …but not after a conjunct: in शत्रु the र is inside त्र, where
      // the plain below-mark is the correct shaping.
      expect(devanagariVisualOrder('शत्रु'), 'श${pua('त्र')}ु');
    });

    test('repha cores fuse with a following right/top matra', () {
      // In वर्मा the repha must sit on the ा stem, not over the म — the
      // core-only glyph can't reposition it, so र्मा bakes as one.
      expect(devanagariVisualOrder('वर्मा'), 'व${pua('र्मा')}');
      expect(devanagariVisualOrder('आचार्य'), 'आचा${pua('र्य')}');
      expect(devanagariVisualOrder('सूर्यो'), 'सू${pua('र्यो')}');
      // Non-repha cores have no fused variants — the loose matra is
      // already correct there.
      expect(devanagariVisualOrder('स्वामी'), '${pua('स्व')}ामी');
    });
  });

  group('ि reorder', () {
    test('moves ि before a plain consonant', () {
      expect(devanagariVisualOrder('सितं॰'), 'िसतं॰');
      expect(devanagariVisualOrder('मिथुन'), 'िमथुन');
    });

    test('moves ि before the whole baked conjunct', () {
      // शक्ति: the matra visually hugs the क्त ligature's left edge.
      expect(devanagariVisualOrder('शक्ति'), 'श${'ि'}${pua('क्त')}');
      expect(devanagariVisualOrder('सक्रिय'), 'स${'ि'}${pua('क्र')}य');
      expect(devanagariVisualOrder('भद्रिका'), 'भ${'ि'}${pua('द्र')}का');
    });

    test('hops back over a nukta to the base consonant', () {
      expect(devanagariVisualOrder('ज़िला'), 'िज़ला');
    });

    test('leaves other matras and malformed input alone', () {
      const clean = 'शु गु चंद्र में ऐसा 20 मई 2026';
      expect(devanagariVisualOrder('चंदा सोम केतु 2026'),
          'चंदा सोम केतु 2026');
      expect(devanagariVisualOrder(clean), isNot(contains('ि')));
      expect(devanagariVisualOrder('ि'), 'ि');
      expect(devanagariVisualOrder('अि'), 'अि');
    });

    test('non-Devanagari text is returned unchanged', () {
      const latin = 'Vimshottari · 120y cycle · 9 lords';
      expect(devanagariVisualOrder(latin), same(latin));
    });
  });

  test('every shipped Hindi string renders without visible halant', () {
    // app_hi.arb plus the intl date names the dasha tables print.
    final arb = jsonDecode(File('lib/l10n/app_hi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final strings = <String>[
      for (final e in arb.entries)
        if (!e.key.startsWith('@') && e.value is String) e.value as String,
      'जनवरी फ़रवरी मार्च अप्रैल मई जून जुलाई अगस्त सितंबर अक्तूबर नवंबर दिसंबर',
      'रविवार सोमवार मंगलवार बुधवार गुरुवार शुक्रवार शनिवार',
    ];
    final leftovers = <String>{};
    // \u escapes: a literal क़-य़ range decomposes to क+़ under NFD and
    // breaks the character class.
    final consonant = RegExp('\u094D[\u0915-\u0939\u0958-\u095F]');
    for (final s in strings) {
      final shaped = devanagariVisualOrder(s);
      if (consonant.hasMatch(shaped)) leftovers.add(s);
    }
    expect(leftovers, isEmpty,
        reason: 'these strings contain a conjunct core missing from '
            'devanagari_conjuncts.g.dart — rerun '
            'tool/gen_devanagari_font.py and commit the regenerated '
            'font + map');
  });

  test('all PDF widget code imports the shaping facade, not pdf/widgets',
      () {
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.endsWith('lib/pdf/pw.dart')) continue; // the facade itself
      if (f.readAsStringSync().contains('package:pdf/widgets.dart')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'import lib/pdf/pw.dart as pw instead — it shapes '
            'Devanagari text; the raw package renders Hindi matras in '
            'the wrong visual order');
  });
}
