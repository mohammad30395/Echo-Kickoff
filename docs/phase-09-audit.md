# Echo Kickoff — Phase 09 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Throwable sound decoy and noise hierarchy in the Phase 08 vertical slice**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Outcome

The reusable player now aims a two-charge sound decoy with the mouse and throws it with Q or right mouse. A short dotted trajectory ends at a procedural target reticle. The controller range-clamps the target and raycasts collision layer 1 before every throw; a wall hit moves the landing point back by a configurable clearance, so the projectile cannot cross solid facility geometry.

The airborne decoy follows a deterministic, delta-scaled arc rendered with CanvasItem primitives. Impact emits one configurable `sound_decoy` event from the validated landing point, briefly draws two impact rings, and applies only a 64 px / 16% confirmation reveal. Listeners consume the event through the existing EventBus/NoiseEvent hearing path and investigate the exact impact position. The HUD shows both icon and text charge state, updates immediately, and resets naturally when Game World is reinstanced.

## Scope alignment

The locked GDD and `02-scope-lock.md` do not list a throwable decoy in the original M01–M10 must-have or stretch set. The user's explicit Phase 09 instruction authorizes this one bounded scope addition. It does not authorize an inventory system, pickups, crafting, ammunition drops, additional enemies, another level, or a second reveal mechanic.

The implementation stays contained by reusing the existing player, shared noise event, Listener hearing, revealable, HUD, restart, and vertical-slice systems. It adds two per-level charges only; no persistent state or new autoload exists. The core concept remains dominant because the decoy's visual reveal is deliberately too weak and too local to navigate by.

## Runtime architecture

```text
TopDownPlayer
├── PulseController
├── DecoyController (PlayerDecoyController)
│   ├── samples global mouse position while unpaused
│   ├── clamps to 360 px maximum range
│   ├── raycasts solid collision and applies 20 px clearance
│   ├── draws dotted trajectory + valid/clamped/invalid reticle
│   ├── owns 2 scene-local charges
│   └── spawns SoundDecoy into the active level
└── InteractionController

SoundDecoy
├── deterministic start/landing interpolation + visual arc
├── one impact at the validated point
├── 64 px weak reveal snapshot
├── EventBus.publish_noise(sound_decoy, 420 px)
└── short procedural impact-ring lifetime

Listener
└── existing event-driven hearing
    └── sound_decoy weighting rewards a close, precise landing

HUDLayer/HUD
└── DecoyHud
    ├── Q / RIGHT MOUSE instruction
    ├── two procedural diamond charge icons
    └── CHARGES N/2 text
```

`SoundDecoy` and `PlayerDecoyController` expose tuning as typed exported variables. The UI binds through typed signals and knows nothing about the Listener or mission. The Listener knows only the shared noise category and remains independent of player/UI scenes.

## Throw validation and state rules

- Mouse aim is refreshed in `_process()` so the indicator follows the current world-space cursor and freezes with normal pause processing.
- The requested point is first limited to 360 px from the player.
- A `PhysicsRayQueryParameters2D` query checks bodies on layer 1, excluding the player's RID.
- On collision, the landing point is placed 20 px toward the player from the hit; orange reticle color communicates that the throw was wall-clamped.
- Landings closer than 28 px are rejected; invalid or zero-charge throws spend nothing and emit no noise.
- A successful throw spends one charge immediately and emits typed charge/thrown/impact signals.
- Both the projectile and controller use `PROCESS_MODE_PAUSABLE`; flight position is unchanged while paused.
- Charges belong to the instantiated player controller, so Game Over restart/new level instance restores 2/2 and removes all prior transient projectiles without autoload cleanup.

## Noise and reveal balance

| Source | Default loudness/reach | Frequency/economy | Information effect | Listener intent |
|---|---:|---|---|---|
| Footstep | 72 px | Frequent after each 88 px traveled | None | Local movement trace; lowest category weight. |
| Sound decoy | 420 px | Targeted; exactly 2 charges per level | 64 px at 16% strength for landing confirmation only | Precise lure. Near impact may replace a more distant event; it does not beat a relay at equal range. |
| Echo Pulse | 480 px noise / 320 px reveal | Reusable with 1.2 s cooldown | Broad, strong world revelation | Primary information/danger tradeoff; higher intrinsic priority than decoy at equal geometry. |
| Reactor relay | 600 px | One extremely loud event per objective | Active relay visibly self-reveals/changes state | Strongest objective stimulus and highest equal-range priority. |

The required scalar hierarchy is therefore **72 < 420 < 480 < 600**. Category weighting does not reverse it at equal distance. It permits the decoy's intended skill expression: a landing close to the Listener can redirect it from a farther source, while an imprecise decoy remains weaker than Echo or relay noise.

## Meaningful alternative solution

Phase 08 establishes the baseline failure: after Relay A alerts the Listener, a player who remains at the relay is reached and sent to Game Over.

The Phase 09 integration test reaches the same Relay A through real CharacterBody2D movement, completes the real 1.5-second hold, and confirms the relay becomes the Listener's target. The player then leads one short decoy throw 64 px along the Listener's approach. The impact lands near the moving enemy, replaces the now-distant relay target with the exact `sound_decoy` position, and changes the Listener to investigate/search.

