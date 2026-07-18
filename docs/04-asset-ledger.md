# Echo Kickoff — Asset Ledger

Updated: 2026-07-18

Policy: **Original procedural or team-created assets only for the jam build. No copyrighted third-party game assets.**

## Approval rules

Every non-code asset must be entered here before release use. “Planned” is not approval. An asset is **Approved** only when its exact repository path, creator, date, source method, rights basis, and modifications are recorded and checked.

Reject an asset if it is NSFW, infringes or imitates recognizable game material, violates itch.io terms, has unknown provenance, requires attribution that cannot be fulfilled, or has license terms incompatible with redistribution on itch.io and GitHub.

Source evidence should be retained locally with the project archive when applicable. A URL alone is insufficient if the license can change.

## Current inventory

There are **no third-party image, audio, font, model, video, or other asset files**. The inventory consists of original jam-authored runtime drawing, twelve original path-only SVGs, two exact-size original PNGs produced by the repository's deterministic visual generator, and fourteen original mono PCM16 WAV cues produced by the repository's deterministic audio generator. No downloaded reference, stock element, external font, model, sample, photograph, recorded third-party sound, or generative-image/audio service was used.

The 2026-07-17 visual and UI revisions add no image, font, texture, shader, model, or third-party asset. Ambient visibility, player-local visibility, richer structural layering, the reusable HUD frame, the threat-state panel, the optional on-screen movement aid, and the seven-stage tutorial presentation are implemented through original runtime CanvasItem and Control drawing. Keyboard and mouse remain the complete default control scheme; the movement aid is disabled by default.

