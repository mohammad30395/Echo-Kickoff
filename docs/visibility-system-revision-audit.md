# Echo Kickoff — Visibility System Revision Audit

Date: **2026-07-17**

Result: **PASS**

## Revision boundary

This revision clarifies the existing darkness/reveal design without changing the locked mission, map topology, movement, objectives, enemy behavior, noise values, win/lose rules, or release targets. It remains Godot 4, typed GDScript, Compatibility renderer, keyboard/mouse, Web, and Windows.

No external asset, shader, post-process, dynamic light, or new gameplay feature was introduced.

## Three-layer visibility architecture

| Layer | Implemented behavior | Player information | Risk |
|---|---|---|---|
| Ambient world | Deep navy floor, restrained cyan grid/room marks, and 0.08 architectural outline baseline | Broad orientation and environmental mood; the facility is no longer an undifferentiated black screen | None |
| Passive local awareness | 52 px full-strength inner zone fading to a 148 px boundary; object response capped at 0.32; four bounded procedural floor discs | Nearby floor and immediate collision edges needed for deliberate movement | Silent; does not reveal Listeners |
| Active Echo | 345 px expanding luminous ring and full reveal response | Strong, temporary long-range structure and threat information | Publishes the existing 500 px `echo_pulse` noise event and alerts hearing enemies |

The hierarchy is therefore **ambient < local awareness < active Echo**. Local awareness supports control, but its smaller range, capped object strength, and enemy exclusion preserve Echo as the primary scouting action.

## Reusable Player ownership

The passive visibility system now belongs to the reusable Player scene rather than to one level:

```text
Player (CharacterBody2D)
├── CollisionShape2D
├── LocalAwareness (PlayerLocalAwareness)
├── Visuals
├── Camera2D
├── PulseController
├── LocalVisibility (LocalVisibilityController)
├── DecoyController
└── InteractionController
```

- `PlayerLocalAwareness` draws the bounded floor zone once with CanvasItem circles/arcs and follows the Player through its parent transform. It has no `_process()` loop and no material.
- `LocalVisibilityController` self-binds to its parent Player, synchronizes the visual and object radii, caches eligible `echo_revealable` nodes once, and updates bounded distance falloff at most every 80 ms.
- The final facility no longer owns or manually binds a special-case local controller.
- Revealable walls, doors, props, terminals, and objectives retain passive local response. Listener visuals explicitly opt out.

## Demonstration and onboarding

`scenes/debug/player_test_room.tscn` now demonstrates all three layers in one room:

- brighter deep-navy ambient floor and low-alpha cyan grid;
- circular spawn platform and lane marks for pulse-free orientation;
- the reusable Player's bounded local floor glow and nearby edge response;
- distant wall, door, terminal, hazard, interactables, and Listener for active-Echo comparison;
- a browser-safe legend naming `AMBIENT`, `LOCAL`, and `ECHO` and the risk attached to Echo.

The final facility onboarding remains concise: movement first explains that the local glow shows nearby space; the following prompt explains that pulse scouting reaches farther. After the first pulse, the existing tutorial immediately states that it also calls Listeners. The cooldown HUD reinforces `LOCAL NEAR // ECHO FAR + DANGER` with text plus the existing icon/bar feedback.

## Performance and Compatibility review

- No full-screen shader, viewport texture, particle system, dynamic light, or Compatibility-unsafe rendering feature was added.
- The local floor zone is four circles and nine short arcs drawn only when created or accessibility color settings change.
- Local object visibility remains a cached, 12.5 Hz bounded distance calculation: 118 eligible final-level revealables, or approximately 1,475 distance evaluations per second.
- No per-frame scene-tree scan and no additional physics query were introduced.
- Active Echo remains capped at one simultaneous effect and retains its existing bounded target collection.
- The release Web export remains single-threaded; no `*.worker.js` file is present.

Live Chromium/WebGL2 sample after keyboard-starting the release build:

| Measurement | Result |
|---|---:|
| Animation frames sampled | 175 |
| Mean frame time | 16.66 ms |
| Calculated mean rate | 60.02 FPS |
| p95 frame time | 17.70 ms |
| Maximum frame time | 17.80 ms |
| JavaScript heap used | 9,839,028 bytes |
| Runtime documents / frames | 1 / 1 |
| Console warnings or errors | 0 |

These heap figures cover the JavaScript loader, not total WebAssembly memory.

## Acceptance verification

| Required check | Evidence | Result |
|---|---|---|
| Navigate nearby without pulsing | The Player moved from spawn to the center wall, received increasing local edge visibility, stopped at the CharacterBody2D collision boundary, and emitted zero Echo pulses. | PASS |
| Long-range information requires Echo | A door beyond 148 px but within 345 px remained outside passive visibility and was reached by the real expanding Echo wave. | PASS |
| Echo remains a meaningful information spike | The sampled door outline exceeded twice its ambient alpha; Echo also revealed an in-range Listener and published `echo_pulse`. | PASS |
| Enemies are not overexposed | Listener visuals reject passive local visibility and retain a no-Echo outline alpha of 0.012 or less. | PASS |
| Three visual layers are distinguishable | Live browser captures show ambient structure, the bounded local glow, and the much larger/brighter Echo ring. | PASS |
| UI explains the hierarchy | Test-room legend, movement/pulse onboarding, post-pulse danger lesson, and pulse HUD all use concise icon-plus-text feedback. | PASS |
| Browser resizing and focus | Enter started the game, D moved the Player, Space emitted Echo, the canvas held focus, and a 1024×768 resize produced a 1024×768 canvas with no overflow. | PASS |
| Web performance | 175-frame sample held a 16.66 ms mean and 17.70 ms p95 with no console warning/error. | PASS |
| Godot import and resources | Headless editor import exited 0 with no parse error, warning, or broken reference. | PASS |
| Previous behavior | Every Phase 01–15 test, the prior visual-pass test, and the new revision test passed. | PASS |

## Export verification

| Target | Artifact evidence | Result |
|---|---|---|
| Web release | `index.html` plus PCK, WASM, JavaScript, icons, and audio worklets; PCK 513,288 bytes; no thread worker | PASS |
| Windows release | PE32+ x86-64 executable plus matching 513,288-byte PCK | PASS |

The verification artifacts and browser screenshots are retained under ignored `build/visibility-revision/`; they are QA evidence, not committed source or submission-package replacements.

## Automated coverage

- `tests/visibility_system_revision_test.gd`: reusable ownership, synchronized target radii, ambient floor, silent local layer, real movement/collision, active Echo range/risk, Listener concealment, UI copy, and Web-safe performance guards — PASS.
- `tests/phase_03_player_test.gd`, `phase_04_reveal_test.gd`, `phase_05_echo_pulse_test.gd`, and `visual_pass_test.gd` — PASS.
- Complete Phase 01–15 regression set — PASS.
- `git diff --check` — PASS.

## Asset and compliance review

The new local-awareness presentation is original procedural GDScript using Godot built-in CanvasItem drawing. `docs/04-asset-ledger.md` updates VIS-001 and VIS-003 with the Player-owned local floor zone and reusable cached controller. No copyrighted or third-party asset was added, and the approved engine, renderer, language, input, and export constraints remain satisfied.

## Decision

**PASS** — Echo Kickoff now provides ambient readability and a reliable silent local navigation zone while keeping active Echo visibly stronger, significantly farther-reaching, temporary, and dangerous. The revised system preserves stealth tension, enemy concealment, Web performance, and the locked scope.
