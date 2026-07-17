# Echo Kickoff — Human Rescue Operative Audit

Date: 2026-07-17  
Engine: Godot 4.7, Compatibility renderer  
Result: **PASS**

## Scope

This pass replaces the former circular Player marker with a visibly human, top-down rescue operative. It changes presentation and visual state feedback only. Player movement values, collision behavior, camera behavior, decoy mechanics, Listener detection, objectives, death, restart, and scene flow remain intact.

## Inspected baseline

Before implementation, the reusable Player scene was confirmed to use:

- `CharacterBody2D` with a centered `CircleShape2D`, radius 15 px.
- Typed, delta-scaled acceleration/deceleration movement at 230 px/s.
- Shared WASD/arrows and virtual-joystick movement selection.
- Mouse-facing direction with a dead zone.
- A smoothed `Camera2D` at smoothing speed 6.
- A procedural Player visual composed primarily of concentric circles and a triangular direction marker.
- Center-origin Echo Pulse and decoy systems.

The circular visual was the part that failed the locked character concept. The controller, collision, and camera foundations were retained.

## Character construction method

The operative is authored entirely with deterministic Godot `Node2D._draw()` geometry. No sprite, texture, AI-generated image, copyrighted artwork, shader, or external character asset is used.

The procedural silhouette contains eight explicit parts:

1. Helmet with a dark cyan visor.
2. Light rescue-suit torso with a dark protective chest panel.
3. Free arm.
4. Scanner arm and visible hand.
5. Left leg and boot.
6. Right leg and boot.
7. Dark rescue/equipment backpack with orange safety stripe.
8. Offset handheld Echo scanner with cyan luminous core.

The canonical drawing faces right. Rotating the complete visual node keeps the helmet, limbs, backpack, scanner, and scanner-origin marker aligned in every direction.

### Palette

| Role | Direction |
|---|---|
| Rescue suit | Light grey/cyan-white |
| Protection and pack | Muted navy/dark blue |
| Helmet visor | Dark cyan-blue |
| Echo scanner | Bright cyan |
| Safety marking | Orange |
| Human outline | Near-black blue |
| Threat warning | Red-orange |
| Captured state | Distress red |

The suit and helmet remain lighter than every authored floor, restricted floor, corridor, panel, and wall-body palette. The cyan scanner is the brightest directional cue, while the body remains below full-screen-effect brightness.

## Effective dimensions and collision

| Item | Value | Result |
|---|---:|---|
| Effective character dimensions | 60 × 54 px | Inside locked 48–64 px range |
| Player collision shape | Circle, 15 px radius | Unchanged |
| Collision local position | `(0, 0)` | Aligned with torso/body center |
| Scanner marker | `(24, 12)` in the facing-local frame | Aligned with drawn handheld device |
| Camera smoothing | Enabled, speed 6 | Unchanged |

Limbs, pack, and scanner may extend outside the collision radius as presentation, but collision resolution remains owned by the established centered `CharacterBody2D` shape.

## Facing system

The Player now resolves facing in this order:

1. Mouse direction when mouse facing is enabled and outside the existing 8 px dead zone.
2. Current keyboard or virtual-joystick movement direction when a usable mouse direction is unavailable.
3. The last valid facing direction while idle.

The procedural body supports eight readable octants: right, down-right, down, down-left, left, up-left, up, and up-right. The forward helmet/visor and offset scanner arm make direction visible without a cursor-like triangle.

## Animation method

Animation is lightweight, deterministic, delta-scaled, and independent of sprite animation:

| State | Procedural response |
|---|---|
| Idle | Subtle torso breathing and equipment-ready pulse |
| Moving | Small forward bob, alternating leg stride, opposing free-arm movement |
| Echo ready | Soft rhythmic cyan scanner glow |
| Echo activation | Brighter white-cyan device core plus a short expanding scanner ring |
| Echo cooldown | Dimmer device core driven by cooldown readiness |
| Threat nearby | Pulsing red-orange shoulder markers and forward warning arc |
| Player captured | Movement stops, limbs splay, suit shifts toward red, distress arcs/slash appear |

