#!/bin/bash
# One entry point for the desktop app: install if needed, then launch.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd -P)"
. "$HERE/common.sh"
source_app='/Applications/CrossOver.app'; bottle=''; hud=0; diagnostic=0
while [ "$#" -gt 0 ]; do
 case "$1" in
 --source-app|--bottle) [ "$#" -ge 2 ] || fail "Missing $1 value"; case "$1" in --source-app) source_app="$2";; --bottle) bottle="$2";; esac; shift 2;;
 --metal-hud) hud=1; shift;; --diagnostic) diagnostic=1; shift;;
 --help|-h) info 'Usage: bash scripts/play.sh [--source-app /Applications/CrossOver.app] [--bottle Steam] [--metal-hud] [--diagnostic]'; exit 0;;
 *) fail "Unknown option: $1";; esac
done
# Do not terminate a running game or install a second runtime underneath it.
if ps -axo comm= | grep -F '\X4.exe' >/dev/null; then
 info 'X4 is already running. / X4 уже запущена.'; exit 0
fi
bash "$HERE/install.sh" --source-app "$source_app"
# Stop Windows Steam gracefully only if the selected bottle is explicit, and
# there are no non-Steam user executables. Never force-kill Wine.
old_paths="$(ps -axo comm= | awk '/\/Contents\/SharedSupport\/CrossOver\/.*wineserver/ {print}')"
if [ -n "$bottle" ] && [ -n "$old_paths" ]; then
 unknown="$(ps -axo comm= | awk '/^[A-Z]:.*\\.*\.exe$/ && !/\\(steam|steamwebhelper|steamservice|services|explorer|rpcss|plugplay|svchost|winedevice|winemenubuilder|conhost)\.exe$/ {print}')"
 if [ -z "$unknown" ]; then
  while IFS= read -r p; do
   [ -n "$p" ] || continue
   case "$p" in "$DEFAULT_APP/"*) [ "$hud" = 1 ] || continue;; esac
   old_app="${p%%/Contents/*}"
   case "$old_app" in /*.app) ;; *) continue;; esac
   [ -x "$old_app/Contents/SharedSupport/CrossOver/bin/wine" ] || continue
   info 'Closing Windows Steam to switch runtime. / Закрываем Windows Steam для смены графической библиотеки.'
   "$old_app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$bottle" --no-update --no-wait --cx-app 'C:\Program Files (x86)\Steam\steam.exe' -shutdown || true
  done <<< "$old_paths"
  for ((i=0;i<45;i++)); do
   current="$(ps -axo comm= | awk '/\/Contents\/SharedSupport\/CrossOver\/.*wineserver/ {print}')"
   if [ "$hud" = 0 ]; then current="$(printf '%s\n' "$current" | grep -v -F "$DEFAULT_APP/" || true)"; fi
   [ -z "$current" ] && break
   sleep 1
  done
 fi
fi
args=()
[ -z "$bottle" ] || args+=(--bottle "$bottle")
[ "$hud" = 0 ] || args+=(--metal-hud)
[ "$diagnostic" = 0 ] || args+=(--diagnostic)
# macOS Bash 3.2 treats an empty array as unset under nounset.
if [ "${#args[@]}" -gt 0 ]; then
 bash "$HERE/launch.sh" "${args[@]}"
else
 bash "$HERE/launch.sh"
fi
