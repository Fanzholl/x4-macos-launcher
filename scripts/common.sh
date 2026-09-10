#!/bin/bash
# Shared helpers; Bash 3.2, standard macOS tools only.
set -euo pipefail
X4_PROJECT='x4-macos-launcher'
X4_VERSION='0.1.0'
MVK_VERSION='1.4.1'
MVK_SHA256='5e662d77f7f280d9bd692ac5d626831198f404e28b0c8d4d11aac04bff8ff418'
MVK_URL='https://github.com/KhronosGroup/MoltenVK/releases/download/v1.4.1/MoltenVK-macos-privateapi.tar'
DYLIB_REL='Contents/SharedSupport/CrossOver/lib64/libMoltenVK.dylib'
MARKER_REL='Contents/Resources/x4-macos-launcher.plist'
DEFAULT_APP="$HOME/Applications/CrossOver-X4.app"
# Preserve an earlier hand-patched copy by choosing a separate managed name.
if [ -d "$DEFAULT_APP" ] && [ ! -f "$DEFAULT_APP/$MARKER_REL" ]; then
 DEFAULT_APP="$HOME/Applications/CrossOver-X4-Managed.app"
fi
DEFAULT_BOTTLES="$HOME/Library/Application Support/CrossOver/Bottles"
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing tool: $1"; }
value() { plutil -extract "$2" raw -o - "$1" 2>/dev/null; }
sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
mac_only() {
 [ "$(uname -s)" = Darwin ] || fail 'This launcher requires macOS.'
}
# Resolve parent symlinks without following the app itself. Reject dangerous names.
app_path() {
 local p="$1" parent leaf
 case "$p" in /*) ;; *) fail 'App paths must be absolute.' ;; esac
 case "$p" in *$'\n'*|*$'\r'*|*/../*|*/./*|*/..|*/.) fail 'Invalid app path.' ;; esac
 [ ! -L "$p" ] || fail 'App path must not be a symlink.'
 parent="$(dirname "$p")"; leaf="$(basename "$p")"
 case "$leaf" in *.app) ;; *) fail 'Destination must end in .app.' ;; esac
 [ -d "$parent" ] || fail "Parent folder does not exist: $parent"
 printf '%s/%s\n' "$(cd "$parent" && pwd -P)" "$leaf"
}
verify_app() {
 local app="$1" marker="$1/$MARKER_REL" expected
 [ -d "$app" ] && [ ! -L "$app" ] || fail 'Patched app missing. Run Setup.command first.'
 [ -f "$marker" ] && [ ! -L "$marker" ] || fail 'App is not managed by this launcher.'
 [ "$(value "$marker" project)" = "$X4_PROJECT" ] || fail 'Unrecognized app marker.'
 [ "$(value "$marker" schema)" = 1 ] || fail 'Unsupported app marker version.'
 [ "$(value "$marker" moltenvkVersion)" = "$MVK_VERSION" ] || fail 'MoltenVK version differs; reinstall.'
 [ "$(value "$marker" archiveSHA256)" = "$MVK_SHA256" ] || fail 'Unexpected MoltenVK archive.'
 expected="$(value "$marker" dylibSHA256)"
 [ -f "$app/$DYLIB_REL" ] && [ ! -L "$app/$DYLIB_REL" ] || fail 'Patched library is missing or linked.'
 [ "$(sha256 "$app/$DYLIB_REL")" = "$expected" ] || fail 'Patched library changed; reinstall.'
 codesign --verify --deep --strict "$app" || fail 'App signature check failed; reinstall.'
}
# Refuse mixed CrossOver runtimes instead of killing a user's games or Steam.
check_runtime() {
 local app="$1" paths p
 paths="$(ps -axo comm= | awk '/\/Contents\/SharedSupport\/CrossOver\/.*(wineserver|winewrapper|wineloader)/ {print}')"
 while IFS= read -r p; do
  [ -n "$p" ] || continue
  case "$p" in "$app/"*) ;; *) fail 'Another CrossOver runtime is active. Save your games, quit Windows Steam and close that bottle, then retry.' ;; esac
 done <<< "$paths"
}
