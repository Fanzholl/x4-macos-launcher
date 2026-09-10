#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
. "$HERE/common.sh"
app="$DEFAULT_APP"; bottles="$DEFAULT_BOTTLES"; bottle=''; diagnostic=0; hud=0; dry=0
usage() {
 cat <<'EOF'
Usage: bash scripts/launch.sh [options]
  --app /absolute/Copy.app
  --bottle NAME               Default: auto-detect if exactly one contains Steam + X4
  --bottles-dir /absolute/dir  Custom CrossOver bottle root
  --diagnostic                Enable X4 debug and a local Wine log
  --metal-hud                 Request Apple's Metal HUD (FPS display is not guaranteed)
  --dry-run                   Validate and show plan without starting anything
  --help
Uses existing Windows Steam and app 392160. Does not download games, change
settings, force-close processes, or upload diagnostics. Logs can contain
account paths; inspect them before sharing. Normal play has debug logging off.
EOF
}
while [ "$#" -gt 0 ]; do
 case "$1" in
 --app|--bottle|--bottles-dir)
  [ "$#" -ge 2 ] && [ -n "$2" ] || fail "Missing value for $1"
  case "$1" in --app) app="$2";; --bottle) bottle="$2";; --bottles-dir) bottles="$2";; esac; shift 2;;
 --diagnostic) diagnostic=1; shift;; --metal-hud) hud=1; shift;; --dry-run) dry=1; shift;;
 --help|-h) usage; exit 0;; *) fail "Unknown option: $1";; esac
done
mac_only
app="$(app_path "$app")"
verify_app "$app"
[ -d "$bottles" ] || fail 'CrossOver bottles folder not found. Install Windows Steam in CrossOver first.'
bottles="$(cd "$bottles" && pwd -P)"
steam_rel='drive_c/Program Files (x86)/Steam'
if [ -z "$bottle" ]; then
 candidates=()
 for candidate in "$bottles"/*; do
  [ -d "$candidate" ] || continue
  if [ -f "$candidate/$steam_rel/steam.exe" ] && [ -f "$candidate/$steam_rel/steamapps/appmanifest_392160.acf" ]; then
   candidates+=("$(basename "$candidate")")
  fi
 done
 if [ "${#candidates[@]}" -eq 1 ]; then bottle="${candidates[0]}"
 else
  info 'Specify --bottle NAME. Auto-detection needs exactly one bottle with Steam + X4 in its main library.'
  if [ "${#candidates[@]}" -gt 0 ]; then printf '  %s\n' "${candidates[@]}"; fi
  exit 1
 fi
fi
case "$bottle" in .|..|*/*|*$'\n'*|*$'\r'*) fail 'Invalid bottle name.';; esac
prefix="$bottles/$bottle"
[ -f "$prefix/cxbottle.conf" ] || fail 'Bottle configuration missing.'
grep -Eq '^"(WineArch|Template)"[[:space:]]*=[[:space:]]*"(win64|[^" ]*_64)"' "$prefix/cxbottle.conf" || fail 'X4 requires a 64-bit bottle.'
[ -f "$prefix/$steam_rel/steam.exe" ] || fail 'Windows Steam is not installed in the standard location in this bottle.'
manifest="$prefix/$steam_rel/steamapps/appmanifest_392160.acf"
if [ -f "$manifest" ]; then
 state="$(awk -F '"' '/"StateFlags"/ {print $4; exit}' "$manifest")"
 [ "$state" = 4 ] || fail 'X4 is not fully installed / Steam has a pending update. Finish it in Steam first.'
else
 info 'No main-library X4 manifest. Steam will handle the selected external library/install.'
fi
check_runtime "$app"
if ps -axo comm= | grep -F '\X4.exe' >/dev/null; then fail 'X4 is already running. Save and exit before starting another instance.'; fi
info "Runtime: $app"
info "Bottle: $bottle; Steam app: 392160; diagnostic=$diagnostic; Metal HUD=$hud"
[ "$dry" = 0 ] || { info 'Dry run: nothing started.'; exit 0; }
logdir="$HOME/Library/Logs/X4-macOS-launcher"
mkdir -p "$logdir"
# Restrict logs to the owner. Log filenames never include a Steam account ID.
umask 077
run="$(mktemp -d "$logdir/run.XXXXXX")"
args=(--bottle "$bottle" --no-update --no-wait)
game_args=(-applaunch 392160)
if [ "$diagnostic" = 1 ]; then
 args+=(--cx-log "$run/wine.log" --debugmsg '-all,err+all')
 game_args+=(-debug all -logfile "x4-launcher-$(date '+%Y%m%d-%H%M%S').log")
else
 args+=(--debugmsg '-all')
fi
if [ "$hud" = 1 ]; then
 # Existing Steam would not inherit this environment variable.
 if ps -axo comm= | grep -F '\steam.exe' >/dev/null; then fail 'Quit Windows Steam before requesting Metal HUD, then retry.'; fi
 export MTL_HUD_ENABLED=1
fi
export CX_BOTTLE_PATH="$bottles"
"$app/Contents/SharedSupport/CrossOver/bin/wine" "${args[@]}" --cx-app 'C:\Program Files (x86)\Steam\steam.exe' "${game_args[@]}" >"$run/launcher.log" 2>&1
info "Launch request sent. If Steam asks for a launch option, choose X4. Local log: $run/launcher.log"
