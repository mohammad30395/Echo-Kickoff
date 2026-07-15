# Echo Kickoff — Phase 07 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Interaction and three-relay mission-objective system (M06)**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Scope alignment

Phase 7 completes the locked M06 objective loop in the current graybox: the player detects nearby facility controls, holds E with visible progress, activates three distinct relays, powers extraction, and completes the extraction interaction to reach Victory. It also adds one reusable locked-door interaction and a dedicated interaction test room.

This phase does not build the final hub-and-three-branch level, add more Listeners, add audio files, or enter presentation/settings scope. The optional log panel was deliberately omitted because the GDD cut-list excludes lore documents and dialogue systems.

## Architecture

```text
TopDownPlayer
└── InteractionController (Area2D)
    ├── event-driven nearby Area2D candidates
    ├── nearest clear candidate selection
    ├── wall line-of-sight ray
    ├── hold/cancel/progress state
    └── prompt/progress/completion signals

FacilityInteractable (Area2D base)
├── ReactorRelay
│   └── ReactorRelayVisual (EchoRevealable)
├── FacilityDoor
│   ├── blocker StaticBody2D
│   └── FacilityDoorVisual (EchoRevealable)
└── ExtractionTerminal
    └── ExtractionTerminalVisual (EchoRevealable)

MissionObjectiveController (scene-local Node)
├── discovers/registers three relays once
├── owns active count and extraction lock
├── updates ExtractionTerminal
├── emits objective/extraction/completion signals
└── requests Victory through EventBus after extraction

HUD
├── InteractionPromptHud
│   ├── contextual text
│   └── hold ProgressBar
└── ObjectiveHud
    ├── three hex/coil relay icons
    ├── locked/powered extraction icon
    └── immediate text state
```

Mission state is not an autoload. It belongs to the active gameplay scene, so New Game and Game Over restart create a clean mission without manual persistent-state cleanup. GameManager remains the sole owner of application transitions.

## Player interaction behavior

The reusable player scene owns an Area2D interaction sensor with a 92 px radius. Enter/exit signals maintain a small candidate list. While candidates exist, the controller selects the nearest one that has a clear physics ray from the player to the interaction anchor.

The ray checks collision layer 1 and excludes the player. A facility door additionally excludes its own blocker so it can be operated from either side; unrelated walls still block it. The dedicated room places Relay B inside sensor overlap but behind a wall, proving that proximity alone cannot expose a prompt or begin activation.

The locked GDD specifies a hold interaction, so relays and extraction default to 1.5 seconds on E. Progress:

- freezes with the paused SceneTree;
- resets when E is released;
- resets when the player leaves range;
- resets when line of sight is lost or focus changes;
- activates exactly once at completion.

Prompts remain useful for unavailable objects: activated relays show `ONLINE`, locked extraction shows its current relay count, and doors distinguish `LOCKED` from `OPEN`. These states do not rely on color alone.

## Mission flow

```text
0/3 relays
  ├── extraction prompt: LOCKED // RELAYS 0/3
  └── activate relay -> one loud reactor_relay NoiseEvent
          |
          v
1/3 -> 2/3 -> 3/3
                  |
                  ├── extraction visual changes from crossed lock to powered beacon
                  ├── HUD changes to EXTRACTION READY
                  └── extraction hold becomes available
                              |
                              v
                    mission_completed -> EventBus.victory_requested -> Victory
```

Each relay emits exactly one `reactor_relay` NoiseEvent from its own fixed position at 600 px loudness. This is greater than the 480 px pulse default. Listeners give relay activation a strong hearing priority and still investigate the event origin through the existing shared noise interface. Repeated activation is rejected and produces neither another objective increment nor another noise.

The mission controller counts actual relay activation state, clamps progress to the required three, and immediately sends count changes to both extraction and HUD. Extraction rejects input before 3/3. Completion is also guarded against repeats.

## Procedural and accessible visual states

- Relay inactive: hollow hexagonal frame, three horizontal coil bars, hollow center.
- Relay active: two live coil arcs and a filled center diamond, plus a temporary reveal.
- Door locked: joined panels with an X lock.
- Door unlocked: joined panels with a circular power mark.
- Door open: physically separated panels and directional chevrons; blocker collision is disabled.
- Extraction locked: doorway chevrons plus a central X.
- Extraction powered: doorway chevrons plus a vertical beacon and ring.
- Extraction complete: filled center diamond.
- Objective HUD: hollow relay hexes become filled diamonds; extraction changes from framed X to paired chevrons; text mirrors every state.

All world visuals inherit EchoRevealable and use CanvasItem drawing. UI uses Control, Label, ProgressBar, and custom polygon/line drawing. No texture, SVG file, shader, external font, image, or audio asset is required.

## Interaction test scene

`res://scenes/debug/interaction_test.tscn` contains:

