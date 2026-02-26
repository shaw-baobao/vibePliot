#!/bin/bash

# Build a macOS .app bundle from the SwiftPM executable target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/version.env"

CONFIGURATION="${BUILD_CONFIGURATION:-release}"
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SPM_BINARY="$ROOT_DIR/.build/$CONFIGURATION/$APP_NAME"

echo "Building $APP_NAME ($CONFIGURATION)..."

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swift build -c "$CONFIGURATION" --package-path "$ROOT_DIR" --product "$APP_NAME"

if [ ! -f "$SPM_BINARY" ]; then
  echo "Binary not found: $SPM_BINARY"
  exit 1
fi

cp "$SPM_BINARY" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

LS_UI_ELEMENT_VALUE="<true/>"
if [ "${MENU_BAR_APP:-1}" != "1" ]; then
  LS_UI_ELEMENT_VALUE="<false/>"
fi

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>${MIN_MACOS}</string>
  <key>LSUIElement</key>
  ${LS_UI_ELEMENT_VALUE}
  <key>NSCameraUsageDescription</key>
  <string>VibePilot needs camera access to detect hand gestures and control input mappings.</string>
</dict>
</plist>
EOF

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "Packaged app: $APP_BUNDLE"

