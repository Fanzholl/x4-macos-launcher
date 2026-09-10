#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
. "$HERE/common.sh"
app="$DEFAULT_APP"; dry=0
while [ "$#" -gt 0 ]; do
 case "$1" in
 --app) [ "$#" -ge 2 ] || fail 'Missing --app value'; app="$2"; shift 2;;
 --dry-run) dry=1; shift;;
 --help|-h) info 'Usage: bash scripts/uninstall.sh [--app /absolute/Copy.app] [--dry-run]'; exit 0;;
 *) fail "Unknown option: $1";; esac
done
mac_only
app="$(app_path "$app")"
[ "$app" != '/Applications/CrossOver.app' ] || fail 'Refusing to remove the original app.'
marker="$app/$MARKER_REL"
[ -f "$marker" ] && [ ! -L "$marker" ] || fail 'Unrecognized app: refusing removal.'
[ "$(value "$marker" project)" = "$X4_PROJECT" ] && [ "$(value "$marker" schema)" = 1 ] || fail 'Unrecognized install marker.'
# A changed library must still be uninstallable; marker identifies our installation.
processes="$(ps -axo comm=)"
if printf '%s\n' "$processes" | grep -F "$app/" >/dev/null; then
 fail 'Patched CrossOver is running. Save and close its games and Windows Steam first.'
fi
[ "$dry" = 0 ] || { info "Would move to Trash: $app"; exit 0; }
mkdir -p "$HOME/.Trash"
trash_parent="$(mktemp -d "$HOME/.Trash/X4-launcher.XXXXXX")"
mv "$app" "$trash_parent/"
info "Moved patched app to $trash_parent"
info 'Original CrossOver, Steam bottle, games and saves remain in place.'
