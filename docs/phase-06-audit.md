# Echo Kickoff — Phase 06 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **First sound-driven Listener vertical slice (M05)**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Scope alignment

Phase 6 implements one reusable Listener that consumes the Phase 5 noise interface and completes the locked M05 state cycle. It adds a dedicated AI test arena and integrates one Listener into the existing player test room. It does not add objectives, relays, extraction, multiple enemies, authored level content, combat, advanced acoustic simulation, audio assets, or any stretch feature.

No `STUNNED` state was added because the GDD does not require one. The FSM contains exactly the six scoped states.

## Scene tree

```text
Listener (CharacterBody2D, listener.gd)
├── CollisionShape2D (CircleShape2D)
├── Visual (ListenerVisual -> EchoRevealable)
└── DebugLabel (Label, hidden by default)

ListenerAITest (Node2D)
├── ArenaVisual (procedural Node2D drawing)
├── Collision
│   ├── TopWall / BottomWall
│   ├── LeftWall / RightWall
│   └── CenterObstacle
├── Player (TopDownPlayer)
├── Listener (four exported patrol offsets)
└── HUDLayer
    └── instructions
```

The test scene is `res://scenes/debug/listener_ai_test.tscn`. The reusable enemy scene is `res://scenes/entities/listener.tscn`.

## State architecture

```text
IDLE -> PATROL -> IDLE
  |        |        |
  +--------+--------+-- noise --> INVESTIGATE --> SEARCH --> RETURN
                                 ^       |             |        |
                                 |       +-------------+        +--> IDLE/PATROL
                                 |
clear short-range sight --> CHASE
                              |
                 sight memory expires
                              +--> SEARCH
                 contact --> caught signal + simulation stop
```

- `IDLE` provides a configurable initial/patrol wait and then advances to the current waypoint.
- `PATROL` visits exported offsets relative to spawn, allowing each scene instance to author its route.
- `INVESTIGATE` moves to the exact accepted noise position. It never follows the emitting player after the event.
- `SEARCH` checks four deterministic offsets around the last-heard or last-seen location for an exported duration.
- `CHASE` requires a short range plus an unobstructed physics ray. It uses the last confirmed visible position and a bounded retarget interval.
- `RETURN` selects the nearest authored patrol point, or spawn when the route is empty, then resumes the normal loop.

The Listener is pausable. Contact emits `player_caught` once, optionally requests Game Over through EventBus, stops physics processing, and cannot continue moving. Scene reload creates a new FSM with no caught, debug, or noise memory.

## Hearing and stimulus priority

The Listener connects once to EventBus `noise_emitted`; it performs no sound-source scene scan. A noise is heard only when:

1. its loudness meets the exported minimum;
2. source distance is within `loudness × hearing_sensitivity`;
3. it passes the replacement rule; and
4. the Listener is not already in a visually confirmed chase.

Priority combines source loudness and remaining radius at the Listener. Category weights make an echo pulse more urgent than an equivalent generic noise and make footsteps less urgent. A newer event can replace an active one when its computed priority retains at least 70% of the current stimulus; any stronger event may replace it. This permits meaningful recent/loud diversions while preventing nearby quiet footsteps from overwriting a loud pulse.

Noise position, category, timestamp, and current priority are exposed for diagnostics. Pulse priority over footsteps and both stronger/newer replacement paths are automated-test assertions.

## Detection, obstacles, and anti-stuck behavior

Detection is intentionally local: the default range is 105 px and checks run every 0.15 seconds. Each check uses one Compatibility-safe 2D ray against the collision mask. The player reference is found once through the `player` group or assigned explicitly by the owning scene. CHASE does not read the player's position through a wall; it moves to the last position confirmed by a detection check.

CHASE retargeting is independently capped at 0.18-second intervals. The automated one-second chase sample performed no more than seven target updates, rather than one per physics frame.

Movement uses `CharacterBody2D.move_and_slide()` against authored collision. On first contact with an obstacle the Listener follows a collision tangent until the direct ray to its target clears. This wall-follow behavior is bounded by an exported duration. A separate no-progress watchdog alternates deterministic recovery directions and, after the exported attempt limit, advances to an appropriate fallback state. The test traverses from one side of the central 100×300 px obstacle to the other without teleporting or abandoning the last-heard area.

## Procedural readability

`ListenerVisual` extends `EchoRevealable`, so the enemy is nearly unreadable in darkness and receives the same luminous reveal/fade lifecycle as walls and terminals. Its original broken-wave silhouette is drawn with polygons and lines. State intensity is communicated by both color and shape:

- INVESTIGATE: orange listening arcs;
- SEARCH: four orange search-point dots;
- CHASE: red double chevrons.

