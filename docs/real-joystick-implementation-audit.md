# Echo Kickoff — Real Joystick Implementation Audit

Date: 2026-07-17 (Asia/Dhaka)

Target: Godot 4.7, GDScript, Compatibility renderer, Web and Windows

Result: **PASS**

## Scope and decision

The former optional bottom-left movement pad has been upgraded in place to a visible-by-default, fully functional analogue virtual joystick. It is anchored in a 240 × 240 safe area at the bottom-right, supports mouse and touch dragging, shares the existing `TopDownPlayer` movement path, and cannot leak a left-button drag into Echo Pulse.

No external asset, JavaScript gameplay library, shader, particle system, C#, GDExtension, Phaser.js, or Three.js dependency was introduced.

## Scene and scripts changed

| File | Change |
|---|---|
| `scenes/ui/movement_aid.tscn` | Repositioned the control to a bottom-right 240 × 240 safe area with 40 px edge margins; added joystick and state labels. |
| `scripts/ui/movement_aid.gd` | Replaced the desktop pad behavior with an analogue mouse/touch joystick, active pointer ownership, dead zone, partial output, auto-centering, round-state gates, Echo conflict guard, and procedural sci-fi drawing. |
| `scenes/ui/accessibility_settings_panel.tscn` | Replaced the old checkbox with a keyboard-focusable joystick mode selector. |
| `scripts/ui/accessibility_settings_panel.gd` | Added the three visibility choices and manager synchronization. |
| `scripts/autoload/accessibility_manager.gd` | Added session-persistent `Always Show Joystick`, `Auto Show on Touch`, and `Hide Joystick` modes; default is Always Show. |
| `scripts/entities/player.gd` | Routes joystick output into the existing acceleration, deceleration, collision, pause, and physics path; selects the stronger intentional source instead of summing inputs. |
| `scripts/entities/player_pulse_controller.gd` | Rejects left-mouse Echo events captured by the visible joystick safe area. |
| `scenes/ui/pulse_cooldown_hud.tscn` | Moved the Echo Pulse HUD above the joystick. |
| `scripts/ui/pulse_cooldown_hud.gd` | Preserves the authored responsive position when the release-only debug row is hidden. |
| `scripts/levels/echo_facility.gd` | Retains Player binding and updates the movement tutorial wording for the visible joystick. |
| `scripts/ui/main_menu.gd` | Updates How to Play copy. |
| `scenes/ui/pause_menu.tscn` | Updates the controls summary. |
| `tests/joystick_ui_revision_test.gd` | Covers the real joystick behavior, touch/mouse isolation, terminal states, settings, and responsive layout. |
| `tests/phase_14_ux_test.gd` | Covers the new keyboard-focusable three-mode setting. |
| `tests/tutorial_revision_test.gd` | Covers visible and hidden joystick tutorial wording. |

The existing `MovementAid` class and scene resource names were retained to avoid breaking the already-decoupled HUD/facility binding. Their runtime behavior is now the real joystick described here.

## Runtime scene structure

```text
EchoFacility
└── HUDLayer (CanvasLayer)
    └── HUD (Control, full rect)
        ├── TopLeftHudStack
        │   ├── ThreatStatusHud
        │   └── DecoyHud
        ├── OnboardingHud
        ├── ObjectiveHud
        ├── InteractionPromptHud
        ├── PulseCooldownHud
        └── MovementAid (real virtual joystick)
            ├── Title
            └── StateLabel
```

## Input flow

1. `MovementAid._gui_input()` accepts left-mouse, `InputEventScreenTouch`, and `InputEventScreenDrag` input inside its reserved area.
2. The first valid pointer owns the drag through `active_pointer_id`. Other fingers and touch-emulated mouse presses cannot hijack it.
3. Displacement beyond the 0.15 dead zone becomes a continuous `Vector2` from 0.0 to 1.0. A half displacement produces half movement speed; full diagonals remain length 1.0.
4. `TopDownPlayer` compares the joystick vector with `Input.get_vector()` from WASD/arrows and uses the stronger intentional source.
5. The selected vector follows the one existing deterministic `_physics_process()` path: acceleration, deceleration, `max_speed`, `move_and_slide()`, collision, and pause behavior.
6. Mouse/touch release, setting hide, pause, Main Menu, Game Over, Victory, or tree exit clears the vector and returns the knob to center. Player deceleration then reaches zero normally.

Input isolation:

- The joystick consumes left-clicks throughout its 240 × 240 safe area.
- `PlayerPulseController` also checks the `virtual_joystick` group before accepting a left-mouse Echo action, providing a second explicit guard.
- Space still emits Echo regardless of pointer position.
- Left mouse outside the joystick still emits Echo.
- The control uses mouse pass-through for non-left buttons, so Q and right-mouse decoy input remain available, including while the pointer is over the joystick.
- Menu buttons are in separate scenes and are unaffected.

## Joystick geometry and visual states

| Property | Value |
|---|---:|
| Reserved safe area | 240 × 240 px |
| Right/bottom safe margin | 40 px |
| Outer radius | 76 px |
| Knob radius | 34 px |
| Dead zone | 0.15 |
| Start interaction padding | 20 px beyond outer radius |
| Output | Continuous `Vector2`, length 0.0–1.0 |

