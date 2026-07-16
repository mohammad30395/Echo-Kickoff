# Phase 15 Release Candidate Report

Result: PASS

Date: 2026-07-15

## Scope

This phase performed balancing, optimisation, Web compatibility checks, and release-candidate export work only. No new gameplay feature was added.

All audit files through Phase 14 were read before changes, and the complete playable game was inspected through automated gameplay routes plus live Web browser smoke tests.

## Balancing values

| Area | Release-candidate value | Rationale |
|---|---:|---|
| Pulse cooldown | 1.45 s | Reduces pulse spam while keeping the dark facility readable. |
| Pulse radius | 345 px | Slightly improves room readability and reduces blind backtracking. |
| Pulse loudness | 500 px | Keeps pulse clearly dangerous and above decoy priority. |
| Footstep spacing | 104 px travelled | Reduces excessive frequent footstep events on long routes. |
| Footstep loudness | 58 px | Keeps footsteps quiet and local. |
| Decoy loudness | 410 px | Still lower than pulse, but strong enough to create a reliable alternative solution. |
| Decoy count | 2 per run | Preserves limited tactical use and route planning. |
| Relay activation loudness | 620 px | Keeps objective actions the loudest normal gameplay event. |
| Primary Listener speed | patrol 74, investigate 112, chase 152 px/s | Creates relay pressure without invalidating the tested safe withdrawal route. |
| Primary Listener hearing | 1.00× | Keeps first relay risk predictable after pulse/relay noise. |
| Primary Listener search duration | 3.1 s | Tense but less sticky after a successful diversion. |
| South Listener speed | patrol 72, investigate 108, chase 148 px/s | Slightly softer extraction-sector pressure. |
| South Listener hearing | 1.05× | Keeps late-route decoys useful without making footsteps dominant. |
| South Listener search duration | 3.2 s | Maintains late-game pressure while preserving extraction return route. |
| Level completion time | 842.4 s modeled first-time route | Phase 11 full route: 24,594 px; within the 12–20 minute target. |

Noise hierarchy now validates as:

```text
footstep 58 < decoy 410 < echo pulse 500 < reactor relay 620
```

## Optimisation work completed

- Cached `EventBus` references in player pulse/decoy paths instead of repeated autoload lookups.
- Cached `AccessibilityManager` references in pulse/decoy visual draw paths.
- Reused `PhysicsRayQueryParameters2D` for Listener sight/route rays.
- Reused `PhysicsRayQueryParameters2D` for decoy aim wall checks.
- Decoy aim raycasts now refresh only when player/mouse position changes meaningfully.
- Decoy aim drawing no longer allocates a trajectory array every draw.
- Echo pulse ring arcs reduced from 96 to 64 segments.
- Active echo effects limited through a local pulse count.
- Debug/test scenes and scripts are excluded from release export packaging.
- Legacy `Sector_00_Test` vertical-slice scene/script are excluded from release export packaging.

## Release-candidate build

Release-candidate artifacts were created under:

- `build/release-candidate/web/`
- `build/release-candidate/windows/`

Export commands:

```bash
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/echo-kickoff.exe
```

Export preset checks:

- Compatibility renderer retained.
- Web `variant/thread_support=false`.
- Web `variant/extensions_support=false`.
- Debug/test scenes excluded from packaged resources.
- `strings build/web/index.pck` found no `scenes/debug`, `scripts/debug`, `sector_00_test`, `sector_00_visual`, or `tests/` paths.

Artifact sizes:

| Artifact | Size |
|---|---:|
| `build/web/index.html` | 8 KB |
| `build/web/index.js` | 276 KB |
| `build/web/index.pck` | 492 KB |
| `build/web/index.wasm` | 38 MB |
| `build/windows/echo-kickoff.exe` | 104 MB |
| `build/windows/echo-kickoff.pck` | 492 KB |

Export performance:

| Export | Real time | Peak memory footprint | Result |
|---|---:|---:|---|
| Web | 2.84 s | 824 MB | PASS |
| Windows Desktop | 2.83 s | 892 MB | PASS |

## Gameplay/performance measurements

Automated route/performance evidence:

| Measurement | Result |
|---|---:|
| Final facility collision count | 94 |
| Final facility revealable count | 120 |
| Room/decision-space count | 37 |
| Safe observation pockets | 14 |
| Final route distance | 24,594 px |
| Modeled first-time completion | 842.4 s |
| Vertical-slice regression route distance | 28,211 px |
| Vertical-slice modeled completion | 917.7 s |
| Full Phase 01–15 suite | PASS |

No particle systems were added. Echo/decoy effects are procedural CanvasItem drawing only.

## Browser tests

Test server:

```bash
python3 -m http.server 8768 --directory build/web
```

### Chromium

Browser: Google Chrome headless with WebGL2/Compatibility path.

Validated:

- Web export load at 1280×720.
- Canvas focus after load.
- Start click required for audio.
- Gameplay HUD after Start.
- Pulse input and echo audio cue.
- Pause/resume.
- Pause → Main Menu.
- Keyboard Start from main menu.
- 1024×768 resize.
- 1920×1080 fullscreen-equivalent viewport.
- Console inspected through DevTools Protocol.

Observed console:

```text
Godot Engine v4.7.stable.official.5b4e0cb0f
OpenGL API OpenGL ES 3.0 (WebGL 2.0 (OpenGL ES 3.0 Chromium)) - Compatibility
Build configuration: Emscripten 4.0.20, single-threaded, no GDExtension support.
ECHO_KICKOFF_BOOT_OK | renderer=gl_compatibility | viewport=1280x720 | platform=Web
ECHO_KICKOFF_AUDIO_USER_GESTURE_OK
ECHO_KICKOFF_AUDIO_CUE_OK industrial_ambience
ECHO_KICKOFF_AUDIO_AMBIENCE_OK
ECHO_KICKOFF_AUDIO_CUE_OK echo_pulse
```

