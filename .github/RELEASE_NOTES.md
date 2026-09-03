## Install

1. Download `BatteryNotify.dmg` below, open it, and drag **BatteryNotify** onto **Applications**.
2. Launch it. macOS blocks the first launch with *"Apple could not verify BatteryNotify is free of malware"* — press **Done** there, **not** *Move to Trash*.
3. Open **System Settings → Privacy & Security**, scroll to the bottom, and press **Open Anyway** on the notice about BatteryNotify.

macOS remembers that decision, so every later launch is normal.

The warning appears because the app is signed ad-hoc instead of with a paid Apple Developer ID; macOS has no identity to check it against. Nothing about the app changes once you allow it.

### Or build it yourself

A copy you compile locally is never flagged, because the quarantine mark is put on files by the browser that downloads them. Xcode is not needed, only the Command Line Tools:

```sh
git clone https://github.com/Restilov/battery-notify.git
cd battery-notify
./build.sh
cp -R build/BatteryNotify.app /Applications/
```

---
