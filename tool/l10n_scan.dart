#!/usr/bin/env dart
// Finds user-facing English still hardcoded in the UI.
//
//   dart run tool/l10n_scan.dart          # report
//   dart run tool/l10n_scan.dart --ci     # exit 1 if anything is unlisted
//
// WHY THIS EXISTS: `flutter analyze` and the tests pass whether or not a
// string is localized, so nothing in the normal toolchain can see this
// class of bug — it took someone walking the app in Hindi to find them.
// This script is that person, automated.
//
// HOW IT WORKS, and why this way: the obvious approach — look for
// `Text('…')` — misses most real code, because Flutter wraps lines and
// puts literals inside ternaries (`? 'Clear filters' : 'Browse'`). The
// first version of this script did exactly that and missed every string
// a human had already found by hand. So instead it looks at EVERY string
// literal and rules out the ones that can't be UI copy.
//
// It is therefore tuned for RECALL, not precision: expect false
// positives, and silence them in `_allowed` with a reason. A missed
// string is a bug shipped to users; a false positive costs five seconds.
//
// It reads text, not the AST — see LIMITATIONS at the bottom. A clean run
// means "no KNOWN hardcoded strings", never "fully localized".
library;

import 'dart:io';
import 'dart:math' show max, min;

/// Literals that are legitimately not localized. Reason required.
const _allowed = <String, String>{
  'Kaal Jyoti': 'brand name, never translated (README ▸ Trademarks)',
  'KAAL JYOTI': 'brand name, never translated',
  'Prashna': 'Sanskrit term; the displayed form comes from an ARB key',
  'legacy chart': 'internal StateError sentinel; the UI branches on '
      'chart.hasBirthData and never shows this text',
  'Letter': 'paper-size name (US Letter), alongside A4 — universal',
  'e.g. marriage, career_change, transplant':
      'literal event-tag examples the user types verbatim (UGC codes)',
  'e.g. gaja_kesari, raj_yoga, mangal_dosha, kaal_sarp':
      'literal yoga-code examples the user types verbatim (UGC codes)',
  'rate limit': 'substring matched against a backend error string, not shown',
  "Auto-report: the reporter blocked this comment's":
      'report metadata sent to the backend moderation queue, not shown to a user',
  '© 2026 Amit Verma': 'copyright legalese passed to the OS license page — not translated',
  // AdminChartReport.reasonLabels — the moderation queue is admin-only
  // (admin_screen is English by design); this is its private copy of the
  // report-reason labels. The user-facing report sheet localizes the same
  // reasons via reportReasonLabel.
  'Could identify a real, named person': 'admin-only report reason label',
  'Sensitive health information': 'admin-only report reason label',
  'Harassing, hateful, or abusive content': 'admin-only report reason label',
  'Spam or fake/test data': 'admin-only report reason label',
  'Something else': 'admin-only report reason label',
  // birth_entry _relationTags — persisted stored keys (relationTag column),
  // displayed via relationTagLabel; the literals are the stable identity.
  'Client': 'stored relation-tag key, displayed via relationTagLabel',
  'Self': 'stored relation-tag key, displayed via relationTagLabel',
  'Spouse': 'stored relation-tag key, displayed via relationTagLabel',
  'Family': 'stored relation-tag key, displayed via relationTagLabel',
  'Friend': 'stored relation-tag key, displayed via relationTagLabel',
  'Other': 'stored relation-tag key, displayed via relationTagLabel',
  'New Delhi': 'default place-name fallback (a real location), not UI copy',
  'KP (Krishnamurti)': 'ModuleMeta category identity (top-level const); displayed via moduleCategoryLabel',
  // kReportReasons VALUE — keyed by stable reason codes and displayed via
  // reportReasonLabel; the English value is only a fallback, never
  // rendered. (The other four match admin labels already listed above.)
  'Sensitive health information shouldn’t be public':
      'kReportReasons fallback value, not rendered',
};

/// Only the layers that render to a user.
///
/// `lib/core/` is excluded BY DESIGN, not laziness: it's the pure
/// calculation engine, deliberately locale-unaware, and its enums keep
/// English `displayName`s as stable identifiers for tests (see the header
/// of lib/l10n/astro_l10n.dart). Its literals are data — ayanamsa names,
/// yoga rule text, yoni names — not UI copy. Where core English *does*
/// leak to the screen (yoga names, transit labels) that's the separate
/// TODO(l10n) class: it needs an engine change to structured data, which
/// no amount of ARB keys can fix, so flagging it here would be noise.
const _scanDirs = <String>[
  'lib/screens',
  'lib/modules',
  'lib/charts',
  'lib/ui',
  'lib/widgetsystem',
  'lib/pdf',
  'lib/mahakosh',
];

