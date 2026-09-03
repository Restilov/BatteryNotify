# BatteryNotify

A tiny macOS menu bar app that warns you when the battery runs low.

- Shows a warning panel when the charge drops to or below your threshold while on battery.
- The panel is drawn by the app itself, not by Notification Center: it needs no
  permission and it never disappears on its own.
- It closes on three things only: you press **Dismiss**, you plug in the
  charger, or the charge climbs back above the threshold.
- No polling: it listens to IOKit power-source events, so it sits at ~0% CPU.
- No Dock icon, no window — just a battery icon in the menu bar.

## Build

Xcode is not required, only the Command Line Tools.

```sh
./build.sh
open build/BatteryNotify.app
```

To install it permanently:

```sh
cp -R build/BatteryNotify.app /Applications/
open /Applications/BatteryNotify.app
```

`Launch at Login` uses `SMAppService`, which expects the app to live in a stable
location, so register it from `/Applications` rather than from `build/`.

## Usage

Click the menu bar icon:

- current percentage and power source
- threshold picker: 10% / 15% / 20% / 25% / 30% (default 20%)
- **Launch at Login** toggle
- **Quit**

## Layout

```
Sources/PowerMonitor.swift   event-driven battery state (IOKit)
Sources/AlertPanel.swift     the floating warning panel
Sources/AppDelegate.swift    menu bar UI and alert logic
Sources/main.swift           entry point
Resources/Info.plist         bundle metadata (LSUIElement = background app)
build.sh                     swiftc build + ad-hoc code signature
```
