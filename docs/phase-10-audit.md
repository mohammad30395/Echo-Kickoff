# Echo Kickoff — Phase 10 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Complete death, restart, progression, pause, and transition lifecycle**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Outcome

`GameManager` is now the single authority for the complete round lifecycle. It owns the required **Playing**, **Paused**, **Player caught**, **Restarting**, **Victory**, and **Transitioning** states while retaining a separate minimal screen location for backward-compatible Boot/Main Menu/Game World/Game Over/Victory navigation.

Listener contact or an explicit confirmed-capture request enters Player caught synchronously, freezes the SceneTree, displays a 0.55-second non-graphic procedural `SIGNAL INTERCEPTED` sequence over the still-loaded level, then fades to Game Over. Restart enters Restarting before replacing the scene, fades the fresh Game World in under Transitioning, and enters Playing only after the new round is ready.

Mission completion enters Victory synchronously, freezes the completed round during fade-out, loads the Victory screen, then restores an interactive Victory state after fade-in. Pause/resume, Escape-to-menu, duplicate request guards, audio cleanup, and all scene-local reset boundaries are covered by integration tests.

## Authority and stored state

No RoundManager, ProgressManager, transition autoload, or additional global singleton was added. The existing three autoloads remain:

```text
root
├── EventBus
│   ├── application requests
│   ├── app_state_changed
│   ├── round_state_changed
│   └── round_started(round_id)
├── AudioManager
│   └── unique per-round AudioStreamPlayer registry
└── GameManager
    ├── ScreenState               navigation location only
    ├── RoundState                authoritative lifecycle
    ├── current_round_id          only stored session progress
    └── one persistent CanvasLayer
        ├── PauseMenu              temporary; at most one
        └── RoundTransitionVisual  persistent fade/caught curtain
```

The only progress snapshot exposed by the autoload is `{ round_id }`. Relay activation, extraction lock/completion, decoy charges, pulse cooldown/count, active effects, Listener state, hearing memory, and caught status remain owned by the instantiated Game World. This avoids shadow copies that could disagree with scene state and guarantees that scene replacement is the reset mechanism.

The legacy `get_state_name()` still reports `main_menu`, `game_world`, `paused`, `game_over`, and `victory` for existing decoupled UI and tests. `get_round_state_name()` is the authoritative gameplay lifecycle interface.

## Required round states

| State | Entry | Guarantees | Exit |
|---|---|---|---|
| Playing | New Game or successful restart fade-in completes | Game World is current, tree unpaused, one fresh scene-local round | Pause, confirmed capture, mission victory, or transition request |
| Paused | Escape/pause request from Playing | Exactly one PauseMenu; tree and all pausable gameplay timers/AI frozen | Resume button returns Playing; Escape or Main Menu button begins menu transition |
| Player caught | First confirmed capture while Playing | Duplicate capture ignored; tree frozen; old level retained during visible death feedback | Game Over transition; state remains Player caught on interactive Game Over screen |
| Restarting | First restart request from Game Over | Duplicate restart ignored; round audio cleared; old terminal scene fades out | Fresh Game World load, then Transitioning |
| Victory | Mission completion while Playing | Completed round freezes immediately; later Victory screen is interactive | Transitioning fade to/from terminal screen or Escape/Main Menu |
| Transitioning | Boot/menu/new-round fade or post-load fade-in | Gameplay requests ignored while busy; high-layer procedural curtain catches pointer input | Target settled state |

Observed runtime history in the focused test:

```text
Transitioning -> Playing -> Paused -> Playing -> Paused -> Transitioning
-> Playing -> Player caught -> Transitioning -> Player caught
-> Restarting -> Transitioning -> Playing
-> Victory -> Transitioning -> Victory -> Transitioning
```

## Death and restart flow

```text
Listener contact / confirmed capture
        |
        v
Player caught
├── reject duplicate capture
├── SceneTree.paused = true
├── keep Game World loaded
└── 0.55 s procedural interception feedback
        |
        v
fade to black -> load Game Over -> fade in -> Player caught
        |
        v
Restart request -> Restarting
├── reject duplicate restart
├── clear registered round audio
├── fade terminal screen out
└── replace Game World scene
        |
        v
Transitioning fade-in -> Playing + round_started(new round_id)
```

