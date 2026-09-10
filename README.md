# X4 Launcher for macOS

Play X4: Foundations on Apple Silicon using your existing CrossOver installation. The launcher downloads the graphics fix, verifies it, prepares a separate CrossOver copy and starts the game.

[Русский](README.ru.md) · [Settings and results](docs/performance.md) · [Support the project](SUPPORT.md)

## Start playing

You need CrossOver 26.2, Windows Steam in a 64 bit bottle, and a purchased, fully installed copy of X4.

1. Download **X4.Launcher.zip** from [Releases](https://github.com/Fanzholl/x4-macos-launcher/releases).
2. Extract the archive and open **X4 Launcher**.
3. Check the selected Steam bottle and click **Install and launch**.

The app handles the graphics patch and sends the launch request to Steam. You do not need to download X4 again. Later launches verify and reuse the patched copy.

The app currently has no Apple Developer ID signature or notarization. macOS may require an initial approval in **System Settings → Privacy & Security → Open Anyway**. Do not disable system security globally.

Save other games before switching runtimes. Windows Steam may close and reopen. If other bottle applications are active, the launcher asks you to close them. It does not terminate a running X4 session.

The original CrossOver remains in place. Both copies share your existing Steam bottle, games and saves. Graphics settings are left for you to choose.

## Tested result

I tested the game on my MacBook Pro with M4 Max, 16 CPU cores, 40 GPU cores and 48 GB memory, using macOS 26.3.1 (a), CrossOver 26.2 and MoltenVK 1.4.1 private API.

The game runs stably for me, with no visible artifacts or major freezes. My heavily developed save with megastations and thousands of ships feels like roughly **45 to 60 FPS**. An early save feels like **100 FPS or more** at the same settings. These are my subjective estimates: the Steam counter in CrossOver shows a black field, so I do not yet have an exact measurement.

I selected **1740×1129** in the game. My MacBook's physical display is **3456×2234**. I have not measured performance at the full panel resolution.

A conservative starting point for testing is an actively cooled M4 Pro with 24 GB memory, around 1080p and Medium settings. This is provisional advice. There is no verified minimum Mac or guaranteed 60 FPS configuration. Large saves benefit from additional memory headroom. See [settings and methodology](docs/performance.md).

## How it works

X4 runs through Wine and Rosetta. MoltenVK translates Vulkan graphics to Metal. This is a compatibility solution, not a native game port.

The patch supplies the missing Vulkan `logicOp` feature. It downloads MoltenVK from the official KhronosGroup release, checks SHA256 and signs the modified CrossOver copy locally. The repository does not include X4, CrossOver or their licenses.

[Technical commands](docs/commands.md) · [Troubleshooting](docs/troubleshooting.md) · [Validation](docs/validation.md)

## Support

If you would like to support my work, you can donate through [Boosty](https://boosty.to/fanzholl) or the MIR card on my [support page](SUPPORT.md). The launcher is free. Donations help me keep testing and developing it.

Thanks to [MoltenVK](https://github.com/KhronosGroup/MoltenVK), the [CodeWeavers forum contributors](https://www.codeweavers.com/support/forums/general/?t=27;msg=346291#c6) and [icetear](https://github.com/icetear/x4-crossover-moltenvk-fix) for the underlying workaround. This project is independent of Egosoft, CodeWeavers and Valve. [MIT](LICENSE) covers our code.
