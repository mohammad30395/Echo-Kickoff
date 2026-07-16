# Echo Kickoff — Game Design Document

Version: Visual-comfort revision 1

Original lock: 2026-07-15

Revised: 2026-07-17

## High concept

**Echo Kickoff** is a short 2D top-down stealth-horror game set in a dim, neon-lit reactor facility. A restrained ambient layer and a small player-local visibility radius keep immediate movement and collision boundaries readable. The player emits echo pulses to reveal longer-range walls, hazards, objectives, and enemies with much greater clarity. A pulse provides essential information, but its noise also gives sound-sensitive Listeners a location to investigate.

Restore three reactor relays and reach extraction without being caught.

Theme statement: **“Every echo pulse kicks off vision for the player and danger from the enemy.”**

## Design pillars

1. **Information has a cost.** Seeing more means producing danger.
2. **Darkness creates uncertainty, not eye strain or confusion.** Immediate pathing is always readable; distant information still requires risk.
3. **One mechanic carries the theme.** Pulsing is simultaneously perception, navigation, tension, and enemy provocation.
4. **Compact and replayable.** A successful first-time run should take roughly 12–20 minutes in the final facility; experienced runs should be substantially shorter, and failure returns the player to play quickly.
5. **Readable neon hierarchy.** Color, shape, motion, and brightness make player, information, danger, objectives, extraction, and blocked systems distinct.

## Core gameplay loop

1. Move cautiously using passive local visibility to read immediate floor and collision edges.
2. Emit a pulse when information is worth the risk.
3. Read the briefly revealed long-range geometry, relay direction, and Listener silhouettes.
4. Predict or evade Listeners investigating the pulse origin.
5. Reach and hold interaction at a relay while exposed.
6. Repeat for three relays as pressure escalates.
7. Return to the now-powered extraction point and escape.

At the second-to-second level: **move → pulse → read → reposition → listen → commit**.

## Player actions and controls

| Action | Default input | Behaviour |
|---|---|---|
| Move | WASD | Eight-direction top-down movement with normalized diagonal speed. Movement produces a small, local sound signal at controlled intervals. |
| Aim pulse | Mouse position | Sets pulse direction/readability if directional presentation is used; the gameplay pulse remains radial for reliability. |
| Echo pulse | Left mouse or Space | Sends an expanding radial reveal. The same event creates a larger enemy-hearing signal at the player's emission position. A short cooldown prevents spam. |
| Throw sound decoy | Q or Right mouse | Throws one of two scene-local decoys toward the mouse. A valid impact creates a targeted sound lure with only a weak local confirmation reveal. |
| Interact | E | Hold near a relay or extraction console; progress cancels if the player leaves range. |
| Pause | Esc | Pauses play and exposes resume, restart, controls, audio sliders, and quit. |
| Optional movement aid | On-screen control, if enabled | A user-enabled visual movement pad or drag joystick may mirror movement input. It must never be required, must not intercept mouse aiming outside its own region, and must not weaken desktop keyboard/mouse play. |

No combat, general inventory, sprint meter, crouch system, or manual flashlight is included in the must-have design. The fixed two-charge decoy HUD is not a general inventory system.

### Visibility model

The visual system has three deliberately different information bands:

1. **Ambient world visibility:** The facility floor, large structural masses, and authored environmental layers remain dimly visible across the view. This establishes mood, composition, and orientation but does not expose distant enemy positions or solve navigation.
2. **Passive player-local visibility:** A small, soft radius around the player continuously reveals immediate floor treatment, nearby wall/collision edges, and the next few movement steps. It is silent, creates no `NoiseEvent`, does not trigger Listeners, and is not a replacement for Echo Pulse.
3. **Active Echo Pulse reveal:** The expanding pulse provides strong luminous outlines and temporary long-range information, including distant structures, hazards, objectives, and Listener silhouettes. It remains the primary scouting tool and always creates danger through the hearing system.

The initial local-visibility tuning target is approximately **120–160 px**, subject to exported-build playtesting. It must be large enough to prevent blind collision and small enough that the current **345 px** release-tuned Echo radius remains materially more informative. Ambient and local visibility may show that a nearby boundary exists, but Echo must provide the clearest structure, identity, and long-range layout reading.

## Echo pulse specification

- A bright ring expands outward from the player.
- Touched geometry gains a fading outline/afterimage, providing a short memory window.
- Echo contrast must be clearly stronger than the ambient and player-local layers at every accessibility setting.
- Relays and extraction have distinct shapes, not color-only identification.
- Listeners caught by the reveal appear as unstable silhouettes.
- The hearing radius is larger than the useful reveal radius, so the pulse is never a free scan.
- A visible/aural cooldown communicates when another pulse is ready.
- Occlusion is desirable only if it remains simple and legible; it must not delay the vertical slice.