The Listener still emits its local `player_caught` signal once, stops its own physics immediately, and sends the confirmed capture through EventBus. GameManager then freezes every other pausable gameplay system, preventing movement, interaction, pulses, decoys, or other Listener activity during death feedback.

## Reset proof

The focused restart scenario deliberately dirties all relevant state before contact: Relay A is active, objective HUD is 1/3, one decoy charge is spent, an Echo is active and cooling down, the Listener has an accepted stimulus, transient pulse/decoy nodes exist, and one synthetic built-in round-audio probe is registered.

After one restart request plus a duplicate request, the test proves:

- round identifier increments exactly once;
- EventBus, AudioManager, and GameManager instance IDs are unchanged and unique;
- Game World, Sector, player, mission, and Listener are new instances;
- objectives are 0/3 and extraction is locked/inactive;
- decoys are restored to 2/2;
- pulse count and cooldown are zero;
- no active pulse or sound-decoy node remains;
- Listener begins IDLE with `none` hearing category and no caught flag;
- round-audio registry is empty;
- SceneTree is unpaused and round state is Playing.

## Pause and timer safety

The pause test starts an Echo Pulse, its cooldown, an airborne decoy, and a Listener investigation before entering Paused. Across 20 paused process frames:

- Echo radius is unchanged;
- pulse cooldown is unchanged;
- decoy position is unchanged;
- Listener position and FSM state are unchanged;
- a duplicate pause request creates no second overlay.

Resume restores Playing and every sampled system advances again. Transition/death tweens are the only pause-exempt timers; they are owned by always-processing GameManager/overlay nodes so a paused round cannot deadlock a menu exit, caught sequence, or victory fade.

## Audio lifecycle

There are still no imported audio files. AudioManager now provides a Web-safe `play_unique_round_audio(cue_id, stream)` boundary for future procedural/team-created cues. Repeated playback of the same cue ID reuses one AudioStreamPlayer rather than adding another node. `stop_round_audio()` stops, frees, and clears every registered player at New Game, caught-to-Game Over, restart, victory, and Main Menu boundaries.

The test uses Godot's built-in `AudioStreamGenerator` only as a silent lifecycle probe: two calls with one cue ID produce the same player and registry count 1; menu escape, capture, and restart reduce the count to 0. No asset was created or imported.

## Procedural transitions and input flow

One persistent CanvasLayer at layer 1000 contains a responsive `RoundTransitionVisual`. It uses only CanvasItem rectangles, arcs, and lines plus a built-in-font Label:

- normal transitions interpolate a near-black full-viewport curtain;
- Player caught uses expanding red interception rings, crossed signal-cut lines, restrained horizontal bands, and `SIGNAL INTERCEPTED` text;
- no texture, image sprite, shader, full-screen sampling loop, particle system, or external asset is used;
- the visual processes while paused and captures pointer input only while visible;
- layout fills and keeps feedback text enclosed at 1280×720, 1024×768, and 1600×900.

PauseMenu is inserted into that same high-level CanvasLayer beneath the transition visual. This keeps the controls above every gameplay HUD layer while allowing the final fade curtain to cover the complete frame. The focused test verifies one pause instance, full runtime-canvas sizing, and a visible title; the exported Web smoke confirms the complete menu visually at 1024×768.

Escape behavior is explicit and safe:

- Playing + Escape: enter Paused.
- Paused + Escape: fade to Main Menu and clear the round.
- Paused Resume button: return to Playing.
- Game Over/Victory + Escape: fade to Main Menu.
- Main Menu buttons remain keyboard/mouse navigable.

## Automated validation

Primary command:

```bash
godot --headless --path . --script tests/phase_10_round_state_test.gd
```