The player remains in the former danger area for a three-second simulated danger window, stays in Game World, and then withdraws north. Exactly one of two charges is consumed. This is a meaningful alternative to immediate flight: precise limited diversion creates a safe escape window after an extremely loud objective event. The relay is still the dominant event until the closer targeted impact occurs.

## Compatibility and performance

- GDScript only; no C#, GDExtension, addon, package, JavaScript gameplay library, native plugin, or network dependency.
- CanvasItem `draw_*` calls only; no texture, sprite, particle resource, shader, light texture, full-screen pass, or renderer-specific feature.
- Flight is one bounded Node2D process for at most 0.65 seconds; impact visual lasts 0.55 seconds and frees itself.
- One physics ray runs per unpaused aim frame and once immediately before a throw. It checks only solid bodies on the existing wall layer.
- The small revealable group is scanned once on impact, not every frame; only nodes within 64 px receive the weak reveal.
- Listener hearing remains signal-driven and performs no sound polling.
- The Web preset remains Compatibility, single-threaded, and extension support disabled.

## Automated validation

Primary command:

```bash
godot --headless --path . --script tests/phase_09_decoy_test.gd
```

| Requirement | Evidence | Result |
|---|---|---|
| Mouse aim / controls | Controller follows global mouse; InputMap contains Q and right mouse; live Web mouse movement changed the target. | PASS |
| Trajectory/target | Eight-point short dotted indicator terminates at the validated position; live Web reticle visually inspected. | PASS |
| Valid landing | Exact impact and event positions equal the range/wall-validated landing. | PASS |
| No wall throw-through | Entry-wall test requests a point beyond the wall and receives a landing on the player side with 20 px clearance. | PASS |
| Configurable impact noise | One 420 px `sound_decoy` NoiseEvent emits at impact. | PASS |
| Listener investigation | Listener accepts the category and targets the exact impact position. | PASS |
| Weak reveal | Nearby revealable receives a nonzero maximum of 16%; radius is 64 px versus Echo's 320 px. | PASS |
| Limited charges | Two throws succeed, third is rejected, HUD reaches 0/2. | PASS |
| Restart reset | Game Over restart creates 2/2, clears active decoys, and resets HUD. | PASS |
| Pause | Airborne decoy position remains fixed across paused process frames. | PASS |
| Noise hierarchy | Automated values assert 72 < 420 < 480 < 600. | PASS |
| Alternative solution | Precise decoy redirects a distant relay target and provides a safe three-second withdrawal window. | PASS |
| Responsive HUD | Decoy panel enclosed and non-overlapping with prompt/Echo panels at 1280×720, 1024×768, and 1600×900. | PASS |
| Procedural-only visual | Decoy scene contains no Sprite2D; source/export scan finds no external assets or shaders. | PASS |

The Phase 09 suite prints `PHASE_09_DECOY_TEST_OK` and exits 0.

## Regression and platform validation

| Check | Result |
|---|---|
| Headless editor import/parse and vertical-slice scene smoke | PASS |
| Phase 1 project/settings/input | PASS |
| Phase 2 complete navigation and responsive application UI | PASS |
| Phase 3 movement/collision/pause/layout | PASS |
| Phase 4 darkness/reveal | PASS |
| Phase 5 Echo/noise/cooldown/restart | PASS |
| Phase 6 Listener FSM/hearing/chase/contact/reset | PASS |
| Phase 7 interactions/objectives/Victory/reset/layout | PASS |
| Phase 8 full loss/restart and three-relay victory playthrough | PASS |
| Phase 9 decoy/hierarchy/alternative/reset/layout | PASS |
| Web release export | PASS |
| Windows Desktop release export | PASS (export only; no Windows host available) |
| Live exported Web runtime | PASS |

The exported Web build loaded in Chrome at 1280 px width, entered Game World, tracked mouse aim, displayed the target indicator, accepted right-click, rendered the airborne procedural decoy, and changed the charge HUD from 2/2 to 1/2. Browser emulation then resized the live canvas to 1024×768; the canvas matched the viewport and the HUD remained enclosed. No JavaScript/Godot console warning or error was recorded during the run.

## Asset and repository check

- VIS-008 records the new procedural effect, aim indicator, and HUD paths.
- No imported image, audio, font, model, video, SVG file, plugin, or third-party asset was added.
- Generated Web/Windows artifacts remain under ignored `build/` paths.
- The work retains Godot 4, typed GDScript, Compatibility rendering, keyboard/mouse, Web/Windows targets, and the original one-level three-relay mission.

## Remaining risks

- The exact two-charge/420 px balance is verified functionally but still needs external human playtesting for discoverability and perceived value.
- Right mouse and resize passed in live Chrome; the Q binding passed automated InputMap validation but should receive one ordinary-browser manual check before submission.
- The Windows release artifact exported successfully on macOS but has not run on Windows hardware.
- The GDD/scope documents remain historically locked without the decoy; Phase 09 is recorded as an explicit user-authorized exception here rather than silently rewriting prior design approval.

## Decision

**PASS**

The throwable sound decoy is reusable, procedural, wall-safe, pause-safe, charge-limited, restart-clean, Web-compatible, integrated into the vertical slice, and balanced beneath Echo/relay revelation and loudness. It gives the Listener a precise new investigation target and passes a concrete alternate Relay A withdrawal scenario without adding a general inventory system or displacing the locked core loop.