| ID | Repository path | Type | Creator/source | Created/acquired | Rights basis | Modifications | Status |
|---|---|---|---|---|---|---|---|
| VIS-001 | `scripts/entities/player_visual.gd`, `scripts/visual/player_local_awareness.gd`, `scenes/entities/player.tscn` | Runtime procedural player marker and passive local-awareness floor zone | Jam-authored GDScript | 2026-07-15; revised 2026-07-17 | Original work; built-in Godot circles, arcs, and polygon | Cyan circular body, directional triangle, and bounded 148 px navigation glow; no texture or shader | Approved |
| VIS-002 | `scripts/debug/player_test_room_visual.gd`, `scenes/debug/player_test_room.tscn` | Runtime procedural graybox room | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot controls and rectangle | Near-black backdrop, collision graybox, and debug HUD | Approved |
| VIS-003 | `scripts/visual/echo_revealable.gd`, `scripts/visual/echo_reveal_primitive.gd`, `scripts/visual/local_visibility_controller.gd` | Runtime darkness/reveal and local-visibility primitives | Jam-authored GDScript | 2026-07-15; revised 2026-07-17 | Original work; built-in Godot CanvasItem drawing | Layered walls, boundaries, doors, props, terminals, hazards, enemy placeholder shape, restrained ambient baseline, reusable Player-owned cached local visibility, and strong active Echo hierarchy | Approved |
| VIS-004 | `scripts/effects/echo_pulse.gd`, `scenes/effects/echo_pulse.tscn`, `scripts/ui/pulse_cooldown_hud.gd`, `scenes/ui/pulse_cooldown_hud.tscn` | Runtime Echo Pulse and cooldown UI | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot arcs, lines, polygons, labels, and ProgressBar | Cyan reveal wave, orange danger accents, optional diagnostics, and cooldown status | Approved |
| VIS-005 | `scripts/entities/listener_visual.gd`, `scenes/entities/listener.tscn`, `scripts/debug/listener_ai_test_visual.gd`, `scenes/debug/listener_ai_test.tscn` | Runtime procedural Listener and AI test arena | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot polygons, polylines, arcs, circles, rectangles, and labels | Broken-wave silhouette, non-color-only alert marks, optional hearing/target diagnostics, obstacle arena, and patrol markers | Approved |
| VIS-006 | `scripts/interactions/reactor_relay_visual.gd`, `scripts/interactions/facility_door_visual.gd`, `scripts/interactions/extraction_terminal_visual.gd`, `scenes/interactions/reactor_relay.tscn`, `scenes/interactions/facility_door.tscn`, `scenes/interactions/extraction_terminal.tscn`, `scripts/ui/interaction_prompt_hud.gd`, `scripts/ui/objective_hud.gd`, `scenes/ui/interaction_prompt_hud.tscn`, `scenes/ui/objective_hud.tscn`, `scripts/debug/interaction_test_visual.gd`, `scenes/debug/interaction_test.tscn` | Runtime procedural facility interactions, mission UI, and test arena | Jam-authored GDScript | 2026-07-15; revised 2026-07-17 | Original work; built-in Godot polygons, polylines, rectangles, circles, labels, and ProgressBar | Layered gold-to-cyan relay states, orange-red/cyan door states, orange-red/green-cyan extraction states, shape-specific locked/powered/open cues, three-node objective HUD, action/status interaction framing, hold prompt, and line-of-sight test room | Approved |
| VIS-007 | `scripts/levels/echo_facility.gd`, `scenes/levels/echo_facility.tscn`, `scripts/ui/onboarding_hud.gd`, `scenes/ui/onboarding_hud.tscn` | Runtime procedural facility onboarding and tutorial UI | Jam-authored typed GDScript and Godot Control scene | 2026-07-15; revised 2026-07-17 | Original work; built-in Godot rectangles, lines, labels, and existing reveal primitives | Seven action-gated lessons, cyan/orange/gold/green semantic states, visible seven-segment progress track, contextual optional-pad hint, and concise local/Pulse/danger/tool guidance | Approved |
| VIS-008 | `scripts/effects/sound_decoy.gd`, `scenes/effects/sound_decoy.tscn`, `scripts/entities/player_decoy_controller.gd`, `scripts/ui/decoy_hud.gd`, `scenes/ui/decoy_hud.tscn` | Runtime procedural sound-decoy effect, aiming indicator, and charge HUD | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot polygons, polylines, arcs, circles, rectangles, and labels | Gold dotted trajectory and target reticle, orange wall-clamped state, airborne diamond, impact rings, and two-charge shape/text HUD | Approved |
| VIS-009 | `scripts/ui/round_transition_visual.gd`, `scenes/ui/round_transition_overlay.tscn` | Runtime procedural round-transition and caught-feedback overlay | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot rectangles, lines, arcs, and Label | Near-black scene fades plus non-graphic red interception rings, signal-cut lines, bands, and text feedback | Approved |
| VIS-010 | `scripts/levels/facility_sector.gd`, `scripts/levels/orientation_sector.gd`, `scripts/levels/laboratory_sector.gd`, `scripts/levels/extraction_sector.gd`, `scripts/levels/echo_facility.gd`, `scenes/levels/echo_facility.tscn`, `scenes/levels/sectors/orientation_sector.tscn`, `scenes/levels/sectors/laboratory_sector.tscn`, `scenes/levels/sectors/extraction_sector.tscn` | Runtime procedural final facility content and reusable sector vocabulary | Jam-authored GDScript and authored Godot scenes | 2026-07-15; revised 2026-07-17 | Original work; built-in Godot rectangles, lines, circles, collision shapes, and existing reveal primitives | Layered blue-black/slate floor panels, minor/major cyan grids, lane markers, circular platforms, corner bands, sector signatures, walls, props, hazards, safe pockets, and authored route topology | Approved |
| VIS-011 | `assets/branding/echo-kickoff-logo.svg`, `assets/ui/icons/pulse.svg`, `assets/ui/icons/interact.svg`, `assets/ui/icons/decoy.svg`, `assets/ui/icons/relay.svg` | Transparent path-only SVG logo and semantic UI icon set | Jam-authored SVG geometry; designed and written directly in this repository | 2026-07-15 | Original work; no font, embedded image, filter, script, external link, copied logo, or protected character | 640x160 geometric wordmark/echo mark; four 64x64 icons using a shared 4 px line weight and the established cyan/ink/orange/gold palette | Approved |
| VIS-012 | `assets/branding/game-icon.png`, `marketing/itch-cover-draft.png`, `tools/generate_assets.py`, `assets/generated-assets.json` | Exact-size generated PNG branding set plus reproducible source and manifest | Jam-authored deterministic Pillow drawing primitives; no random, network, font, external image, or generative-image input | 2026-07-15 | Original work; generator and SHA-256 provenance retained in repository | 512x512 RGBA game icon with transparent surround; 630x500 RGBA intentionally opaque itch cover draft; 4x supersampling and Lanczos downsampling | Approved |
| VIS-013 | `scripts/ui/hud_frame.gd`, `scripts/ui/movement_aid.gd`, `scripts/ui/threat_status_hud.gd`, `scenes/ui/hud_frame.tscn`, `scenes/ui/movement_aid.tscn`, `scenes/ui/threat_status_hud.tscn` | Runtime procedural HUD framing, optional movement aid, and non-positional threat-state display | Jam-authored typed GDScript and Godot Control scenes | 2026-07-17 | Original work; built-in Godot rectangles, lines, circles, arcs, polygons, and labels | Dark translucent sci-fi panels with cyan/orange state accents; bounded bottom-left drag pad disabled by default; text-and-shape Listener states without revealing enemy location | Approved |
| VIS-014 | `scripts/levels/campaign_arena_sector.gd`, `scenes/levels/resonance_labs.tscn`, `scenes/levels/blackout_core.tscn`, `scripts/interactions/extraction_gate_visual.gd`, `scripts/entities/reactor_warden_visual.gd`, matching scenes | Runtime procedural campaign maps, physical extraction gate, and Reactor Warden | Jam-authored typed GDScript and authored Godot scenes | 2026-07-18 | Original work; built-in Godot rectangles, paths, collision shapes, arcs, polygons, and lines | Figure-eight laboratory, ring-and-core facility, animated dual-panel gate, larger violet/orange enemy silhouette, and rotating guard fins | Approved |
| VIS-015 | `assets/ui/icons/extraction-door.svg`, `assets/ui/icons/warden.svg`, `assets/ui/icons/locked-level.svg`, `assets/ui/icons/rank-s.svg`, `assets/ui/icons/rank-a.svg`, `assets/ui/icons/rank-b.svg`, `assets/ui/icons/rank-c.svg` | Transparent path-only campaign status and rank SVG set | Jam-authored SVG path geometry written directly in this repository | 2026-07-18 | Original work; no font, image, filter, script, external link, copied logo, or protected character | Seven 64/96 px semantic vectors using the established cyan, gold, violet, orange, green, and rust palette | Approved |
| AUD-001 | `assets/audio/echo_pulse.wav`, `assets/audio/echo_pulse.wav.import` | Main Echo Pulse sound | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-15 | Original project audio; no source sample, third-party license, or attribution dependency | Mono PCM16 WAV, 24 kHz, 0.860 s, peak -7.00 dBFS, broad click plus descending tonal echo | Approved |
| AUD-002 | `assets/audio/footstep.wav`, `assets/audio/footstep.wav.import` | Quiet player footstep | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-15 | Original project audio; no source sample, third-party license, or attribution dependency | Mono PCM16 WAV, 24 kHz, 0.140 s, peak -18.00 dBFS, quiet low thud plus grit | Approved |
| AUD-003 | `assets/audio/listener_movement.wav`, `assets/audio/listener_alert.wav`, matching `.import` files | Listener movement and alert cues | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-15 | Original project audio; no source sample, third-party license, or attribution dependency | Movement: 0.250 s, peak -14.00 dBFS, dry scrape plus low joint tone. Alert: 0.720 s, peak -7.00 dBFS, rising gated warning interval. Both mono PCM16 WAV at 24 kHz | Approved |
| AUD-004 | `assets/audio/decoy_impact.wav`, `assets/audio/relay_activation.wav`, `assets/audio/door_open.wav`, matching `.import` files | Interaction and objective cues | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-15 | Original project audio; no source sample, third-party license, or attribution dependency | Decoy impact: 0.380 s, peak -8.00 dBFS. Relay activation: 1.420 s, peak -6.00 dBFS. Door open: 0.680 s, peak -10.00 dBFS. All mono PCM16 WAV at 24 kHz | Approved |
| AUD-005 | `assets/audio/player_caught.wav`, `assets/audio/victory_extraction.wav`, matching `.import` files | Failure and victory cues | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-15 | Original project audio; no source sample, third-party license, or attribution dependency | Caught: 0.500 s, peak -7.00 dBFS, restrained low impact. Victory/extraction: 1.820 s, peak -8.00 dBFS, ascending harmonic beacon. Both mono PCM16 WAV at 24 kHz | Approved |
| AUD-006 | `assets/audio/industrial_ambience.wav`, `assets/audio/industrial_ambience.wav.import` | Low industrial ambience loop | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-15 | Original project audio; no source sample, third-party license, or attribution dependency | Mono PCM16 WAV, 24 kHz, 6.000 s, peak -20.00 dBFS, seamless low industrial hum imported as forward loop on the Ambience bus | Approved |
| AUD-007 | `assets/audio/power_surge.wav`, `assets/audio/gate_unlock.wav`, `assets/audio/warden_alert.wav`, `assets/audio/level_complete.wav`, matching `.import` files | Campaign power, gate, Warden, and completion cues | Jam-authored deterministic mathematical synthesis in `tools/generate_audio_assets.py`; recorded in `assets/audio/generated-audio.json` | 2026-07-18 | Original project audio; no source sample, third-party license, AI audio, or attribution dependency | Four mono PCM16 24 kHz cues, 0.840–2.180 s, peaks from -9 to -8 dBFS; unique documented signatures and SHA-256 records | Approved |

