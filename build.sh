#!/bin/bash
# Builds a universal BatteryNotify.app without Xcode (Command Line Tools are enough).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BatteryNotify"
BUNDLE_ID="com.resti.BatteryNotify"
APP="build/$APP_NAME.app"
DEPLOYMENT_TARGET="13.0"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# The tag you picked is the single source of truth for the version number;
# nothing is typed into Info.plist by hand.
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
VERSION=${VERSION#v}
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"

# One slice per architecture, then glued together so the release runs on both
# Apple Silicon and Intel.
for arch in arm64 x86_64; do
	swiftc \
		-target "$arch-apple-macos$DEPLOYMENT_TARGET" \
		-O -whole-module-optimization \
		-o "build/$APP_NAME-$arch" \
		Sources/*.swift
done

lipo -create -output "$APP/Contents/MacOS/$APP_NAME" \
	"build/$APP_NAME-arm64" "build/$APP_NAME-x86_64"
rm -f "build/$APP_NAME-arm64" "build/$APP_NAME-x86_64"

# The icon is generated from source rather than checked in as a binary asset.
ICONSET="build/AppIcon.iconset"
swift Tools/make-icon.swift "$ICONSET" >/dev/null
iconutil --convert icns --output "$APP/Contents/Resources/AppIcon.icns" "$ICONSET"
rm -rf "$ICONSET"

# Ad-hoc signature: enough to run locally and to satisfy SMAppService.
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP"

echo "Built $APP (version $VERSION)"
lipo -archs "$APP/Contents/MacOS/$APP_NAME"
