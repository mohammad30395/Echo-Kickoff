# Echo Kickoff — Phase 05 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Central Echo Pulse and unified noise-event system (M03 and M04)**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Scope alignment

Phase 5 completes the locked M03 pulse/reveal milestone and the shared M04 sound-event interface. It adds a player-triggered expanding reveal, cooldown feedback, pulse and footstep noise publication, and diagnostics needed for the next Listener phase. It does not add Listener AI, pulse occlusion, audio assets, objectives, relays, extraction, or level content.

## Architecture

```text
TopDownPlayer
└── PulseController (PlayerPulseController)
    ├── input: echo_pulse
    ├── cooldown and anti-spam
    ├── distance-spaced footsteps
    └── instantiates EchoPulse beside the player

EchoPulse (temporary Node2D scene)
├── procedural reveal ring
├── orange danger accents
├── one-time revealable candidate snapshot
├── geometry-distance reveal/falloff
└── publishes pulse NoiseEvent

EventBus
└── publish_noise(position, loudness, category)
    └── noise_emitted(NoiseEvent)

PulseCooldownHud
├── readiness ProgressBar
├── READY / RECHARGING status
├── REVELATION + DANGER launch message
└── F2 diagnostic state
```

Responsibilities remain narrow:

- `NoiseEvent` is a typed `RefCounted` data structure containing position, loudness, category, and timestamp. Loudness is the effective hearing radius in pixels. It also provides deterministic `reaches()` and distance-strength helpers for future Listener consumers.
- EventBus creates and publishes every noise through one `noise_emitted` signal. It does not retain history or perform hearing logic.
- `PlayerPulseController` owns player input, tuning, cooldown, pulse instantiation, and footstep cadence. It does not reveal targets itself and does not know about future Listeners.
- `EchoPulse` owns one expanding wave and frees itself on completion. It snapshots revealable candidates once, reveals them as the wavefront reaches their geometry, and publishes exactly one pulse noise event at its recorded origin.
- `PulseCooldownHud` binds through controller signals and has no scene-loading or gameplay-state responsibility.

## Default tuning

| Parameter | Default |
|---|---:|
| Reveal radius | 320 px |
| Pulse duration | 0.65 s |
| Pulse loudness/hearing radius | 480 px |
| Minimum edge reveal strength | 0.12 |
| Pulse cooldown | 1.2 s |
| Footstep spacing | 88 px travelled |
| Footstep loudness/hearing radius | 72 px |
| Footstep minimum movement speed | 35 px/s |

The required relationship is enforced by scene defaults: the 480 px pulse noise radius is larger than the 320 px useful reveal radius. Footsteps are 15% of pulse loudness and therefore much quieter and shorter-range.

## Pulse and reveal behavior

Space or left mouse uses the existing `echo_pulse` input action. A successful request creates one `EchoPulse` at the player's current global position. The pulse remains at that recorded origin while the player may move away.

The ring expands linearly from zero to the exported radius over the exported duration. Revealables are triggered only after the wavefront reaches them. Strength interpolates from 1.0 at the source to the configured minimum at the edge.

`EchoRevealPrimitive.get_reveal_distance_from()` measures the closest point of walls, doors, props, terminals, and hazards rather than their node origin. Floor boundaries measure distance to their perimeter while the player is inside. This prevents long geometry from revealing early because its pivot happens to be near the pulse.

When the pulse begins:

- a cyan luminous ring communicates revelation;
- segmented orange arcs and the initial warning diamond communicate danger;
- the HUD displays `ECHO KICKOFF: REVELATION + DANGER`;
- one `echo_pulse` NoiseEvent records the origin, 480 px loudness, category, and monotonic timestamp;
- the cooldown bar empties and refills visibly before another pulse is accepted.

No PNG, animation resource, texture, shader, audio file, or particle system is used.

## Unified footsteps

The pulse controller measures actual player distance travelled. While velocity exceeds the movement threshold, each configured distance interval publishes a `footstep` NoiseEvent through the same EventBus method used by pulses. Moving against a wall without travelling does not create false steps. The cadence is distance-based and therefore frame-rate independent.

No footstep sound file is included yet; this phase establishes the gameplay event consumed by the next Listener phase.

## Debug visualization

Diagnostics are exported `false` and disabled by default. F2 toggles the state and updates active pulses immediately.

When enabled, the pulse draws:

- the maximum reveal-radius circle;
- a larger segmented orange noise-radius circle;
- lines and markers for collected reveal targets, with out-of-range targets visually subdued.

