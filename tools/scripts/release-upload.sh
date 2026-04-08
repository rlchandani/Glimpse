#!/bin/bash
set -euo pipefail

# Glimpse Local Release Script
# Builds, signs, creates DMG, generates Sparkle appcast.
# The DMG + appcast are output to build/release/ for manual GitHub Release upload.
#
# Usage:
#   ./tools/scripts/release-upload.sh
#
# Notarization is automatic when Developer ID certificate + AC_PASSWORD are available.
# Without them, the script still works — just skips notarization (Sparkle EdDSA signing
# is what matters for updates to existing users).

VERSION=$(grep 'MARKETING_VERSION' Glimpse.xcodeproj/project.pbxproj | head -1 | sed 's/[^0-9.]//g')
SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -path "*/artifacts/sparkle/Sparkle/bin" -maxdepth 6 2>/dev/null | head -1)
if [ -z "$SPARKLE_BIN" ]; then
  echo "❌ Sparkle bin not found in DerivedData — build the project first"
  exit 1
fi
SIGN_UPDATE="$SPARKLE_BIN/sign_update"
GENERATE_APPCAST="$SPARKLE_BIN/generate_appcast"
BUILD_DIR="build/release"
DOWNLOAD_URL_PREFIX="https://github.com/rlchandani/Glimpse/releases/download/v${VERSION}"

# Resolve paths (script may be called from project root)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../resources"

# Detect capabilities
HAS_DEVELOPER_ID=false
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
  HAS_DEVELOPER_ID=true
fi

HAS_NOTARIZATION=false
if xcrun notarytool history --keychain-profile "AC_PASSWORD" &>/dev/null 2>&1; then
  HAS_NOTARIZATION=true
fi

echo "=== Glimpse Release v${VERSION} ==="
echo ""
echo "  Developer ID:  $($HAS_DEVELOPER_ID && echo '✅ Available' || echo '⚠️  Not found — skipping notarization')"
echo "  Notarization:  $($HAS_NOTARIZATION && echo '✅ Available' || echo '⚠️  Not configured — skipping notarization')"
echo ""

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if ! command -v create-dmg &>/dev/null; then
  echo "❌ create-dmg not found — install with: brew install create-dmg"
  exit 1
fi

# Export method
if $HAS_DEVELOPER_ID; then
  EXPORT_METHOD="developer-id"
else
  EXPORT_METHOD="mac-application"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Building: Glimpse"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Archive
echo "📦 Archiving..."
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release \
  -skipMacroValidation \
  archive -archivePath "$BUILD_DIR/archive.xcarchive" \
  -quiet

# Step 2: Export
echo "📤 Exporting..."
/usr/libexec/PlistBuddy -c "Add :method string ${EXPORT_METHOD}" "$BUILD_DIR/ExportOptions.plist"
/usr/libexec/PlistBuddy -c "Add :signingStyle string automatic" "$BUILD_DIR/ExportOptions.plist"

xcodebuild -exportArchive \
  -archivePath "$BUILD_DIR/archive.xcarchive" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -quiet

APP_PATH="$BUILD_DIR/export/Glimpse.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ Export failed — app not found at $APP_PATH"
  exit 1
fi
echo "✅ Export complete (method: ${EXPORT_METHOD})"

# Step 3: Notarize (if available)
if $HAS_DEVELOPER_ID && $HAS_NOTARIZATION; then
  echo "🔏 Notarizing app..."
  codesign -dvv "$APP_PATH" 2>&1 | grep -E "Authority|Runtime"
  ditto -c -k --keepParent "$APP_PATH" "$BUILD_DIR/Glimpse.zip"
  xcrun notarytool submit "$BUILD_DIR/Glimpse.zip" \
    --keychain-profile "AC_PASSWORD" \
    --wait
  echo "📌 Stapling..."
  xcrun stapler staple "$APP_PATH"
  echo "✅ Notarization complete"
else
  echo "⏭️  Skipping notarization"
fi

# Step 4: Create DMG
echo "💿 Creating DMG..."
DMG_NAME="Glimpse-${VERSION}.dmg"
rm -f "$BUILD_DIR/$DMG_NAME"

DMG_STAGING="$BUILD_DIR/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"

DMG_ARGS=(
  --volname "Glimpse"
  --window-pos 200 120
  --window-size 600 400
  --icon-size 100
  --icon "Glimpse.app" 150 190
  --app-drop-link 450 190
  --hide-extension "Glimpse.app"
  --no-internet-enable
)

# Add optional resources if they exist
if [ -f "$RESOURCES_DIR/AppIcon.icns" ]; then
  DMG_ARGS+=(--volicon "$RESOURCES_DIR/AppIcon.icns")
fi
create-dmg "${DMG_ARGS[@]}" "$BUILD_DIR/$DMG_NAME" "$DMG_STAGING"

# Set custom file icon on the DMG (if AppIcon available)
if [ -f "$RESOURCES_DIR/AppIcon.icns" ]; then
  ICON_RSRC=$(mktemp)
  sips -i "$RESOURCES_DIR/AppIcon.icns" >/dev/null 2>&1
  DeRez -only icns "$RESOURCES_DIR/AppIcon.icns" > "$ICON_RSRC" 2>/dev/null
  Rez -append "$ICON_RSRC" -o "$BUILD_DIR/$DMG_NAME" 2>/dev/null
  SetFile -a C "$BUILD_DIR/$DMG_NAME" 2>/dev/null
  rm -f "$ICON_RSRC"
fi

if $HAS_DEVELOPER_ID && $HAS_NOTARIZATION; then
  echo "🔏 Notarizing DMG..."
  xcrun notarytool submit "$BUILD_DIR/$DMG_NAME" \
    --keychain-profile "AC_PASSWORD" \
    --wait
  xcrun stapler staple "$BUILD_DIR/$DMG_NAME"
  echo "✅ DMG notarized"
fi

# Step 5: Sign for Sparkle
echo "✏️  Signing for Sparkle..."
"$SIGN_UPDATE" "$BUILD_DIR/$DMG_NAME"

# Step 6: Generate appcast
echo "📋 Generating appcast..."
mkdir -p "$BUILD_DIR/appcast_source"
cp "$BUILD_DIR/$DMG_NAME" "$BUILD_DIR/appcast_source/"

"$GENERATE_APPCAST" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX/" \
  "$BUILD_DIR/appcast_source"

cp "$BUILD_DIR/appcast_source/appcast.xml" "$BUILD_DIR/appcast.xml"
echo "✅ Appcast generated"

# ─── Summary ───
echo ""
echo "═══════════════════════════════════════"
echo "  Release v${VERSION} Complete"
echo "═══════════════════════════════════════"
echo "  DMG:     $BUILD_DIR/$DMG_NAME"
echo "  Appcast: $BUILD_DIR/appcast.xml"
if $HAS_DEVELOPER_ID && $HAS_NOTARIZATION; then
  echo "  Signed:  ✅ Developer ID + Notarized"
else
  echo "  Signed:  ⚠️  Sparkle EdDSA only (no notarization)"
fi
echo ""
echo "  Next steps:"
echo "    git tag v${VERSION} && git push --tags"
echo "    gh release create v${VERSION} $BUILD_DIR/$DMG_NAME $BUILD_DIR/appcast.xml --title v${VERSION} --generate-notes"
echo ""