The inactive state uses a translucent dark control plate, cyan double ring, dead-zone ring, four directional arrow marks, and a centered outlined knob. During drag, the knob moves within the visible range, brightens, gains a cyan halo, and the text reports live output strength. High-contrast mode continues to remap the cyan/panel colors through `AccessibilityManager`.

## HUD positions

| Element | Anchored safe zone |
|---|---|
| Threat indicator | Top-left at (20, 20) |
| Decoy indicator | Top-left stack at (20, 98) |
| Tutorial | Top-centre, 20 px from top |
| Mission objective | Top-right, 20 px right margin |
| Interaction prompt | Bottom-centre |
| Pulse cooldown | Bottom-right above joystick: horizontal offsets -350 to -20; release runtime vertical offsets -412 to -328 |
| Joystick | Bottom-right: offsets -280 to -40 on both axes |

At 1280 × 720, the Pulse HUD occupies `(930, 308)` to `(1260, 392)` and the joystick safe area occupies `(1000, 440)` to `(1240, 680)`, leaving 48 px vertical separation. At 1024 × 768, they occupy `(674, 356)` to `(1004, 440)` and `(744, 488)` to `(984, 728)`, again leaving 48 px. They do not overlap.

## Settings behavior

| Setting | Behavior |
|---|---|
| Always Show Joystick | Visible immediately; **default**. |
| Auto Show on Touch | Hidden until the first touch input in the current application session, then visible. |
| Hide Joystick | Hidden and any active vector is cleared. |

The selected enum and detected-touch state live in the `AccessibilityManager` autoload, so they survive scene changes during the current session. They intentionally reset when the application/browser page is restarted; no persistent disk or browser storage was added.

## Verification

### Automated Godot checks

All 20 current headless test scripts passed, including the complete Phase 01–15 regression suite and the visual, visibility, tutorial, and joystick revision tests.

Focused joystick coverage passed for:

- WASD movement and arrow-action compatibility.
- Default Always Show behavior and all three settings modes.
- Full cardinal drag and normalized diagonal output.
- Partial 0.5 analogue output producing 0.5 Player target speed.
- Strongest-intent keyboard/joystick selection.
- Collision/acceleration/deceleration through the existing Player controller.
- Mouse release and touch release returning to center.
- Player decelerating to a full stop after release.
- Multi-touch pointer ownership and touch-emulated mouse protection.
- Pause, resume/restarted-round, Game Over, and Victory input gates.
- Echo outside the joystick and no Echo inside it.
- Right mouse remaining a valid decoy input.
- Pairwise HUD non-overlap and safe browser bounds.

### Browser checks

A fresh release Web export was tested in Chromium 150 at:

| Resolution | Result |
|---|---|
| 1280 × 720 (16:9) | PASS — joystick remained 40 px from the right/bottom safe edges; all HUD zones were readable and separate. |
| 1024 × 768 (4:3) | PASS — canvas resized exactly, no page scroll, no HUD overlap, and keyboard focus remained on `CANVAS`. |
| 1600 × 900 (16:9) | PASS — automated anchor, safe-boundary, and pairwise-overlap assertions. |

Live browser actions passed:

- Mouse drag visibly moved and brightened the knob and moved the Player.
- Release visibly returned the knob to center.
- CDP-dispatched touch drag visibly moved the knob; release returned it to center.
- A left click inside the joystick produced no Echo ring or cooldown.
- A left click outside produced the Echo ring, cooldown, and danger tutorial.
- A right click over the joystick reduced decoy charges from 2/2 to 1/2.
- WASD, Arrow Down, pause, Resume, resize, and canvas focus remained functional.
- Browser diagnostics recorded zero runtime, page-log, or network errors.
- A 120-frame sample at 1024 × 768 averaged 16.61 ms per frame (approximately 60 FPS).

Fresh Compatibility release exports completed for both Web and Windows. Both generated PCKs are 545,196 bytes and share SHA-256 `0f69a78e61a37b40524c23cac03a8daa8170ed812ff951cff797be883e92fbbf`.

## Known limitations

- Touch behavior was verified with Godot `InputEventScreenTouch`/`InputEventScreenDrag` tests and Chromium touch-event dispatch, not a physical touchscreen device.
- The visibility preference lasts for the current application session only, exactly as requested; it does not survive a browser reload or application restart.
- The joystick is a movement control, not a complete mobile control scheme. Echo, decoy, interaction, and pause retain the locked keyboard/mouse controls.
- The 240 × 240 bottom-right reservation intentionally reduces unobstructed playfield space in that corner.
- The Windows release exported successfully on macOS but was not launched on Windows hardware during this audit.

## Final decision

**PASS** — the bottom-right virtual joystick is clearly visible by default, procedurally styled, analogue, mouse- and touch-functional, multi-touch-safe, responsive across tested browser aspect ratios, integrated into the existing Player controller, isolated from Echo Pulse, compatible with decoy and keyboard input, disabled in non-playing states, and separated from every required HUD element.
