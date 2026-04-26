#!/usr/bin/env bash
#
# Build, sign, install, and launch a release iOS build on a physical device.
#
# Usage:
#   scripts/run_ios_release.sh <device>
#     <device>  Anything xcrun devicectl recognizes: name, UDID, ECID, serial.
#               e.g. zzphone  or  00008101-001268480C51003A
#
# Optional env overrides:
#   APP_PROFILE     path to main-app .mobileprovision (default: ~/certs/zzphonelumina.mobileprovision)
#   SIGN_IDENTITY   SHA-1 hash of a codesigning identity (default: first "Apple Development" in keychain)

set -euo pipefail

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo "usage: $(basename "$0") <device>"
      exit 0
      ;;
    *) break ;;
  esac
done

DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  echo "usage: $(basename "$0") <device>" >&2
  echo "  e.g. $(basename "$0") zzphone" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Load KEYCHAIN_PASSWORD (and any other deploy-time env) from .env so this
# script can unlock the login keychain non-interactively, matching the
# pattern used by scripts/deploy-testflight.sh.
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$REPO_ROOT/.env"
  set +a
fi

APP_PROFILE="${APP_PROFILE:-$HOME/certs/zzphonelumina.mobileprovision}"

if [ ! -f "$APP_PROFILE" ]; then
  echo "missing provisioning profile: $APP_PROFILE" >&2
  exit 1
fi

if [ -z "${SIGN_IDENTITY:-}" ]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk '/Apple Development:/ {print $2; exit}')"
fi
if [ -z "$SIGN_IDENTITY" ]; then
  echo "no 'Apple Development' identity in keychain; unlock keychain and import your dev cert" >&2
  exit 1
fi

# codesign reads the signing identity's private key out of the login keychain.
# When the keychain is locked (auto-lock after idle, fresh login, reboot) every
# `codesign --sign` call fails with errSecInternalComponent — even though
# `security find-identity` still lists the identity above. Unlock it now so
# the signing loop below runs cleanly. If KEYCHAIN_PASSWORD is set (loaded
# from .env above, matching scripts/deploy-testflight.sh), unlock headlessly
# with -p; otherwise fall back to the interactive TTY prompt. No-op if the
# keychain is already unlocked.
LOGIN_KC="$(security login-keychain | tr -d '[:space:]"')"
if [ -n "$LOGIN_KC" ]; then
  echo "==> unlock login keychain ($LOGIN_KC)"
  if [ -n "${KEYCHAIN_PASSWORD:-}" ]; then
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$LOGIN_KC"
  else
    security unlock-keychain "$LOGIN_KC"
  fi
fi

BUNDLE="$REPO_ROOT/build/ios/iphoneos/Runner.app"

echo "==> device:   $DEVICE"
echo "==> identity: $SIGN_IDENTITY"

echo "==> flutter build ios --release --no-codesign"
flutter build ios --release --no-codesign

echo "==> embed provisioning profile"
cp "$APP_PROFILE" "$BUNDLE/embedded.mobileprovision"

extract_entitlements() {
  local profile="$1" out="$2" tmp
  tmp="$(mktemp)"
  security cms -D -i "$profile" > "$tmp"
  /usr/libexec/PlistBuddy -x -c 'Print :Entitlements' "$tmp" > "$out"
  rm -f "$tmp"
}

ENT_APP="$(mktemp).plist"
extract_entitlements "$APP_PROFILE" "$ENT_APP"

sign_inner() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  find "$dir" -maxdepth 1 \( -name "*.framework" -o -name "*.dylib" \) -print0 |
    xargs -0 -I{} /usr/bin/codesign --force --sign "$SIGN_IDENTITY" --timestamp=none \
      --preserve-metadata=identifier,entitlements,flags {}
}

echo "==> sign frameworks and bundle"
sign_inner "$BUNDLE/Frameworks"

/usr/bin/codesign --force --sign "$SIGN_IDENTITY" --timestamp=none \
  --entitlements "$ENT_APP" "$BUNDLE"

echo "==> verify"
codesign --verify --verbose=2 --deep --strict "$BUNDLE"

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$BUNDLE/Info.plist")"

echo "==> install on $DEVICE"
xcrun devicectl device install app --device "$DEVICE" "$BUNDLE"

echo "==> launch $BUNDLE_ID (attaching console; Ctrl-C to detach)"
# --console attaches the device process's stdio to this terminal so NSLog
# output (e.g. the [AppleSpeech] traces from AppleSpeechPlugin.swift) is
# visible without Xcode. Ctrl-C detaches without killing the app.
xcrun devicectl device process launch \
  --console \
  --terminate-existing \
  --device "$DEVICE" "$BUNDLE_ID"

echo "==> done; app running on $DEVICE"
