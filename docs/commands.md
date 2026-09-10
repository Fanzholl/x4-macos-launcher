# Technical commands

Desktop app: download the release ZIP, extract and open X4 Launcher. The app bundles these scripts; it does not need Python, Git, Homebrew or Xcode on the player's Mac.

Source checkout alternative:

```bash
bash scripts/play.sh --bottle Steam
```

This installs the graphics fix, requests graceful Windows Steam shutdown when safe and launches X4. It never force kills a game or a bottle. If other programs are active, save and close them first. If X4 is already running, it leaves it running.

```bash
bash scripts/install.sh --dry-run
bash scripts/install.sh --source-app /Applications/CrossOver.app --dest-app "$HOME/Applications/CrossOver-X4-Test.app"
bash scripts/install.sh --archive /path/MoltenVK-macos-privateapi.tar
bash scripts/install.sh --allow-untested
bash scripts/launch.sh --app "$HOME/Applications/CrossOver-X4-Test.app" --bottle Steam
bash scripts/launch.sh --bottles-dir /Volumes/Games/Bottles --bottle Games
bash scripts/launch.sh --bottle Steam --diagnostic
bash scripts/launch.sh --bottle Steam --metal-hud
bash scripts/doctor.sh
bash scripts/uninstall.sh
```

The default is `~/Applications/CrossOver-X4.app`. If an unmarked manual copy already occupies it, the default becomes `~/Applications/CrossOver-X4-Managed.app`. Managed copies are reused after verification; upgrades require uninstalling the managed copy first. Uninstall moves it to Trash and never removes games/saves. Other CrossOver 26.x releases require `--allow-untested`; the desktop app defaults to the tested 26.2. CrossOver 27 and ARM64 Preview are outside this release's scope.

The desktop app offers bottles with Windows Steam at the standard location. External game libraries are resolved by Steam. For custom bottle roots, use the command options above. Install the patched app into a local Applications folder, not an iCloud/File Provider folder whose Finder metadata may invalidate signatures.

For development, build the app with Xcode Command Line Tools: `bash scripts/build-app.sh`. Run tests with `python3 -m unittest discover -s tests -v`. All tests use isolated fixtures and never start a game. The build is ad-hoc signed and not notarized. Users may need macOS's per-app Open Anyway approval. Do not market the build as a signed/notarized distribution.
