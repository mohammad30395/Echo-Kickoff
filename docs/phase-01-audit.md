# Echo Kickoff — Phase 01 Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **M01 project/export baseline only**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Files changed

| File | Purpose |
|---|---|
| `.gitignore` | Ignores Godot cache, local metadata, temporary export files, and generated build output while preserving `build/.gdignore`. |
| `README.md` | Documents requirements, setup, run, validation, controls baseline, and export commands. |
| `build/.gdignore` | Prevents generated exports from being scanned or repackaged as Godot project resources. |
| `project.godot` | Defines the Godot project, boot scene, display/render settings, thread model, and input map. |
| `export_presets.cfg` | Defines Windows Desktop and single-threaded Web release presets. |
| `scenes/boot.tscn` | Minimal responsive technical boot screen. |
| `scripts/boot.gd` | Populates renderer, viewport, and platform diagnostics. |
| `scripts/boot.gd.uid` | Godot-generated stable resource UID for the boot script. |
| `tests/phase_01_project_test.gd` | Repeatable GDScript validation of locked settings, bindings, and export presets. |
| `tests/phase_01_project_test.gd.uid` | Godot-generated stable resource UID for the validation script. |
| `docs/phase-01-audit.md` | This Phase 1 verification record. |

Generated `.godot/` data and all files under `build/web/` and `build/windows/` are ignored and are not release-source changes.

## Settings applied

- Project name: `Echo Kickoff`.
- Main scene: `res://scenes/boot.tscn`.
- Pinned engine feature: Godot `4.7`, GL Compatibility.
- Scripting: GDScript only.
- Base viewport: `1280×720`.
- Responsive 2D stretch: `canvas_items` with `expand` aspect handling.
- Renderer: `gl_compatibility` for desktop and mobile/platform fallback.
- Render thread model: `0` (single-threaded; no separate render thread).
- Web export: `variant/thread_support=false` and `variant/extensions_support=false`.
- Windows export: `build/windows/echo-kickoff.exe`.
- Web export: `build/web/index.html`.
- Generated builds and tests are excluded from packaged project resources.
- No addons, third-party plugins, GDExtensions, C#, native libraries, package manifests, or external JavaScript source were added.

### Input map

| Action | Inputs verified |
|---|---|
| `move_up` | W, Up Arrow |
| `move_down` | S, Down Arrow |
| `move_left` | A, Left Arrow |
| `move_right` | D, Right Arrow |
| `echo_pulse` | Space, Left Mouse Button |
| `interact` | E |
| `throw_decoy` | Q, Right Mouse Button |
| `pause` | Escape |
| `restart` | R |

The inputs are configuration only. The boot scene does not implement gameplay.

## Tests run

| Test | Evidence | Result |
|---|---|---|
| Documentation prerequisite | Every file that existed under `docs/` was read in full before project changes. | PASS |
| Editor project parse/import | `godot --headless --path . --editor --quit` exited 0 with no parse, import, plugin, or GDExtension errors. | PASS |
| GDScript parse | `godot --headless --path . --script scripts/boot.gd --check-only` exited 0. | PASS |
| Configuration/input test | `godot --headless --path . --script tests/phase_01_project_test.gd` printed `PHASE_01_PROJECT_TEST_OK` and exited 0. | PASS |
| Headless scene boot | `godot --headless --path . --quit-after 3` printed `ECHO_KICKOFF_BOOT_OK` with `gl_compatibility`. | PASS |
| Native 1280×720 boot | Windowed Compatibility run printed `viewport=1280x720`; captured frame was visually inspected and showed the exact title plus renderer, viewport, and platform diagnostics. | PASS |
| Responsive 4:3 resize | A `1024×768` window produced an expanded `1280×960` 2D canvas without a boot error. | PASS |
| Web release export | `godot --headless --path . --export-release Web build/web/index.html` exited 0 and produced HTML, PCK, JavaScript loader, and WebAssembly artifacts. No `*.worker.js` thread worker was produced. | PASS |
| Windows release export | `godot --headless --path . --export-release "Windows Desktop" build/windows/echo-kickoff.exe` exited 0 and produced a PE32+ x86-64 executable plus PCK. | PASS |
| Export isolation | Clean rebuild logs package only the boot scene/script and project metadata; `build/` and `tests/` content is excluded. | PASS |
| Ignore rules | `git check-ignore` confirmed `.godot/`, Web/Windows output, `.DS_Store`, `.pck`, and `.tmp` paths are ignored. | PASS |
| Prohibited technology scan | Source scan found no `.cs`, `.gdextension`, `.dll`, `.so`, `.dylib`, `.js`, `.ts`, `package.json`, addons, Phaser.js, Three.js, or Next.js. | PASS |

## Known limitations

- The exported Web build was generated successfully but was not live-smoke-tested in a browser because browser automation was unavailable in this session. A browser run remains required before the submission build is accepted.
- The Windows executable was generated on macOS and identified as a valid PE32+ x86-64 binary, but it was not launched on a Windows machine. Clean Windows execution remains required before submission.
- Godot's headless dummy display reports an expanded square canvas (`1280×1280`) with `expand` stretch. Native windowed checks report the correct `1280×720` base at 16:9 and responsive `1280×960` canvas at 4:3.
- Export binaries are local generated evidence and are intentionally ignored rather than committed.
- There is no gameplay, player controller, echo pulse, decoy, interaction, pause, or restart behaviour in this phase. Only their input actions are configured, as required.
- No game art or audio assets exist yet; the boot screen uses Godot controls and the engine's built-in font.

## Decision

**PASS**

Phase 01 satisfies the requested technical-baseline scope: the Godot 4.7 project parses and boots, uses only GDScript and the Compatibility renderer, has responsive 1280×720 display settings, provides isolated Windows and single-threaded Web presets, defines and verifies every requested input action, contains no prohibited dependency or gameplay implementation, and documents reproducible setup and validation steps.
