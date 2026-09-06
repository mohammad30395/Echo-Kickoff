# Echo Kickoff

> See the facility. Make yourself heard. Survive what answers.

**Echo Kickoff** is a 2D top-down stealth-horror campaign built around one dangerous choice: every Echo Pulse reveals the world to the rescuer and broadcasts their position to sound-sensitive enemies called Listeners.

Restore the reactor network, redirect enemies with limited sound decoys, and return to the extraction gate before the facility finds you.

**[Play the Web build](https://echo-kickoff.vercel.app)**

## Why it stands out

- **One mechanic, two consequences:** Echo is both the player's strongest source of information and the enemy's strongest lead.
- **Readable stealth:** footsteps, decoys, Echo Pulses, and reactor activations form a clear noise hierarchy.
- **Three-operation campaign:** layouts, reactor counts, enemy pressure, and Reactor Wardens escalate from Easy to Hard.
- **Physical mission payoff:** the entry gate seals behind the rescuer, remains locked during restoration, and opens only when every required reactor is online.
- **Original presentation:** characters, environments, effects, UI, icons, and audio are project-authored; gameplay characters are animated procedurally without sprite sheets.
- **Accessible by design:** high contrast, reduced flash, screen-shake control, volume mixing, keyboard navigation, mouse support, and an optional virtual joystick.

## The campaign

| Operation | Reactors | Threats | Par time |
|---|---:|---|---:|
| Easy — Orientation Deck | 3 | 2 Listeners | 12 min |
| Medium — Resonance Labs | 5 | 3 Listeners + 1 Reactor Warden | 18 min |
| Hard — Blackout Core | 7 | 4 Listeners + 2 Reactor Wardens | 25 min |

Finishing an operation unlocks the next. Each run receives an S/A/B/C rank based on time and chase pressure, while Echo and decoy counts remain descriptive play-style statistics. Campaign unlocks, best rank, and best time are saved locally.

## How to play

1. Move cautiously and use the rescuer's short local visibility to read nearby collision edges.
2. Emit an Echo Pulse when longer-range information is worth attracting nearby Listeners.
3. Use a limited decoy to move danger toward a chosen location.
4. Hold the interaction key at every reactor in the operation.
5. Return to the sealed entry gate after the full grid is restored.
6. Cross the opened gate to complete the operation.

A Listener catching the rescuer ends the run immediately. Reactors and decoy charges reset cleanly on restart.

## Controls

| Action | Keyboard / mouse |
|---|---|
| Move | WASD or Arrow Keys |
| Echo Pulse | Space or Left Mouse Button |
| Throw decoy | Q or Right Mouse Button |
| Restore reactor | Hold E nearby |
| Pause / resume | Escape |
| Restart after capture | R or the Restart button |
| Navigate menus | Mouse, Tab, Arrow Keys, Enter |

The optional bottom-right joystick mirrors movement only; keyboard and mouse remain the complete default control scheme.

## Team

- Mohammad Mahmudul Kabir Fahmid
- Shashwata Nandi
- Animesh Singha Ayon

## Technology and compliance

- Godot **4.7.stable** (`4.7.stable.official.5b4e0cb0f`)
- Typed GDScript only
- Compatibility renderer
- Single-threaded Web export and Windows Desktop export
- No C#, GDExtension, native plugin, Phaser.js, or Three.js
- No required network service, account, installer, or external runtime
- No third-party game assets or copyrighted franchise material

The project interprets the theme **KICKOFF** directly: **every Echo Pulse kicks off vision for the player and danger from the enemy.**

## Run locally

Install Godot 4.7 and its matching export templates. From the repository root, import resources once and launch the project:

```bash
godot --headless --editor --path . --quit
godot --path .
```

There must be a space between `--path` and `.`. If Godot is installed at the project team's local CLI path, use:

```bash
~/.local/bin/godot --path .
```

A short headless smoke check is also available:

```bash
godot --headless --path . --quit-after 2
```

Successful startup prints `ECHO_KICKOFF_BOOT_OK` with renderer, viewport, and platform information.

## Verification

The repository includes headless regression coverage for project settings, navigation, responsive layout, player movement, collision, visibility, Echo, Listener AI, interaction, objectives, decoys, campaign progression, audio, accessibility, release configuration, gate containment, and procedural enemy animation.

Run the submission-critical checks with:

```bash
godot --headless --path . --script tests/submission_polish_test.gd
godot --headless --path . --script tests/campaign_expansion_test.gd
godot --headless --path . --script tests/phase_15_release_candidate_test.gd
```

Run every automated test:

```bash
for test_file in tests/*_test.gd; do
  godot --headless --path . --script "$test_file" || exit 1
done
```

## Export

```bash
mkdir -p build/web build/windows
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/echo-kickoff.exe
```

Serve the Web folder over HTTP; do not open `index.html` directly:

```bash
python3 -m http.server 8770 --directory build/web
```

Then open `http://localhost:8770`. Browser audio begins after the Start click, as required by browser autoplay policies.

## Repository map

```text
assets/              Original branding, UI resources, and synthesized audio
scenes/              Campaign levels, reusable entities, interactions, and UI
scripts/             Typed gameplay, procedural drawing, systems, and autoloads
tests/               Headless gameplay, flow, layout, and release regression tests
docs/                Design locks, compliance records, audits, and submission copy
export_presets.cfg   Windows and single-threaded Web release presets
project.godot        Godot project and input configuration
```

## Credits and license

Echo Kickoff is released under the [MIT License](LICENSE).

Copyright (c) 2026 Mohammad Mahmudul Kabir Fahmid.

All game code, procedural visuals, UI resources, SVG icons, branding, and synthesized audio were created for Echo Kickoff. Godot Engine is used under its own license. See [the asset ledger](docs/04-asset-ledger.md) for the full provenance record and [known issues](docs/known-issues.md) for current non-breaking limitations.
