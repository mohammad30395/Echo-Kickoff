# Echo Kickoff — Phase 08 Vertical Slice Report

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **M07 complete vertical-slice level — `Sector_00_Test`**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Outcome

`Sector_00_Test` replaces the former debug room in the normal Game World. It is a complete three-relay run with a dark west entry, minimal contextual onboarding, a single Listener guarding the first branch, upper and lower traversal loops, locked extraction near the entry, reliable contact failure/restart, and Victory/Main Menu return.

The player-facing level contains no placeholder copy, test-room instructions, debug key hints, imported asset, image sprite, shader, or external dependency. Debug input remains available in dedicated development rooms but is explicitly disabled for the production level instance.

## Runtime scene tree

```text
GameWorld
└── Sector_00_Test
    ├── FacilityFloor                 procedural near-black floor and entry beacon
    ├── Revealables                  15 walls, 4 props, 3 hazards, floor boundary
    ├── CollisionGeometry            authored matching StaticBody2D rectangles
    ├── Player                       movement, Camera2D, pulse, interaction
    ├── MissionController            authoritative 3-relay run state
    ├── RelayA / RelayB / RelayC     reusable noisy reactor relays
    ├── ExtractionTerminal           locked until 3/3
    ├── Listener                     one sound-driven enemy
    └── HUDLayer
        └── HUD
            ├── PulseCooldownHud
            ├── ObjectiveHud
            ├── InteractionPromptHud
            └── OnboardingHud
```

The layout is authored as fixed rectangle and landmark data in `sector_00_test.gd`. Runtime construction creates only the matching procedural draw and collision nodes; it is deterministic authored content, not a random-generation system.

## Level structure and player guidance

- The player starts beside the only permanently readable world landmark: a dim west-entry beacon.
- Moving 68 px replaces `MOVE // WASD OR ARROW KEYS` with `ECHO // SPACE OR LEFT MOUSE`.
- The first pulse replaces that instruction with the theme relationship: `ECHO REVEALS THE FACILITY // ECHO ALSO TRAVELS`.
- When the Listener accepts a pulse or relay event, the message becomes `LISTENER ALERTED // BREAK LINE OF SIGHT`.
- Relay and extraction actions rely on the existing contextual hold-E prompt; no duplicate tutorial panel is added.
- The objective HUD communicates 0/3 through 3/3 and extraction readiness immediately, with shape and text as well as color.

The central 420×300 reactor block and offset branch walls create an upper loop, a lower loop, and open alternate connections around obstacles. Relay rooms and extraction have more than one approach/exit. Extraction is logically locked but never sealed by a physical door, so failure to complete an objective cannot trap the player. Outer boundaries are continuous and every tested route remains inside the camera limits.

## Full playthrough steps

### Intentional loss and restart

1. Boot reached Main Menu and keyboard New Game reached Game World.
2. The player moved through the dark west vestibule; the movement instruction advanced to the pulse instruction.
3. Space emitted a real Echo Pulse and revealed the entry walls.
4. The player followed the west/north approach to Relay A.
5. A pulse at Relay A revealed the relay and produced an `echo_pulse` event accepted by the one Listener.
6. The relay hold interaction was exercised and the player deliberately remained in the alerted area.
7. The Listener reached physical contact and routed through EventBus/GameManager to Game Over.
8. Restart created a new `Sector_00_Test` with 0/3 relays, locked extraction, no active pulse, and no caught/noise memory on the Listener.

### Evasive victory and menu return

1. A new run entered through the west vestibule and pulsed before approaching Relay A.
2. Relay A was revealed and activated with the real 1.5-second hold; the player escaped north before the Listener completed its investigation.
3. The upper perimeter route passed around the reactor block to Relay B; a pulse, hold, noise event, visible relay-state change, and 2/3 HUD update all completed.
4. The eastern route reached Relay C; activation immediately changed the HUD and extraction to ready at 3/3.
5. The lower perimeter route returned around the opposite side of the central block to extraction, demonstrating the second traversal loop.
6. Holding E at powered extraction completed the mission and routed to Victory.
7. Victory returned to Main Menu.

