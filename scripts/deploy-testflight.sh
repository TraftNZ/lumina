#!/usr/bin/env bash
set -euo pipefail

#──────────────────────────────────────────────────────────────
# deploy-testflight.sh — Build & upload Lumina to TestFlight
#
# Usage:
#   ./scripts/deploy-testflight.sh              # full build (server + app + upload)
#   ./scripts/deploy-testflight.sh --skip-server # skip Go server rebuild
#   ./scripts/deploy-testflight.sh --build-only  # build archive but don't upload
#──────────────────────────────────────────────────────────────

SKIP_SERVER=false
BUILD_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --skip-server) SKIP_SERVER=true ;;
    --build-only)  BUILD_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--skip-server] [--build-only]"
      echo "  --skip-server  Skip rebuilding the Go gRPC xcframework"
      echo "  --build-only   Build the archive but don't upload to TestFlight"
      exit 0
      ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
IPA_DIR="$PROJECT_DIR/build/ios/ipa"
EXPORT_OPTIONS="$PROJECT_DIR/ios/ExportOptions.plist"
ENV_FILE="$PROJECT_DIR/.env"

#──────────────────────────────────────────────────────────────
# Load .env (KEYCHAIN_PASSWORD, optional API keys)
#──────────────────────────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

#──────────────────────────────────────────────────────────────
# Pre-flight checks
#──────────────────────────────────────────────────────────────
step "Unlocking keychain"
if [ -n "${KEYCHAIN_PASSWORD:-}" ]; then
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" ~/Library/Keychains/login.keychain-db
else
  security unlock-keychain ~/Library/Keychains/login.keychain-db
fi
ok "Keychain unlocked"

step "Pre-flight checks"

command -v flutter >/dev/null || fail "flutter not found in PATH"
command -v xcrun   >/dev/null || fail "xcrun not found — install Xcode"
[ -f "$EXPORT_OPTIONS" ] || fail "ios/ExportOptions.plist not found"

ok "All tools available"

#──────────────────────────────────────────────────────────────
# Auto-increment build number
#──────────────────────────────────────────────────────────────
step "Incrementing build number"

PUBSPEC="$PROJECT_DIR/pubspec.yaml"
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
BUILD_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
if [[ "$CURRENT_VERSION" == *"+"* ]]; then
  BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
else
  BUILD_NUMBER=0
fi
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="${BUILD_NAME}+${NEW_BUILD_NUMBER}"

sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
ok "Version: $BUILD_NAME (build $NEW_BUILD_NUMBER)"

#──────────────────────────────────────────────────────────────
# Build Go gRPC server → iOS xcframework
#──────────────────────────────────────────────────────────────
if [ "$SKIP_SERVER" = false ]; then
  step "Building Go gRPC server (xcframework)"
  make -C "$PROJECT_DIR" server-ios
  ok "xcframework built"
else
  warn "Skipping server build (--skip-server)"
fi

#──────────────────────────────────────────────────────────────
# Flutter build — archive only (skip flaky IPA export)
#──────────────────────────────────────────────────────────────
step "Installing Flutter dependencies"
flutter pub get
ok "Dependencies resolved"

step "Building Xcode archive"
rm -rf "$IPA_DIR"
flutter build ipa \
  --release \
  --no-tree-shake-icons \
  --obfuscate \
  --split-debug-info=./debug-info \
  --build-name="$BUILD_NAME" \
  --build-number="$NEW_BUILD_NUMBER" \
  --export-options-plist="$EXPORT_OPTIONS"

[ -d "$ARCHIVE_PATH" ] || fail "Archive not found at $ARCHIVE_PATH"
ok "Archive built: $ARCHIVE_PATH"

#──────────────────────────────────────────────────────────────
# Locate IPA (flutter build ipa already exported it)
#──────────────────────────────────────────────────────────────
step "Locating IPA"

API_KEY_ID="${APP_STORE_CONNECT_KEY_ID:-8NHAT5UHHV}"
API_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-42725b04-be15-4f93-8b52-c22bb46da07f}"

IPA_PATH=$(find "$IPA_DIR" -name "*.ipa" -type f 2>/dev/null | head -1)
[ -f "$IPA_PATH" ] || fail "IPA not found in $IPA_DIR — flutter build ipa may have failed"

ok "IPA ready: $IPA_PATH"

#──────────────────────────────────────────────────────────────
# Upload to TestFlight
#──────────────────────────────────────────────────────────────
if [ "$BUILD_ONLY" = true ]; then
  warn "Skipping upload (--build-only)"
  echo ""
  ok "IPA ready at: $IPA_PATH"
  exit 0
fi

step "Uploading to TestFlight"

xcrun altool --upload-app \
  -f "$IPA_PATH" \
  -t ios \
  --apiKey "$API_KEY_ID" \
  --apiIssuer "$API_ISSUER_ID"

ok "Upload complete!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Lumina $BUILD_NAME ($NEW_BUILD_NUMBER) → TestFlight${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  The build will appear in App Store Connect within ~15 minutes."
echo "  TestFlight testers will be notified once processing completes."
