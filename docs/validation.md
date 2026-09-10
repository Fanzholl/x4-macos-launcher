# Validation record

10 September 2026, release 0.1.1.

## Completed

1. I downloaded the official MoltenVK 1.4.1 privateapi archive and verified that its SHA256 matched both the release metadata and the installer's pin.
2. I checked the graphics capability with a native feature probe running as x86_64 on my M4 Max. It reported `logicOp=0` with the original CrossOver library and `logicOp=1` with the replacement.
3. I launched X4 through the copied CrossOver runtime and played early and heavily developed saves. Gameplay was stable, with no visible artifacts or major freezes. My screenshots also include an external flight view. I have not measured FPS with an instrumented capture.
4. I tested the packaged installer against my CrossOver 26.2 installation using a separate validation destination. I checked the installed library hash, managed marker and strict bundle signature. The original library hash remained unchanged.
5. I tested the automatic entry script: it installed a managed copy and launched Steam with the X4 launch request. The script allows up to 45 seconds for Steam to shut down gracefully and never uses a force kill.
6. I ran sixteen isolated workflow tests on macOS; all passed. They cover checksum rejection, signing failure cleanup, original preservation, duplicate installs, symlink/path rejection, unknown destinations, version gating, active game preservation, bottle ambiguity, incomplete downloads, 32 bit bottles and runtime conflicts. Regression tests also cover the automatic entry with no options under Bash 3.2 and graceful Steam shutdown when requesting Metal HUD on an already running managed runtime.
7. I built the Swift desktop application for Apple Silicon and verified its resource self test and strict code signature. The ZIP contains the app and bundled scripts, without game or vendor binaries.

## Limits

I have not yet verified the desktop application's visual layout through automated screen capture or tested a fresh download and first Gatekeeper approval on a clean account. The build is locally signed and not notarized. I cannot promise that macOS will approve it automatically.

I verified installation in the local Applications folder. In a separate test in a Documents folder managed by a File Provider, signature verification failed because Finder metadata was restored on the bundle. The failed install cleaned its staging folder and did not publish a destination. Application builds use the macOS temporary directory, and installation defaults to the local Applications folder.

I have only tested gameplay on the M4 Max configuration described in this project. Different Macs, operating systems, CrossOver versions and X4 builds need separate testing. I have not verified that the optional Metal HUD displays valid FPS on my setup.

I have not included game saves or private diagnostic logs in the repository.

![External flight view from my game](../assets/screenshots/flight.png)