## Planned procedural/team-created assets

These entries define intent only. Replace each with exact paths and evidence when created.

| Planned ID | Asset | Intended method | Release condition |
|---|---|---|---|
| P-VIS-01 | Player marker | Runtime Godot draw primitives authored during jam | Fulfilled by VIS-001 in Phase 3. |
| P-VIS-02 | Echo pulse ring and afterimages | Runtime lines/polygons/particles, Compatibility-safe | Fulfilled by VIS-003 and VIS-004; reduced-flash option remains planned for M09. |
| P-VIS-03 | Facility walls/props | Runtime primitives or original shapes authored during jam | Fulfilled for the final facility by VIS-002, VIS-003, VIS-007, and the reusable authored sector content in VIS-010. |
| P-VIS-04 | Listener silhouettes | Original procedural shapes authored during jam | Fulfilled by VIS-005 in Phase 6; original broken-wave geometry was reviewed as non-franchise procedural work. |
| P-VIS-05 | Relay/extraction/UI icons | Original geometric shapes authored during jam | Runtime state shapes were fulfilled by VIS-006 in Phase 7; the reusable pulse/interact/decoy/relay SVG symbols were fulfilled by VIS-011 in Phase 12. States still differ by geometry and text as well as color. |
| P-AUD-01 | Pulse sound | Runtime synthesis or team-created recording/synthesis | Fulfilled by AUD-001 in Phase 13 as a baked original WAV with generator and SHA-256 provenance. |
| P-AUD-02 | Footsteps | Runtime synthesis or team-created Foley | Fulfilled by AUD-002 in Phase 13 as a baked original WAV with generator and SHA-256 provenance. |
| P-AUD-03 | Listener cues | Team-created synthesis | Fulfilled by AUD-003 in Phase 13 as baked original WAVs with safe peak levels and distinctive signatures. |
| P-AUD-04 | Relay/extraction/failure cues | Team-created synthesis | Fulfilled by AUD-004 and AUD-005 in Phase 13 as baked original WAVs with generator and SHA-256 provenance. |
| P-AUD-05 | Industrial ambience | Runtime layers or team-created synthesis | Fulfilled by AUD-006 in Phase 13 as a baked original looping WAV; no third-party sample was used. |
| P-FONT-01 | UI font | Godot/default fallback or original approved choice | Avoid adding a font file unless rights and redistribution are verified. |
| P-VIS-06 | Ambient world and player-local visibility layers | Jam-authored Compatibility-safe CanvasItem drawing with cached bounded per-object falloff | Fulfilled by revised VIS-003 and VIS-010 on 2026-07-17; 148 px local radius remains weaker than the 345 px Echo and emits no noise. |
| P-VIS-07 | Polished structural/floor layering | Existing procedural geometry extended with original fills, edge bands, room motifs, hazard patterns, and controlled neon accents | Fulfilled by revised VIS-003, VIS-006, and VIS-010 on 2026-07-17 without new texture or shader dependencies. |
| P-UI-01 | Optional movement pad / joystick-like aid | Original Godot Control and draw primitives using existing movement actions | Fulfilled by VIS-013 on 2026-07-17. The pad is hideable, disabled by default, bounded to its own region, non-blocking for keyboard/mouse, and Web-compatible. |

