# Echo Kickoff — Phase 02 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Core scene architecture and application flow only**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Scene tree

Runtime root:

```text
root
├── EventBus                 (autoload)
├── AudioManager            (autoload)
├── GameManager             (autoload)
├── CurrentScene
└── PauseMenu               (temporary overlay; only while paused)
```

Application scenes:

```text
Boot (Control)
├── Background (ColorRect)
├── ProceduralBackground (Control)
└── Center (CenterContainer)
    └── Content (VBoxContainer)
        ├── Title
        ├── Divider
        ├── DiagnosticsLabel
        └── Status

MainMenu (Control)
├── Background (ColorRect)
├── ProceduralBackground (Control)
└── Center
    └── Content
        ├── Eyebrow
        ├── Title
        ├── Theme
        ├── Spacer
        ├── NewGameButton
        └── Controls

GameWorld (Control)
├── Background (ColorRect)
├── ProceduralBackground (Control)
├── Header
└── Center
    └── Message
        ├── Title
        ├── Description
        └── PauseHint

PauseMenu (Control overlay)
├── Dimmer (ColorRect)
└── Center
    └── Content
        ├── Title
        ├── ResumeButton
        ├── MainMenuButton
        └── Hint

GameOver (Control)
├── Background (ColorRect)
├── ProceduralBackground (Control)
└── Center
    └── Content
        ├── Title
        ├── Message
        ├── RestartButton
        ├── MainMenuButton
        └── Hint

Victory (Control)
├── Background (ColorRect)
├── ProceduralBackground (Control)
└── Center
    └── Content
        ├── Title
        ├── Message
        ├── MainMenuButton
        └── Hint
```

All scene roots and backgrounds use full-rect anchors. Content is held by responsive containers rather than fixed screen coordinates. The shared procedural background draws its grid and echo rings at runtime; no external visual or audio assets are present.

## Autoload responsibilities

### EventBus

- Declares application requests without owning navigation.
- Carries boot, new-game, pause, resume, main-menu, restart, game-over, and victory requests.
- Publishes state changes for future UI or gameplay observers.
- Keeps UI scripts independent of GameManager and gameplay scenes.

### GameManager

- Is the only owner of application state and scene transitions.
- Validates allowed transitions from boot, menu, world, paused, game-over, and victory states.
- Instantiates/removes the pause overlay and controls `SceneTree.paused`.
- Restores an unpaused, overlay-free state before every full scene change.
- Loads the Game World placeholder for new-game and restart requests.

### AudioManager

- Provides the persistent audio-service boundary for future phases.
- Owns master linear volume and mute state through the built-in Master bus.
- Loads no audio files and has no gameplay responsibilities.

The three autoloads are explicitly required by Phase 2. No other autoload, plugin, addon, native dependency, or external service was introduced.

## Navigation tests

Automated command:

```bash
godot --headless --path . --script tests/phase_02_flow_test.gd
```

The integration suite uses the actual Boot scene, UI button signals, EventBus requests, GameManager transitions, keyboard actions, pause state, and current scene. All paths completed with the expected state and scene:

| Navigation path | Expected result | Result |
|---|---|---|
| Boot → Main Menu | `main_menu`, `MainMenu` | PASS |
| Main Menu → New Game → Game World | `game_world`, `GameWorld` | PASS |
| Game World → Pause | World retained, `PauseMenu` overlay, tree paused | PASS |
| Pause → Resume | Overlay removed, World retained, tree resumed | PASS |
| Pause → Main Menu | `main_menu`, `MainMenu`, tree resumed | PASS |
| Game World → Game Over | `game_over`, `GameOver` | PASS |
| Game Over → Restart | Fresh `GameWorld` scene | PASS |
| Game Over → Main Menu | `main_menu`, `MainMenu` | PASS |
| Game World → Victory | `victory`, `Victory` | PASS |
| Victory → Main Menu | `main_menu`, `MainMenu` | PASS |

Keyboard coverage includes focused-button `ui_accept`, the configured pause action for both pause and resume, and the configured restart action. Every interactive control is asserted to be keyboard focusable and mouse-enabled. Standard Godot `Button` nodes provide mouse click navigation.

## Additional validation

| Test | Evidence | Result |
|---|---|---|
| Project parse/import | Headless editor import exited 0 with no warnings, broken references, plugin errors, or GDExtension errors. | PASS |
| Phase 1 regression | `tests/phase_01_project_test.gd` printed `PHASE_01_PROJECT_TEST_OK`. | PASS |
| Responsive layout | Every scene root filled and every content container stayed inside 1280×720, 1024×768, and 1600×900 test viewports. | PASS |
| Native display | Compatibility runs passed at 1280×720 and a resized 1024×768 window; the latter correctly expanded the 2D canvas to 1280×960. | PASS |
| Visual inspection | Native 1280×720 Main Menu capture showed centered, readable content and procedural grid/rings. | PASS |
| Web export | Single-threaded Web release export completed; no thread worker was produced. | PASS |
| Windows export | Windows Desktop release export completed as a PE32+ x86-64 executable. | PASS |
| Asset/technology scan | No external assets, C#, GDExtension, native library, addon, plugin, or external JavaScript source was found. | PASS |

Live execution of the Web build in a browser and the Windows executable on Windows remain later platform smoke tests; this phase verified their clean exports and responsive scene layout. Generated builds remain ignored.

## Scope check

- No player, enemy, pulse, decoy, relay, extraction, collision, score, or other gameplay mechanic was implemented.
- Game-over and victory entry points are EventBus requests intended for later gameplay systems.
- UI scenes publish requests only; they do not load gameplay scenes or mutate game state directly.
- Compatibility renderer, GDScript-only policy, single-threaded Web export, scope lock, and GameJam compliance remain intact.

## Decision

**PASS**

Phase 02 provides the requested decoupled application architecture and complete core scene flow with responsive, asset-free UI and repeatable navigation tests. No required path is missing, and no gameplay work has entered this phase.
