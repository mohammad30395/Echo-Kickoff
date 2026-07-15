# Phase 16 Final QA

Result: **PASS**

Date: 2026-07-15

## Scope

The project was treated as feature-frozen. Work in this phase was limited to final QA, final release exports, packaging, checksums, version metadata, manifesting, and known-issues documentation.

No gameplay features were added.

## Documents reviewed

- `docs/00-gamejam-compliance.md`
- `docs/01-game-design-document.md`
- `docs/02-scope-lock.md`
- Every previous phase audit/report from Phase 01 through Phase 15

The compliance document still has external gates that cannot be proven from the repository alone:

- Team eligibility/registration.
- Public GitHub repository visibility.
- itch.io page visibility/submission status.
- Pitch video upload/submission.
- No post-deadline modifications.

These remain submission-owner responsibilities.

## Automated gameplay QA

Full Phase 01-15 regression suite passed:

- `PHASE_01_PROJECT_TEST_OK`
- `PHASE_02_FLOW_TEST_OK`
- `PHASE_02_LAYOUT_TEST_OK`
- `PHASE_03_PLAYER_TEST_OK`
- `PHASE_04_REVEAL_TEST_OK`
- `PHASE_05_ECHO_PULSE_TEST_OK`
- `PHASE_06_LISTENER_TEST_OK`
- `PHASE_07_INTERACTION_TEST_OK`
- `PHASE_08_VERTICAL_SLICE_TEST_OK`
- `PHASE_09_DECOY_TEST_OK`
- `PHASE_10_ROUND_STATE_TEST_OK`
- `PHASE_11_CONTENT_TEST_OK`
- `PHASE_12_VISUAL_TEST_OK`
- `PHASE_13_AUDIO_TEST_OK`
- `PHASE_14_UX_TEST_OK`
- `PHASE_15_RELEASE_CANDIDATE_TEST_OK`

Coverage from the suite confirms:

| Required check | Evidence |
|---|---|
| Main menu | Phase 02, 14 |
| New game | Phase 02, 10, 14 |
| Tutorial steps | Phase 11, 14 |
| Every relay | Phase 07, 08, 11 |
| Every door | Phase 07, 11 |
| Enemy hearing | Phase 06, 08, 11 |
| Decoy | Phase 09, 11, Chrome Web smoke |
| Death | Phase 06, 08, 10 |
| Restart | Phase 05, 07, 10, 11 |
| Pause | Phase 02, 03, 05, 10, 13, 14 |
| Volume controls | Phase 13, 14 |
| Accessibility settings | Phase 14 |
| Victory | Phase 02, 07, 08, 10, 11 |
| Return to menu | Phase 02, 08, 10 |
| Web export | Final export + Chrome Web smoke |
| Windows export | Final export + PE/PCK static verification |

## Final exports

Commands run:

```bash
godot --headless --path . --export-release "Web" build/final/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/final/windows/echo-kickoff.exe
```

Final Web export:

- `build/final/web/index.html`
- `build/final/web/index.js`
- `build/final/web/index.pck`
- `build/final/web/index.wasm`
- `build/final/web/index.png`
- `build/final/web/index.icon.png`
- `build/final/web/index.apple-touch-icon.png`
- `build/final/web/index.audio.worklet.js`
- `build/final/web/index.audio.position.worklet.js`

Final Windows export:

- `build/final/windows/echo-kickoff.exe`
- `build/final/windows/echo-kickoff.pck`

Windows static verification:

```text
build/final/windows/echo-kickoff.exe: PE32+ executable (GUI) x86-64, for MS Windows
build/final/windows/echo-kickoff.pck: data
```

## Web browser QA

Local server:

```bash
python3 -m http.server 8770 --directory build/final/web
```

Chrome normal-profile smoke passed:

```text
CHROME_GUI_LOGS_MATCHED {"boot":true,"canvas":true,"keyboardStart":true,"ambience":true,"mousePulse":true,"mouseDecoy":true,"resize":true,"fullscreenEquivalent":true,"errorCount":0}
```

Observed Chrome engine logs:

```text
Godot Engine v4.7.stable.official.5b4e0cb0f
OpenGL API OpenGL ES 3.0 (WebGL 2.0 ... Chromium) - Compatibility
Build configuration: Emscripten 4.0.20, single-threaded, no GDExtension support.
ECHO_KICKOFF_BOOT_OK
ECHO_KICKOFF_AUDIO_USER_GESTURE_OK
ECHO_KICKOFF_AUDIO_CUE_OK industrial_ambience
ECHO_KICKOFF_AUDIO_CUE_OK echo_pulse
ECHO_KICKOFF_AUDIO_CUE_OK decoy_impact
```

Chrome canvas checks:

- Initial normal browser client area: 1280×633 CSS pixels, 2560×1266 backing pixels at device pixel ratio 2.
- Resize check: 1024×768 CSS/backing pixels.
- Fullscreen-equivalent check: 1920×1080 CSS/backing pixels.

Firefox final smoke:

- Firefox 152.0.5 headless launched the final Web export and produced a 1280×720 PNG screenshot without process failure.
- No Firefox console automation stack was available in this session. Phase 15 remains the latest full Firefox interactive smoke evidence.

## Packaging

Itch.io Web ZIP:

- `build/final/package/echo-kickoff-web-itch.zip`
- Size: 10,680,463 bytes
- Contains only the nine required Web export files at ZIP root.
- Does not include source files.
- Does not include debug tools.
- Does not include docs/tests/tools/project files/Git metadata.

ZIP root:

```text
index.apple-touch-icon.png
index.audio.position.worklet.js
index.audio.worklet.js
index.html
index.icon.png
index.js
index.pck
index.png
index.wasm
```

SHA-256 checksums:

- `build/final/SHA256SUMS.txt`

Release metadata created:

- `VERSION`
- `docs/final-build-manifest.md`
- `docs/known-issues.md`

## Release-mode/debug checks

Release PCK checks found no packaged references to:

- `tests/`
- `tools/`
- `marketing/`
- `scenes/debug/`
- `scripts/debug/`
- `sector_00_test`
- `sector_00_visual`

Godot remap/resource path names for production `.gd`/`.tscn` files remain visible in the PCK, which is normal for Godot release exports using bytecode/script remaps. Source files are not included in the itch.io Web ZIP as separate files.

## Known non-breaking issues

See `docs/known-issues.md`.

Most important release caveats:

- Windows build was not natively launched on Windows hardware from this macOS host.
- Firefox final QA in this session was load/screenshot-only; Phase 15 contains the prior full Firefox smoke evidence.
- Browser audio requires Start/user gesture, as expected.

## Final decision

**PASS**

Echo Kickoff has a final Web export named `index.html`, a Windows release export, an itch.io Web ZIP with required files at ZIP root, SHA-256 checksums, version metadata, a final build manifest, and a known-issues document. The project remains feature-frozen and suitable for submission, subject to the external itch.io/GitHub/team/video checks listed above.