## Visual-revision asset rules

- The locked palette is a project-authored design system, not a third-party asset: player cyan/white; Echo cyan-blue; danger and blocked systems orange-red; relay gold or bright cyan; extraction green-cyan; structures dark blue-gray.
- Future polish should extend existing `draw_*`, Polygon2D, Line2D, Control, and original SVG vocabulary before introducing new files.
- Any new icon, texture, shader, font, raster, or audio file still requires an exact Approved inventory row before release use.
- An implementation-only change to colors or procedural drawing code must update the relevant existing VIS row's modifications and review evidence; planned rows do not retroactively approve code or assets.
- Passive local light and active Echo must have different range, intensity, timing, and semantic purpose. Recoloring one effect is not sufficient evidence of compliance.

## 2026-07-17 procedural visual-pass review

- Creator/process: original procedural presentation work authored in this repository using typed GDScript and Godot CanvasItem drawing only.
- New asset files: none. No raster, vector, font, texture, material, shader, model, sample, downloaded reference, or generator output was introduced.
- Implemented vocabulary: layered floor panels and grids; circular room platforms; corridor lane marks; structural wall mass, seams, and edge bands; cool muted props; orange-red hazards; gold/cyan relays; orange-red/cyan doors; orange-red/green-cyan extraction; cyan-white player; cyan-blue Echo; orange-red danger.
- Visibility method: a cached list of revealable objects receives a bounded 148 px player-local visibility falloff at an 80 ms interval. It emits no noise, performs no physics query, and cannot passively reveal Listeners. Active Echo remains the 345 px strong reveal.
- Rights review: all changed geometry and palette code is original jam work and introduces no recognizable protected character, copied game material, logo, or third-party dependency.
- Technical review: no material or shader is assigned to revealables; Compatibility renderer and Web export constraints remain intact.
- Review result: **Approved.**

