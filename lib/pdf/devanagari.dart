/// Devanagari visual pre-shaping for the PDF exporter.
///
/// The `pdf` package draws glyphs in Unicode logical order straight
/// from the cmap — no OpenType shaping. Proper Hindi needs two things
/// it can't do, both handled here as pure string→string transforms
/// applied by the lib/pdf/pw.dart facade to every string that reaches
/// a page:
///
/// 1. **Conjuncts** ([_substituteConjuncts]): क्र, स्व, र्य… are glyphs
///    with no codepoint, reachable only through GSUB rules. The
///    generated font assets/kj_devanagari_pdf.ttf (see
///    tool/gen_devanagari_font.py) bakes every two-consonant core plus
///    the corpus's longer cores into Private-Use-Area codepoints, and
///    devanagari_conjuncts.g.dart maps core → PUA char. Cores are
///    matched longest-first; an unmapped long core degrades to its
///    longest mapped prefix + visible halant (readable typewriter
///    form), never garbage.
/// 2. **The short-i matra** ([devanagariVisualOrder]): ि is stored
///    after its consonant but drawn before it — Devanagari's only
///    pre-base matra. After conjunct substitution it hops before the
///    whole ligature (a PUA char counts as a base), which is exactly
///    where the shaped glyph expects it.
///
/// All other matras and marks attach acceptably at their default
/// positions, so they pass through untouched — as does non-Devanagari
/// text (fast, via early contains checks). Hindi-complete by
/// construction; other Indic scripts would need their own rules AND
/// their own generated font before we localize into them.
library;

import 'devanagari_conjuncts.g.dart';

const int _iMatra = 0x093F; // ि
const int _virama = 0x094D; // ्
const int _nukta = 0x093C; // ़
const int _zwnj = 0x200C;
const int _zwj = 0x200D;

bool _isConsonant(int rune) =>
    (rune >= 0x0915 && rune <= 0x0939) || // क..ह
    (rune >= 0x0958 && rune <= 0x095F) || // nukta forms क़..य़
    (rune >= 0x0978 && rune <= 0x097F); // marwari/extended ॸ..ॿ

/// A reorder target for ि: a plain consonant or a baked conjunct.
bool _isBase(int rune) =>
    _isConsonant(rune) || (rune >= 0xE000 && rune <= 0xF8FF);

/// A dependent vowel sign that may ligate with its base (रु, दृ, हृ…) —
/// candidates for a base+matra entry in the generated map.
bool _isLigatableMatra(int rune) =>
    (rune >= 0x0941 && rune <= 0x0944) || rune == 0x0962 || rune == 0x0963;

/// Any dependent vowel — used to probe for a fused core+matra glyph
/// after a conjunct core matches (only repha cores have them baked).
bool _isDependentVowel(int rune) => rune >= 0x093E && rune <= 0x094C;

final RegExp _devanagariRune = RegExp('[ऀ-ॿ]');

/// [text] in the order and codepoints the unshaped renderer needs:
/// conjunct cores and ligating base+matra pairs collapsed to their
/// pre-shaped PUA glyphs, then every ि moved before the base it
/// belongs to.
String devanagariVisualOrder(String text) {
  if (!_devanagariRune.hasMatch(text)) return text;
  final s = _substituteConjuncts(text);
  if (!s.contains('ि')) return s;
  final runes = s.runes.toList();
  for (var i = 1; i < runes.length; i++) {
    if (runes[i] != _iMatra) continue;
    var j = i - 1;
    while (j > 0 &&
        (runes[j] == _nukta || runes[j] == _zwnj || runes[j] == _zwj)) {
      j--;
    }
    // Malformed input (ि with no base) — leave it where it stands.
    if (!_isBase(runes[j])) continue;
    runes.removeAt(i);
    runes.insert(j, _iMatra);
  }
  return String.fromCharCodes(runes);
}

String _substituteConjuncts(String text) {
  final runes = text.runes.toList();
  final out = StringBuffer();
  var i = 0;
  while (i < runes.length) {
    if (!_isConsonant(runes[i])) {
      out.writeCharCode(runes[i++]);
      continue;
    }
    // Maximal core from i: C(nukta?)(virama C(nukta?))* — record the
    // end index after each unit so we can shrink longest-first.
    var j = i + 1;
    if (j < runes.length && runes[j] == _nukta) j++;
    final unitEnds = <int>[];
    while (j + 1 < runes.length &&
        runes[j] == _virama &&
        _isConsonant(runes[j + 1])) {
      j += 2;
      if (j < runes.length && runes[j] == _nukta) j++;
      unitEnds.add(j);
    }
    var matched = false;
    for (var u = unitEnds.length - 1; u >= 0; u--) {
      final end = unitEnds[u];
      final pua = devanagariConjuncts[String.fromCharCodes(runes, i, end)];
      if (pua != null) {
        // A repha core re-bakes with a following right/top matra (the
        // repha sits on the matra stem: र्मा in वर्मा) — prefer the
        // fused variant when one exists.
        if (end < runes.length && _isDependentVowel(runes[end])) {
          final fused =
              devanagariConjuncts[String.fromCharCodes(runes, i, end + 1)];
          if (fused != null) {
            out.write(fused);
            i = end + 1;
            matched = true;
            break;
          }
        }
        out.write(pua);
        i = end;
        matched = true;
        break;
      }
    }
    // No conjunct — a bare base may still ligate with its matra
    // (रु, दृ, हृ…).
    if (!matched &&
        unitEnds.isEmpty &&
        j < runes.length &&
        _isLigatableMatra(runes[j])) {
      final pua = devanagariConjuncts[String.fromCharCodes(runes, i, j + 1)];
      if (pua != null) {
        out.write(pua);
        i = j + 1;
        matched = true;
      }
    }
    // No conjunct here (or an unmapped core): emit the consonant and
    // rescan — a leftover virama then passes through as-is, giving the
    // readable typewriter degrade.
    if (!matched) out.writeCharCode(runes[i++]);
  }
  return out.toString();
}