F3 toggles the optional AI diagnostics. When enabled, a label shows FSM/noise state, a circle shows `debug_reference_loudness × hearing_sensitivity`, and a line shows the current movement target. Diagnostics are exported `false` and draw nothing by default.

## Performance and Compatibility considerations

- Hearing is event-driven; no per-frame sound-source lookup or scene-tree scan occurs.
- Player lookup is cached and only retried when the reference is missing.
- Detection is interval-gated and performs at most one short ray per check.
- CHASE target refresh is interval-gated instead of recalculated every frame.
- Obstacle ray checks occur only during bounded wall-follow recovery.
- Search points are a fixed four-element sequence with no runtime path allocation.
- All movement uses `_physics_process(delta)`, delta-scaled acceleration, and deterministic state timers.
- Visuals use CanvasItem polygons, polylines, arcs, circles, and labels only.
- There are no textures, shaders, particles, NavigationServer maps, GDExtensions, C#, or external assets.
- Web export remains single-threaded with GDExtension support disabled.

## Automated validation

Primary command:

```bash
godot --headless --path . --script tests/phase_06_listener_test.gd
```

| Requirement | Evidence | Result |
|---|---|---|
| Reusable scene | CharacterBody2D, collision, typed script, revealable procedural visual, and hidden debug label verified. | PASS |
| Exact FSM | Exactly IDLE, PATROL, INVESTIGATE, SEARCH, CHASE, and RETURN; no extra state. | PASS |
| Patrol | IDLE emitted a transition to PATROL and moved toward four exported waypoint offsets. | PASS |
| Event-driven hearing | EventBus publication reached the connected Listener; effective radius included the test instance's 1.25 sensitivity. | PASS |
| Recorded origin | Player moved after emission while investigation target remained the exact pulse position. | PASS |
| Priority | Loud pulse replaced footstep; newer quiet footstep was rejected; stronger and sufficiently strong newer stimuli replaced. | PASS |
| Investigation | Accepted event entered INVESTIGATE and crossed the obstacle to the last-heard area. | PASS |
| Search/return | Timed local SEARCH entered RETURN and recovered to IDLE/PATROL. | PASS |
| Close detection | Clear nearby target entered CHASE. | PASS |
| Obstacle blocking | Central wall blocked sight; last-seen and movement targets did not follow the hidden player. | PASS |
| Bounded retarget | One-second visible chase remained below the asserted update cap. | PASS |
| Stuck prevention | Long-wall traversal completed; per-frame displacement remained below teleport threshold. | PASS |
| State indicators | SEARCH and CHASE exposed distinct shape-based alert levels. | PASS |
| Debug default/toggle | Diagnostics began off; F3 enabled label/radius/target state. | PASS |
| Pause/disable | Position and state remained fixed while paused; explicit disable also stopped movement. | PASS |
| Contact/death | Contact emitted once, retained caught state, and stopped later simulation. | PASS |
| Game Over integration | Contact in the real Game World routed through EventBus/GameManager to the Game Over scene. | PASS |
| Scene reload | Caught state, FSM, noise memory, and debug toggle reset cleanly. | PASS |

The suite printed `PHASE_06_LISTENER_TEST_OK` and exited 0. A 300-frame dedicated-scene smoke run with diagnostics and an emitted pulse also exited 0 without errors.

## Regression and export validation

| Check | Result |
|---|---|
| Headless editor import/parse | PASS |
| Phase 1 project/input/settings suite | PASS |
| Phase 2 complete flow and responsive layout suites | PASS |
| Phase 3 player movement/collision/pause/layout suite | PASS |
| Phase 4 darkness/reveal suite | PASS |
| Phase 5 pulse/noise/pause/restart suite | PASS |
| Phase 6 Listener suite | PASS |
| Dedicated Listener scene 300-frame headless smoke | PASS |
| Single-threaded Web release export | PASS |
| Windows Desktop release export | PASS |
| Prohibited technology and external-asset source scan | PASS |

The Web build was exported but not live-run in a browser because the browser-control runtime was unavailable in this session. The Windows executable was not launched on Windows. These remain final platform smoke requirements and are not claimed as runtime passes.

## Asset and scope check

- VIS-005 records the original Listener silhouette and AI test-room drawing in the asset ledger.
- No imported image, audio, font, model, video, plugin, addon, or other external asset was added.
- M05 is complete as one Listener vertical slice; M06 is the next permitted scope item.
- No objective, relay, extraction, multiple-Listener content, sound asset, combat, stun mechanic, or stretch feature was added.
- Godot 4, typed GDScript, Compatibility renderer, keyboard/mouse, Web/Windows targets, and the locked concept remain intact.

## Decision

**PASS**

Phase 06 delivers the first readable sound-driven enemy loop: patrol, weighted hearing, exact-origin investigation, local search, short unobstructed chase, contact failure, and reliable return/recovery all pass without external assets or scope expansion.
