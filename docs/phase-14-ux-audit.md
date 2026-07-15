# Phase 14 UX Audit

Result: PASS

Date: 2026-07-15

## Source documents reviewed

- `docs/01-game-design-document.md`
- `docs/02-scope-lock.md`
- Previous phase audits: Phase 0 through Phase 13

## Player-facing UI completed

- Main menu:
  - Start game
  - How To Play panel
  - Credits panel
  - Master, effects, and ambience volume controls
  - High contrast, reduced flash, and screen-shake options
- In-game HUD:
  - Pulse cooldown and readiness
  - Decoy count and controls
  - Relay objective count
  - Interaction prompt
  - Short tutorial/onboarding banner
- Pause menu:
  - Resume
  - Main menu
  - Master, effects, and ambience volume controls
  - High contrast, reduced flash, and screen-shake options
  - Keyboard/mouse control reminder
- Terminal screens:
  - Death screen with restart and main menu
  - Victory screen with main menu

## Onboarding rules implemented

Tutorial sequence is run-local and non-repeating once a lesson is understood:

1. Movement first: `MOVE // WASD OR ARROW KEYS`
2. Pulse through play after movement distance is detected
3. Immediate danger framing after pulse: `PULSE REVEALS // PULSE ALSO CALLS LISTENERS`
4. Interaction lesson appears around relays, doors, and extraction
5. Decoy lesson appears only after the pulse/danger lesson is established
6. Extraction prompt appears after all relays are active

Messages are intentionally short and disappear permanently for the current run when the relevant player action or state is observed.

## Accessibility

- `AccessibilityManager` autoload owns global UX options:
  - High contrast mode
  - Reduced screen flash
  - Screen-shake toggle
- `AccessibilitySettingsPanel` is reused by the main menu and pause menu.
- High contrast mode updates HUD/prompt/pulse/decoy visual colors through shared helper methods.
- Reduced flash lowers echo pulse visual intensity and suppresses extra danger arcs.
- Screen shake can be disabled globally; when disabled, camera offset is forced back to zero.
- UI controls support keyboard focus and mouse activation.
- Text sizes remain readable at 1280×720.
- Menu, pause, death, victory, HUD, and settings controls remain inside browser-safe bounds during tested resize cases.

## Scene and script changes

- Added `scripts/autoload/accessibility_manager.gd`
- Added `scenes/ui/accessibility_settings_panel.tscn`
- Added `scripts/ui/accessibility_settings_panel.gd`
- Updated `project.godot` autoload configuration
- Updated `scenes/ui/main_menu.tscn`
- Updated `scripts/ui/main_menu.gd`
- Updated `scenes/ui/pause_menu.tscn`
- Updated tutorial and accessibility behavior in `scripts/levels/echo_facility.gd`
- Updated HUD/effect visuals for accessibility settings:
  - `scripts/ui/pulse_cooldown_hud.gd`
  - `scripts/ui/decoy_hud.gd`
  - `scripts/ui/objective_hud.gd`
  - `scripts/ui/interaction_prompt_hud.gd`
  - `scripts/ui/onboarding_hud.gd`
  - `scripts/ui/round_transition_visual.gd`
  - `scripts/effects/echo_pulse.gd`
  - `scripts/effects/sound_decoy.gd`
  - `scripts/entities/player_decoy_controller.gd`
- Added `tests/phase_14_ux_test.gd`
- Updated `tests/phase_13_audio_test.gd` for the revised pause-menu layout

## Automated validation

Commands run:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script tests/phase_14_ux_test.gd
godot --headless --path . --script tests/phase_02_flow_test.gd
godot --headless --path . --script tests/phase_02_layout_test.gd
godot --headless --path . --script tests/phase_10_round_state_test.gd
godot --headless --path . --script tests/phase_13_audio_test.gd
```

Full Phase 01-14 regression suite was also run and passed:

- `PHASE_01_PROJECT_TEST_OK`
- `PHASE_02_FLOW_TEST_OK`
- `PHASE_02_LAYOUT_TEST_OK`
- `PHASE_03_PLAYER_TEST_OK`
- `PHASE_04_REVEAL_TEST_OK`
- `PHASE_05_ECHO_PULSE_TEST_OK`
- `PHASE_06_LISTENER_TEST_OK`
- `PHASE_07_INTERACTION_TEST_OK`
- `PHASE_08_VERTICAL_SLICE_TEST_OK`
- `PHASE_09_DECOY_TEST_OK`
- `PHASE_10_ROUND_STATE_TEST_OK`
- `PHASE_11_CONTENT_TEST_OK`
- `PHASE_12_VISUAL_TEST_OK`
- `PHASE_13_AUDIO_TEST_OK`
- `PHASE_14_UX_TEST_OK`

Phase 14 specific output:

```text
UX_MENU_OK | Start, How to Play, Credits, audio/accessibility settings, keyboard focus
UX_TERMINAL_SCREENS_OK | pause, death, victory keyboard and mouse controls
UX_SAFE_BOUNDS_OK | menu, pause, death, victory remain inside browser-safe viewports
UX_TUTORIAL_ACCESSIBILITY_OK | run-local lessons, no repeats, shake/flash/contrast settings functional
PHASE_14_UX_TEST_OK
```

## Export validation

Commands run:

```bash
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/echo-kickoff.exe
```

Both exports completed without Godot build errors.

## Browser smoke test

The in-app browser JavaScript control tool was not exposed in this session, so the Web export was smoke-tested with a local HTTP server plus isolated Chrome DevTools Protocol automation.

Tested:

- Web export load at `http://127.0.0.1:8767/index.html`
- 1280×720 canvas sizing
- Main menu display
- How To Play panel
- Credits panel
- Accessibility toggles
- Start game after user gesture
- In-game tutorial HUD
- Pulse input cue
- Pause menu
- 1024×768 browser resize

Observed Web logs:

```text
ECHO_KICKOFF_BOOT_OK | renderer=gl_compatibility | viewport=1280x720 | platform=Web
ECHO_KICKOFF_AUDIO_USER_GESTURE_OK
ECHO_KICKOFF_AUDIO_CUE_OK industrial_ambience
ECHO_KICKOFF_AUDIO_AMBIENCE_OK
ECHO_KICKOFF_AUDIO_CUE_OK echo_pulse
```

Resize metrics:

```json
{"title":"Echo Kickoff","inner":[1024,768],"canvas":{"w":1024,"h":768,"clientW":1024,"clientH":768}}
```

Chrome reported `ReadPixels` warnings during screenshot capture only. No Godot runtime errors or broken references were observed.

## Risks and follow-up

- Windows export was built on macOS but not hardware-smoke-tested on Windows.
- Browser audio still depends on the required user gesture, which is handled through Start game.
- The tutorial sequence is designed for the vertical slice; final level tuning should verify that player route timing still teaches pulse, danger, interaction, and decoy in order.

## Acceptance result

PASS — Phase 14 player-facing UI, onboarding, accessibility options, browser-safe layout, and validation requirements are complete.
