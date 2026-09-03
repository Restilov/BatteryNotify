#!/bin/bash
# Wraps the built app into a drag-to-install disk image.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BatteryNotify"
APP="build/$APP_NAME.app"
DMG="build/$APP_NAME.dmg"
STAGE="build/dmg"

if [ ! -d "$APP" ]; then
	echo "error: $APP not found, run ./build.sh first" >&2
	exit 1
fi

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
# The symlink is what gives the mounted image its "drag me into Applications" pane.
ln -s /Applications "$STAGE/Applications"

hdiutil create \
	-volname "$APP_NAME" \
	-srcfolder "$STAGE" \
	-ov -format UDZO \
	"$DMG" >/dev/null

rm -rf "$STAGE"
echo "Built $DMG"