## 2026-07-17 joystick and HUD revision review

- Creator/process: original UI presentation authored in this repository with typed GDScript, Godot Controls, and CanvasItem custom drawing.
- New external assets: none. No raster, SVG, font, texture, shader, model, audio, downloaded reference, or generator output was introduced.
- Movement-aid policy: the aid is an optional desktop-browser accessibility control, disabled by default, and does not replace or synthesize keyboard actions. A left-button drag must begin inside its bounded pad; right mouse remains available for decoys and left mouse remains available for Echo outside the pad.
- HUD vocabulary: one reusable procedural frame establishes consistent dark translucent panels, corner brackets, scan line, accent line, and high-contrast-aware cyan/orange state colors. The threat display communicates state only, not Listener position.
- Technical review: event-driven input, no per-frame UI loop, no shader, no touch/mobile expansion, no external dependency, and no Compatibility-renderer exception.
- Review result: **Approved.**

## 2026-07-17 tutorial revision review

- Creator/process: original onboarding logic and presentation authored in this repository with typed GDScript, Godot Controls, and CanvasItem line drawing.
- New external assets: none. No raster, SVG, font, texture, shader, model, audio, downloaded reference, or generator output was introduced.
- Presentation vocabulary: the existing HUD frame now carries a seven-segment progress track; cyan identifies movement/visibility, orange identifies Pulse danger, gold identifies interaction/decoy/mission guidance, and green-cyan identifies powered extraction. Every state retains text and is not color-only.
- Movement-aid policy: the first lesson remains keyboard/mouse-first. `OPTIONAL PAD` appears only when the user enables the existing accessibility option; disabling it restores the keyboard-only copy immediately.
- Technical review: trigger checks reuse the facility's existing process path; the progress track redraws only when tutorial/accessibility state changes; no shader, physics query, particle, external dependency, or Compatibility-renderer exception was added.
- Review result: **Approved.**

