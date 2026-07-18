# Echo Kickoff

Echo Kickoff is a Godot 4 game-jam project for the IUT 12th ICT FEST 2026. It is a 2D top-down stealth-horror campaign where every Echo Pulse reveals the dark facility—and tells sound-sensitive enemies where to search.

The finished campaign has three sequential operations. Easy restores 3 reactors against 2 Listeners, Medium restores 5 against 3 Listeners and 1 Reactor Warden, and Hard restores 7 against 4 Listeners and 2 Wardens. Every repaired reactor raises the facility lighting. Full power opens a physical extraction gate; cross the doorway to finish the operation. Progress, unlocks, best rank, and best time are saved locally.

## Campaign

| Operation | Reactors | Enemies | Par time |
|---|---:|---|---:|
| Easy — Orientation Deck | 3 | 2 Listeners | 12 min |
| Medium — Resonance Labs | 5 | 3 Listeners + 1 Warden | 18 min |
| Hard — Blackout Core | 7 | 4 Listeners + 2 Wardens | 25 min |

Runs receive S/A/B/C ranks from time and chase count. Echo and decoy use are shown as play-style statistics and never penalized. The Reactor Warden reacts to recent audible trajectories, including false trajectories created by decoys; it receives no hidden player position.

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

If `godot` is not on `PATH` in this workspace, use the installed binary directly:

```bash
~/.local/bin/godot --path . --editor
```

Run a short headless boot check:

```bash
godot --headless --path . --quit-after 2
```

A successful boot writes an `ECHO_KICKOFF_BOOT_OK` diagnostics line.

Validate the complete campaign contract:

```bash
godot --headless --path . --script tests/campaign_expansion_test.gd
```

This checks the 3/5/7 reactor totals, 2/4/6 enemy totals, exact tuning profiles, power/gate sequence, Warden interception, ranks, unlock order, reset, and missing/corrupt save recovery.

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

Validate pulse input, expansion, reveal falloff, noise data, footsteps, cooldown, pause, debug visuals, scene reload, and Game Over restart with:

```bash
godot --headless --path . --script tests/phase_05_echo_pulse_test.gd
```

A successful pulse/noise test writes `PHASE_05_ECHO_PULSE_TEST_OK`.

Validate Listener patrol, hearing, investigation, search, chase, obstacle recovery, pause/contact behavior, and Game Over integration with:

```bash
godot --headless --path . --script tests/phase_06_listener_test.gd
```

Validate wall-safe hold interactions, relay noise, objective HUD updates, locked doors, extraction gating, Victory routing, reset, and responsive layout with:

```bash
godot --headless --path . --script tests/phase_07_interaction_test.gd
```

Run the dedicated interaction room directly:

```bash
godot --path . --scene res://scenes/debug/interaction_test.tscn
```

## Application flow

```text
Boot -> Main Menu -> Game World
Game World -> Pause -> Resume or Main Menu
Game World -> Game Over -> Restart or Main Menu
Game World -> Results -> Next Level, Retry, Level Select, or Main Menu
```

UI scenes publish requests through `EventBus`; `GameManager` owns transitions and pause state. `CampaignManager` owns the level catalog and local progression. `AudioManager` plays fourteen deterministic, original, baked WAV cues.

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
| `interact` | E (reactor repair) |
| `throw_decoy` | Q, Right Mouse Button |
| `pause` | Escape |
| `restart` | R |
| `debug_reveal` | F1 |
| `debug_pulse_visuals` | F2 |
| `debug_listener_ai` | F3 |

In production levels, hold E near a reactor relay, restore the full grid, then cross the opened extraction doorway. Space or left mouse emits the Echo Pulse; Q or right mouse throws a decoy. Debug controls are confined to test rooms and disabled in production.

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
scenes/              Three campaign levels, UI, reusable entities, and debug rooms
scripts/             Typed campaign/gameplay code, procedural drawing, and autoloads
tests/               Headless campaign, gameplay, flow, visual, audio, and layout checks
docs/                GameJam planning, compliance, and phase audits
project.godot        Project settings and input map
export_presets.cfg   Windows and single-threaded Web presets
```
