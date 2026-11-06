# Intently

**A minimal Android launcher built around intentions.**

Intently turns your home screen into a short list of intentions. Give each row a
word — Read, Listen, Create, Move — and group the apps that serve it underneath.
Tap the row to launch the primary app, or swipe up to open the whole intention.

Intently is an independent, GPLv3-licensed fork of
[Olauncher](https://github.com/tanujnotes/Olauncher) by Tanuj M.

## Features

- **Intention-first home screen.** Name each row, add the apps that belong to it,
  and choose which app opens on a tap.
- **Fast app drawer.** Search by name, with automatic launch when one result
  matches.
- **Useful gestures.** Swipe up for all apps, double tap to lock, and configurable
  left/right app shortcuts.
- **Quiet by default.** No ads, no analytics, and no data collection.
- **Make it yours.** Text size, bold font, alignment, themes, status bar, and
  daily wallpapers.
- **Modern Android support.** Work profile and Private Space support on supported
  devices.

## Install

Download the latest APK from
[GitHub Releases](https://github.com/mexitalian/Intently/releases/latest).

Intently requires Android 7.0 (API 24) or newer. This fork is distributed through
GitHub Releases; it is not published on Google Play or F-Droid by this project.

## Gestures

- **Swipe up** anywhere on the home screen to open the app drawer.
- **Swipe up on an intention** to open its folder view.
- **Long press** the home screen to open settings.
- **Double tap** to lock the screen. This requires enabling Intently's
  accessibility service.
- **Swipe left or right** to open the optional shortcut apps.

## Build

Intently is a standard Gradle Android project.

Requirements:

- JDK 17
- Android SDK with API 36 installed

```sh
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

The debug APK is written to `app/build/outputs/apk/debug/`.

## Upstream sync

Intently stays on the GPLv3 lineage of [Olauncher](https://github.com/tanujnotes/Olauncher),
but inherits functional changes in controlled batches, not as a rolling rebrand.

- The `olauncher` remote points at the original Olauncher repository.
- `olauncher/master` is fetched separately from `origin/master`.
- Rebases stay out of the way; merges keep history readable and conflict-free as
  much as possible.
- The `olauncher` remote fetches the original code, but the fork decides which
  functional work to inherit.

```sh
scripts/sync-upstream.sh
```

That script creates or reuses `sync/upstream`, merges `olauncher/master` into it,
and leaves the result on a branch for review before any push. Intently-specific
branding, privacy, and store metadata are meant to stay Intently-facing.

The remote is deliberately named `olauncher` rather than the conventional
`upstream`: `gh` CLI treats an `upstream` remote as the base repository, which
would aim pull request commands at tanujnotes/Olauncher instead of this fork.

## Privacy

Intently does not include analytics, advertising, or crash-reporting SDKs. App
settings and intention data stay on the device. The optional daily wallpaper
feature downloads a wallpaper feed and image over HTTPS; no personal data is sent
with that request. The wallpaper feed is currently inherited from Olauncher.

The accessibility service is optional and is used only for the double-tap-to-lock
gesture. Usage-access data, when enabled, is processed on the device and is not
uploaded.

## Attribution and license

Intently is derived from [Olauncher](https://github.com/tanujnotes/Olauncher),
originally created by Tanuj M ([@tanujnotes](https://github.com/tanujnotes)) and
improved by its contributors. The original work is licensed under the GNU General
Public License v3.0. Original copyright remains with the Olauncher authors and
contributors; modifications in this fork are copyright their respective authors.

This project is distributed under the
[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).
See [LICENSE](LICENSE) for the full text.

Intently is not affiliated with or endorsed by the Olauncher project.
