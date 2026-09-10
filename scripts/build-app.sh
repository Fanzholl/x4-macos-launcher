#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
output="${1:-$root/dist}"
mkdir -p "$output"
output="$(cd "$output" && pwd -P)"
[ ! -e "$output/X4.Launcher.zip" ] || { echo 'Output ZIP already exists; choose an empty output directory.' >&2; exit 1; }
stage="$(mktemp -d "${TMPDIR:-/tmp}/x4-app-build.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
app="$stage/X4 Launcher.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
xcrun swiftc -O -target arm64-apple-macos11.0 "$root/native/Launcher.swift" -o "$app/Contents/MacOS/launcher"
cp -R "$root/scripts" "$app/Contents/Resources/scripts"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>io.github.fanzholl.x4launcher</string>
<key>CFBundleName</key><string>X4 Launcher</string>
<key>CFBundleExecutable</key><string>launcher</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
for attr in com.apple.quarantine com.apple.FinderInfo com.apple.ResourceFork; do xattr -r -s -d "$attr" "$app" 2>/dev/null || true; done
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
"$app/Contents/MacOS/launcher" --self-test
ditto -c -k --sequesterRsrc --keepParent "$app" "$output/X4.Launcher.zip"
shasum -a 256 "$output/X4.Launcher.zip" | sed "s|$output/||" > "$output/SHA256SUMS.txt"
echo "Built $output/X4.Launcher.zip"