/// Files whose English is intentional or deliberately deferred.
const _skipFiles = <String, String>{
  'lib/screens/admin_screen.dart': 'internal tool, English by design',
  'lib/services/os_widget_service.dart':
      'OS widget renders outside the app — out of scope (TODO(l10n) in file)',
  // These two render English that ORIGINATES in the core rule engine
  // (yoga names/details; scanGochar transit labels), which no ARB key
  // can fix — it needs core to emit structured data. Their localizable
  // chrome (e.g. the 8 yoga categories) is intentionally bundled INTO
  // that same follow-up so the widget flips to Hindi in one move rather
  // than shipping half-translated. Tracked separately; not this sweep.
  'lib/modules/yogas_module.dart':
      'deferred: yoga names/details come from the rule engine (needs core change)',
  'lib/modules/upcoming_events_module.dart':
      'deferred: scanGochar transit labels come from core pre-rendered in English',
};

/// Lines in these contexts never render to a user.
final _ignoreLine = RegExp(
  r'^\s*(import|export|part|library)\b'
  r'|debugPrint\(|(?<!\w)print\('
  r'|Sentry|FirebaseAnalytics|analytics\.'
  r'|saveWidgetData|setAppGroupId'
  r'|RegExp\(|jsonDecode|jsonEncode'
  // Thrown-exception messages are developer diagnostics, not UI copy —
  // StateError/ArgumentError signal an invariant violation. The repo
  // guards (`throw StateError('Sign in to …')`) are defensive and
  // unreachable: the UI gates each action behind a sign-in check first.
  // A message meant for the user is built into a Text/snackbar, not a
  // throw.
  r'|throw (StateError|ArgumentError|UnsupportedError|Exception|FormatException)\('
  r'|(SELECT|INSERT|UPDATE|DELETE|CREATE TABLE|PRAGMA|ALTER)\s',
  caseSensitive: true,
);

/// Looks like English UI copy rather than an identifier, key, or format.
///
/// Two shapes count: a phrase (has a space), or a single Capitalised word
/// ('Delete', 'Save'). Lowercase single tokens are ids and config values
/// ('north', 'off', 'pending_review') and are deliberately excluded.
bool _isUiCopy(String raw) {
  final s = raw
      .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
      .replaceAll(RegExp(r'\$\w+'), '')
      .replaceAll(RegExp(r'\\[ntr]'), '')
      .trim();
  if (s.length < 3) return false;
  if (!RegExp(r'[A-Za-z]{2}').hasMatch(s)) return false;
  if (RegExp(r'[ऀ-෿؀-ۿ]').hasMatch(s)) return false; // already translated
  if (RegExp(r'^https?:|^assets/|\.(dart|png|svg|ttf|json|db)$').hasMatch(s)) {
    return false;
  }
  if (RegExp(r'^[dMyHmsE/:.\s,-]+$').hasMatch(s)) return false; // date pattern
  if (RegExp(r'^#[0-9a-fA-F]{3,8}$').hasMatch(s)) return false; // colour
  final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length == 1) {
    // Single token: only UI copy if it reads like a word, Capitalised.
    return RegExp(r'^[A-Z][a-z]{2,}$').hasMatch(words.first);
  }
  // Phrase: needs at least one alphabetic word.
  return words.any((w) => RegExp(r'^[A-Za-z]{2,}$').hasMatch(w));
}

/// Strips comments and the contents of raw strings so they aren't scanned.
String _stripComments(String src) {
  final out = StringBuffer();
  var i = 0;
  while (i < src.length) {
    if (src.startsWith('//', i)) {
      while (i < src.length && src[i] != '\n') {
        i++;
      }
    } else if (src.startsWith('/*', i)) {
      final end = src.indexOf('*/', i + 2);
      final stop = end == -1 ? src.length : end + 2;
      for (var j = i; j < stop; j++) {
        if (src[j] == '\n') out.write('\n'); // keep line numbers honest
      }
      i = stop;
    } else {
      out.write(src[i]);
      i++;
    }
  }
  return out.toString();
}

/// Every Dart string literal in [src], as (offset, contents).
/// Skips raw strings (r'…') — those are patterns, never prose.
List<(int, String)> _literals(String src) {
  final out = <(int, String)>[];
  final re = RegExp(
    r"""(r?)('''(?:[\s\S]*?)'''|\"\"\"(?:[\s\S]*?)\"\"\"|'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")""",
  );
  for (final m in re.allMatches(src)) {
    if (m.group(1) == 'r') continue; // raw string: RegExp/path, not prose
    var body = m.group(2)!;
    if (body.startsWith("'''") || body.startsWith('"""')) {
      body = body.substring(3, body.length - 3);
    } else {
      body = body.substring(1, body.length - 1);
    }
    // A regex can't balance the quotes inside `'…${ x ? '..' : '' }…'` —
    // it stops at the first inner quote, leaving a fragment with an
    // unclosed `${`. Such fragments aren't real literals; skip them.
    // (The interpolation itself is localized in the real source.)
    if (RegExp(r'\$\{[^}]*$').hasMatch(body)) continue;
    // Unescape so allowlist matching and output read as real text
    // ("comment's", not "comment\'s").
    body = body
        .replaceAll(r"\'", "'")
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
    out.add((m.start, body));
  }
  return out;
}