```text
InteractionTest
├── procedural arena and boundary collision
├── dedicated line-of-sight wall
├── Player with InteractionController
├── MissionObjectiveController
├── Relay A / Relay B / Relay C
├── locked FacilityDoor
├── locked ExtractionTerminal
└── responsive objective, prompt, and instruction HUD
```

The normal `GameWorld` graybox also contains the same three-relay mission loop, one Listener, and extraction, making the application start-to-Victory route functional before final level construction.

## Performance and Compatibility considerations

- Proximity candidates are maintained by Area2D signals; there is no per-frame group scan for interactions.
- Mission interactables are discovered once per scene and then connected by typed signals.
- Line-of-sight rays run only while a candidate is inside the small interaction sensor.
- Hold progress is scalar, delta-based, and pausable.
- Relay noise reuses EventBus/NoiseEvent and creates no separate acoustic system.
- HUD updates only on prompt progress or mission state changes.
- Procedural visuals use bounded polygons, polylines, rectangles, circles, and arcs.
- No NavigationServer change, full-screen effect, shader, texture, GDExtension, C#, addon, or third-party dependency was added.
- The Web preset remains single-threaded with extension support disabled.

## Automated validation

Primary command:

```bash
godot --headless --path . --script tests/phase_07_interaction_test.gd
```

| Requirement | Evidence | Result |
|---|---|---|
| Reusable interactables | Relay, door, and extraction inherit FacilityInteractable; their visuals inherit EchoRevealable. | PASS |
| GDD input/hold | E binding and 1.5-second relay/extraction defaults verified. | PASS |
| Nearby detection | Clear Relay A entered focus and displayed a hold prompt. | PASS |
| Wall blocking | Relay B overlapped the sensor through a wall but could neither focus nor activate. | PASS |
| Hold cancellation | Leaving range reset partial progress and did not activate. | PASS |
| Pause | Partial hold progress remained unchanged while paused. | PASS |
| Relay state | Activation changed both logical and procedural shape state. | PASS |
| Relay noise | Each relay emitted one 600 px event at its relay position. | PASS |
| Listener consumption | The in-range Game World Listener received `reactor_relay` through the shared noise interface. | PASS |
| Repeat guard | Repeated relay, door, and extraction holds produced no duplicate state/event. | PASS |
| Locked extraction | Interaction before 3/3 did not complete the mission. | PASS |
| Locked door | Locked input was rejected; explicit unlock permitted one hold, opened panels, and disabled collision. | PASS |
| Immediate HUD | Objective text advanced through 0/3, 1/3, 2/3, 3/3/ready, and complete. | PASS |
| Third-relay unlock | Third activation immediately powered extraction logic, prompt, icon, and shape. | PASS |
| Victory | Powered extraction completed the mission and real Game World routed to Victory. | PASS |
| Reset | Victory new-run and Game Over restart both restored 0/3 with locked extraction. | PASS |
| Responsive UI | Objective and prompt HUDs remained enclosed at 1280×720, 1024×768, and 1600×900. | PASS |

The suite printed `PHASE_07_INTERACTION_TEST_OK` and exited 0. The dedicated interaction scene also completed a 180-frame headless Compatibility smoke with all procedural revealables enabled.

## Regression and export validation

| Check | Result |
|---|---|
| Headless editor import/parse with no warning or broken reference | PASS |
| Phase 1 project/input/settings suite | PASS |
| Phase 2 flow and responsive layout suites | PASS |
| Phase 3 player movement/collision/pause/layout suite | PASS |
| Phase 4 darkness/reveal suite | PASS |
| Phase 5 pulse/noise/pause/restart suite | PASS |
| Phase 6 Listener FSM/hearing/contact/restart suite | PASS |
| Phase 7 interaction/objective/Victory/reset/layout suite | PASS |
| Native 1280×720 Compatibility render inspection | PASS |
| Single-threaded Web release export | PASS |
| Windows Desktop release export | PASS |
| Prohibited technology and external-asset source scan | PASS |

The Web build was exported but not live-run in a browser in this session. The Windows executable was exported on macOS but not launched on Windows. These remain final platform smoke requirements and are not claimed as runtime passes.

## Asset and scope check

- VIS-006 records every new original procedural interaction, mission-HUD, and test-room visual path.
- No imported image, SVG file, audio, font, model, video, plugin, addon, or third-party material was added.
- The optional log panel was cut in accordance with the GDD.
- M06 is complete; M07 final-level construction is the next permitted must-have.
- Godot 4, typed GDScript, Compatibility renderer, keyboard/mouse, Web/Windows targets, and the locked concept remain intact.

## Decision

**PASS**

Phase 07 delivers the complete facility objective loop in a test graybox: safe contextual hold interaction, exactly three noisy relays, immediate accessible state feedback, locked-to-powered extraction, Victory routing, and clean restart behavior all pass without final-level scope or external assets.
