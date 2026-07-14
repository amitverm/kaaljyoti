# Kaal Jyoti

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B.svg)](https://flutter.dev)

Free & open-source Vedic astrology app — high calculation precision (Swiss Ephemeris), a deeply customizable dashboard, and a consent-governed research community. Offline-first: charts are computed and stored on your device; no account is ever required to use the calculator.

**No ads. No tracking. No paid tier.** And because the code is open, you can verify all three.

Website: **[kaaljyoti.com](https://kaaljyoti.com)** · [Privacy](https://kaaljyoti.com/privacy.html) · [Terms](https://kaaljyoti.com/terms.html) · [Support](https://kaaljyoti.com/support.html)

## What's implemented (v1 scope)

- **Chart engine** — birth chart (Rashi/D1) + Navamsa (D9) from DOB/time/place; North Indian, South Indian and Circular styles; 47 ayanamsas (Lahiri default, per-kundli override); planetary positions, panchang at birth, yoga/dosha detection; Prashna kundli.
- **Customizable dashboard** (primary differentiator) — named views per kundli created from templates (Overview, Today, Divisional Focus, Practitioner, Blank); responsive span grid (2 columns on phones, 3 on tablets; widgets sized full/half/third per instance); long-press drag-to-rearrange on the dashboard itself; widget duplication (e.g. three Divisional Chart instances showing D3/D7/D9, or all three dasha systems side by side); per-instance config via a generic settings sheet. All driven by one widget registry — hosts never know module internals.
- **Divisional charts** — full D1–D60 varga engine (D2 Hora, D3, D4, D7, D9, D10, D12, D16, D20, D24, D27, D30 Trimshamsa, D40, D45, D60) behind one configurable Divisional Chart widget.
- **Appearance settings** (elderly-friendly) — text size 100–160%, Classic/High-contrast/Dark palettes, serif or simple headings; persisted, applied app-wide including chart painters.
- **Dasha systems** — Vimshottari, Yogini, Jaimini Chara behind a single `DashaCalculator` interface emitting a shared 3-level period tree.
- **Widget contract** (`lib/widgetsystem/astro_module.dart`) — metadata / dataSource / cardView / detailView / pdfView. Dashboard, customizer and PDF exporter all loop over the registry; a new module = one class + one registry entry.
- **PDF export/print** — module toggle list pre-checked from the dashboard, A4/Letter, cover page, optional practitioner branding, native share/print sheet. Free on every plan.
- **Offline-first storage** — SQLCipher-encrypted SQLite; passphrase in platform keystore. Personal kundlis never leave the device unless sync is enabled.
- **Mahakosh** — consent-governed contribution (self/third-party/health consent branches), anonymized charts (MK-codes), precomputed search index, AND/OR/NOT combination search, research request board with moderation queue, two-way notifications, respond-with-chart flow.
- **Accounts & sync** — Supabase auth (value-driven, never forced); opt-in per-kundli cross-device sync.
- **i18n architecture** — `lib/l10n/app_en.arb` with the Sanskrit-term policy documented; add `app_<code>.arb` per language, no code changes.

Also included: **community discussions** on Mahakosh charts (report/block/moderation built in), **push notifications** (FCM as a delivery pipe only — no Firebase Analytics; entirely disabled unless you provide your own Firebase config at build time), and optional **crash reporting** (Sentry; inert without a DSN — builds you compile yourself contain no telemetry).

## Getting started

```bash
git clone https://github.com/amitverm/kaaljyoti.git
cd kaaljyoti
flutter pub get
flutter run
```

Requires Flutter 3.27+ (Dart 3.6+). The app runs fully offline with no configuration.

### Backend (Mahakosh / auth / sync)

Follow `supabase/README.md` (create project → `supabase db push` → deploy the edge functions → set secrets), then run with:

```bash
cp env.example.json env.json   # fill in your real values (env.json is git-ignored)
flutter run --dart-define-from-file=env.json
```

(Equivalent one-off form: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`)

`SUPABASE_ANON_KEY` takes the **publishable key** (`sb_publishable_...`) shown in new Supabase projects — it's the successor to the legacy anon key, with identical low privileges under RLS. Never use the secret (`sb_secret_`) / service_role key in the app.

Without these defines, Mahakosh/auth/sync screens show their signed-out/unconfigured states.

## Architecture map

```
lib/
  core/astro/        engine: sweph wrapper, snapshot, panchang, yogas,
                     divisional charts, dasha/ (3 systems + registry)
  charts/            North/South/Circular CustomPainters + ChartView
  widgetsystem/      module contract + registry (dashboard/PDF loop over it)
  modules/           7 modules: birth chart, dasha, panchang,
                     moon/nakshatra, positions, navamsa, yogas
  data/              encrypted SQLite: kundlis, dashboard views, settings
  mahakosh/          community repo client, chart index builder, research
  services/          place lookup (Open-Meteo + tz), sync
  screens/           all 15 designed screens + PDF export screen
  pdf/               exporter (loops over registry pdfViews)
  l10n/              app_en.arb + terminology policy
supabase/            migrations (schema + RLS + triggers), edge functions
                     (search, matching, moderation, notification fan-out)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — contributions are welcome and
require copyright assignment (this keeps the project's licensing options
open). Run `flutter analyze` and `flutter test` before submitting.

## License

Kaal Jyoti — Vedic astrology & kundali app
Copyright (C) 2026 Amit Verma

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

Planetary calculations are powered by the Swiss Ephemeris, used under
its AGPL license option.

## Trademarks

"Kaal Jyoti", the diya emblem, and related brand art are trademarks of
Amit Verma and are NOT licensed under the AGPL. You may build and run
this source for yourself, but a redistributed fork must ship under its
own name, icon, and branding. The brand source art (SVG masters and
store graphics) is intentionally not included in this repository; the
generated launcher icons and in-app emblem remain only so the app
builds as published.

Contact: <vermaji.amit@gmail.com> or open an issue at
<https://github.com/amitverm/kaaljyoti/issues>.