Current release baseline plus the planned local-visibility target, to be validated again during the visual revision:

| Parameter | Target |
|---|---:|
| Passive player-local radius | 120–160 px (planned) |
| Echo reveal radius | 345 px |
| Listener hearing radius | 500 px |
| Strong afterimage | 0.8 s |
| Full fade | 2.5 s |
| Pulse cooldown | 1.45 s |
| Relay hold time | 1.5 s |

The values remain playtest-tunable. The required relationship is: **passive local radius < Echo reveal radius < Echo hearing radius**, with a brief but usable visual memory.

## Enemies: Listeners

Listeners are blind or nearly blind creatures that navigate primarily by sound. They must be threatening but predictable through strong audio and silhouette feedback.

### State model

1. **Patrol:** Follows a short route or waits at authored points. Emits a low idle signature.
2. **Investigate:** On hearing a sound, travels to the sound's recorded origin. A pulse is high priority; footsteps are low priority and must be closer.
3. **Search:** At the origin, sweeps a small nearby area for several seconds. Newer/louder sounds replace the current target.
4. **Chase:** If the player enters a short contact-sense radius or is directly detected at close range, pursues at higher speed.
5. **Return:** After losing the player and receiving no new sound, returns to its patrol route.

### Behaviour rules

- A Listener reacts to a pulse only if inside that pulse's hearing radius.
- It investigates the recorded source position, not the player's continuously updated position.
- State changes have distinct sound cues and readable silhouette motion.
- Listeners do not coordinate, use ranged attacks, open complex doors, or learn across runs.
- Contact with a Listener defeats the player immediately after a very brief, readable catch cue.
- Navigation failures must fail safely; a stuck Listener should not teleport into the player.

## Win and lose conditions

**Win:** All three reactor relays are active and the player completes the extraction interaction. Show a short completion panel with time, pulse count, retries, and a clear restart/quit choice.

**Lose:** A Listener catches the player. Show a short non-graphic failure sting, then allow immediate restart from the beginning. Relay progress resets on restart.

There is no health bar, combat death, timer death, or score requirement.

## Level structure

One compact handcrafted facility, one gameplay scene:

```text
             Relay A — Turbine Room
                      |
Extraction — Central Hub — Relay B — Control Room
                      |
             Relay C — Coolant Bay
```

- The player begins beside the unpowered extraction console, establishing the return goal.
- The central hub branches into three visually and acoustically distinct relay routes.
- Relay order is free, but activation progressively increases ambient instability and Listener pressure.
- Routes include loops or side connectors so evasion is possible; avoid mandatory dead ends around relay consoles.
- Each branch contains one memorable landmark shape visible by pulse.
- Use collision and silhouettes to communicate boundaries; do not rely on detailed textures.
- Target: 2–3 Listeners total, never more than the level and navigation can support reliably.

Escalation should come from changed patrol placement/speed and stronger ambience, not spawning many enemies. After the third relay, extraction becomes unmistakably active and a direct return route remains possible.

## Onboarding and UI

- Start with a three-line overlay: move, pulse, interact.
- The first corridor safely teaches that a pulse reveals geometry.
- The first Listener encounter demonstrates that the same pulse attracts danger.
- A persistent minimal relay indicator shows three distinct nodes and extraction lock state.
- Context text appears only when in interaction range.
- Pause screen repeats controls and offers audio/accessibility settings.
- Failure and victory transitions must be brief and skippable.

No lore dialogue, cutscenes, minimap, inventory UI, quest log, or tutorial level.

## Visual direction

Echo Kickoff uses a dark sci-fi neon presentation with layered shapes, restrained glow-like outlines, structural fills, floor zoning, and controlled accents. It must feel atmospheric and polished, not like an empty black field containing only skeletal lines.

### Locked color system

