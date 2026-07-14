# OS Home-Screen Widgets — Setup Guide

Two widgets ship with the app: **Daily Panchang** (tithi, nakshatra,
sunrise/sunset, Rahu Kaal for your city) and **Live Transit** (rising
lagna + every graha's sign).

## How it works (read this once)

Home-screen widgets cannot run Flutter or Swiss Ephemeris. So the app
**precomputes** everything whenever the Today screen calculates
(`OsWidgetService.pushToday`) and hands the native side plain strings
via the `home_widget` plugin:

- **Android**: stored in SharedPreferences; two `AppWidgetProvider`s
  (`PanchangWidgetProvider`, `TransitWidgetProvider`) render them with
  RemoteViews. The OS's 30-minute widget cycle re-reads the store; the
  Transit widget also carries a precomputed 12-hour timeline and picks
  the freshest entry, so the lagna stays roughly current between app
  opens.
- **iOS**: stored in an App Group `UserDefaults` suite; a WidgetKit
  extension renders them. The Transit widget turns the 12-hour JSON
  timeline into scheduled WidgetKit entries (30-min steps) — iOS
  animates through them without waking the app. The Panchang widget
  reloads itself when the tithi ends (`pw_refresh_at`).

Data is at most one app-session stale; both widgets show their "as of"
time. Opening the app (which lands on Today) refreshes everything.

## One-time steps on your machine

### 0. Fetch the plugin

```bash
flutter pub get   # picks up home_widget
```

### 1. Android — nothing else

Everything is already in the repo (providers, layouts, provider-info
XML, manifest receivers). Build and run; long-press the home screen →
Widgets → Kaal Jyoti.

### 2. iOS — two manual Xcode steps (~10 minutes)

The Swift code is already at `ios/KaalJyotiWidgets/KaalJyotiWidgets.swift`;
Xcode just needs a target to own it.

**a. Create the Widget Extension target**

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File → New → Target… → **Widget Extension**.
3. Product Name: exactly `KaalJyotiWidgets`. UNCHECK "Include
   Configuration App Intent" (we use static widgets). Don't activate
   the scheme prompt matters little — either is fine.
4. Xcode generates a `KaalJyotiWidgets` folder with a template swift
   file — **delete the template's contents and replace the folder's
   swift file** with the repo's
   `ios/KaalJyotiWidgets/KaalJyotiWidgets.swift` (or delete the
   generated file and drag ours into the target, ticking
   "KaalJyotiWidgets" as target membership).
5. Set the extension's iOS Deployment Target to 16.0 (or your app's
   minimum, if higher).

**b. Attach the App Group to BOTH targets**

1. Select the **Runner** target → Signing & Capabilities → “+
   Capability” → App Groups → add
   `group.com.kaaljyoti`.
2. Select the **KaalJyotiWidgets** target → same capability, same
   group id.
3. The id must match `OsWidgetService.appGroupId` in
   `lib/services/os_widget_service.dart` — change both together if
   you ever rename it.

Build & run the Runner scheme on a device, open the app once (so
Today pushes data), then add the widgets from the home-screen widget
gallery.

## Troubleshooting

- **Widget says "Open the app once"** — no data yet: launch the app,
  let Today finish computing.
- **iOS widget never updates** — the App Group is missing on one of
  the two targets, or the group id doesn't match the Dart constant.
- **Android widget stale after midnight** — expected at most until
  the next 30-minute OS cycle or app open; the panchang strings carry
  their own end-times so it never *misleads*.
- **Times look shifted** — widgets show times in the device's zone;
  the panchang city only controls sunrise/lagna (same rule as the
  Today screen).

## Extending

New fields: write another `HomeWidget.saveWidgetData` key in
`OsWidgetService.pushToday`, read it in the Kotlin provider / Swift
view, add a TextView/Text. Keep everything strings — the native side
should never compute astrology.
