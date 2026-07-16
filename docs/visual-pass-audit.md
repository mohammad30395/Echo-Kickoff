# Echo Kickoff — Procedural Visual Pass Audit

Date: **2026-07-17**

Result: **PASS**

## Scope

This pass improves the existing visual language without changing the locked mission, level topology, player abilities, enemy behavior, noise balance, win/lose rules, or export targets.

The implementation remains Godot 4, typed GDScript, Compatibility renderer, CanvasItem procedural drawing, keyboard/mouse, Web, and Windows. No external asset or gameplay feature was added.

## Visual-system architecture

### Visibility hierarchy

| Layer | Range / strength | Purpose |
|---|---:|---|
| Ambient world | 0.08–0.12 outline baseline on architecture and objectives | Prevents immediate collision edges and landmarks from disappearing completely. |
| Player-local visibility | 52 px full-strength inner zone fading to 148 px; capped at 0.32 of full reveal | Supports short pathing and control without exposing the complete room or route. |
| Active Echo | 345 px tuned radius; full luminous response with fade | Reveals broad layout and threats while publishing the existing dangerous noise event. |

`LocalVisibilityController` caches eligible `EchoRevealable` nodes once when the level binds, then refreshes their distance falloff every 80 ms. It does not publish a noise event, perform a physics query, scan the scene tree every frame, or reveal Listeners. Active Echo remains larger, brighter, temporary, and dangerous.

### Procedural environment vocabulary

- Floors use deep blue-black/slate base panels, minor and major cyan grid lines, inset perimeter bands, room-platform rings, connection lane marks, sector signatures, and corner brackets.
- Walls use dark navy mass, steel-blue inset panels, cyan edge bands, segment seams, caps, and shadow backing.
- Boundaries use layered perimeter lines, inset bands, and non-color-only corner brackets.
- Props use muted cool fills, inset panels, braces, and fastener marks.
- Hazard markers use orange-red fill, warning bands, outlines, and diagonal striping.
- Terminals use layered housings, screens, scan lines, buttons, and state geometry.

All geometry is static or redraws only when reveal/state values change. No full-screen shader, texture lookup, particle system, or Compatibility-unsafe feature is used.

### Role palette and state language

| Role | Implemented direction | Non-color cue |
|---|---|---|
| Player | Cyan-white core and cyan glow | Circular focal marker and facing wedge |
| Echo | Cyan-blue | Expanding double ring |
| Listener danger | Orange to red | Broken silhouette plus alert/search/chase marks |
| Relay inactive / active | Gold / bright cyan | Horizontal idle bars versus powered coils and diamond core |
| Door locked / unlocked / open | Orange-red / cyan | Cross lock, circular unlock mark, separated panels and chevrons |
| Extraction locked / powered | Orange-red / green-cyan | Cross lock versus powered core/chevrons |
| Props and structures | Muted cool blue-gray | Mass, inset panels, seams, braces, and corner treatment |

The objective HUD mirrors the relay gold/cyan and extraction orange-red/green-cyan roles while retaining icon and text feedback.

## Intentionally simple areas

- Existing authored room topology and collision remain unchanged.
- Decorative animation, particles, texture noise, post-processing, dynamic shadows, and full-screen light shaders remain cut.
- The reusable door received the new treatment, but no new door was inserted into the final level because that would change feature-frozen route behavior.
- The optional on-screen movement pad was omitted; keyboard/mouse controls and browser-safe HUD already pass, and an extra overlay did not justify its input/layout risk.
- Existing original SVG UI icons and generated branding remain unchanged.

## Performance considerations

- Cached local-visibility targets: **118** eligible revealables; the two Listeners opt out.
- Visibility refresh: **12.5 Hz** maximum, approximately **1,475 bounded distance evaluations/second** in the full facility.
- Local visibility uses no raycast and no per-frame group scan.
- Only revealables whose effective strength changes call `queue_redraw()`.
- Sector floor geometry is static and draws once unless explicitly invalidated.
- Echo remains limited to the existing simultaneous-effect cap and 64-segment rings.
- No new material, shader, texture, particle, or external dependency was introduced.

Chromium Web performance sample at 1280-wide browser launch:

| State | Frames sampled | Mean frame | Calculated FPS | p95 frame | Max frame |
|---|---:|---:|---:|---:|---:|
| Idle dark/local state | 180 | 16.672 ms | 59.98 | 17.70 ms | 17.80 ms |
| Active Echo sample | 90 | 16.656 ms | 60.04 | 17.70 ms | 17.80 ms |

Chromium reported approximately **9.17 MiB JS heap used** and **11.55 MiB total JS heap** during the idle sample. These browser numbers describe the JavaScript loader heap, not total WebAssembly memory.

## Visual and browser checks

| Check | Evidence | Result |
|---|---|---|
| Dark state | Browser capture shows player, nearby wall edge, grid panels, platforms, local orientation, objectives, and safe HUD without exposing the full facility. | PASS |
| Active Echo state | Browser capture shows a much larger cyan-blue ring, stronger wall/terminal response, and orange danger accents. | PASS |
| Echo still carries risk | Existing pulse noise and Listener tests pass; browser log records the Echo cue and tutorial danger message. | PASS |
| Objective states | Automated visual test validates gold/cyan relays and orange-red/green-cyan extraction; Phase 07/08/11 mission tests pass. | PASS |
| Door states | Automated visual test and Phase 07 interaction test validate locked, unlocked, and open geometry. | PASS |
| Enemy concealment | Both Listener visuals opt out of passive local visibility and remain at no-Echo alpha 0.012. | PASS |
| Color plus shape contrast | Player, Echo, enemy, relay, door, extraction, hazard, and structure roles have distinct palette anchors and geometry. | PASS |
| High contrast / reduced flash | Phase 14 accessibility regression passes. | PASS |
| Browser resize | Chromium canvas resized to exactly 1024×768; existing layout suite also passes 1280×720, 1024×768, and 1600×900. | PASS |
| Browser console | Compatibility/WebGL2, single-threaded, no GDExtension; no error or exception captured. | PASS |
| Web export | Release export completed in 3.46 s; PCK 509,916 bytes. | PASS |
| Windows export | Release export completed in 3.00 s; PCK 509,916 bytes. | PASS |

Browser screenshots were retained as local QA evidence in `build/visual-pass/` and are not source assets or release-package inputs.

## Automated validation

- Godot headless editor import: PASS, with no script parse error or broken resource.
- Phase 01 through Phase 15 regression scripts: PASS.
- `tests/phase_04_reveal_test.gd`: PASS with revised restrained-ambient and enemy-concealment expectations.
- `tests/visual_pass_test.gd`: PASS for visibility hierarchy, floor layering, structural vocabulary, interactable roles, enemy concealment, Compatibility safety, and performance guards.
- Full three-relay active-enemy route: PASS; 24,594 px modeled first-time route and Victory retained.
- `git diff --check`: PASS.

## Asset and provenance review

No new non-code visual asset was created. The changed artwork is original procedural GDScript using Godot built-in drawing calls. `docs/04-asset-ledger.md` records the revised VIS-003, VIS-006, and VIS-010 systems and the completed P-VIS-06/P-VIS-07 plans.

## Decision

**PASS** — the facility now has readable ambient structure, restrained player-local visibility, stronger procedural floor/wall/prop treatment, and clear mission-state color language while preserving the darkness premise and the Echo-versus-danger tradeoff. Gameplay scope and Web/Windows Compatibility constraints remain intact.
