#!/bin/bash

# Build, package, and launch the app for local development.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/version.env"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

BUILD_CONFIGURATION=debug "$SCRIPT_DIR/package_app.sh"

open "$ROOT_DIR/build/${APP_NAME}.app"