| Gameplay role | Primary direction | Suggested anchor | Required use |
|---|---|---|---|
| Void / deep background | Blue-black | `#050A12` | Deepest negative space; never the only visible world layer. |
| Ambient floor / panels | Dark navy | `#0B1624` | Low-contrast floor fields, panels, and sector separation. |
| Walls / structures | Dark blue-gray | `#16283A` with `#31556B` edges | Persistent structural mass plus softly luminous nearby/revealed edges. |
| Player | Cyan and white | `#5BE7F2`, `#D9FAFF` | Always-readable core, outline, and facing marker. |
| Echo / information | Cyan-blue | `#52D9FF` | Pulse ring, strong reveal, readiness, information feedback. |
| Listener danger / alerts | Orange-red | `#FF5C3A` | Enemy silhouette, alert, chase, caught, invalid danger state. |
| Relay / objectives | Yellow-gold or bright cyan | `#FFD166` / `#64F2FF` | Objective identity selected by local contrast; shape and text remain authoritative. |
| Extraction | Green-cyan | `#45F0B0` | Powered extraction and completion; distinct from normal Echo. |
| Hazard / blocked system | Orange-red | `#FF7043` | Hazard marks, locked/blocked state, interruption. |
| Primary text | Cool white | `#E8FBFF` | Critical labels and readable HUD copy. |

Colors are role anchors, not a license to encode state by hue alone. Relays, extraction, Listeners, locked systems, cooldown, and danger also require distinct geometry, iconography, text, animation, or brightness patterns. High-contrast mode may substitute colors while preserving the same semantic roles.

### Layering rules

- The world is never completely unreadable during ordinary play.
- Ambient floor fields, subtle grids, large structural fills, room motifs, and sparse hazard accents establish depth without revealing the full route.
- Player-local visibility continuously exposes immediate collision edges with a soft falloff and no flash.
- Echo adds the strongest luminous outline, clearer interior detail, and long-range silhouettes before fading back to the ambient/local baseline rather than to invisibility.
- The player remains a bright cyan/white focal point with a procedural facing indicator.
- Relays use coil/hex geometry and objective accents; powered extraction uses its green-cyan chevron/beacon language.
- Listeners use broken orange-red waveform silhouettes and non-color-only alert deformation.
- Restrained screen shake, flash, and glitch effects remain optional and accessibility-aware.
- Use Compatibility-renderer-safe CanvasItem primitives or bounded Web-safe effects. Avoid expensive full-screen shader loops.

The game should remain legible and visually coherent without copyrighted sprites, texture packs, logos, or recognizable franchise designs.

## Audio direction

Audio carries gameplay information but cannot be the only channel for mandatory state.

- Sparse industrial ambience: low hum, relay drones, occasional structural ticks.
- Pulse: short broadband click followed by a tonal expanding echo.
- Footsteps: quiet rhythmic signals with enough spacing to imply risk.
- Listener states: separate idle, investigate, search, and chase motifs.
- Relay activation: layered electrical rise that remains distinct from the pulse.
- Extraction: stable harmonic beacon after all relays activate.
- Failure: brief impact and silence; avoid graphic content and jump-scare volume spikes.

Prefer sounds synthesized at runtime or created specifically for the jam. Any recorded or generated file must be original, documented in the asset ledger, normalized, and tested in browser autoplay constraints. Do not use third-party music for the must-have build.

## Accessibility

- Never encode an essential state by sound alone: use icons, rings, silhouette animation, and/or text.
- Never encode relay/alert state by color alone: pair color with distinct shapes and motion.
- Immediate collision boundaries must remain understandable without pulsing, including in high-contrast and reduced-flash modes.
- Ambient visibility must not depend on flashes, rapid luminance changes, or audio.
- Provide master, ambience, and effects volume controls; allow mute.
- Provide reduced screen shake and reduced flash options, defaulting to conservative effects.
- Avoid rapid strobing; pulse brightness should expand and fade smoothly.
- Use readable, high-contrast text at a practical minimum size for 1280×720.
- Controls are shown in-game and use common single-hand keyboard plus mouse/Space alternatives.
- Keyboard and mouse are the complete required control scheme. Any on-screen movement aid is optional, can be hidden, and cannot cover critical HUD, prompts, the player, or mouse-aim space at supported browser sizes.
- Pause must truly pause the simulation in desktop and Web builds where supported.
- The critical route must be navigable with visual cues when audio is muted.

Full remapping, localization, screen-reader support, and alternate input devices are stretch work only after the final build is stable.

## Difficulty and pacing targets

- First safe pulse within 10 seconds.
- First cause-and-effect Listener reaction within 60 seconds.
- First relay reachable within 3–5 minutes for a new player.
- Successful first run through the final facility: 12–20 minutes.
- Experienced run: approximately 6–12 minutes.
- Restart to player control: under 3 seconds on target hardware.
- At least one viable evasion route from every relay interaction area.

## Must-have features

