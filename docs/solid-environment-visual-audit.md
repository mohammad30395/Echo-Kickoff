# Solid Environment Visual Audit

Date: 2026-07-17

Project: Echo Kickoff

Renderer: Godot 4 Compatibility (`gl_compatibility`)
Result: **PASS**

## Scope and source review

This pass was performed against the locked game concept and the revised visual system documented in:

- `docs/visual-revision-notes.md`
- `docs/visual-pass-audit.md`
- `docs/visibility-system-revision-audit.md`
- The authored Orientation, Laboratory, and Extraction sector scenes and scripts
- The reusable reveal, interaction, relay, door, extraction, Listener, Player, and Echo implementations

No gameplay route, mission rule, AI behavior, control, audio balance, or external asset was added. The change replaces the transparent wireframe presentation with solid procedural environment rendering while preserving the existing collision and scene architecture.

## New colour palette

| Role | Orientation corridor | Resonance laboratory | Extraction sector | Use |
| --- | --- | --- | --- | --- |
| Base floor | `(0.025, 0.075, 0.120, 1.0)` navy | `(0.022, 0.075, 0.095, 1.0)` deep teal | `(0.020, 0.080, 0.085, 1.0)` green-black | Fully opaque facility foundation |
| Primary panel | `(0.040, 0.130, 0.190, 1.0)` steel blue | `(0.035, 0.130, 0.145, 1.0)` teal steel | `(0.030, 0.130, 0.130, 1.0)` dark green-cyan | Alternating solid floor panels |
| Room surface | `(0.045, 0.150, 0.205, 1.0)` blue | `(0.045, 0.145, 0.150, 1.0)` laboratory teal | `(0.040, 0.150, 0.140, 1.0)` extraction green | Circular room and platform identity |
| Corridor surface | `(0.050, 0.170, 0.220, 1.0)` | `(0.050, 0.170, 0.170, 1.0)` | `(0.045, 0.180, 0.150, 1.0)` | Door vestibules and technical lanes |
| Primary accent | `(0.220, 0.780, 0.880, 1.0)` cyan | `(0.200, 0.720, 0.740, 1.0)` teal | `(0.200, 0.860, 0.660, 1.0)` green-cyan | Sector trim, platforms, lanes, boundaries |
| Secondary accent | `(0.260, 0.430, 0.680, 1.0)` steel blue | `(0.480, 0.330, 0.720, 1.0)` violet | `(0.200, 0.550, 0.660, 1.0)` blue-green | Props and room differentiation |
| Wall body / trim | navy steel / cyan | deep teal / teal-cyan | dark green-teal / green-cyan | Solid wall mass and luminous technological edge |
| Relay energy | dark blue with gold `#FFAD3D` | dark blue with gold `#FFAD3D` | dark blue with gold `#FFAD3D` | Reactor grids and inactive relay state |
| Restricted / danger | muted purple-red with orange-red | muted purple-red with orange-red | muted red-green with orange-red | Listener zones, hazards, locked states |

All base, panel, room, and corridor fills use full alpha. Saturated colours are reserved for narrow trim, state indicators, Echo response, and warnings so the environment remains dark without reverting to transparency.

## Reusable visual components

### `EchoRevealable`

The reveal base now supports an opt-in solid-body mode. Environment and interactable bodies retain a dark near-opaque fill at ambient strength while their luminous colour and outline still respond to local visibility and Echo. Listener visuals do not opt in, so enemies remain concealed outside an active reveal.

### `FacilitySector`

One sector node batches the following procedural details in custom drawing rather than creating decorative child nodes:

- Fully opaque base and alternating panel field
- Solid connection vestibules and corridor lanes
- Room-specific circular surfaces and layered platforms
- Relay-zone gold reactor grids
- Listener-zone muted red/orange danger rings and markings
- Subtle minor and major grids
- Narrow boundary trim, corner marks, and sector signatures

### `EchoRevealPrimitive`

The existing reusable primitive now supplies:

- Solid walls with backing shadow, steel body, inset face, lighter top/inner band, darker depth band, panel seams, end caps, corners, and reveal-reactive trim
- Solid crates with reinforced corners
- Solid circular floor machinery with core, vents, and radial connections
- Solid warning panels with industrial stripes and status lights
- Existing floor boundaries, doors, terminals, hazards, and enemy placeholders retained on the Compatibility-safe custom drawing path

### Interactable visuals

- Reactor relays use a substantial machine body, inactive gold core, active cyan energy core, base feet, and Echo response.
- Facility doors use a solid portal, top and lower depth bands, reinforced panels, status bars, and shape-plus-colour state symbols.
- The extraction terminal/gate uses a solid circular platform, side rails, frame, status bar, and locked/available/complete symbols.

## Rooms updated

| Area | Visual identity and authored treatment | Result |
| --- | --- | --- |
| Orientation corridor | Opaque navy/steel floor panels, cyan lanes and structural trim, blue secondary props, circular orientation platforms | PASS |
| Resonance laboratory | Deep teal panels, violet secondary accents, two gold reactor-grid relay zones, muted orange/red first-Listener warning zone | PASS |
| Reactor relay areas | Dark blue machinery surfaces, gold grid and inactive energy details, high-contrast cyan active state | PASS |
| Extraction area | Dark green-cyan panels and lanes, green-cyan trim, Relay C gold grid, southern Listener warning zone | PASS |
| Dangerous Listener zones | Restricted dark purple/red surfaces and limited orange/red arcs/stripes; enemy itself remains concealed until Echo or alert feedback | PASS |

