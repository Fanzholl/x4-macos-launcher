# Performance and settings

## What was observed

Test date: 10 September 2026. Hardware: 16 inch MacBook Pro, Apple M4 Max with 16 CPU cores and 40 GPU cores, 48 GB unified memory. macOS 26.3.1 (a), CrossOver 26.2, MoltenVK 1.4.1 privateapi, Steam app 392160 build 23660954. Existing 64 bit Steam bottle, MSync enabled, graphics backend Auto. Exact DLC/mod list and an instrumented frame time capture were not recorded.

The maintainer reports stable play, no visible artifacts and no major freezes in two scenarios. A very developed save with megastations, thousands of player and faction ships, and large fleets felt like roughly 45 to 60 FPS. An early save with far fewer entities felt like 100 FPS or more. The Steam overlay was black, so **neither range is measured FPS**. The first supplied scenes show the map; a later screenshot also confirms an external flight view. Do not generalize them to every cockpit view, fleet battle or station interior. Ship counts and comparison to a powerful desktop PC are player reports, not controlled measurements.

The settings menu and local configuration both show **1740×1129**. The Mac panel is **3456×2234**. Retina scaling and screenshot pixel dimensions do not establish the game's actual framebuffer size. The evidence does not support a claim of 45 to 60 FPS at full panel resolution. CrossOver explains its high resolution mode in the [user guide](https://support.codeweavers.com/en_US/crossover-mac-user-guide).

The configuration also contains `gamespeed=0.5`. Whether Reduced Speed Mode was active during the reported play has not been established; the stored value alone does not prove it was enabled. Record the actual simulation speed in future tests. This is another reason not to present these impressions as a controlled benchmark. Egosoft introduced [Reduced Speed Mode as an accessibility option](https://wiki.egosoft.com/X4%20Foundations%20Wiki/Game%20Updates%20and%20Patch%20History/X4%20Foundations%207.xx%20Changelogs/).

Activity Monitor snapshots show X4 at about 11.91 GB memory, total system memory use about 39.99 GB, green memory pressure and no swap on a 48 GB machine. These are snapshots, not peak requirements. Total CPU idle percentage does not rule out a busy simulation thread; the separate CPU snapshots were taken at different moments.

## Reproduce the tested graphics profile

| Setting | Value |
|---|---|
| Display | Fullscreen, 1740×1129 |
| Anti aliasing | TAA |
| FSR / frame generation | Off / off |
| VSync / frame cap | Off / 120 |
| Field of view | 90° |
| Preset / textures / shadows | High / High / High |
| Soft shadows | On |
| SSAO | Medium |
| Glow / interface glow | High / High, intensity 75 |
| Chromatic aberration / distortion | On / On |
| Parallax occlusion | High |
| Level of detail / effect distance | 70 / 70 |
| Radar | High |
| Screen space reflections | Low |
| Reflection probes | High |
| Volumetric fog | Medium |
| Cockpit glass reflections | 100 |
| HQ video capture | Off |
| Character / traffic density, from config | 0.50 / 0.50 |

![Display settings](../assets/screenshots/display-settings.png)
![Graphics settings](../assets/screenshots/graphics-settings.png)

Use the settings menu. No script overwrites `config.xml`, input, sound, saves or gameplay preferences.

## Provisional hardware and resolution guidance

These are starting profiles to test, not measured minimums or purchasing guarantees. The only hardware tested by this project is M4 Max / 48 GB. The [original forum report](https://www.codeweavers.com/support/forums/general/?t=27;msg=346291#c6) also reports launch on M4 Pro without an FPS benchmark.

| Intended use | Starting hardware | Resolution and settings | Evidence |
|---|---|---|---|
| Conservative entry test | Actively cooled M4 Pro, 24 GB | 1920×1080 or a similar 16:10 resolution, Medium, TAA, FSR off initially, shadows Medium, SSAO Low, fog Low, LOD 50 | Proposed starting point; not measured |
| Match the report | M4 Max 16 CPU / 40 GPU, 48 GB | 1740×1129, profile above | Stable play reported; FPS subjective |
| Larger saves and fleets | Strong CPU plus 36 to 48 GB or more | Start near 1080p with Medium settings; test the actual save | Memory headroom advice; no universal FPS threshold |
| Sharper image | M4 Max class, 48 GB | Try 2560×1440 or 2560×1600, Medium/High; reduce shadows, SSAO and fog first | Untested at these resolutions |
| Full Retina / 4K | No verified minimum | Test separately, begin with Medium, consider FSR Quality if available | No supported FPS claim |
| Older/base M chips or 8 GB | No verified minimum | Experimental; no comfortable performance claim | Not tested |

Allow room for the installed game and DLC, the original CrossOver, about 1 GB for its copied app and temporary download/copy space. Prefer at least **5 GB free beyond the already installed game** for this installation, plus normal macOS memory/swap headroom. The game installation on this machine occupies about 32 GB, but another DLC set may differ. Game requirements are listed by [Egosoft on Steam](https://store.steampowered.com/app/392160/X4_Foundations/); Windows GPU minimums are not equivalent Mac requirements.

## Establish a comfortable profile

For this project, test for a sustained 30 FPS floor or a 60 FPS target in the scenes you actually play, with acceptable frame time spikes. These are targets, not claims about a particular chip. Use AC power, record the macOS power mode, give the machine 10 minutes to warm up and close unnecessary heavy applications.

Use the same save, unpaused scene, camera route and simulation speed. Disable SETA and record Reduced Speed Mode. Test three 60 second passes after loading has settled. Separate early save flight, late save flight, a station interior, fleet combat and the map. Record resolution, Retina mode, AA, FSR, frame generation, frame cap, DLC/mods and software builds. Avoid verbose logs during performance captures.

Use a verified FPS or frame time source. The optional Metal HUD request in the launcher is experimental until its overlay is visibly working. Do not derive FPS from CPU/GPU utilization, subjective smoothness or a black Steam counter. Record average FPS and 99th percentile frame time from a capture when possible; document how any reported 1% low is calculated. If no working tool is available, report responsiveness and stutter qualitatively.

To distinguish graphics load from simulation, compare the same unpaused scene at two resolutions. If lowering resolution helps greatly, tune resolution, shadows, SSAO, reflections and fog. If it barely helps, additional simulation work may be the limit. This is a diagnostic inference, not proof from total utilization alone. Large universes can become demanding on a desktop PC too; this launcher does not change the game's simulation engine.