The automated input-driven route traversed **6,524 px**. Using a cautious first-time effective pace of 48 px/s plus 62 seconds for pulses, observation, interaction, and evasion gives a modeled first run of **197.9 seconds (3 minutes 18 seconds)**, inside the requested 3–5 minute target. This is a design model backed by a complete route, not a substitute for an external first-time human timing session.

## Issues found and fixed

| ID | Issue found during playthrough | Fix and verification |
|---|---|---|
| VS-01 | A wide central Listener patrol could be outside the pulse radius when the first relay was revealed, weakening the required reveal-and-danger beat. | The single Listener now patrols a compact authored north-west listening pocket: safely beyond an unavoidable instant catch, but within the Relay A pulse radius. Pulse acceptance is asserted before the loss path proceeds. |
| VS-02 | The Listener's default 25 px catch range was smaller than the player-plus-Listener collision radii (15 + 16 = 31 px). Real bodies could collide forever without entering the catch threshold. | Default contact range increased to 34 px, the minimum safe margin above physical contact. Actual movement now reaches Game Over; Phase 6 contact/reset regression still passes. |
| VS-03 | Early patrol placements either made the entry corridor unsafe or allowed the Listener to reach Relay A before a 1.5-second hold could reasonably complete. | Spawn/patrol were moved to a pulse-reachable but separated pocket. The loss route catches a stationary player, while the full win route activates Relay A and escapes without disabling the Listener. |
| VS-04 | At 1024×768 the centered interaction prompt overlapped the bottom-right pulse panel despite both controls remaining inside the viewport. | Prompt width reduced to 330 px and the production pulse HUD removes its unused debug row. An explicit rectangle non-overlap assertion now passes at 1280×720, 1024×768, and 1600×900. |
| VS-05 | Player-facing pulse/Listener debug keys and the pulse debug hint were inherited from reusable test architecture. | Production level disables both debug input toggles, forces debug drawing off, and hides/compacts the debug hint. Dedicated test scenes retain their diagnostics. |
| QA-01 | A clean export attempt failed after its target directories were deliberately removed. | Recreated `build/web` and `build/windows` before export and used `set -e`; both fresh release exports then completed. Generated build directories remain ignored. |
| QA-02 | The first headless Chrome launch lacked WebGL2 and correctly stopped at Godot's capability screen. | Repeated the same exported build under Chrome's software WebGL2 backend. Godot reported Compatibility/WebGL2, single-threaded Emscripten, and no GDExtension support; the game canvas rendered with no runtime exception. |

## Validation evidence

Primary complete-playthrough command:

```bash
godot --headless --path . --script tests/phase_08_vertical_slice_test.gd
```

The suite uses actual movement actions, collision, pulse input events, hold interaction, Listener hearing/chase/contact, GameManager transitions, and scene reload. It does not directly mark objectives complete or teleport through the tested routes.

