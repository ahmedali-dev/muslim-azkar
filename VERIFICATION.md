# Version 1.4.1 delivery verification · 5 November 2026

- The reader’s “النص” label is reduced to 11 sp; zikr body font settings and
  the counter size are unchanged.
- GitHub Actions workflows and the static Arabic landing page are prepared.
  Repository creation, remote workflow results, and public deployment must be
  verified separately after publication is authorized.
- Selected themes are **سكينة** for light mode and **ليل** for dark mode,
  following the user's HTML design selections. Home cards, reading surfaces,
  navigation, Settings, and category library use matching colours.
- The compact 80 dp counter paints a tasbih-bead ring in light mode and a moon
  orbit in dark mode. Painter invalidation follows progress and brightness changes.
  No backdrop blur, continuous animation, or additional dependencies are used.
- Themes remain cached and selected independently of counter progress. Native
  reading, reset, completion, persistence, and notifications retain their logic.
- Widget checks cover narrow/short screens, 200% text, no blur, stable theme
  identity across a counter tap, and counter size. No physical-device frame-rate
  benchmark was available.
- Image sharing adds native Android single/multiple PNG sharing through a
  non-exported, cache-scoped FileProvider. Paths are validated beneath the share
  cache, read grants are temporary, and no storage/network permission is added.
- Native multi-image sharing was observed in Android’s chooser with two
  `image/png` content URIs and temporary read grants. No message was sent.
- Exports support 1080×1350 portrait and 1080×1080 square cards in either theme.
  All 315 source entries are checked in both formats: pagination preserves their
  complete text and shaped lines fit inside the image. PNG dimensions decode
  correctly in tests. Source images use bundled Amiri/Tajawal fonts.
- Source navigation was scraped from the exact selector
  **`.card-body.text-primary-emphasis`**. Every azkar link was followed, and only
  the standalone **`القرآن`** (`/quran`) link was excluded.
- Captured **27 categories / 315 entries** in source-menu order: the original
  morning/evening collections plus **25 additional categories**. Every text,
  diacritic, punctuation mark, repetition count, inline reference, and virtue is
  checked against a browser-captured UTF-16 FNV-1a fingerprint.
- `python3 tool/import_categories.py --check`: **passed** for all 315 entries
  and their offline assets. Morning/evening entries compare equal to the earlier
  version, preserving their IDs and saved progress keys.
- Four entries have source repetition count **0**. JSON preserves that value;
  the app tracks manual reading completion instead of prescribing repetitions.
- `flutter analyze`: **No issues found**.
- `flutter test --concurrency=1`: **16 tests passed**. Tests cover counter bounds,
  weighted progress, all-category loading/exclusion, source-zero reading, daily
  reset, persistence, independent category progress, library search/navigation,
  short/narrow layouts, 200% accessibility text, and reminder-permission branches.
- Reminder isolation test confirms that additional categories do not inherit the
  evening reminder. Existing notification IDs and payloads remain unchanged.
- Android integration test: **passed** on the ARM64 Android **17 / API 37**
  emulator with 16 KB pages. Verified the morning counter/automatic advance,
  Settings, all 27 library categories, Arabic search, opening Food Azkar, and
  counter/automatic advance in that additional section.
- Native Android screenshots were captured and visually inspected:
  `screenshots/home.png`, `morning.png`, `settings.png`, `categories.png`, `food.png`, `home_dark.png`, `categories_dark.png`, `evening_dark.png`, `share_preview_light.png`, `share_preview_dark.png`, `share_light.png`, `share_dark.png`, `android_share_sheet.png`.
- Release split APK and app-bundle commands build successfully. The final ARM64
  release APK is separately installed/launched from its built binary.
- All three release APKs are checked against **15,000,000 bytes**. Exact sizes
  and SHA-256 hashes are in `deliverables/build_manifest.json`; archive/binary
  checksums are in `deliverables/SHA256SUMS.txt`.
- Packaging checks every collection inside every APK against its source asset.
  The clean source ZIP is CRC-checked and includes the runnable Android wrapper.
- APK manifests retain **minSdk 23**, target SDK 35, Arabic application label,
  boot/exact-alarm/notification declarations, and reboot-restoration receivers.
  **INTERNET and VIBRATE are absent**. AndroidX adds its internal signature
  permission for receiver registration. APK v1/v2 signing is verified.
- Bundles contain ARMv7, ARM64, and x86-64 libraries. Font files and OFL licenses
  are bundled. No runtime content downloads or extra permissions were added.

## Practical limits

Use the pinned **Flutter 3.32.8 / Dart 3.8.1**, JDK 17, and compile SDK 36. The
minimum API level is configured for Android 6; that physical device version was
not available for testing. Real reboot delivery, long-term alarm timing, and
manufacturer battery restrictions still require physical-device testing;
permission/fallback paths and cold-notification selection were tested with mocks.

Asr highlighting follows the local time configured in Settings (default 16:00).
The app does not calculate geographic prayer times or request location access.
Social apps were not installed on the emulator; preview/export and the Android share
sheet were checked, but no external post or message was sent. Actual receiving-app
behaviour depends on the installed app. Reminders remain morning/evening only. Release builds use a development signing
certificate unless an upload key is configured for store distribution.
