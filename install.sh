#!/bin/bash
# Installs (or reinstalls) the latest Painted City into /Applications and opens it:
#
#   curl -fsSL https://raw.githubusercontent.com/iamfedese/painted-city-releases/main/install.sh | bash
#
# Releases are not notarized by Apple (that needs a paid developer account), so a copy downloaded in a browser
# is quarantined and macOS refuses to open it ("Apple could not verify…"). Files fetched with curl aren't
# quarantined, so the app installed this way opens normally. After that, it updates itself (Sparkle).
# scripts/release.sh publishes this file next to the update feed.
set -euo pipefail

URL="https://github.com/iamfedese/painted-city-releases/releases/latest/download/PaintedCity.zip"
APP="/Applications/PaintedCity.app"

if [[ "$(uname)" != Darwin ]]; then
    echo "Painted City runs on macOS only." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Painted City…"
curl -fL --progress-bar "$URL" -o "$TMP/PaintedCity.zip"
ditto -x -k "$TMP/PaintedCity.zip" "$TMP"
if [[ ! -d "$TMP/PaintedCity.app" ]]; then
    echo "The download didn't contain PaintedCity.app." >&2
    exit 1
fi

# Replace a running copy rather than leave the old one on screen.
pkill -x PaintedCity 2>/dev/null && sleep 1 || true

# /Applications is writable for admin users; otherwise ask for the password.
SUDO=""
[[ -w /Applications ]] || SUDO="sudo"
$SUDO rm -rf "$APP"
$SUDO ditto "$TMP/PaintedCity.app" "$APP"
# In case an earlier browser download left the quarantine flag behind on anything.
$SUDO xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo "")"
echo "Installed Painted City${VERSION:+ $VERSION} in /Applications. It lives in the menu bar (palette icon)."
open "$APP"
