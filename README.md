# BatteryNotify

A tiny macOS menu bar app that warns you when the battery runs low.

- Shows a warning panel when the charge drops to or below your threshold while on battery.
- The panel is drawn by the app itself, not by Notification Center: it needs no
  permission and it never disappears on its own.
- It closes on three things only: you press **Dismiss**, you plug in the
  charger, or the charge climbs back above the threshold.
- No polling: it listens to IOKit power-source events, so it sits at ~0% CPU.
- No Dock icon, no window — just a battery icon in the menu bar.

Requires macOS 13 or later. Universal: Apple Silicon and Intel.

## Install

Download `BatteryNotify.dmg` from the
[latest release](../../releases/latest), open it and drag the app into
`Applications`.

The app is signed ad-hoc rather than with an Apple Developer ID, so the first
launch has to go through Gatekeeper by hand: right-click the app in
`Applications`, choose **Open**, then confirm. macOS remembers the choice, and
every later launch is normal. The command line equivalent is:

```sh
xattr -d com.apple.quarantine /Applications/BatteryNotify.app
```

## Usage

Click the menu bar icon:

- current percentage and power source
- threshold picker: 10% / 15% / 20% / 25% / 30% (default 20%)
- **Launch at Login** toggle
- **Quit**

`Launch at Login` uses `SMAppService`, which expects the app to live in a stable
location, so register it from `/Applications` rather than from a build folder.

## Build from source

Xcode is not required, only the Command Line Tools.

```sh
./build.sh      # -> build/BatteryNotify.app (universal)
./package.sh    # -> build/BatteryNotify.dmg
```

Install the result the same way as a downloaded release:

```sh
cp -R build/BatteryNotify.app /Applications/
open /Applications/BatteryNotify.app
```

Launching it straight out of `build/` is fine for a quick test, but keep the
copy in `/Applications` for daily use: both Spotlight and `SMAppService` skip
apps sitting in arbitrary locations.

## Release

Pushing a `v*` tag builds the app on a macOS runner and publishes the disk image
as a GitHub release:

```sh
git tag v1.0
git push origin v1.0
```

`workflow_dispatch` runs the same build without publishing, leaving the disk
image as a downloadable workflow artifact.

## Layout

```
Sources/PowerMonitor.swift       event-driven battery state (IOKit)
Sources/AlertPanel.swift         the floating warning panel
Sources/AppDelegate.swift        menu bar UI and alert logic
Sources/main.swift               entry point
Resources/Info.plist             bundle metadata (LSUIElement = background app)
Tools/make-icon.swift            the app icon, drawn in code
build.sh                         universal swiftc build + ad-hoc signature
package.sh                       disk image packaging
.github/workflows/release.yml    build and publish on tag
```