| Check | Evidence | Result |
|---|---|---|
| Dark entry / movement learning | Player begins visible beside entry beacon; world revealables start at zero; movement advances the contextual tutorial. | PASS |
| Pulse / world reveal | Entry pulse reveals authored geometry; relay pulse reveals the procedural relay. | PASS |
| Listener alert | The real Echo Pulse event is accepted as `echo_pulse`; alert state/message updates. | PASS |
| Intentional loss | Listener reaches actual body contact and Game Over. | PASS |
| Restart | Relay count, extraction, pulse, caught state, and Listener memory reset. | PASS |
| Three objectives | A, B, and C activate once through hold input and visibly change state; HUD reaches 3/3 immediately. | PASS |
| Extraction / victory | Locked before 3/3, ready after 3/3, then Victory and Main Menu return. | PASS |
| Two routes | Full run uses the upper outward route and lower return route around the central reactor block. | PASS |
| Collision / soft-lock | All authored waypoints are reached with CharacterBody2D movement; no direct transform bypass; extraction remains physically accessible. | PASS |
| No foreknowledge dependency | Entry beacon, progressive two-step onboarding, pulse outlines, prompts, and objective HUD provide the required information. | PASS |
| First-run duration target | 6,524 px complete route; 197.9-second cautious model. | PASS (modeled) |
| Responsive UI | HUD enclosed and prompt/pulse panels non-overlapping at all three target sizes. | PASS |
| Native Compatibility render | Dark baseline, entry pulse, relay reveal/alert, contextual prompt, and 4:3 state visually inspected. | PASS |
| Live Web runtime | Chrome WebGL2 loaded the single-threaded Compatibility build; Enter, movement, Space/pulse, canvas draw, and 1024×768 resize worked with no runtime exception. | PASS |
| Windows artifact | Fresh PE32+ x86-64 executable and PCK exported. | PASS (export only) |

Regression suites for Phases 1–7 all pass after the level and contact-threshold changes. Headless editor parse/import and dedicated `Sector_00_Test` smoke runs exit 0 without broken references or GDScript errors.

## Performance notes

- The level adds 15 wall rectangles, 4 collidable props, 3 non-colliding hazard marks, and one floor boundary; all are small bounded CanvasItem draw calls.
- One pulse snapshots approximately 28 local revealables once and removes each reached target from its pending list. There is no per-frame tree scan, physics flood, full-screen shader, light texture, or per-pixel loop.
- Only one Listener runs the existing interval-gated sight ray and event-driven hearing logic.
- The live Web build remained responsive during movement, a pulse, and viewport resize under software WebGL2; no JavaScript, WebAssembly, or Godot runtime exception was recorded.
- Chrome reported readback stalls only while the QA harness captured screenshots. Those `ReadPixels` diagnostics are capture overhead and do not occur in normal play.
- The complete accelerated integration suite exits in roughly 5–6 seconds at 2.5× simulation speed on the development Mac. A release-hardware frame-time capture remains part of final performance polish.

## Remaining risks

- **R05/R16 — external comprehension and timing:** the 3:18 duration is modeled and the run was authored/tested by the developer. A first-time external player still needs to confirm darkness readability, route discovery, and actual 3–5 minute completion.
- **R06/R07 — Listener balance:** one complete loss and one evasive victory pass, but more human attempts are needed to tune whether Relay A feels tense rather than scripted. The later relays are intentionally lower-pressure with one Listener.
- **R08 — browser input:** live Web verified Enter, D movement, Space pulse, WebGL2 rendering, and resize. Headless Chrome did not provide a trustworthy physical-Escape probe, so pause/resume should receive one manual check in a normal browser before submission; the Godot input/flow integration suite passes it.
- **R10 — Windows execution:** the Windows build is a valid exported PE32+ artifact but has not been launched on Windows hardware.
- **R09/R13 — audio:** the slice remains completable muted and uses visual/text/shape cues, but authored audio and audio-browser behavior are still later milestones.
- **R21 — release performance:** the bounded architecture and software-WebGL smoke pass are strong, but final profiling on a lower-end browser/Windows device is still required.

None of these residual items prevents the current Phase 08 vertical slice from booting, teaching its loop, completing loss/restart, or completing objectives/extraction. They remain release/submission gates rather than permission to add more levels.

## Decision

**PASS**

`Sector_00_Test` is the only authored gameplay level and now demonstrates the locked Echo Kickoff loop from entry through both failure/restart and victory/menu return. The complete route, objective state, alternate loops, darkness/reveal language, one-Listener response, responsive UI, native render, live Web runtime, and all regressions pass. No additional level should be started before the remaining external timing/browser/Windows checks are scheduled within later polish and release phases.
