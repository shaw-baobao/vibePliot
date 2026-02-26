#!/bin/bash

# Package a release app and generate a zip archive.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/version.env"

BUILD_CONFIGURATION=release "$SCRIPT_DIR/package_app.sh"

cd "$ROOT_DIR/build"
ZIP_NAME="${APP_NAME}-v${VERSION}.zip"
rm -f "$ZIP_NAME"
zip -r -q "$ZIP_NAME" "${APP_NAME}.app"

echo "Release archive: $ROOT_DIR/build/$ZIP_NAME"