| Requirement | Evidence | Result |
|---|---|---|
| Required states | Enum and observed history contain Playing, Paused, Player caught, Restarting, Victory, Transitioning. | PASS |
| Capture triggers death | Real Listener contact enters Player caught. | PASS |
| Brief death feedback | Game World remains current and paused while caught visual/text is visible before Game Over. | PASS |
| Clean restart | Dirty objective/decoy/pulse/enemy/audio state resets through fresh scene load. | PASS |
| Duplicate state | Duplicate pause, capture, and restart requests are ignored; one transition and one round increment occur. | PASS |
| Duplicate autoload | Exactly one EventBus, AudioManager, GameManager, and transition CanvasLayer; IDs persist across restart. | PASS |
| Duplicate audio | Repeated cue ID returns one player; all round boundaries clear registry. | PASS |
| Objective reset | 1/3 dirty state becomes 0/3; extraction relocks. | PASS |
| Decoy reset | 1/2 dirty state becomes 2/2. | PASS |
| Enemy reset | Heard/caught state becomes IDLE, `none`, uncaught. | PASS |
| Pause timers/AI | Echo radius/cooldown, decoy, and Listener freeze and resume. | PASS |
| Escape to menu | Actual Escape input from Paused and Victory reaches clean unpaused Main Menu. | PASS |
| Procedural fades | One texture/shader-free always-processing overlay covers transitions and caught feedback. | PASS |
| Minimal session progress | Autoload snapshot contains only `round_id`; gameplay progress is scene-local. | PASS |
| Responsive feedback | Overlay and label enclosed at all three target viewports. | PASS |
| Pause UI layering | One full-canvas PauseMenu remains visible above gameplay HUD and below the fade curtain. | PASS |

The suite prints `PHASE_10_ROUND_STATE_TEST_OK` and exits 0 without runtime warnings or errors.

## Regression and platform validation

| Check | Result |
|---|---|
| Headless editor import/parse | PASS |
| Phase 1 project/settings/input | PASS |
| Phase 2 complete navigation and responsive layouts | PASS |
| Phase 3 player movement/collision/pause/layout | PASS |
| Phase 4 darkness/reveal | PASS |
| Phase 5 pulse/noise/timer/restart | PASS |
| Phase 6 Listener FSM/hearing/contact/reset | PASS |
| Phase 7 interaction/objective/Victory/reset | PASS |
| Phase 8 full loss/restart and three-relay victory playthrough | PASS |
| Phase 9 decoy/hierarchy/alternative/reset | PASS |
| Phase 10 round lifecycle/reset/transition suite | PASS |
| Web release export | PASS — HTML, WebAssembly, and PCK generated successfully. |
| Windows Desktop release export | PASS — valid x86-64 PE executable generated successfully; execution remains a Windows-hardware gate. |
| Live exported Web transition/input smoke | PASS — Compatibility renderer booted; New Game, visible Pause, Escape fade to Main Menu, and 1024×768 browser resize passed with no application exception/warning. |

Earlier phase tests that assumed instant scene replacement now wait for GameManager's explicit transition boundary. Their gameplay assertions and routes are unchanged.

## Compliance and performance

- Godot 4.7, typed GDScript, Compatibility renderer, keyboard/mouse, Web and Windows targets remain unchanged.
- No C#, GDExtension, addon, plugin, native library, Phaser.js, Three.js, external service, or network dependency was added.
- Transition visuals are bounded CanvasItem draw calls; no expensive per-frame scene scan or per-pixel effect exists.
- One persistent overlay replaces repeated allocation of transition UI. PauseMenu remains temporary and duplicate-guarded.
- Round audio registry is empty in the current asset-free build and bounded by unique cue IDs when later used.
- VIS-009 records the new original procedural overlay; no non-code asset entered the repository.

## Remaining risks

- The Windows artifact must still be executed on Windows hardware before submission; macOS can only validate export structure.
- The caught feedback duration and red intensity pass functional/accessibility constraints but still need external human comfort/readability feedback.
- Future authored audio must use the unique registry, be entered in the asset ledger, and be volume/duplicate-tested on Web before release.

## Decision

**PASS**

All source-level, lifecycle, reset, pause, progression, duplicate-guard, responsive, regression, export, and live Web requirements pass. The Windows release artifact is structurally valid and still requires the normal final execution check on Windows hardware before submission.