## Door and mission-object state language

| State | Shape and colour language | Result |
| --- | --- | --- |
| Normal closed | Cyan solid paired panels with circular/vertical center mark | PASS |
| Normal open | Separated green-cyan panels with outward chevrons | PASS |
| Locked | Orange-red panels with crossed center mark | PASS |
| Relay-controlled | Violet paired nodes linked through a diamond circuit | PASS |
| Extraction locked | Orange-red gate frame with crossed center | PASS |
| Extraction available | Green-cyan powered center line and ring | PASS |
| Extraction complete | Filled green-cyan extraction diamond | PASS |
| Relay inactive / active | Gold barred core / cyan energized diamond and arcs | PASS |

State names are exposed by the reusable visual components and covered by automated checks, so readability is not inferred from colour alone.

## Visibility and contrast validation

| Condition | Observation | Result |
| --- | --- | --- |
| Normal ambient | Floors and wall bodies are solid, dark, and physically readable; fine trim remains restrained. | PASS |
| Local player visibility | Nearby outlines increase above ambient without publishing noise; collision edges remain clearer than distant structure. | PASS |
| Echo Pulse | The cyan expanding ring brightens reached structural trim and orange danger/object states; Echo remains the strongest information layer. | PASS |
| Player / wall contrast | The white-cyan Player core remains over three times the representative wall-body luminance. | PASS |
| Enemy / danger contrast | Listener passive visibility remains disabled; revealed/chasing enemies use red-orange danger contrast. | PASS |
| Relay visibility | Relays have solid silhouettes and distinct gold inactive/cyan active feedback, including a reveal spike on activation. | PASS |

The solid-body fill does not flatten the reveal mechanic: body mass remains dark and stable, while `ambient outline < local outline < Echo outline` remains true. Distant enemy information is still withheld until earned through active sound.

## Performance and Web compatibility

- No fullscreen shader, CanvasItem shader, external JavaScript library, texture atlas, or photographic background was added.
- New floor detail is batched into the existing sector node's `_draw()` call.
- Wall depth and prop detail reuse the existing revealable nodes; no tiny decorative-node field was created.
- The new environment scripts add no `_process()` loop, physics query, scene-tree scan, or per-frame allocation path.
- Release Web export uses `variant/thread_support=false` and the Compatibility renderer.
- Fresh Windows release export also completed without warnings or broken references.

Chromium Web measurements on the release export:

| Scenario | Viewport | Frames sampled | Average | p95 frame time | Console errors |
| --- | --- | ---: | ---: | ---: | ---: |
| Ambient gameplay | 1280 × 720 | 181 over 3 seconds | **60.21 FPS** | 17.3 ms | 0 |
| Active Echo window | 1280 × 720 | 49 over 0.8 seconds | **60.10 FPS** | 17.6 ms | 0 |
| Resized gameplay | 1024 × 768 | Exact canvas-to-viewport match | Stable | No layout break observed | 0 |

Post-test JavaScript heap use was approximately 9.8 MB. Browser DOM node count remained 47; the Godot world renders inside one canvas. Firefox 152 reached the Godot Web loader in a headless smoke launch; the full interactive and measured browser gate was performed in Chromium because Firefox's command-line screenshot was captured before WASM startup completed.

## Before / after observations

### Before

- The floor read mainly as a near-black grid.
- Wall bodies and props were multiplied down to roughly five percent ambient alpha, leaving outlines without physical mass.
- Platforms, machinery, and warning objects appeared ghosted or debug-like.
- Room identity depended mostly on sparse line motifs.
- The world looked like a transparent collision/debug visualization.

### After

- The entire playable facility sits on opaque navy, teal, steel-blue, and green-cyan floor surfaces with alternating panels.
- Corridors, rooms, relay areas, extraction routes, and Listener danger zones have distinct but coherent colour identities.
- Walls remain clearly separate from the floor without Echo because they have solid mass, depth bands, seams, corners, caps, and technological trim.
- Crates, machinery, warning panels, relays, doors, and extraction structures have substantial silhouettes.
- Echo remains meaningful because it drives the strongest luminous outline, scan ring, state contrast, and enemy revelation rather than merely making transparent bodies visible.

## Verification record

- Godot editor/headless script scan: PASS, no parse errors or broken references.
- Focused `solid_environment_visual_test.gd`: PASS.
- Complete automated suite: **21/21 PASS**, including gameplay routes, collision, visibility, Listener AI, relays, decoy, round states, audio, UX, joystick, release-candidate, and visual regressions.
- Fresh Web release export: PASS.
- Fresh Windows release export: PASS.
- Chromium 1280 × 720 ambient/Echo capture and performance sampling: PASS.
- Chromium resize to 1024 × 768 with exact canvas fit and safe HUD bounds: PASS.
- Browser console error inspection: PASS, zero errors.
- Compatibility performance during Echo: PASS.
- Native Compatibility-rendered state sheet covering four door states, three extraction states, and two relay states: PASS; all nine silhouettes and palettes were visually distinct.

## Final result

**PASS** — Echo Kickoff no longer presents its facility as a transparent wireframe prototype. Floors, walls, props, mission objects, doors, and extraction structures now use solid procedural surfaces with coherent room identities, clear state language, retained darkness, preserved Echo risk/reward, Web-safe rendering, and measured 60 FPS Compatibility performance.
