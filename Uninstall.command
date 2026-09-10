#!/bin/bash
cd "$(dirname "$0")" || exit 1
bash "scripts/uninstall.sh" "$@"
status=$?
printf '\nPress Return to close. / Нажмите Enter, чтобы закрыть.\n'
read -r _
exit "$status"
