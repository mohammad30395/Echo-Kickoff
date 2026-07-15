# Echo Kickoff — itch.io Page Copy

Use this copy for the itch.io project page and jam submission. Replace bracketed placeholders before publishing.

## Short description

A 2D stealth-horror game where every echo pulse reveals the dark facility and alerts the sound-sensitive enemies hunting you.

## Full game description

**Echo Kickoff** is a short 2D top-down stealth-horror game made for the **IUT 12th ICT FEST 2026 GameJam** theme: **KICKOFF**.

The facility is almost completely dark. You cannot safely see the world unless you make sound. Each Echo Pulse briefly reveals walls, hazards, relays, doors, extraction routes, and enemy silhouettes — but the same pulse also gives the Listeners a place to investigate.

Restore three reactor relays, manage the danger created by your own noise, use limited sound decoys to misdirect enemies, and reach extraction before the Listeners catch you.

Theme adaptation: **Every echo pulse kicks off vision for the player and danger from the enemy.**

## How to Play

1. Move through the dark facility and use short memory from each fading Echo Pulse.
2. Pulse only when information is worth the risk.
3. Watch and listen for Listeners reacting to sound.
4. Activate all three reactor relays.
5. Use sound decoys to pull Listeners away from dangerous routes.
6. Return to extraction after all relays are online.

Win by activating all three relays and completing extraction. Lose if a Listener catches you.

## Controls

| Action | Input |
|---|---|
| Move | WASD or Arrow Keys |
| Echo Pulse | Space or Left Mouse Button |
| Interact / hold objective | E |
| Throw sound decoy | Q or Right Mouse Button |
| Pause | Escape |
| Restart from death screen | R or on-screen button |
| Menu navigation | Keyboard, mouse, Tab/Enter where applicable |

## Accessibility and options

- Master, effects, and ambience volume controls.
- High-contrast mode.
- Reduced screen flash option.
- Screen-shake toggle.
- Text and icon feedback for critical gameplay states.
- Keyboard and mouse support.

## Team and member information

Team name: **[TEAM NAME]**

Members:

1. **[Member 1 full name]** — **[Student ID / registration identifier]**
2. **[Member 2 full name, if applicable]** — **[Student ID / registration identifier]**
3. **[Member 3 full name, if applicable]** — **[Student ID / registration identifier]**

Contact: **[Team contact email/Discord/phone if required by organizers]**

## Engine / framework

Built with **Godot 4.7**, **GDScript**, and the **Compatibility renderer**.

No C#, no GDExtension, no Phaser.js, no Three.js, and no extra runtime/software is required for the Web build.

## Public GitHub repository

Repository: `https://github.com/mohammad30395/Echo-Kickoff.git`

Before submitting, verify that this repository is public and accessible from a logged-out browser session.

## Downloads / builds

Recommended jam build:

- Web build: upload `build/final/package/echo-kickoff-web-itch.zip` to itch.io.

Optional additional build if accepted by the page setup:

- Windows build: upload the contents of `build/final/windows/` together so `echo-kickoff.exe` remains beside `echo-kickoff.pck`.

## Asset credits

All game code, procedural visuals, UI icons, branding art, and audio cues were created during the jam for Echo Kickoff.

Asset summary:

- Procedural gameplay visuals: original Godot CanvasItem/GDScript drawing.
- Logo and UI icons: original geometric SVG assets made for this project.
- Game icon and itch cover draft: original deterministic generated artwork from the repository tool.
- Audio: original deterministic synthesized WAV files created for the project; no third-party samples or music.
- Engine: Godot Engine.

No third-party game assets, copyrighted game material, stock sound packs, external music, character art, or downloaded sprites are used.

## Known non-breaking issues

- Browser audio starts only after the player presses Start, which is required by modern browser autoplay rules.
- First Web load can take several seconds because the Godot WebAssembly file is approximately 39.5 MB.
- Windows export was generated and statically verified on macOS, but should still be launched on Windows hardware if time is available before submission freeze.
- Final Firefox verification in Phase 16 was limited to launch/screenshot smoke; Phase 15 contains the prior full Firefox smoke evidence.

## Suggested itch.io tags

`stealth`, `horror`, `top-down`, `godot`, `gamejam`, `web`, `keyboard-and-mouse`, `2d`