The debug-room command arguments `--emit-test-pulse` and `--pulse-debug` allow deterministic Compatibility captures. They do not run during normal application flow.

## Web/performance considerations

- The pulse performs one group snapshot at launch; it does not search the scene tree every frame.
- Reached targets are removed from a small pending list, so each target is revealed once per pulse.
- No physics query, ray tracing, occlusion, navigation query, full-screen shader, framebuffer sample, viewport texture, or per-pixel loop is used.
- Runtime visuals are bounded CanvasItem arc, line, circle, and polygon draw commands.
- Debug-only maximum-radius and target drawing is skipped entirely by default.
- Each pulse is a short-lived node that queues itself for deletion at completion.
- Cooldown and footstep calculations are scalar/distance operations in pausable processing.
- Footstep publication is distance-spaced rather than per-frame.
- The successful Web export uses the existing single-threaded Compatibility preset with GDExtension support disabled.

## Automated validation

Primary command:

```bash
godot --headless --path . --script tests/phase_05_echo_pulse_test.gd
```

| Requirement | Evidence | Result |
|---|---|---|
| EchoPulse scene | Input instantiated the typed procedural scene in the active room. | PASS |
| NoiseEvent structure | Position, loudness, category, explicit/automatic timestamp, reach, and falloff were verified. | PASS |
| Unified publication | Pulse and footsteps were captured from the same EventBus `noise_emitted` signal. | PASS |
| Input | Parsed `echo_pulse` action created the first pulse; Phase 1 verifies Space and left-mouse mappings. | PASS |
| Expansion | Controlled half-duration steps advanced the ring from origin to half and full radius. | PASS |
| Reveal timing | Near target revealed at the half wave while the far target remained dark until reached. | PASS |
| Reveal falloff | Near target retained greater reveal strength than the far target. | PASS |
| Geometry distance | Primitive override computes closest shape/perimeter distance rather than pivot-only distance. | PASS |
| Noise payload | Pulse recorded player position, 480 px loudness, `echo_pulse` category, and valid timestamp. | PASS |
| Cooldown HUD | Indicator began full, entered cooldown, and displayed the revelation/danger launch state. | PASS |
| Anti-spam | Immediate repeat returned no pulse and emitted no noise; a later request succeeded after cooldown. | PASS |
| Footsteps | Actual walking emitted distance-spaced `footstep` events below 25% of pulse loudness. | PASS |
| Pause | Active wave radius and cooldown remained unchanged while SceneTree was paused. | PASS |
| Debug default/toggle | Diagnostics began false; F2 enabled current pulse radii and nonempty target state. | PASS |
| Scene reload | Pulse count, cooldown, debug state, and active pulse nodes reset cleanly. | PASS |
| Game Over restart | Restart created a fresh controller with zero cooldown/count and no old pulse. | PASS |

The suite printed `PHASE_05_ECHO_PULSE_TEST_OK` and exited 0.

## Regression and platform validation

| Check | Result |
|---|---|
| Headless editor parse/import with warnings treated as failures | PASS |
| Phase 1 project/settings/input suite | PASS |
| Phase 2 complete navigation suite | PASS |
| Phase 2 responsive layout suite at 1280×720, 1024×768, and 1600×900 | PASS |
| Phase 3 movement, collision, pause, and resize suite | PASS |
| Phase 4 darkness/reveal lifecycle suite | PASS |
| Native 1280×720 pulse and F2 diagnostic Compatibility captures | PASS |
| Single-threaded Web release export | PASS |
| Windows Desktop release export | PASS |
| Prohibited technology and external-asset scan | PASS |

The Web build was exported successfully but not live-run in a browser because browser automation is unavailable in this session. The Windows executable was not launched on Windows. Both remain final platform smoke requirements and are not claimed as runtime passes here.

## Asset and scope check

- VIS-004 records the original procedural pulse and cooldown HUD in the asset ledger.
- No external or non-code asset was added.
- No Listener, hearing reaction, enemy AI, pulse occlusion, audio playback, relay, extraction, objective, win, or lose mechanic was added.
- M03 and M04 now provide the event interface required by the next Listener vertical slice.
- GDScript-only, Compatibility renderer, Web/Windows targets, GDD, scope lock, and GameJam constraints remain intact.

## Decision

**PASS**

Phase 05 implements the central theme mechanic: every pulse simultaneously starts temporary revelation and publishes a larger danger signal, with clear cooldown feedback, quiet shared-interface footsteps, bounded Web-safe processing, and clean transient-state resets.