Fixed `PackedVector2Array` drawing buffers are allocated once and reused. Threat proximity reads the two already-cached facility Listener references at 10 Hz; it does not scan the scene tree or change Listener AI.

## Gameplay integration

| Existing system | Preservation evidence |
|---|---|
| Keyboard movement | Same `Input.get_vector()` actions and velocity function; Phase 03 and operative tests pass |
| Virtual joystick | Same strongest-intent shared movement path; analogue, touch, and conflict tests pass |
| Collision | Same 15 px centered circle; cardinal, diagonal, and wall collision tests pass |
| Camera | Same smoothed `Camera2D`; resize and camera assertions pass |
| Echo Pulse | Radius, cooldown, loudness, reveal, and enemy-risk behavior unchanged; visual/noise origin moved to scanner marker |
| Decoy | Aim, wall clamp, trajectory, center launch, charges, and Listener diversion unchanged |
| Listener detection | Listener code and hearing behavior unchanged; Phase 06 and full routes pass |
| Death and captured flow | Existing `round_state_changed` event drives captured pose; Phase 10 passes |
| Restart/reload | New Player instance restores ready scanner, 2/2 decoys, no threat/capture, zero pulse count |
| Pause | Player physics remains pausable; animation freezes through round-state pause feedback |

## Test evidence

### Dedicated operative coverage

`tests/human_rescue_operative_test.gd` verifies:

- Procedural-only construction and all eight human body/equipment parts.
- 60 × 54 effective dimensions and unchanged 15 px collision.
- All eight mouse-facing directions and movement-direction fallback.
- Keyboard and analogue joystick paths.
- Delta-driven idle and movement animation state.
- Scanner readiness, activation flash, cooldown, and exact Echo origin.
- Decoy target and trajectory preservation.
- Cached nearby-threat state and captured feedback.
- Contrast against every floor/wall palette in all three sectors.
- 1280×720, 1024×768, and 1600×900 footprint/camera checks.
- Fresh-instance restart/reset state.

### Regression coverage

The complete 22-script headless suite covers Phases 01–15 plus vertical-slice, content, environment, tutorial, visibility, joystick, and operative regressions. The long route tests traverse all sectors, three relays, Listener encounters, decoy withdrawals, extraction, Victory, death, restart, and Main Menu return.

### Web render notes

The release Web export was rendered in Chromium using WebGL 2 / Godot Compatibility, single-threaded:

- **1280×720:** right-facing operative remained readable beside the entry corridor and all HUD safe zones remained separate.
- **1024×768:** upward-facing operative remained readable after resize; helmet, torso, separate limbs, pack, orange band, and scanner were distinguishable.
- **Pulse frame:** the large Echo ring visibly began at the raised handheld scanner instead of the torso center; the device showed a stronger white-cyan activation flash.
- Browser console showed normal engine, Compatibility/WebGL, single-threaded, audio-gesture, ambience, and pulse-cue messages with no errors.

Temporary QA captures were intentionally not added as game assets or committed into the release package.

## Acceptance checklist

| Requirement | Result |
|---|---|
| Human at normal gameplay scale | PASS |
| Helmet, torso, two arms, two legs | PASS |
| Rescue pack and handheld scanner | PASS |
| Not a circle, ship, cursor, eye, or robot orb | PASS |
| Procedural/vector construction; no AI image | PASS |
| 48–64 px effective footprint | PASS — 60 × 54 |
| Existing collision retained | PASS |
| Mouse and movement fallback facing | PASS |
| Four cardinal directions minimum | PASS — eight directions |
| Walking, idle, ready, flash, cooldown animation | PASS |
| Threat and captured feedback | PASS |
| Movement/camera/decoy/detection/death/restart preserved | PASS |
| Visibility across authored floor zones | PASS |
| Common browser resizing | PASS |
| Compatibility/Web export | PASS |
| No warnings or broken references | PASS |

## Final result

**PASS** — the Player is now a clearly human top-down rescue operative with an immediately readable facing direction, procedural locomotion, a handheld Echo device, and state feedback. The redesign remains asset-free, Web-compatible, aligned with the existing collision body, and regression-safe across the complete game flow.
