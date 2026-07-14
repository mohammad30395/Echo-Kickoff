# Echo Kickoff — Scope Lock

Locked on: **2026-07-15**  
Internal submission target: **2026-07-19 17:00 Asia/Dhaka**, subject to any earlier organizer notice

## Product sentence

Build one 6–10 minute 2D top-down stealth-horror level in which a radial echo pulse temporarily reveals a dark facility while alerting Listeners, then let the player activate three relays and extract.

Anything that does not strengthen or stabilize that sentence is not must-have work.

## Non-negotiable constraints

- Godot 4, GDScript, Compatibility renderer.
- Keyboard and mouse PC play.
- Windows and Web exports tested; at least one compliant working submission build is mandatory.
- New work only from this jam repository.
- Original procedural or team-created assets only; every asset is logged.
- No C#, GDExtension, Phaser.js, Three.js, native plugin dependency, extra runtime, or online service.
- No Godot project creation or gameplay implementation during Phase 0 documentation.

## Must-have backlog

Priority order is strict. A later row cannot displace an earlier incomplete row.

| ID | Deliverable | Done when |
|---|---|---|
| M01 | Project/export baseline | Pinned Godot 4 version, Compatibility renderer, clean boot, input map, Windows and Web test exports. |
| M02 | Player and room | Movement, normalized diagonals, collisions, camera, compact graybox. |
| M03 | Pulse/reveal | Expanding radial pulse reveals geometry/objectives/enemies, fades, and respects cooldown. |
| M04 | Sound events | Pulse and footsteps publish location, loudness/radius, and time through one simple interface. |
| M05 | One Listener vertical slice | Patrol → investigate → search → chase/contact → return works and is readable. |
| M06 | Objective loop | Three relay interactions, accurate progress UI, locked then powered extraction, win state. |
| M07 | Complete level | Central hub plus three branches, 2–3 Listeners, loops/evasion space, onboarding. |
| M08 | Full game flow | Start/help, pause, failure, fast restart, victory, quit where platform permits. |
| M09 | Presentation/accessibility | Procedural visuals/audio, readable state cues, volume controls, reduced shake/flash. |
| M10 | Export QA/submission | Repeated Windows/Web smoke tests, asset audit, itch.io upload/retest, archive/freeze. |

## Stretch backlog

Stretch work is locked until M01–M10 pass in exported builds:

1. Wall-occluded pulse.
2. Local best time and pulse count presentation.
3. One additional Listener variant using existing systems.
4. Full input rebinding.
5. Extra props, particles, and relay-specific ambience.
6. Post-win replay modifier.

Stretch work is removed immediately if it introduces an export regression, accessibility regression, new asset uncertainty, or more than 60 minutes of unresolved debugging.

## Explicit cut-list

- Combat, health, weapons, takedowns, inventory, crafting, collectibles.
- More than one level, procedural maps, bosses, cutscenes, dialogue, lore systems.
- Save/load, cloud data, analytics, accounts, online features, multiplayer, leaderboards.
- Advanced dynamic lighting, 3D, destructible environments, ragdolls.
- Mobile/VR/console ports, controller polish, macOS/Linux packaging.
- Voice acting, licensed soundtrack, asset packs, recognizable franchise material.
- Complex acoustic simulation, ray-traced hearing, coordinated enemy squads.
- Toolchain or dependency changes outside the locked technical stack.

## Schedule budget

This is a survival schedule, not an estimate of how long every feature could ideally take.

| Date (BDT) | Exit condition |
|---|---|
| Jul 15 | Phase 0 documents committed; no project created as part of this phase. |
| Jul 16 | M01–M05 vertical slice works in editor and in an early Web/Windows export. |
| Jul 17 | M06–M08 complete; full graybox run is winnable and losable. |
| Jul 18, 12:00 | M09 integrated; content complete. |
| Jul 18, 18:00 | Feature freeze; only fixes, tuning, submission media, and compliance work. |
| Jul 19 | M10, clean builds, upload, download/retest, video capture, archive. Target submission by 17:00 BDT. |
| Jul 20–21 | Only organizer-permitted submission/page/video work; never modify frozen game/repository after the official online cutoff. |

## Change-control rule

A scope addition is permitted only when all of the following are true:

1. M01–M10 already pass in both exported targets.
2. It uses existing systems and approved assets.
3. It is estimated at no more than two hours including testing.
4. It improves a judging criterion or resolves a demonstrated playtest problem.
5. A rollback point exists and the addition cannot endanger the submission deadline.

Otherwise record the idea after the jam; do not implement it.

## Automatic cuts

- If Web export is blocked for more than two focused hours, preserve a working Windows build first, then revisit Web only after the complete loop passes.
- If pulse occlusion is not reliable by the M03 exit, use an unoccluded radial reveal.
- If multiple Listeners cause navigation instability, ship two reliable Listeners rather than three unstable ones.
- If runtime audio synthesis is inconsistent on Web, use small original pre-rendered sounds documented in the ledger.
- If special effects differ between render targets, use simple CanvasItem lines/polygons with identical gameplay readability.
- If the final level is too large, reduce branch length rather than removing a relay or the extraction return.

## Definition of done

“Implemented” means it works in the editor. “Done” means it also works in exported Windows and Web builds, has no unapproved assets, has visible and audible feedback, survives restart, and passes its relevant acceptance criteria in `docs/01-game-design-document.md`.
