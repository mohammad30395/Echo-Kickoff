# Echo Kickoff — Game Design Document

Version: Phase 0 scope-locked design  
Date: 2026-07-15

## High concept

**Echo Kickoff** is a short 2D top-down stealth-horror game set in an almost completely dark reactor facility. The player emits echo pulses to briefly reveal nearby walls, hazards, objectives, and enemies. A pulse provides essential information, but its noise also gives sound-sensitive Listeners a location to investigate.

Restore three reactor relays and reach extraction without being caught.

Theme statement: **“Every echo pulse kicks off vision for the player and danger from the enemy.”**

## Design pillars

1. **Information has a cost.** Seeing more means producing danger.
2. **Darkness creates uncertainty, not confusion.** The player retains enough orientation and feedback to make deliberate choices.
3. **One mechanic carries the theme.** Pulsing is simultaneously perception, navigation, tension, and enemy provocation.
4. **Short and replayable.** A successful first run should take roughly 6–10 minutes; failure returns the player to play quickly.

## Core gameplay loop

1. Move cautiously through darkness using the last fading echo as memory.
2. Emit a pulse when information is worth the risk.
3. Read the briefly revealed geometry, relay direction, and Listener silhouettes.
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
| Interact | E | Hold near a relay or extraction console; progress cancels if the player leaves range. |
| Pause | Esc | Pauses play and exposes resume, restart, controls, audio sliders, and quit. |

No combat, inventory, sprint meter, crouch system, or manual flashlight is included in the must-have design.

## Echo pulse specification

- A bright ring expands outward from the player.
- Touched geometry gains a fading outline/afterimage, providing a short memory window.
- Relays and extraction have distinct shapes, not color-only identification.
- Listeners caught by the reveal appear as unstable silhouettes.
- The hearing radius is larger than the useful reveal radius, so the pulse is never a free scan.
- A visible/aural cooldown communicates when another pulse is ready.
- Occlusion is desirable only if it remains simple and legible; it must not delay the vertical slice.

Initial tuning targets, to be adjusted by playtest:

| Parameter | Target |
|---|---:|
| Reveal radius | 320 px |
| Listener hearing radius | 480 px |
| Strong afterimage | 0.8 s |
| Full fade | 2.5 s |
| Pulse cooldown | 1.2 s |
| Relay hold time | 1.5 s |

The units are provisional implementation values, not promises. The required relationship is: **hearing radius > reveal radius**, with a brief but usable visual memory.

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

- Near-black navy background rather than absolute black.
- Procedural vector-like shapes drawn with Godot primitives: lines, polygons, rings, particles, and simple silhouettes.
- Player: small pale core with a directional notch.
- Environment: cool cyan echo edges that decay into darkness.
- Relays: three-part hexagonal/coil symbols; inactive and active states differ in shape, animation, and brightness.
- Listeners: tall, broken red/orange waveform silhouettes with an alert deformation.
- Extraction: high-contrast doorway/chevron motif.
- Restrained screen shake and glitch effects; readability takes priority.
- Compatibility-renderer-safe CanvasItem effects only. No effect may be essential unless tested in Web and Windows exports.

The game should remain legible without copyrighted sprites, texture packs, logos, or recognizable franchise designs.

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
- Provide master, ambience, and effects volume controls; allow mute.
- Provide reduced screen shake and reduced flash options, defaulting to conservative effects.
- Avoid rapid strobing; pulse brightness should expand and fade smoothly.
- Use readable, high-contrast text at a practical minimum size for 1280×720.
- Controls are shown in-game and use common single-hand keyboard plus mouse/Space alternatives.
- Pause must truly pause the simulation in desktop and Web builds where supported.
- The critical route must be navigable with visual cues when audio is muted.

Full remapping, localization, screen-reader support, and alternate input devices are stretch work only after the final build is stable.

## Difficulty and pacing targets

- First safe pulse within 10 seconds.
- First cause-and-effect Listener reaction within 60 seconds.
- First relay reachable within 2–3 minutes for a new player.
- Successful first run: 6–10 minutes.
- Experienced run: 3–6 minutes.
- Restart to player control: under 3 seconds on target hardware.
- At least one viable evasion route from every relay interaction area.

## Must-have features

- One start/pause/failure/victory flow.
- Responsive top-down movement and collision.
- Radial pulse with temporary environmental, objective, and enemy reveal.
- Shared sound-event system used by pulse, footsteps, and Listeners.
- Listener patrol, investigate, search, chase/contact, and return behaviour.
- One compact level with three functional relays and powered extraction.
- Relay progress UI, contextual prompts, controls, and clear feedback.
- Original/procedural visual and audio presentation.
- Master/ambience/effects volume plus reduced shake/flash options.
- Stable, tested Windows and Web exports; if only one can be submitted, it must satisfy the rulebook and be explicitly documented.

## Stretch features

Only begin after all must-have acceptance tests pass on exported builds:

- Pulse occlusion by walls.
- Seedless run statistics and local best time.
- One additional Listener archetype using the same state system.
- Optional full key rebinding.
- Extra procedural particles, environmental props, and relay-specific ambience.
- A tiny post-win replay modifier.

## Explicit cut-list

The following are prohibited for the jam build unless the scope lock is deliberately revised after every must-have test passes:

- Combat, weapons, takedowns, health, crafting, inventory, or collectibles.
- Multiple levels, procedural level generation, boss fights, or story cutscenes.
- Save/load, accounts, online services, multiplayer, leaderboards, or analytics.
- Voice acting, branching dialogue, lore documents, or localization pipeline.
- Dynamic lighting requiring advanced renderer features, 3D scenes, or physics-heavy destruction.
- Mobile, console, VR, gamepad-first, macOS, or Linux release work.
- C#, GDExtension, plugins requiring native binaries, Phaser.js, or Three.js.
- Third-party asset-pack integration or copyrighted game material.
- Complex hearing simulation, sound ray tracing, machine-learning AI, or squad tactics.

## Final acceptance criteria

The final game is accepted only when all statements below are true:

1. A fresh player can start, learn the controls, activate three distinct relays, unlock extraction, and reach a victory screen without developer help.
2. A pulse visibly reveals nearby environment for a limited time and causes every in-range Listener to investigate the pulse's recorded origin.
3. Darkness returns after the pulse, while feedback remains sufficient to avoid arbitrary navigation failures.
4. Footsteps create weaker/shorter-range sound events than pulses.
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
