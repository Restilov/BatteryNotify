#!/bin/bash
# Builds BatteryNotify.app without Xcode (Command Line Tools are enough).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BatteryNotify"
BUNDLE_ID="com.resti.BatteryNotify"
APP="build/$APP_NAME.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"

swiftc \
	-target "$(uname -m)-apple-macos13.0" \
	-O -whole-module-optimization \
	-o "$APP/Contents/MacOS/$APP_NAME" \
	Sources/*.swift

# Ad-hoc signature: required for notifications and the login item to work.
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP"

echo "Built $APP"
