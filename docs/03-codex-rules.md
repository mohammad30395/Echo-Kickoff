# Echo Kickoff — Codex Rules

These rules govern all automated or assisted changes in this repository during the jam.

## Read first

Before making a change, inspect:

1. Git status and recent history.
2. The six files in `docs/`.
3. Existing project conventions and nearby code once the Godot project exists.
4. The asset ledger for any non-code file.

Never overwrite or discard unrelated user changes. If the worktree is dirty, separate the requested change from existing work.

## Phase boundary

Phase 0 is documentation only. Do not create `project.godot`, scenes, scripts, imports, export presets, art, audio, or gameplay until the user explicitly starts the implementation phase.

## Locked stack

- Godot 4.x; pin the exact version when implementation begins.
- GDScript only, typed where practical.
- Compatibility renderer.
- Windows and Web targets.
- Keyboard and mouse.
- No C#, GDExtension, native binary plugins, Phaser.js, or Three.js.
- No required network access, account, installer, database, or extra runtime.

Do not add addons, packages, generated binaries, or external services without explicit user approval and a compliance review.

## Scope discipline

- Implement must-haves in the exact M01–M10 order in `docs/02-scope-lock.md`.
- Treat its stretch list and cut-list as hard gates.
- Prefer one clear system over configurable architecture.
- Reuse the same sound-event path for player noise and Listener hearing.
- Prefer authored, compact content over procedural level generation.
- Fix or simplify a failing must-have before adding polish.
- Do not silently reinterpret the concept, add game modes, or increase content count.

## Godot engineering rules

- Keep scene responsibilities small and explicit: player, Listener, relay, extraction, level/game flow, UI, and audio.
- Use signals for discrete events such as sound emitted, relay activated, caught, and run completed.
- Use groups or narrowly scoped references instead of global tree searches every frame.
- Avoid unnecessary autoloads; one game-state/settings autoload is the maximum unless justified.
- Avoid per-frame allocation, broad `get_nodes_in_group()` scans, and complex physics queries when event-driven logic suffices.
- Use deterministic state transitions for Listener AI. Log or expose the current state during development, then disable noisy debug output for release.
- Put tuning values in exported typed variables or a small constants resource; do not scatter magic numbers.
- Keep gameplay independent of frame rate using `_physics_process(delta)` and Godot timers appropriately.
- Pause, restart, scene reload, and victory must disconnect or reset transient state cleanly.
- Keep paths and filenames lowercase `snake_case`; use `PascalCase` class names and `snake_case` variables/functions/signals.
- Treat warnings and parse errors as failures. Do not suppress errors to make a test appear green.

## Rendering and export rules

- Use 2D CanvasItem-compatible primitives and effects that work in the Compatibility renderer.
- No gameplay-critical effect may depend on unsupported Web shaders, HDR, compute, or renderer-specific behaviour.
- Test an exported Web and Windows build at the end of every vertical milestone, not only at submission time.
- Avoid case-sensitive resource-path mistakes; Web exports may expose them.
- Keep build output outside tracked source directories unless a deliberate release folder is approved.
- Never commit `.godot/`, editor cache, imported temporary output, credentials, signing keys, or local machine paths.

## Asset and licensing rules

- Prefer runtime procedural visuals and team-created audio.
- Do not download, generate, import, trace, imitate, or reference copyrighted game characters, logos, maps, sprites, music, SFX, UI, or other recognizable franchise material.
- Do not assume “free,” search-result availability, or AI generation makes an asset safe.
- Record every non-code asset in `docs/04-asset-ledger.md` before it enters a release build.
- Approved status requires creator/source, creation date, license/permission, modifications, and repository path.
- Reject NSFW material, itch.io ToS violations, unclear provenance, or incompatible license terms.
- If third-party material ever becomes necessary, obtain explicit user approval and use only clearly licensed material allowed by the event; the stricter project policy still prefers CC0. Preserve the source URL and license proof.

## Accessibility and safety rules

- Essential information cannot rely on audio alone or color alone.
- Avoid rapid flashing and high-amplitude jump-scare audio.
- Keep reduced shake/flash options functional whenever those effects exist.
- Maintain readable controls, interaction prompts, and state indicators at 1280×720.
- Horror remains non-graphic and non-NSFW.

## Verification required for every change

Use the smallest relevant set, expanding with risk:

1. Parse/static check for every changed GDScript.
2. Headless or automated scene boot where possible.
3. Manual focused test of changed behaviour.
4. Restart/reload test for stateful changes.
5. Web and Windows export smoke test for milestone or rendering/audio/input changes.
6. Full acceptance pass before submission.

Report what was actually tested and any untested risk. Never claim an export or playtest passed without running it.

## Git and jam integrity

- Keep commits small, descriptive, and chronological; do not falsify, squash away, or rewrite jam history.
- Do not commit secrets, personal tokens, or large unreviewed binaries.
- Do not change the remote, force-push, publish, submit, or tag without user authorization.
- Before final submission, verify repository visibility, commit hash, asset ledger, exported artifacts, and itch.io page.
- After the official online deadline, make no project or repository modifications before onsite judging. Read-only inspection is allowed; any organizer-authorized exception must be documented.

## Stop conditions

Stop and ask the user before:

- changing the locked concept, engine, renderer, language, input/platform targets, must-have count, or asset policy;
- adding a dependency, addon, third-party service, or third-party asset;
- removing a must-have rather than applying an automatic cut;
- performing destructive Git operations, publishing, submitting, or changing public visibility;
- acting when an official rule conflict could cause disqualification.

## Completion report format

Every implementation handoff should state:

- outcome and user-visible behaviour;
- files changed;
- tests run and results;
- asset-ledger changes;
- remaining risks or acceptance criteria;
- whether the scope lock and GameJam compliance remain intact.
