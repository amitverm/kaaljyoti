# Adding a Language

A practical guide for translating Kaal Jyoti. You add **one file** —
`lib/l10n/app_<code>.arb` — and the language appears in Settings ▸
Language, named in its own script, with the whole app following it,
PDF export included. No Dart changes.

You do not need to be a programmer. If you can edit a text file and
follow the quoting rules below, you can ship a language. This holds for
non-Latin scripts too — see [Scripts](#scripts) if yours isn't Latin.

## The 60-second version

```bash
cp lib/l10n/app_en.arb lib/l10n/app_es.arb   # your language code
# edit app_es.arb: set "@@locale", translate the values, delete the @-blocks
flutter gen-l10n
flutter run
```

Settings ▸ Language now lists your language. That's the whole loop.

## Where things live

| File | Role |
|---|---|
| `lib/l10n/app_en.arb` | **The template.** Every key, plus the `@key` blocks describing what each string is for. Read these — they carry the rules. |
| `lib/l10n/app_hi.arb` | A complete real translation. The best reference for what a finished file looks like. |
| `lib/l10n/app_<code>.arb` | **Your file.** The only one you create. |
| `lib/l10n/gen/` | Generated Dart. `flutter gen-l10n` writes it; never hand-edit, but do commit it. |
| `l10n.yaml` | Points gen-l10n at the above. You don't touch it. |
| `lib/l10n/astro_l10n.dart` | Maps app enums to your keys. You don't touch it. |

## Picking the language code

Use the ISO 639-1 two-letter code: `es` Spanish, `bn` Bengali, `ta`
Tamil, `mr` Marathi, `fr` French. The file name (`app_es.arb`) and the
`"@@locale"` value inside it **must match**, or gen-l10n silently uses
the filename and you'll debug a ghost.

Region variants (`app_pt_BR.arb`) work the same way. Only add one if the
regions genuinely differ in wording — a plain `app_pt.arb` covers both
otherwise.

## Anatomy of the file

```json
{
  "@@locale": "es",
  "languageEndonym": "Español",
  "appTitle": "Kaal Jyoti",
  "planetSun": "Sol",
  "signAbbrAries": "Ari",
  "rdHidden": "Se ocultó la carta {code} de tu vista.",
  "keUpdateEventsBody": "{count, plural, =1{1 evento} other{{count} eventos}}"
}
```

Four rules that cover almost everything:

1. **Translate the value, never the key.** `"planetSun"` stays
   `"planetSun"` in every language forever.
2. **`{placeholders}` are copied verbatim.** `{code}`, `{count}`,
   `{name}` are holes the app fills at runtime. Translate the words
   around them; move them where your grammar wants them; never rename
   or delete one. A missing placeholder is a build error — which is the
   system protecting you.
3. **`"languageEndonym"` is your language's own name, in your own
   language** — `"Español"`, not `"Spanish"`. This is what makes your
   language appear in the Settings picker, so it is the one key you
   must not skip.
4. **Delete the `@key` blocks from your file.** They're documentation
   that only the English template needs. Read them while translating,
   then drop them — copies in your file do nothing and rot.

### JSON quoting

The file is JSON, so:

- Escape a literal double quote as `\"`.
- Escape a backslash as `\\`.
- Apostrophes and curly quotes need no escaping — `"L'astrologie"` is
  fine.
- No trailing comma after the last entry.
- Save as UTF-8. Any editor from the last decade does this by default.

If `flutter gen-l10n` prints a parse error with a line number, it's
almost always one of the first two.

## The terminology policy (the important part)

**Sanskrit astrological terms are transliterated, never translated.**
Nakshatra names, graha names, dasha system names, tithi/yoga/karana
names, and the words *kundli*, *lagna*, *ayanamsa*, *Mahakosh* are the
same term in every language — write them in **your script**, don't
replace them with a local equivalent.

Hindi does exactly this: `nakshatraAshwini` is `अश्विनी` — Ashwini
spelled in Devanagari, not translated into a Hindi word meaning
"horse-woman".

| Key | English | Hindi | Why |
|---|---|---|---|
| `planetSun` | Sun | सूर्य | Sanskrit graha name, transliterated |
| `nakshatraAshwini` | Ashwini | अश्विनी | Fixed term, transliterated |
| `appTitle` | Kaal Jyoti | Kaal Jyoti | Brand — stays Latin everywhere |
| `save` | Save | सहेजें | Ordinary UI copy — genuinely translated |

UI copy — buttons, labels, explanations, error messages — *is*
translated normally. When in doubt, read the key's `@`-block in
`app_en.arb`; the ones with fixed terms say so.

The brand name **"Kaal Jyoti" stays in Latin script in every language.**

## Key families worth knowing

Keys are prefixed by area, so related strings sit together:

| Prefix | Area |
|---|---|
| `planet*`, `sign*`, `nakshatra*`, `tithi*`, `yoga*`, `karana*`, `vara*`, `masa*` | Astro name tables |
| `module*` | Dashboard widget titles |
| `cfg*`, `dm*`, `ym*`, `ss*`, `kp*`, `av*`, `bb*` … | Per-module strings |
| `nav*`, `mn*`, `si*`, `td*` | Chrome: nav bar, menu, sign-in, Today |
| `cb*`, `ds*`, `rd*`, `nr*`, `ms*`, `rc*` | Mahakosh: contribute, discussion, research, reports |
| `label*`, `dir*`, `weekday*` | Shared bits used in several places |

### `*Abbr*` keys: never slice a name

Keys like `signAbbrAries` and `nakshatraAbbrAshwini` are short tokens for
dense chart cells (2–4 characters). They exist as their own keys
**because you cannot produce them by cutting the first three letters off
a full name** — that shreds combining marks in Devanagari, Tamil, Bengali
and most Indic scripts. Write a real abbreviation that your script reads
naturally at small sizes, and keep it short: it has to fit inside a chart
box.

### Consent strings need a native speaker

`cbMainConsent`, `cbThirdPartyConsent`, and the `cbAnon*` lines are what
a user legally agrees to when contributing a chart to Mahakosh. Translate
these precisely — don't soften, embellish, or summarize.

In languages that mark the speaker's gender, use a **dual-gender**
first-person form so the sentence fits any user. Hindi does this with
`देता/देती हूँ`.

## Plurals

Some keys use ICU plural syntax:

```json
"keUpdateEventsBody": "{count, plural, =1{1 evento} other{{count} eventos}}"
```

Use the categories your language actually has — `zero`, `one`, `two`,
`few`, `many`, `other` are all available, and `other` is required.
Languages with one plural form can collapse to `=1{…} other{…}`;
Arabic or Russian should use the full set. You are not obliged to match
English's shape here.

## Partial translations are fine

Any key you leave out **falls back to English automatically.** You can
ship 200 of ~1050 keys and get a working, half-translated app — not
crashes, not blanks. So:

- Translate the visible chrome first (`nav*`, `mn*`, `td*`, `label*`).
- Then the astro name tables (`planet*`, `sign*`, `nakshatra*`).
- Then the module bodies.

Send a PR whenever you're ready. Incomplete is welcome.

## Checking your work

```bash
flutter gen-l10n     # regenerates lib/l10n/gen/ — must print no errors
flutter analyze      # must report no errors
flutter run          # Settings ▸ Language ▸ your language
```

To compare against the template and find what's still missing:

```bash
python3 -c "
import json
en = json.load(open('lib/l10n/app_en.arb'))
mine = json.load(open('lib/l10n/app_es.arb'))
ek = {k for k in en if not k.startswith('@')}
mk = {k for k in mine if not k.startswith('@')}
print('missing:', len(ek - mk)); print('unknown:', sorted(mk - ek))
"
```

`unknown` should always be empty — anything listed there is a typo in a
key name, which would silently fall back to English forever.

Then walk the app in your language. `docs/` has a printable QA sheet
listing every screen if you want a full pass.

## Scripts

Nothing to do — your script is handled, including in PDF export.

Worth knowing why, since PDFs are where this usually goes wrong.
On a phone the OS lends the app a font for any script it doesn't ship,
so the UI just works. A PDF has no OS to borrow from: every glyph must
be **embedded in the file**, or readers show empty boxes (tofu).

So the exporter reads the text it's about to render, works out which
scripts are in it, and embeds those faces — driven by your
`languageEndonym` (which is by definition written in your script) plus
any names the user typed. Only what's needed is downloaded, so an
English chart still exports as fast as it ever did.

These scripts are covered:

> Arabic · Armenian · Bengali · Devanagari · Ethiopic · Georgian ·
> Gujarati · Gurmukhi · Hebrew · Kannada · Khmer · Lao · Malayalam ·
> Myanmar · Oriya · Sinhala · Tamil · Telugu · Thai · Thaana

Latin, Greek and Cyrillic need no entry — the app's own body font
already carries them, so Spanish, Vietnamese, Greek and Russian are
covered too.

**If your script isn't on that list**, it's one line for a maintainer —
open the PR and say so. The table is `_scriptFaces` in
`lib/modules/common.dart`; it's keyed by Unicode block rather than by
language, which is why adding a language never touches it. CJK is the
notable absentee: those fonts are tens of megabytes and want a decision
about bundling before anyone wires them in.

## Known gaps (not your fault)

A few strings are still English in **every** language including Hindi,
because they're built inside the calculation engine rather than read
from an ARB file. Don't hunt for keys that would fix these — they don't
exist yet:

- **Yoga names and their "why it fired" details** (`yogas_module.dart`).
- **Transit event labels** in Upcoming Events (`scanGochar`).
- **Ashtakoota koota notes** — the varna and yoni names.
- **The OS home-screen widget** — deliberately out of scope; it renders
  outside the app.

Each is marked `TODO(l10n)` in the code and needs an engine change, not
a translation.

## Gotchas learned the hard way

- **`"@@locale"` must match the filename.** They disagree silently.
- **A key you invent falls back to English forever, without warning.**
  gen-l10n ignores unknown keys. Run the `unknown:` check above.
- **Don't copy the `@key` blocks** from the template. Only
  `app_en.arb` needs them; copies elsewhere are dead weight that drifts
  out of date.
- **Don't reorder or reformat wholesale.** Keep your file's key order
  close to the template's so diffs stay readable for reviewers.
- **`{count}` inside a plural is two braces**: `other{{count} eventos}`
  — the outer pair belongs to the plural, the inner to the placeholder.
- **Abbreviations are width-constrained.** A "short" form that's five
  glyphs wide will overflow a chart cell. Check it on a real chart.
- **Case tricks don't travel.** English chart chips lowercase transit
  planets to distinguish them from natal ones; that's a no-op in
  Devanagari and most Indic scripts. Don't count on upper/lowercase
  carrying meaning in your translation.
- **Commit `lib/l10n/gen/`.** It's generated but tracked — a PR without
  it won't build for the next person.
