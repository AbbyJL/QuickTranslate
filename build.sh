#!/bin/bash
set -e

APP_NAME="QuickTranslate"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SRC_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "=== Building ${APP_NAME} ==="

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Create app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy Info.plist
cp "${SRC_DIR}/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Generate app icon: run Swift script, create iconset, convert to icns, copy to bundle
echo "Generating icon..."
cd "${SRC_DIR}"
swift GenerateIcon.swift > /dev/null 2>&1
iconutil -c icns "${SRC_DIR}/AppIcon.iconset" -o "${SRC_DIR}/AppIcon.icns"
cp "${SRC_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${APP_BUNDLE}/Contents/Info.plist"
echo "App icon added"

# Compile Swift source
echo "Compiling..."
swiftc \
    -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
    "${SRC_DIR}/QuickTranslateApp.swift" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Carbon \
    -parse-as-library \
    -target arm64-apple-macos12.0 \
    -sdk $(xcrun --show-sdk-path) \
    -O

if [ $? -eq 0 ]; then
    echo "=== Build succeeded ==="
    echo "App bundle: ${APP_BUNDLE}"
    echo ""
    echo "To run:  open \"${APP_BUNDLE}\""
    echo "To install:  cp -r \"${APP_BUNDLE}\" /Applications/"
else
    echo "=== Build failed ==="
    exit 1
fi
