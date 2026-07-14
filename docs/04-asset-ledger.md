# Echo Kickoff — Asset Ledger

Updated: 2026-07-15  
Policy: **Original procedural or team-created assets only for the jam build. No copyrighted third-party game assets.**

## Approval rules

Every non-code asset must be entered here before release use. “Planned” is not approval. An asset is **Approved** only when its exact repository path, creator, date, source method, rights basis, and modifications are recorded and checked.

Reject an asset if it is NSFW, infringes or imitates recognizable game material, violates itch.io terms, has unknown provenance, requires attribution that cannot be fulfilled, or has license terms incompatible with redistribution on itch.io and GitHub.

Source evidence should be retained locally with the project archive when applicable. A URL alone is insufficient if the license can change.

## Current inventory

At Phase 3 there are **no imported image, audio, font, model, video, or other third-party asset files**. The visual inventory below is generated at runtime by original jam-authored GDScript and built-in Godot drawing primitives.

| ID | Repository path | Type | Creator/source | Created/acquired | Rights basis | Modifications | Status |
|---|---|---|---|---|---|---|---|
| VIS-001 | `scripts/entities/player_visual.gd`, `scenes/entities/player.tscn` | Runtime procedural player marker | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot circles and polygon | Cyan circular body and directional triangle | Approved |
| VIS-002 | `scripts/debug/player_test_room_visual.gd`, `scenes/debug/player_test_room.tscn` | Runtime procedural graybox room | Jam-authored GDScript | 2026-07-15 | Original work; built-in Godot rectangles and lines | Facility grid, wall, obstacle, and HUD primitives | Approved |

## Planned procedural/team-created assets

These entries define intent only. Replace each with exact paths and evidence when created.

| Planned ID | Asset | Intended method | Release condition |
|---|---|---|---|
| P-VIS-01 | Player marker | Runtime Godot draw primitives authored during jam | Fulfilled by VIS-001 in Phase 3. |
| P-VIS-02 | Echo pulse ring and afterimages | Runtime lines/polygons/particles, Compatibility-safe | Verify Web and Windows rendering and reduced-flash option. |
| P-VIS-03 | Facility walls/props | Runtime primitives or original shapes authored during jam | Graybox portion fulfilled by VIS-002; final facility art remains planned. |
| P-VIS-04 | Listener silhouettes | Original procedural shapes authored during jam | Confirm no resemblance traced from an existing franchise. |
| P-VIS-05 | Relay/extraction/UI icons | Original geometric shapes authored during jam | Verify shape-based, non-color-only states. |
| P-AUD-01 | Pulse sound | Runtime synthesis or team-created recording/synthesis | Record creator/tool/settings and exported file path if baked. |
| P-AUD-02 | Footsteps | Runtime synthesis or team-created Foley | Record raw source ownership and edits if recorded. |
| P-AUD-03 | Listener cues | Team-created synthesis | Record creator/tool/settings; normalize and safety-check volume. |
| P-AUD-04 | Relay/extraction/failure cues | Team-created synthesis | Record creator/tool/settings and files. |
| P-AUD-05 | Industrial ambience | Runtime layers or team-created synthesis | No third-party samples unless separately approved and logged. |
| P-FONT-01 | UI font | Godot/default fallback or original approved choice | Avoid adding a font file unless rights and redistribution are verified. |

## Asset entry template

Copy one row per file or inseparable generated set:

| ID | Repository path | Type | Creator/source | Created/acquired | Rights basis | Modifications | Status |
|---|---|---|---|---|---|---|---|
| A-000 | `res://...` | image/audio/font/etc. | Team member or exact source URL/tool | YYYY-MM-DD | Original/CC0/explicit permission plus evidence | Edits and tools | Planned/Review/Approved/Rejected |

Additional notes for generated assets must identify the generator/tool, the prompt or process record where practical, and the human review confirming that the output contains no recognizable protected character, logo, or copied game material.

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
