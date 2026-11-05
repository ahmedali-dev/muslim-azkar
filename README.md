# Muslim Azkar · أذكار المسلم

Arabic-only, fully offline Flutter Android app with **27 categories / 315 entries**:
RTL Material 3, bundled Arabic fonts, daily saved progress, reading counters,
copy/share, Arabic category search, themes, font sizes, and morning/evening reminders.

Version **1.4.1** applies the selected **سكينة (Sakina)** design to light mode
and **ليل (Layl)** to dark mode. Sakina uses sage-green featured cards, white
reading surfaces, and a compact tasbih-bead counter. Layl uses deep teal surfaces,
soft green highlights, and a moon-orbit counter. System theme mode automatically
chooses the matching design; manual light/dark settings remain available.

Counters retain **80 dp** touch targets. Decorations use vector painting with no
blur, continuous animation, external assets, or new dependencies. Themes remain
cached and counter taps do not regenerate the application theme.

## GitHub, Releases, and landing page

- Repository: https://github.com/ahmedali-dev/muslim-azkar
- Landing page: https://ahmedali-dev.github.io/muslim-azkar/
- Downloads: https://github.com/ahmedali-dev/muslim-azkar/releases/latest

`.github/workflows/android.yml` analyzes and tests every pull request/push.
Trusted pushes build signed split APKs and an Android App Bundle as Actions
artifacts. A `v*` tag whose version matches `pubspec.yaml` also publishes those
files, a build manifest, and SHA-256 checksums in GitHub Releases. Pull-request
builds never receive signing secrets. All third-party actions are pinned by SHA.

Configure four encrypted repository Actions secrets before release builds:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
and `ANDROID_KEY_ALIAS`. Signing files exist only temporarily on the runner and
are removed after the build. Keep an offline backup of the chosen signing key;
future releases need the same key to update existing installs. No keys or
passwords belong in Git history.

This repository uses a dedicated app signing key stored in encrypted Actions
secrets. Its public SHA-256 certificate fingerprint is in
`signing-certificate.sha256`. A private local backup is kept outside Git in
`.tooling/signing/`; keep that folder safe. The first GitHub release has a
different signature from the earlier development APKs, so those installations
need a one-time reinstall. Subsequent GitHub releases use the same app key.

The Arabic landing page is static HTML in `site/`, with bundled fonts and local
screenshots. `.github/workflows/pages.yml` deploys it to GitHub Pages on changes
to `site/` or by manual dispatch. Set the repository's Pages source to **GitHub
Actions**. Download buttons always point to the latest Release APK, so they
update automatically when a new version is published.

```sh
# Bump pubspec.yaml first, then publish a matching tag.
git tag v1.4.1
git push origin v1.4.1
```

Workflow references: [GitHub Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages),
[GitHub release CLI](https://cli.github.com/manual/gh_release_create).

## Share a zikr as an image

Tap the image icon in the reader. Choose **سكينة / ليل** and **portrait / square**,
preview the result, then share through Android's system share sheet to WhatsApp,
X, Facebook, or another installed image-sharing app. Portrait PNGs are 1080×1350;
square PNGs are 1080×1080. Existing text sharing remains available.

Long texts are split at shaped Arabic line boundaries; no words or diacritics
are removed. Share the displayed page or all pages. Images include the section,
source repetition count, app name, and IslamBook credit. Temporary exports stay
in the app's cache and use a non-exported FileProvider with read grants. They
expire after two days. No storage permission, network request, new dependency,
or automatic posting is involved. Available destinations and multi-image limits
depend on the installed receiving apps.

## Run and build

Use **Flutter 3.32.8 / Dart 3.8.1** (`.fvmrc`), JDK 17, Android SDK platform 36,
command-line tools, and NDK 27.0.12077973. This Flutter version retains support
for Android 6; the app minimum is **API 23**. Development needs dependency
access; the installed release app has **no Internet permission**.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle
```

Build separate APKs to meet the **under 15 MB** download-size requirement:

```sh
flutter build apk --release --split-per-abi
# Or: sh scripts/build_release.sh
```

Outputs are under `build/app/outputs/flutter-apk/`. Use `arm64-v8a` for most
modern phones. The plain APK command creates a larger universal APK. Native
libraries are compressed in APKs and extracted on installation. The build
script checks every split APK against 15,000,000 bytes.

Release builds use a development signing key unless `android/key.properties`
supplies `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. Use your own
upload key for store distribution. The app bundle is written under
`build/app/outputs/bundle/release/`.

## Captured content

On **2 November 2026**, every category link in IslamBook's
`.card-body.text-primary-emphasis` section was followed, except the standalone
**`القرآن`** link. This adds **25 categories** to the original morning/evening
collections, for **27 categories and 315 source entries**. Related categories
such as Quranic supplications, Quran-completion dua, and ruqyah are retained.

- Original files: `assets/morning_azkar.json` (31 entries / 464 repetitions) and
  `assets/evening_azkar.json` (30 / 364). Existing item IDs and progress keys remain.
- Additional collections: `assets/categories/<source-id>.json`.
- Ordered category titles, exact source links, counts, and asset paths:
  `assets/categories/catalog.json`. The About screen credits all 27 source pages.
- Arabic words, punctuation, diacritics, source repetition counts, and visible
  virtues are unchanged. Visible layout whitespace is retained from `innerText`.
  Inline references remain in the original text and also populate `source` when
  available. No narrators or religious repetition counts were invented.
- Four source entries have a repetition count of **0**. Their original value is
  retained; the reader offers **mark as read** and tracks one completion action.

```sh
python3 tool/import_categories.py --check  # validate all 315 captured entries/assets
python3 tool/import_categories.py          # regenerate assets and category metadata
```

`tool/source/categories_capture.json` is the UTF-8 browser capture, with an
independent UTF-16 FNV-1a fingerprint for every item. It verifies transcription
integrity, not cryptographic security. The legacy `tool/capture_content.py`
continues to verify the original two collections. No scraping runs in the app.

## App behavior

- Open the category library from Home or its app-bar grid icon. Arabic search
  ignores tashkeel, tatweel, and common alef/ya/ta-marbuta variants.
- Every category has independent progress under the local calendar date. It
  resets at midnight, on resume, on the next tap, or on relaunch. Settings remain.
- Swipe between entries; long text scrolls within its card. Complete a counter
  to advance automatically. Completion provides review/restart actions.
- Daily reminders remain **morning/evening only**, default off at 05:30 / 16:30.
  Android notification permission is requested on enabling; optional exact-alarm
  access falls back to approximate scheduling when denied. Schedules restore
  through boot/app-replacement receivers and refresh on resume. Notification
  taps open the corresponding collection. OS force-stop/battery rules may delay
  delivery; reopen after changing timezone.
- Set your city's Asr time in Settings for evening highlighting (default 16:00).
  No location permission or geographic prayer-time calculation is used.
- Amiri/Tajawal fonts and their OFL licenses are bundled; licenses are accessible
  from About. No advertising, analytics, tracking, or runtime content downloads.

## Verification

```sh
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d <android-device-id>
```

This exercises morning and additional-category reading and saves native Android
PNGs under `screenshots/`. `VERIFICATION.md` records actual checks and limits.
Source is organized under `lib/{data,models,providers,screens,widgets,theme,services}`.
