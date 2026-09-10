#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
. "$HERE/common.sh"
app="$DEFAULT_APP"
while [ "$#" -gt 0 ]; do
 case "$1" in --app) [ "$#" -ge 2 ] || fail 'Missing --app'; app="$2"; shift 2;;
 --help|-h) info 'Usage: bash scripts/doctor.sh [--app /absolute/Copy.app]. Read-only, no uploads.'; exit 0;;
 *) fail "Unknown option: $1";; esac
done
mac_only
info 'X4 macOS Launcher diagnostic summary (read-only; no uploads)'
info "Launcher: $X4_VERSION"
info "macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
info "Chip: $(sysctl -n machdep.cpu.brand_string)"
info "CPU cores: $(sysctl -n hw.physicalcpu)"
info "Memory GiB: $(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1073741824}')"
if [ -d "$app" ]; then
 info "CrossOver: $(value "$app/Contents/Info.plist" CFBundleShortVersionString)"
 verify_app "$app"
 info "Managed library and app signature: OK; MoltenVK $MVK_VERSION privateapi"
else info 'Patched app: not installed'; exit 1; fi
info 'No FPS claim can be inferred from this check. Test a save and record frame times.'