- One start/pause/failure/victory flow.
- Responsive top-down movement and collision.
- Radial pulse with temporary environmental, objective, and enemy reveal.
- Shared sound-event system used by pulse, footsteps, and Listeners.
- Two-charge wall-safe sound decoy using the same noise-event and Listener-hearing systems.
- Listener patrol, investigate, search, chase/contact, and return behaviour.
- One compact level with three functional relays and powered extraction.
- Relay progress UI, contextual prompts, controls, and clear feedback.
- Original/procedural visual and audio presentation.
- Ambient world visibility plus a silent player-local visibility radius that preserves immediate collision readability.
- A clear HUD hierarchy for local visibility, pulse readiness, relay progress, decoy count, and Listener danger state.
- Master/ambience/effects volume plus reduced shake/flash options.
- Stable, tested Windows and Web exports; if only one can be submitted, it must satisfy the rulebook and be explicitly documented.

## Stretch features

Only begin after all must-have acceptance tests pass on exported builds:

- Pulse occlusion by walls.
- Seedless run statistics and local best time.
- One additional Listener archetype using the same state system.
- Optional full key rebinding.
- Extra procedural particles, environmental props, and relay-specific ambience.
- Optional on-screen movement pad. A drag joystick is allowed only after it proves non-interfering; otherwise use a simpler directional aid or omit the control entirely.
- A tiny post-win replay modifier.

## Explicit cut-list

The following are prohibited for the jam build unless the scope lock is deliberately revised after every must-have test passes:

- Combat, weapons, takedowns, health, crafting, inventory, or collectibles.
- Multiple levels, procedural level generation, boss fights, or story cutscenes.
- Save/load, accounts, online services, multiplayer, leaderboards, or analytics.
- Voice acting, branching dialogue, lore documents, or localization pipeline.
- Dynamic lighting requiring advanced renderer features, 3D scenes, or physics-heavy destruction.
- Mobile, console, VR, gamepad-first, macOS, or Linux release work.
- Mobile/touch-platform support. An optional on-screen movement aid does not expand the target platform or replace desktop keyboard/mouse QA.
- C#, GDExtension, plugins requiring native binaries, Phaser.js, or Three.js.
- Third-party asset-pack integration or copyrighted game material.
- Complex hearing simulation, sound ray tracing, machine-learning AI, or squad tactics.

## Final acceptance criteria

The final game is accepted only when all statements below are true:

1. A fresh player can start, learn the controls, activate three distinct relays, unlock extraction, and reach a victory screen without developer help.
2. A pulse visibly reveals nearby environment for a limited time and causes every in-range Listener to investigate the pulse's recorded origin.
3. Strong pulse revelation fades back to the ambient/local baseline, never to total unreadability; nearby collision and immediate pathing remain understandable without arbitrary navigation failures.
4. The normal noise hierarchy remains footsteps < decoy < Echo Pulse < relay activation; the decoy is targeted and limited, while footsteps are frequent and local.
5. Listener patrol, investigate, search, chase/contact, and return transitions complete without script errors or navigation deadlocks in three consecutive full runs.
6. Contact causes a clear, non-graphic loss; restart restores a clean initial state within 3 seconds on test hardware.
7. Relay UI accurately shows 0–3 activations, extraction cannot win early, and the third relay clearly powers extraction.
8. Essential enemy, relay, pulse, loss, and extraction states remain understandable with game audio muted and without relying on color alone.
9. Master, ambience, and effects volume controls work; reduced shake/flash settings suppress the relevant effects.
10. The Windows export and Web export each complete three consecutive start-to-win or start-to-loss smoke runs without a crash, freeze, missing input, broken audio initialization, or missing resource. Any unsubmitted target must be explicitly removed from claims and the ledger.
11. The game is playable with keyboard and mouse, requires no additional player-installed software, and includes controls/how-to-play information.
12. Every non-code asset has an approved entry in the asset ledger, with no NSFW, infringing, ripped, or unverified material.
13. The public Git repository, itch.io page, build, credits, required team information, and pitch-video link satisfy the compliance checklist.
14. The exact submitted commit and builds are archived and frozen after the deadline.
15. At pulse cooldown, the player can distinguish passive local light from active Echo revelation: local light is small, silent, and navigation-only, while Echo is broad, information-rich, temporary, and dangerous.
16. Player, Echo information, Listener danger, relays, extraction, walls, and hazards follow the locked role hierarchy and remain understandable without color alone.
17. Pulse readiness, relay count, decoy charges, interaction state, and current danger state are readable at 1280×720 and supported browser resizes without overlapping safe boundaries.
18. If an on-screen movement aid ships, it can be hidden, does not capture unrelated mouse input, does not obstruct required UI, and the full game still passes using keyboard and mouse alone.
