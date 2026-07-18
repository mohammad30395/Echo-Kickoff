# Echo Kickoff — Three-Level Campaign Audit

Updated: 2026-07-18

## Delivered campaign

| Level | Scene | Reactors | Enemies | Par |
|---|---|---:|---|---:|
| Easy — Orientation Deck | `scenes/levels/echo_facility.tscn` | 3 | 2 Listeners | 720 s |
| Medium — Resonance Labs | `scenes/levels/resonance_labs.tscn` | 5 | 3 Listeners + 1 Reactor Warden | 1080 s |
| Hard — Blackout Core | `scenes/levels/blackout_core.tscn` | 7 | 4 Listeners + 2 Reactor Wardens | 1500 s |

`CampaignManager` owns the typed catalog, sequential unlocks, selected level, best result replacement, and schema-versioned local save at `user://echo_kickoff_progress.cfg`. `GameWorld` is now a thin dynamic wrapper. The original `EchoFacility` scene and its named Easy nodes remain available to regression tests.

## Objective and extraction

`CampaignLevel` discovers players, reactors, enemies, sectors, HUD, power grid, and extraction gate by groups or reusable node contracts. Repairing a reactor raises a monotonic power ratio, brightens the `CanvasModulate`, energizes sector floor/conduit drawing, updates the objective HUD, and plays an original surge cue.

The last reactor begins a 1.6-second sequence: controls and joystick state clear, the grid reaches neutral power, a reduced-flash-aware overlay announces `GRID ONLINE // EXTRACTION OPEN`, two procedural gate panels slide apart, collision disables near the end, and controls return. The gate has `LOCKED`, `POWERING`, `OPEN`, and `EXITED` states and accepts one crossing only. Production extraction terminals are status consoles; the physical threshold completes the level.

## Enemy escalation

`Listener.apply_tuning()` applies the exact Easy/Medium/Hard movement, hearing, detection, retarget, memory, and search profiles from the campaign specification. Reactor Wardens inherit wall collision and audible-event handling from Listener. They guard inactive reactors, accelerate by up to 25% with restored power, respond to reactor activations, and project the direction of the latest two accepted strong sound events for at most 220 pixels. Decoys use the same history and can create a false intercept. Warden code does not read hidden player coordinates.

## Results and accessibility

`RunTelemetry` records elapsed time, Echo Pulse count, decoy count, and transitions into chase. `RunResult` deterministically applies S/A/B/C boundaries. Results offer Next Level, Retry, Level Select, and Main Menu; rank and time are retained using rank first and time as the tie-breaker.

Keyboard/mouse, the optional virtual joystick, Echo/decoy mechanics, Compatibility rendering, single-threaded Web export, high contrast, reduced flash, and screen-shake settings remain supported. No fullscreen shader or third-party runtime dependency was added.

## Asset provenance

Seven new path-only SVGs cover the door, Warden, locked level, and four rank badges. Four new deterministic baked WAVs cover power surge, gate unlock, Warden alert, and level completion. Exact ownership, method, and rights records are in `docs/04-asset-ledger.md`; audio hashes and technical metadata are in `assets/audio/generated-audio.json`.

## Automated validation

`tests/campaign_expansion_test.gd` covers:

- exact 3/5/7 reactor and 2/4/6 enemy totals;
- exact tuning profiles and par times;
- locked threshold, one gate opening/crossing, collision release, control lock/return, and monotonic full power;
- rank boundaries without Pulse/decoy penalties;
- Warden decoy interception, 220-pixel cap, power escalation, and absence of hidden-coordinate reads;
- missing/corrupt save recovery, sequential unlock order, reset, and isolated save storage.

The complete legacy suite retains Easy gameplay, UI, accessibility, audio, Web, and release-candidate regression coverage. Long-form Easy route tests now finish by crossing the opened physical gate.

Validation recorded on 2026-07-18:

- all 23 `tests/*_test.gd` scripts passed in clean headless processes;
- `python3 tools/generate_audio_assets.py --check` reproduced all fourteen audio files and their manifest;
- the Godot 4.7 editor completed a timed parse/import with no script or resource error;
- Web release export succeeded at `build/final/web/index.html` with a single-threaded 39,509,339-byte WASM and 704,888-byte PCK;
- Windows release export succeeded at `build/final/windows/echo-kickoff.exe`; `file` identifies a 64-bit Windows PE GUI executable and the matching PCK is present;
- Chromium 150 loaded the final packaged build over local HTTP, reported Compatibility/WebGL 2, Emscripten single-threaded/no-GDExtension configuration, printed `ECHO_KICKOFF_BOOT_OK`, entered Easy from the focused campaign button, rendered the complete HUD/facility/gate, started ambience after the user gesture, and produced no error-level browser log entries;
- Firefox 152.0.6 loaded the same package and rendered the complete campaign menu. Firefox emitted an engine-path WebAssembly deprecation warning and an internal shutdown message, but no observed game-script failure.

## Remaining human release gate

Automated checks and browser boot smokes establish code/build integrity, but final acceptance still requires a person to complete all three packaged levels in Chromium and Firefox, check balance and route readability at real-time speed, verify the Windows build on Windows hardware, and record the exact submission commit. These manual checks are intentionally not claimed from headless automation.