Canvas metrics:

```json
{"1280x720":{"w":1280,"h":720},"1024x768":{"w":1024,"h":768},"1920x1080":{"w":1920,"h":1080}}
```

Result: PASS. No Chromium console errors were recorded. Screenshot-related `ReadPixels` warnings were ignored as test harness readback cost.

### Firefox

Browser: Firefox 152 headless through WebDriver BiDi.

Validated:

- Web export load at 1280×720.
- Canvas focus after load.
- Start click required for audio.
- Gameplay HUD after Start.
- Pulse input and echo audio cue.
- Pause/resume.
- Pause → Main Menu.
- Keyboard Start from main menu.
- 1024×768 resize.
- 1920×1080 fullscreen-equivalent viewport.
- Console inspected through BiDi `log.entryAdded`.

Observed console:

```text
Godot Engine v4.7.stable.official.5b4e0cb0f
OpenGL API OpenGL ES 3.0 (WebGL 2.0) - Compatibility
Build configuration: Emscripten 4.0.20, single-threaded, no GDExtension support.
ECHO_KICKOFF_BOOT_OK | renderer=gl_compatibility | viewport=1280x720 | platform=Web
ECHO_KICKOFF_AUDIO_USER_GESTURE_OK
ECHO_KICKOFF_AUDIO_CUE_OK industrial_ambience
ECHO_KICKOFF_AUDIO_AMBIENCE_OK
ECHO_KICKOFF_AUDIO_CUE_OK echo_pulse
```

Canvas metrics:

```json
{"1280x720":{"w":1280,"h":720},"1024x768":{"w":1024,"h":768},"1920x1080":{"w":1920,"h":1080}}
```

Result: PASS. No Firefox BiDi console errors were recorded.

## Automated validation

Full suite run:

```bash
godot --headless --path . --script tests/phase_01_project_test.gd
godot --headless --path . --script tests/phase_02_flow_test.gd
godot --headless --path . --script tests/phase_02_layout_test.gd
godot --headless --path . --script tests/phase_03_player_test.gd
godot --headless --path . --script tests/phase_04_reveal_test.gd
godot --headless --path . --script tests/phase_05_echo_pulse_test.gd
godot --headless --path . --script tests/phase_06_listener_test.gd
godot --headless --path . --script tests/phase_07_interaction_test.gd
godot --headless --path . --script tests/phase_08_vertical_slice_test.gd
godot --headless --path . --script tests/phase_09_decoy_test.gd
godot --headless --path . --script tests/phase_10_round_state_test.gd
godot --headless --path . --script tests/phase_11_content_test.gd
godot --headless --path . --script tests/phase_12_visual_test.gd
godot --headless --path . --script tests/phase_13_audio_test.gd
godot --headless --path . --script tests/phase_14_ux_test.gd
godot --headless --path . --script tests/phase_15_release_candidate_test.gd
```

All printed their phase PASS markers, including:

```text
PHASE_15_RELEASE_CANDIDATE_TEST_OK
```

## Known non-breaking issues

- Windows build was exported on macOS but was not launched on Windows hardware in this environment.
- Firefox stderr reports an Emscripten/WebAssembly deprecation warning for the generated Godot loader; this is engine output, not project code, and the build runs.
- Firefox stderr reports a WebGL vertex-attribute warning from the engine render path; no gameplay or console error was observed.
- Chromium stderr reports screenshot-related `ReadPixels` stalls during test capture; normal gameplay does not perform those readbacks.
- The local Python HTTP server logged broken pipes during earlier aborted Firefox screenshot probes; the final BiDi browser test loaded all game files normally.

## Decision

PASS — Echo Kickoff is a release candidate for Web submission. The build remains Godot 4, GDScript-only, Compatibility-rendered, single-threaded on Web, free of GDExtension/C#/external JS dependencies, and playable without external software beyond a browser.

## Post-revision integration addendum — 2026-07-17

Result: **PASS**

The environment-art, ambient/local visibility, optional movement-aid, HUD, accessibility, and tutorial revisions completed after the original Phase 15 measurements have now been validated together. No gameplay feature or balance value changed. The original Phase 15 balance table and 842.4-second modeled route remain authoritative.

Fresh integration verification produced matching 538,028-byte Web and Windows PCKs with SHA-256 `ba6b0b92bf36c6806abf71f4a1b94444b47085fd2817cddb1dcdcdc3ba3f6cc8`. Web export completed in 3.49 seconds with 876.1 MiB peak RSS; Windows export completed in 2.63 seconds with 941.1 MiB peak RSS. The Web build remains single-threaded, contains no worker artifact, and the release PCK excludes debug/test resource paths.

Chromium validated ambient/local visibility, active Echo and danger feedback, decoy count change, pause/resume, high contrast, the optional movement aid, outside-pad mouse isolation, keyboard coexistence, focus, and exact 1280×720 → 1024×768 resizing. Its 180-frame ambient and active-Echo samples both averaged 16.61 ms, with zero subscribed page/runtime/network errors. Firefox BiDi validated live menu-to-game movement and Echo input against the same export with zero subscribed browser errors.

All 20 current Godot headless tests passed, including Phase 01–15 plus the visual, visibility, joystick/HUD, and tutorial revision suites. Existing non-breaking tradeoffs remain: Windows hardware launch is pending, the Godot Web WASM is approximately 39.5 MB, and Firefox emits the previously documented generated-engine-path warnings.

The complete evidence, scope cuts, external submission gates, and remaining polish items are recorded in `docs/post-revision-integration-report.md`. Release-candidate status remains **PASS**.
