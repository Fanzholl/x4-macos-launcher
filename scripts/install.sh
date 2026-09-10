#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
. "$HERE/common.sh"
source_app='/Applications/CrossOver.app'; dest_app="$DEFAULT_APP"; archive=''; dry=0; allow=0
usage() {
 cat <<'EOF'
Usage: bash scripts/install.sh [options]
  --source-app /absolute/CrossOver.app   Original licensed CrossOver
  --dest-app /absolute/Copy.app          New copy (default ~/Applications/CrossOver-X4.app)
  --archive /path/MoltenVK.tar           Offline archive; pinned checksum still required
  --allow-untested                      Permit other CrossOver 26.x versions
  --dry-run                            Print plan without downloading or changing files
  --help
Installs MoltenVK 1.4.1 private-API into a COPY, removes quarantine only there,
and signs that copy ad-hoc. Never changes the source, bottles, games or saves.
Existing managed installs are verified and reused. Uninstall before upgrading.
EOF
}
while [ "$#" -gt 0 ]; do
 case "$1" in
 --source-app|--dest-app|--archive)
  [ "$#" -ge 2 ] && [ -n "$2" ] || fail "Missing value for $1"
  case "$1" in --source-app) source_app="$2";; --dest-app) dest_app="$2";; --archive) archive="$2";; esac; shift 2;;
 --allow-untested) allow=1; shift;; --dry-run) dry=1; shift;; --help|-h) usage; exit 0;;
 *) fail "Unknown option: $1";; esac
done
mac_only
for tool in curl shasum tar ditto codesign xattr plutil file sysctl; do need "$tool"; done
[ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" = 1 ] || fail 'This release targets Apple Silicon Macs.'
source_app="$(app_path "$source_app")"
[ -d "$source_app" ] || fail 'Install and activate CrossOver first.'
[ ! -e "$source_app/$MARKER_REL" ] || fail 'Choose the original CrossOver, not a patched copy.'
[ "$(value "$source_app/Contents/Info.plist" CFBundleIdentifier)" = com.codeweavers.CrossOver ] || fail 'Source is not CrossOver.'
cx_version="$(value "$source_app/Contents/Info.plist" CFBundleShortVersionString)"
case "$cx_version" in
 26.2|26.2.*) ;;
 26.*) [ "$allow" = 1 ] || fail "CrossOver $cx_version is untested. Tested: 26.2. Use --allow-untested explicitly to try another 26.x.";;
 *) fail 'Only CrossOver 26.x with the x86_64 Wine layout is supported by this release.';;
esac
[ -f "$source_app/$DYLIB_REL" ] && [ ! -L "$source_app/$DYLIB_REL" ] || fail 'Source MoltenVK library missing or linked.'
file "$source_app/$DYLIB_REL" | grep -q x86_64 || fail 'Expected x86_64 CrossOver runtime.'
# Default parent is the sole folder the installer may create before staging.
if [ ! -d "$(dirname "$dest_app")" ]; then
 [ "$dest_app" = "$DEFAULT_APP" ] || fail 'Create the custom destination parent folder first.'
 if [ "$dry" = 0 ]; then mkdir -p "$HOME/Applications"; fi
fi
if [ "$dry" = 1 ] && [ ! -d "$(dirname "$dest_app")" ]; then
 info "Would create $HOME/Applications"
else
 dest_app="$(app_path "$dest_app")"
fi
[ "$source_app" != "$dest_app" ] || fail 'Source and destination must differ.'
case "$dest_app/" in "$source_app/"*) fail 'Destination must be outside the source app.';; esac
case "$source_app/" in "$dest_app/"*) fail 'Source must be outside the destination app.';; esac
info "CrossOver $cx_version -> $dest_app"
info "MoltenVK $MVK_VERSION privateapi; SHA-256 $MVK_SHA256"
if [ -e "$dest_app" ] || [ -L "$dest_app" ]; then
 verify_app "$dest_app"
 info 'Existing managed installation verified. No files changed.'; exit 0
fi
if [ "$dry" = 1 ]; then info 'Dry run: no download or app changes.'; exit 0; fi
# Serialize installers for this destination; never take over a stale lock.
lock="${dest_app}.install-lock"
mkdir "$lock" 2>/dev/null || fail "Install lock exists: $lock (check for another installer)."
stage=''
cleanup() {
 if [ -n "$stage" ] && [ -d "$stage" ]; then rm -rf "$stage"; fi
 rmdir "$lock" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
stage="$(mktemp -d "$(dirname "$dest_app")/.x4-install.XXXXXX")"
if [ -z "$archive" ]; then
 archive="$stage/MoltenVK.tar"
 curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fL --retry 2 --connect-timeout 20 --max-time 300 "$MVK_URL" -o "$archive"
fi
[ -f "$archive" ] || fail 'Archive not found.'
[ "$(sha256 "$archive")" = "$MVK_SHA256" ] || fail 'Archive checksum mismatch. Nothing installed.'
info 'Official archive checksum verified.'
member='MoltenVK/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib'
tar -xf "$archive" -C "$stage" "$member"
replacement="$stage/$member"
[ -f "$replacement" ] && [ ! -L "$replacement" ] || fail 'Invalid archive library.'
file "$replacement" | grep -q x86_64
file "$replacement" | grep -q arm64 || fail 'Expected universal MoltenVK library.'
source_hash="$(sha256 "$source_app/$DYLIB_REL")"
bundle="$stage/$(basename "$dest_app")"
ditto "$source_app" "$bundle"
cp "$replacement" "$bundle/$DYLIB_REL"
chmod 0755 "$bundle/$DYLIB_REL"
codesign --force --sign - "$bundle/$DYLIB_REL"
marker="$bundle/$MARKER_REL"
plutil -create xml1 "$marker"
plutil -insert schema -integer 1 "$marker"
plutil -insert project -string "$X4_PROJECT" "$marker"
plutil -insert launcherVersion -string "$X4_VERSION" "$marker"
plutil -insert moltenvkVersion -string "$MVK_VERSION" "$marker"
plutil -insert archiveSHA256 -string "$MVK_SHA256" "$marker"
plutil -insert dylibSHA256 -string "$(sha256 "$bundle/$DYLIB_REL")" "$marker"
plutil -insert crossoverVersion -string "$cx_version" "$marker"
plutil -insert installedAt -string "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$marker"
# xattr is scoped to the copy, including symlinks themselves. Do not follow targets.
xattr -r -s -d com.apple.quarantine "$bundle" 2>/dev/null || true
# Finder metadata on copied bundles can invalidate strict signing.
xattr -r -s -d com.apple.FinderInfo "$bundle" 2>/dev/null || true
xattr -r -s -d com.apple.ResourceFork "$bundle" 2>/dev/null || true
codesign --force --deep --preserve-metadata=entitlements --sign - "$bundle"
verify_app "$bundle"
[ "$(sha256 "$source_app/$DYLIB_REL")" = "$source_hash" ] || fail 'Source changed during installation; aborting.'
[ ! -e "$dest_app" ] && [ ! -L "$dest_app" ] || fail 'Destination appeared during installation; refusing overwrite.'
mv "$bundle" "$dest_app"
info "Installed: $dest_app"
info 'Quit Windows Steam/other bottle programs from the original CrossOver, then run Play.command.'