/// Core fields that hold ENGLISH by design — the calculation layer keeps
/// them as stable identifiers, and `astro_l10n.dart` is what turns them
/// into display text. Rendering one directly is the bug this catches:
/// `Text(p.lordLabel)` instead of `Text(dashaLordLabel(l10n, p))`.
///
/// This class is invisible to the literal scan below (it's a variable,
/// not a string), and it is exactly what a human found by walking the app
/// in Hindi — a whole dasha list in English on an otherwise-Hindi screen.
///
/// `displayName` is deliberately NOT listed: it's too common a name to
/// judge without types — `PlaceResult.displayName` is a geocoded city
/// ("New Delhi, Delhi, India") that must stay verbatim, and flagging it
/// would cry wolf on four screens. `Text(planet.displayName)` therefore
/// slips past; a human in a Hindi build is still the backstop.
final _rawCoreField = RegExp(
  r'\.(lordLabel|western|levelName|signifies|meaning)\b',
);

/// Widget constructors whose text argument renders to the user.
final _rendersText = RegExp(
  r'\b(Text|KJSectionLabel|KJTag|pw\.Text|TextSpan)\s*\(|'
  r'\b(?:label|labelText|title|hintText|tooltip|message|actionLabel|subtitle)\s*:',
);

/// Line indices covered by a `ModuleMeta( … )` argument list.
/// Its `title:` is the English identifier/fallback BY DESIGN —
/// `localizedTitle` carries the displayed name (widgetsystem/astro_module.dart).
Set<int> _moduleMetaLines(List<String> lines) {
  final out = <int>{};
  var depth = 0;
  var open = false;
  for (var i = 0; i < lines.length; i++) {
    if (!open && lines[i].contains('ModuleMeta(')) {
      open = true;
      depth = 0;
    }
    if (!open) continue;
    out.add(i);
    for (final c in lines[i].split('')) {
      if (c == '(') depth++;
      if (c == ')') depth--;
    }
    if (depth <= 0) open = false;
  }
  return out;
}

void main(List<String> args) {
  final ci = args.contains('--ci');
  if (!Directory('lib').existsSync()) {
    stderr.writeln('run me from the package root');
    exit(2);
  }

  final findings = <(String, int, String)>[];
  final files = [
    for (final d in _scanDirs)
      if (Directory(d).existsSync())
        ...Directory(d)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !_skipFiles.containsKey(f.path)),
  ]..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final src = _stripComments(f.readAsStringSync());
    final lines = src.split('\n');
    final metaLines = _moduleMetaLines(lines);
    // Offset -> line index, once per file.
    final lineStarts = <int>[0];
    for (var i = 0; i < src.length; i++) {
      if (src[i] == '\n') lineStarts.add(i + 1);
    }
    int lineOf(int off) {
      var lo = 0, hi = lineStarts.length - 1;
      while (lo < hi) {
        final mid = (lo + hi + 1) >> 1;
        if (lineStarts[mid] <= off) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      return lo;
    }

    for (final (off, text) in _literals(src)) {
      if (!_isUiCopy(text)) continue;
      if (_allowed.containsKey(text.trim())) continue;
      final li = lineOf(off);
      if (metaLines.contains(li)) continue;
      if (_ignoreLine.hasMatch(lines[li])) continue;
      findings.add((f.path, li + 1, text));
    }

    // Raw core English rendered straight to the screen. Checked over a
    // small window because `Text(` and the field often wrap apart.
    for (var i = 0; i < lines.length; i++) {
      if (!_rawCoreField.hasMatch(lines[i])) continue;
      if (metaLines.contains(i) || _ignoreLine.hasMatch(lines[i])) continue;
      final window = lines.sublist(max(0, i - 1), min(lines.length, i + 2));
      if (!window.any(_rendersText.hasMatch)) continue;
      findings.add((f.path, i + 1, 'raw core English: ${lines[i].trim()}'));
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('l10n_scan: no hardcoded UI strings found.');
    exit(0);
  }

  String? current;
  for (final (path, line, text) in findings) {
    if (path != current) {
      stdout.writeln('\n$path');
      current = path;
    }
    final flat = text.replaceAll('\n', ' ');
    final shown = flat.length > 62 ? '${flat.substring(0, 62)}…' : flat;
    stdout.writeln('  ${line.toString().padLeft(4)}  $shown');
  }
  stdout.writeln('\n${findings.length} candidate(s) in '
      '${findings.map((f) => f.$1).toSet().length} file(s).');
  stdout.writeln('Move each into lib/l10n/app_en.arb + app_hi.arb, or add it '
      'to _allowed in this script with a reason.');
  exit(ci ? 1 : 0);
}

// LIMITATIONS — so nobody trusts a clean run more than it deserves:
//  * Text assembled in a variable then passed to Text(myVar).
//  * English coming out of core (yoga names, transit labels) — those are
//    TODO(l10n) and need an engine change, not a key.
//  * Strings that ARE localized but wrong (a Hindi typo, a mistranslation).
//  * Adjacent-literal concatenation is reported as separate literals.
// A human walking the app in a non-English locale remains the real test.
