# Echo Kickoff — Joystick and UI Revision Audit

Date: 2026-07-17  
Scope: optional on-screen movement aid and player-facing HUD refinement  
Renderer/platform target: Godot 4 Compatibility, Web and Windows  
Result: **PASS**

## Scope decision

The selected movement option is a compact joystick-like drag pad in the bottom-left safe zone. It is an optional desktop-browser accessibility aid, not a mobile-control conversion and not a replacement for keyboard and mouse.

- Keyboard and mouse remain the complete, primary control scheme.
- The pad is disabled and hidden by default.
- The player can enable it from the existing Accessibility panel on the main menu or pause menu.
- The pad uses original procedural drawing and no external asset.
- UI scale was not added. The anchored responsive layout already preserves readable sizing and separation at the supported browser dimensions; arbitrary scaling would create avoidable collision risk this late in the frozen scope.

## Runtime architecture

| Part | Responsibility |
|---|---|
| `AccessibilityManager` | Owns the run-persistent `movement_aid_enabled` setting and emits a dedicated state-change signal without changing the existing accessibility signal contract. |
| `MovementAid` | Draws the circular pad, accepts a bounded left-button drag, applies a dead zone and maximum radius, and sends a normalized direction directly to the bound Player. |
| `Player` | Combines the optional pad vector with the existing keyboard vector and limits the result to length 1 before the existing acceleration, collision, and deterministic physics path. |
| `EchoFacility` | Binds the reusable pad to the active Player and binds the threat HUD to the facility's cached Listener list. |
| `HudFrame` | Supplies the shared dark translucent panel, accent line, brackets, scan line, warning palette, and high-contrast response. |
| `ThreatStatusHud` | Aggregates Listener state changes through signals and reports only QUIET, ALERT, SEARCH, CONTACT, or FADING; it never exposes an enemy position. |

The movement aid does not synthesize `Input.action_press` events. A press must start inside its own rectangle, right mouse is ignored, and an active drag is cleared on release, hide/disable, pause, main-menu transition, or tree exit. It has no `_process()` loop, shader, touch event, physics query, or scene-tree scan.

## HUD hierarchy and safe zones

| Zone | Content | Hierarchy |
|---|---|---|
| Top left | Threat state, then decoy charges | Stable `VBoxContainer`; threat is cyan in quiet states and warning-colored when danger rises; decoy remains gold and shows icon plus `CHARGES n/n`. |
| Top center | Progressive tutorial | Short stage tag plus one concise instruction; the message remains temporary and run-local. |
| Top right | Mission objective | Reactor-grid title, three relay indicators, extraction LOCKED/POWERED state, icon, and exact count. |
| Bottom left | Optional movement aid | Labeled circular pad with neutral and active states; hidden when disabled. |
| Bottom center | Interaction prompt | Facility-interface label, icon plus text, action state, and progress bar. |
| Bottom right | Echo status | `LOCAL NEAR // ECHO FAR SCAN`, exact readiness percentage, cooldown bar, and explicit revelation-plus-danger warning. |

The two top-left panels use a single layout owner because independently instanced top-left Control roots briefly initialized at the origin in the Web export. The stable stack removes that browser-only overlap and is covered by exact-position and pairwise-intersection assertions.

## Input and navigation verification

| Check | Evidence | Result |
|---|---|---|
| Default keyboard-only play | Pad begins hidden; `WASD`/arrows still drive the original Player path. | PASS |
| Enabled pad movement | A real left-button drag moved the player and advanced the movement tutorial. | PASS |
| Direction and speed | Cardinal drag, keyboard-plus-pad diagonal normalization, dead zone, and maximum vector length are asserted. | PASS |
| Input isolation | Outside presses are rejected; right mouse never starts a drag; left mouse outside the pad still fires Echo; right mouse still throws a decoy. | PASS |
| Transient-state cleanup | Release, setting disable/hide, and pause clear both pad and Player vectors. | PASS |
| Keyboard focus | Canvas retained focus; Escape opened pause and Enter activated focused Resume. | PASS |
| Settings navigation | The new checkbox participates in the existing keyboard focus chain and works by mouse. | PASS |

## Browser and visual verification

Chromium 150 was run from the release Web export through a local HTTP server. The in-app browser endpoint was unavailable in this environment, so the same page was exercised through Chrome's local debugging protocol.

| Check | Observed result | Result |
|---|---|---|
| 1280×720 | All HUD zones remained inside the canvas; the pad stayed below the player focus and did not cover objectives, threat, decoy, tutorial, interaction, or cooldown information. | PASS |
| 1024×768 resize | Canvas became exactly 1024×768 with zero page scroll; the same zones stayed separated and readable. | PASS |
| 1600×900 | Automated anchor and pairwise-overlap verification passed. | PASS |
| Mouse actions | Left click produced the broad Echo ring and danger state; right click reduced decoys from `2/2` to `1/2`. | PASS |
| Pause/resume | Pause dimmed the HUD, retained the enabled setting, and resumed through focused keyboard activation. | PASS |
| Console | 0 page-log errors or runtime exceptions during the final interaction/resize pass. | PASS |
| Browser focus/audio gate | Active element remained `CANVAS`; the game was started through a user click, preserving the existing Web audio gate. | PASS |

## Performance and compatibility

- 120-frame Chromium sample at 1024×768: mean `16.64 ms`, 95th percentile `17.70 ms`, maximum `17.70 ms` (approximately 60 FPS).
- Browser runtime snapshot: 1 document, 1 frame, 47 DOM nodes, and 12,250,040 bytes of JavaScript heap in use.
- The movement aid is event-driven and allocates no object per rendered frame.
- The threat HUD uses Listener signals and the facility's cached Listener references rather than scanning the scene tree.
- The shared frame uses CanvasItem primitives only. No shader, viewport effect, particle system, external library, C#, GDExtension, touch API, or renderer-specific feature was added.
- Fresh release exports completed for `Web` and `Windows Desktop` with the Compatibility renderer.

## Regression coverage

`tests/joystick_ui_revision_test.gd` verifies the new control and HUD requirements. The existing Phase 01–15 tests, visual-pass test, and revised visibility-system test were also run after the final layout change. All passed without script warnings, broken references, or changed gameplay contracts.

The visual audit additionally confirmed:

- Echo remains the strongest broad reveal and still communicates danger.
- Local awareness remains weaker, bounded, and silent.
- The threat HUD communicates Listener behavior without revealing a Listener location.
- Relay, extraction, decoy, interaction, tutorial, and cooldown states preserve icon-plus-text feedback.
- High-contrast color overrides still propagate through the revised procedural frames.

## Asset and scope review

The revision introduces no external asset. The procedural frame, movement aid, and threat-state display are recorded as `VIS-013` in `docs/04-asset-ledger.md`; planned entry `P-UI-01` is marked fulfilled. Keyboard/mouse gameplay remains fully functional when the option is disabled.

No mobile/touch support, virtual action remapping, new gameplay mechanic, enemy-location radar, UI framework, or third-party dependency was added. This stays within the locked GDD and frozen GameJam scope.

## Acceptance result

- Optional movement control: **PASS**
- Keyboard/mouse preserved: **PASS**
- Mouse aim, Echo, and decoy isolation: **PASS**
- HUD hierarchy and state clarity: **PASS**
- Browser resizing and safe boundaries: **PASS**
- Accessibility/settings integration: **PASS**
- Compatibility/Web performance: **PASS**
- Asset provenance and scope lock: **PASS**

Final result: **PASS**
