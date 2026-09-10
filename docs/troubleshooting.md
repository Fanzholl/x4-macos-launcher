# Troubleshooting

## No compatible Vulkan device

Run `bash scripts/doctor.sh`. Confirm the game was launched with **Play.command** or `scripts/launch.sh`, using the patched copy. Quit old Windows Steam and bottle processes before switching runtimes; an existing Steam process can receive the launch request and use its old runtime. Do not run both simultaneously. This patch exposes `logicOp`; an identical error can also indicate a different missing capability in a new X4 version.

## Steam starts but X4 waits

Bring Steam and any X4 dialog to the front. Read any launch-option, first-run or login prompt. A running X4 process is not proof that a rendered scene appeared. If there is an error, record its exact text. After exiting X4, retry `bash scripts/launch.sh --bottle Steam --diagnostic`. The last line of a startup log does not necessarily identify what is blocking the game.

## “Damaged” app / signature error

Use the original, unmodified CrossOver as the install source. Our installer signs the modified copy and verifies its signature. Do not disable Gatekeeper system-wide. If a managed copy was changed or updated, quit its programs, move it to Trash with `scripts/uninstall.sh` and reinstall. Save any installation error text before retrying. A pre-existing unmarked manual copy must be moved aside by its owner or use a different destination.

## Steam's FPS overlay is black

Observed on the test machine. It does not provide a usable benchmark. Optionally quit Windows Steam and request `--metal-hud`; do not assume it works or equate estimated smoothness with measured FPS. For repeatable evidence use a verified frame-time capture and the [performance procedure](performance.md).

## Low frame rate in a developed save

Test the same unpaused scene and view at two resolutions, keeping simulation speed fixed. If reducing pixel count helps substantially, lower resolution, shadows, SSAO or fog. If it barely helps and the bottleneck is simulation, resolution alone cannot resolve it. Measure early-save flight, late-save flight, station interior, fleet combat and map separately. Map rendering does not establish cockpit/combat performance. [Egosoft's performance guidance](https://forum.egosoft.com/) is the source to consult when diagnosing game-side simulation issues.

## Logs

`--diagnostic` writes under `~/Library/Logs/X4-macOS-launcher/` and requests an X4 log named `x4-launcher-YYYYMMDD-HHMMSS.log` in the game's Documents/Egosoft/X4 account directory. Wine diagnostics may include account paths and user information. Review and redact before attaching anything to a public issue. This project never uploads logs automatically. Return to normal launch after diagnostics.

## Removal

The uninstaller moves only an app carrying this project's marker to Trash. It refuses the original `/Applications/CrossOver.app`, symlink app paths and active copied runtimes. Bottles and saves remain shared and are not removed. Restore the copy from Trash if needed, or use the original app for other games.