## Asset entry template

Copy one row per file or inseparable generated set:

| ID | Repository path | Type | Creator/source | Created/acquired | Rights basis | Modifications | Status |
|---|---|---|---|---|---|---|---|
| A-000 | `res://...` | image/audio/font/etc. | Team member or exact source URL/tool | YYYY-MM-DD | Original/CC0/explicit permission plus evidence | Edits and tools | Planned/Review/Approved/Rejected |

Additional notes for generated assets must identify the generator/tool, the prompt or process record where practical, and the human review confirming that the output contains no recognizable protected character, logo, or copied game material.

## Phase 12 visual-production review

- Creator/process: original geometric artwork authored for Echo Kickoff on 2026-07-15. SVGs were written as repository-native vector paths. PNGs were drawn by the deterministic Pillow script in `tools/generate_assets.py`.
- Inputs: no prompt-driven image generator, downloaded reference, external asset, font, sample, stock shape library, photograph, recognizable character, or third-party logo.
- Rights: original jam work intended for redistribution with this project. No attribution dependency or external license applies to VIS-011 or VIS-012.
- Reproduction: `python3 tools/generate_assets.py --check` rebuilds the PNG bytes in memory and verifies both committed outputs and their manifest.
- Exact raster records: game icon SHA-256 `e17893d1e63c4245eda97935ea868de196690c10b90eecd436ac39cd7bfad339`; itch cover SHA-256 `a3767e6b9724dc9afa08c882db8fb867e3cc53a3c1145a7ba3745dec0568721c`.
- Review result: no recognizable protected character, copied game material, copyrighted logo, photographic background, NSFW content, or itch.io-incompatible material is present. **Approved.**

This is the Phase 12 asset-production approval, not the final submission sign-off. The final checklist below remains open until the finished build, credits, archive, Windows hardware run, and submission package are reviewed together.

## Campaign audio-production review

- Creator/process: original audio authored for Echo Kickoff on 2026-07-15 and extended on 2026-07-18. All fourteen WAVs were generated by fixed mathematical synthesis in `tools/generate_audio_assets.py`; no runtime procedural audio is used by production gameplay.
- Inputs: no downloaded sound, sample pack, recorded third-party source, AI audio service, external instrument preset, old project asset, template game cue, or copyrighted game audio.
- Rights: original jam work intended for redistribution with this project. No attribution dependency or external license applies to AUD-001 through AUD-007.
- Reproduction: `python3 tools/generate_audio_assets.py --check` verifies the committed WAVs and `assets/audio/generated-audio.json`.
- Exact source record: `assets/audio/generated-audio.json` stores path, bus, channel count, sample rate, duration, peak/RMS levels, loop flag, frequency signature, and SHA-256 for every committed audio file.
- Format policy: all cues are mono PCM16 WAV at 24 kHz. The ambience file is imported as a forward loop. Runtime export excludes the provenance JSON but includes the imported audio streams.
- Review result: no recognizable protected material, copied game sample, copyrighted recording, NSFW audio, or itch.io-incompatible material is present. **Approved.**

This is the Phase 13 audio-production approval, not the final submission sign-off. The final checklist below remains open until the finished build, credits, archive, Windows hardware run, and submission package are reviewed together.

## Pre-submission asset audit

- [ ] Enumerate all non-code files under the Godot project and match each to an Approved ledger entry.
- [ ] Confirm all runtime procedural assets are created by jam-authored code and need no external resource.
- [ ] Confirm no files were copied from another game, old project, template game, asset pack, search result, or franchise reference.
- [ ] Confirm no NSFW content and no itch.io ToS violation.
- [ ] Confirm credits on itch.io match this ledger, even for assets that do not legally require attribution.
- [ ] Confirm raw/project/source files needed to prove provenance are preserved in the final archive.
- [ ] Confirm Web and Windows exports contain only approved resources.
- [ ] Record the final audit reviewer, timestamp, and commit below.

Final reviewer: **TBD**  
Audit timestamp: **TBD**  
Final commit: **TBD**  
Result: **PENDING**
