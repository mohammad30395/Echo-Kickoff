# Echo Kickoff — Phase 04 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Darkness and echo-revealable world foundation only**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Scope alignment

Phase 4 implements the visual-reveal foundation required before the M03 expanding pulse. It establishes dark-state readability rules, reusable reveal timing, procedural facility primitives, and a room-wide debug reveal. It does not implement a pulse radius, pulse ring, sound event, enemy AI, objective, relay, extraction, or gameplay reveal collision.

## Visual-system architecture

```text
EchoRevealable (Node2D base)
├── exported reveal_duration
├── exported fade_speed
├── exported darkness_visibility
├── exported revealed_fill_alpha
├── exported luminous_color
├── receive_reveal(strength, duration_override)
├── clear_reveal()
├── reveal_changed(strength)
└── dark/fill/outline helper functions
    │
    └── EchoRevealPrimitive
        ├── Wall
        ├── Floor boundary
        ├── Door
        ├── Prop
        ├── Terminal
        ├── Hazard marker
        └── Enemy placeholder shape for future visual subclasses
```

`EchoRevealable` is a sprite-independent typed GDScript base. Any future wall, door, prop, terminal, or enemy visual can inherit it and draw with the shared fill/outline helpers. Revealable nodes join the `echo_revealable` group for discrete debug and future integration, but the base has no knowledge of the player, pulse implementation, enemies, collisions, or application UI.

`receive_reveal()` clamps incoming strength to 0–1, retains the stronger current value, holds it for the configured duration, and then fades toward zero at `fade_speed * delta`. The optional duration override allows a future pulse or other reveal source to choose a temporary hold without changing the object default. `reveal_changed` provides an event boundary for future effects or diagnostics.

## Darkness/readability model

- Revealable outlines start at 1.2% alpha and fills at half that baseline, leaving geometry nearly invisible rather than absolutely absent.
- Full reveal uses a bright cyan core outline plus a wider low-alpha outline, producing a clear luminous edge without a shader.
- Fill remains restrained at 24% maximum alpha so outlines carry the visual language.
- The near-black navy room backdrop remains stable and does not expose navigational geometry.
- The player visual is outside the reveal system and retains a high-opacity pale core and directional triangle, so control remains readable in darkness.
- Doors, terminals, props, and hazards use different geometry as well as color, supporting the GDD accessibility requirement against color-only communication.

Native 1280×720 Compatibility captures were visually inspected in both states. The dark state retained a clear player while room geometry was unreadable; the revealed state showed crisp walls, door chevrons, terminal structure, prop cross-bracing, and hazard stripes.

## Debug reveal

The `debug_reveal` input action is bound to **F1**. `PlayerTestRoom._unhandled_input()` responds by calling `receive_reveal(1.0, 1.2)` on revealables owned by that room. The action is intentionally a temporary test-room reveal, not the expanding echo pulse.

The room also accepts the explicit `--reveal-test-room` user argument for deterministic visual captures. This path exists only on the debug-room script and does not run during normal application flow.

## Procedural primitives

| Primitive | Drawing method | Shape distinction |
|---|---|---|
| Wall segment | Filled and outlined centered rectangle with axis line | Solid structural bar |
| Floor boundary | Nested rectangle outlines | Large perimeter contour |
| Door | Framed rectangle, center seam, opposing chevrons | Entry/exit motif |
| Prop | Framed rectangle with diagonal cross-bracing | Crate/block silhouette |
| Terminal | Block, inset display, three circular controls | Console silhouette |
| Hazard marker | Framed block with diagonal repeated stripes | Warning surface pattern |
| Enemy support | Broken polyline silhouette primitive | Reserved visual shape; no enemy or AI instance added |

All primitives use `custom _draw()` with `draw_rect`, `draw_line`, `draw_circle`, `draw_polyline`, and `draw_colored_polygon`-compatible CanvasItem operations. They require no image sprite, texture, font asset, material, or shader.

## Performance considerations

- No full-screen shader, sampling loop, viewport texture, light system, particle system, or post-processing pass was added.
- There are no ShaderMaterials; the system uses Compatibility-safe CanvasItem draw commands only.
- A fully dark revealable disables `_process()`. Processing starts only when reveal is received and disables again at zero strength.
- `queue_redraw()` occurs only when reveal strength changes or an exported shape setting changes.
- The F1 implementation scans the revealable group only for the discrete debug key event; there is no per-frame scene-tree scan.
- Draw loops are bounded to the local hazard marker and run only during redraw. The debug room uses eleven small primitive nodes.
- Collision bodies remain separate from visuals, preventing reveal state from changing physics behavior.
- A future pulse should deliver reveal through bounded overlap/spatial results rather than scanning all revealables every frame.

## Automated tests

Primary command:

```bash
godot --headless --path . --script tests/phase_04_reveal_test.gd
```

| Requirement | Evidence | Result |
|---|---|---|
| Nearly invisible start | All room revealables began at strength 0, outline alpha ≤ 0.02, and inactive processing. | PASS |
| Receive reveal strength | Strength 0.75 was accepted; a later weaker reveal did not reduce it. | PASS |
| Reveal duration | Strength remained stable through the configured 0.2-second hold. | PASS |
| Fade speed/delta | Strength moved 0.75 → 0.25 over one second at speed 0.5, then returned to zero. | PASS |
| Luminous outline | Revealed outline alpha exceeded the dark outline by more than 10×. | PASS |
| Supported visual types | Wall, boundary, door, prop, terminal, hazard, and future enemy kinds use the common base. | PASS |
| Player readability | Procedural player core remained at ≥80% opacity and outside world fading. | PASS |
| F1 debug reveal | Parsed `debug_reveal` input revealed every revealable in the test room. | PASS |
| Compatibility path | Every revealable had no material/shader and no texture dependency. | PASS |
| Idle cost | Fully faded objects disabled per-frame processing. | PASS |

The suite printed `PHASE_04_REVEAL_TEST_OK` and exited 0.

## Regression and export validation

| Check | Result |
|---|---|
| Headless editor parse/import with no warning or broken reference | PASS |
| Phase 1 project/settings suite | PASS |
| Phase 2 complete navigation suite | PASS |
| Phase 2 responsive layout suite at 1280×720, 1024×768, and 1600×900 | PASS |
| Phase 3 movement, collision, pause, and resize suite | PASS |
| Native 1280×720 dark/revealed Compatibility visual inspection | PASS |
| Single-threaded Web release export | PASS |
| Windows Desktop release export | PASS |
| Prohibited technology and external-asset scan | PASS |

The Web build was exported successfully but was not live-run in a browser because browser automation is unavailable in this session. Windows execution on Windows also remains a later platform smoke test; neither is claimed here.

## Asset and scope check

- VIS-003 records the original procedural reveal system in the asset ledger.
- No non-code asset or third-party material was added.
- No expanding echo pulse, echo cooldown, sound emission, Listener, relay, extraction, objective, or gameplay reveal trigger was implemented.
- The reveal foundation is decoupled from player movement and application flow.
- GDScript-only, Compatibility renderer, Web/Windows targets, accessibility direction, GDD, and scope lock remain intact.

## Decision

**PASS**

Phase 04 provides the requested reusable darkness/reveal architecture and procedural world vocabulary with a clear visual contrast, bounded runtime cost, automated lifecycle coverage, and no M03 pulse implementation.
