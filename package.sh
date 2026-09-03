#!/bin/bash
# Wraps the built app into a laid-out, drag-to-install disk image.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BatteryNotify"
VOLUME="BatteryNotify"
APP="build/$APP_NAME.app"
DMG="build/$APP_NAME.dmg"
STAGE="build/dmg"
RW_DMG="build/$APP_NAME-rw.dmg"

WINDOW_WIDTH=560
WINDOW_HEIGHT=380
ICON_SIZE=128

if [ ! -d "$APP" ]; then
	echo "error: $APP not found, run ./build.sh first" >&2
	exit 1
fi

rm -rf "$STAGE" "$DMG" "$RW_DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
# The symlink is what gives the mounted image its "drag me into Applications" pane.
ln -s /Applications "$STAGE/Applications"

# A read-write image first: Finder has to be able to write the .DS_Store that
# stores the window size and the icon positions.
hdiutil create \
	-volname "$VOLUME" \
	-srcfolder "$STAGE" \
	-fs HFS+ \
	-size 40m \
	-format UDRW \
	-ov "$RW_DMG" >/dev/null

MOUNT=$(hdiutil attach "$RW_DMG" -nobrowse -noautoopen | awk -F'\t' '/\/Volumes\// {print $NF}')
trap 'hdiutil detach "$MOUNT" >/dev/null 2>&1 || true' EXIT

# If a volume of the same name is already mounted, ours lands on a suffixed one
# ("BatteryNotify 1"). Address Finder by where it actually mounted, never by the
# name we asked for, or the layout gets applied to the wrong disk.
MOUNTED_VOLUME=$(basename "$MOUNT")

# Finder is what owns the window layout, so it has to be driven from AppleScript.
# On a headless machine this can fail; the image is still valid, just unstyled.
osascript <<EOF || echo "warning: could not style the window, shipping the plain layout" >&2
tell application "Finder"
	tell disk "$MOUNTED_VOLUME"
		open
		set current view of container window to icon view
		set toolbar visible of container window to false
		set statusbar visible of container window to false
		set the bounds of container window to {200, 150, $((200 + WINDOW_WIDTH)), $((150 + WINDOW_HEIGHT))}

		set options to the icon view options of container window
		set arrangement of options to not arranged
		set icon size of options to $ICON_SIZE
		set text size of options to 13

		set position of item "$APP_NAME.app" of container window to {150, 170}
		set position of item "Applications" of container window to {410, 170}

		update without registering applications
		close
	end tell
end tell
EOF

sync
if [ ! -f "$MOUNT/.DS_Store" ]; then
	echo "warning: no .DS_Store was written, the window layout will not stick" >&2
fi

hdiutil detach "$MOUNT" >/dev/null
trap - EXIT

hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG" >/dev/null
rm -rf "$RW_DMG" "$STAGE"
echo "Built $DMG"
