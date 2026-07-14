# Echo Kickoff

Echo Kickoff is a Godot 4 GameJam project for the IUT 12th ICT FEST 2026 GameJam. The locked concept is a 2D top-down stealth-horror game where every echo pulse reveals the dark facility and alerts sound-sensitive Listeners.

Phase 4 contains the technical baseline, core application flow, reusable top-down player controller, and the darkness/echo-revealable visual foundation. The actual expanding echo pulse, enemies, relays, extraction, and other gameplay systems have not been implemented.

## Requirements

- Godot **4.7.stable** (`4.7.stable.official.5b4e0cb0f` used for this baseline)
- Matching Godot export templates for Windows Desktop and Web
- Keyboard and mouse

The project uses GDScript only, the Compatibility renderer, and no third-party plugins or external JavaScript frameworks.

## Open and run

### Godot editor

1. Launch Godot 4.7.
2. Import or scan this directory and select `project.godot`.
3. Press **F6/F5** or click **Run Project**.
4. Confirm the technical boot screen hands off to the main menu. The console reports the renderer, viewport, and platform.

### Command line

From the repository root:

```bash
godot --path . --editor
```

Run a short headless boot check:

```bash
godot --headless --path . --quit-after 2
```

A successful boot writes an `ECHO_KICKOFF_BOOT_OK` diagnostics line.

Validate the locked Phase 1 settings, input map, and export presets:

```bash
godot --headless --path . --script tests/phase_01_project_test.gd
```

A successful configuration test writes `PHASE_01_PROJECT_TEST_OK` and exits with status 0.

Validate every application navigation path and responsive scene layout:

```bash
godot --headless --path . --script tests/phase_02_flow_test.gd
godot --headless --path . --script tests/phase_02_layout_test.gd
```

Successful tests write `PHASE_02_FLOW_TEST_OK` and `PHASE_02_LAYOUT_TEST_OK`.

Validate cardinal and normalized diagonal movement, wall collision, deterministic response, pause behavior, and responsive debug-room layout:

```bash
godot --headless --path . --script tests/phase_03_player_test.gd
```

A successful controller test writes `PHASE_03_PLAYER_TEST_OK`. To run the standalone graybox room directly:

```bash
godot --path . --scene res://scenes/debug/player_test_room.tscn
```

Press **F1** in the test room to temporarily reveal all procedural geometry. Validate the reveal lifecycle, primitive coverage, dark-state cost, debug input, and shader-free Compatibility path with:

```bash
godot --headless --path . --script tests/phase_04_reveal_test.gd
```

A successful reveal-system test writes `PHASE_04_REVEAL_TEST_OK`.

## Application flow

```text
Boot -> Main Menu -> Game World
Game World -> Pause -> Resume or Main Menu
Game World -> Game Over -> Restart or Main Menu
Game World -> Victory -> Main Menu
```

UI scenes publish requests through `EventBus`; `GameManager` owns transitions and pause state. `AudioManager` provides the asset-free audio service boundary for later phases.

## Display and controls baseline

- Base viewport: **1280×720**
- Stretch mode: **2D canvas items**, aspect **expand**
- Renderer: **Compatibility** (`gl_compatibility`)
- Web export: **single-threaded**, GDExtension support disabled

Configured input actions:

| Action | Inputs |
|---|---|
| `move_up` | W, Up Arrow |
| `move_down` | S, Down Arrow |
| `move_left` | A, Left Arrow |
| `move_right` | D, Right Arrow |
| `echo_pulse` | Space, Left Mouse Button |
| `interact` | E |
| `throw_decoy` | Q, Right Mouse Button |
| `pause` | Escape |
| `restart` | R |

These actions are configured for later gameplay phases; the boot scene does not act on them.

## Export

Install the matching Godot 4.7 export templates, then export from **Project → Export** using:

- `Windows Desktop` → `build/windows/echo-kickoff.exe`
- `Web` → `build/web/index.html`

Equivalent command-line exports:

```bash
mkdir -p build/windows build/web
godot --headless --path . --export-release "Windows Desktop" build/windows/echo-kickoff.exe
godot --headless --path . --export-release "Web" build/web/index.html
```

Generated build directories are ignored by Git. Serve the Web build over HTTP rather than opening `index.html` directly.

## Project layout

```text
scenes/              Boot, UI, game world, reusable entities, and debug rooms
scripts/             Typed GDScript source, procedural drawing, and autoload services
tests/               Headless configuration, flow, and layout checks
docs/                GameJam planning, compliance, and phase audits
project.godot        Project settings and input map
export_presets.cfg   Windows and single-threaded Web presets
```
