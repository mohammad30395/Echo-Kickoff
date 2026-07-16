# Echo Kickoff — Tutorial Revision Audit

Date: **2026-07-17**

Scope: revised visibility-model and player-tool onboarding

Renderer/platform target: Godot 4 Compatibility, Web and Windows

Result: **PASS**

## Revision boundary

The locked mission, authored facility, movement, visibility strengths, Pulse and noise balance, Listener behavior, objectives, win/lose rules, and export targets are unchanged. This revision changes only tutorial sequencing, contextual prompts, banner presentation, and wording consistency.

The implementation remains typed GDScript and Godot Control/CanvasItem drawing. It adds no gameplay feature, external asset, shader, library, C#, GDExtension, or renderer-specific dependency.

## Authoritative teaching model

The onboarding now teaches the revised three-layer visibility hierarchy directly through play:

1. Ambient structure prevents an unreadable black screen.
2. Passive local awareness gives the Player a small, silent navigation area at all times.
3. Active Echo reaches substantially farther and reveals more strongly, but publishes a loud noise that attracts Listeners.

Keyboard and mouse remain the default and complete control scheme. The optional on-screen Move Pad is introduced only when the player enables it in Accessibility.

## Ordered tutorial flow

| Stage | Player-facing copy | Trigger | Completion evidence |
|---:|---|---|---|
| 1 | `MOVE // WASD / ARROWS` | New run starts. If the optional pad is enabled, the suffix `+ OPTIONAL PAD` appears. | Player moves at least 48 px from spawn. |
| 2 | `LOCAL // YOU CAN ALWAYS SEE A LITTLE AROUND YOU` | Movement action is understood. | Player continues beyond the separate 132 px orientation band while seeing the bounded local glow. |
| 3 | `PULSE // REVEAL FARTHER: [SPACE] / LEFT MOUSE` | Local visibility has been observed. | Player emits a real Echo Pulse. Early Pulse input cannot skip stages 1–2. |
| 4 | `DANGER // PULSE REVEALS, BUT CALLS LISTENERS` | First taught Pulse. | A Listener reacts to Echo/relay noise and the warning remains readable for at least 1.35 seconds. |
| 5 | `INTERACT // HOLD [E] AT RELAYS / EXTRACTION` | Pulse danger has been demonstrated. | A valid facility interaction completes. Locked/unavailable controls do not present an actionable lesson. |
| 6 | `DECOY // [Q] / RIGHT MOUSE MISDIRECTS LISTENERS` | Interaction is understood. | A decoy is thrown. An early decoy cannot skip danger or interaction teaching. |
| 7 | `MISSION // RESTORE 3 RELAYS, THEN EXTRACT` | Decoy use is understood. | Relay progress updates in context; at 3/3 the copy becomes `EXTRACTION // POWERED: RETURN TO ENTRY`; extraction completes onboarding. |

Each completed lesson is stored in the current facility run and cannot reappear. Restart/new game creates a fresh facility and therefore correctly resets the run-local tutorial.

## Trigger and event-order safeguards

- The first two lessons use concentric, direction-independent distance bands, so the authored route does not require a hidden directional corridor trigger.
- The `if/elif` transition intentionally prevents one long frame, test teleport, or high-speed movement from completing both Move and Local in the same update.
- Pulse is gated behind completion of the local-visibility observation; premature Pulse input cannot advance onboarding.
- Echo noise is published before `pulse_started` in the existing runtime. The revised flow records an early Listener reaction, then starts the danger lesson when the Pulse action arrives instead of skipping it.
- Listener confirmation uses a pause-aware 1.35-second timer. Whether the noise or Pulse signal arrives first, the orange consequence message remains readable before interaction guidance replaces it.
- Interaction and decoy completion are order-gated. A legitimate early interaction is remembered and consumed only after danger teaching; an early decoy never skips a prerequisite.

## Banner, prompts, and wording

The top-center banner retains the reusable procedural HUD frame and adds a visible seven-segment progress track. Completed/current segments advance with the action sequence; redraw occurs only when the tutorial or accessibility state changes.

| Semantic state | Presentation |
|---|---|
| Movement, local visibility, Pulse | Cyan frame, stage tag, instruction text, and progress. |
| Pulse danger | Orange warning frame plus explicit `DANGER` and Listener wording. |
| Interaction, decoy, mission | Gold accent plus action/tool text. |
| Powered extraction | Green-cyan accent plus explicit return instruction. |

Color is never the only signal. The stage tag and instruction text remain present in every palette, including high-contrast mode.

Interaction prompts now distinguish `HOLD TO INTERACT` from unavailable `SYSTEM STATUS` feedback. Tutorial, cooldown HUD, pause help, interaction prompts, and How to Play consistently use `[SPACE]`, `[E]`, `[Q]`, Left Mouse, and Right Mouse terminology. The How to Play panel contains five short action-oriented lines rather than a paragraph.

## Optional movement-aid behavior

| Check | Observed result | Result |
|---|---|---|
| Default run | First prompt is keyboard-first and does not mention a pad. | PASS |
| Enabled before Start | First prompt becomes `WASD / ARROWS + OPTIONAL PAD`; the bounded pad is visible. | PASS |
| Setting changed during first lesson | Copy refreshes immediately without resetting or advancing the lesson. | PASS |
| Setting disabled | Keyboard-only copy returns; keyboard and mouse remain fully functional. | PASS |
| Later lessons | Pad wording does not intrude into visibility, danger, interaction, decoy, or mission guidance. | PASS |

## Automated verification

`tests/tutorial_revision_test.gd` covers:

- keyboard-first and conditional-pad copy;
- exact Move and Local trigger boundaries;
- local-versus-farther reveal wording;
- premature Pulse/decoy resistance;
- both sides of the Echo-noise/Pulse event-order race;
- the complete seven-stage action order;
- permanent per-run dismissal;
- semantic frame state and seven-stage progress data;
- interaction action/status framing;
- one-line tutorial copy no longer than 56 characters.

The prior Phase 01–15, joystick/HUD, visibility-revision, and visual-pass tests were also run. All **20** test scripts passed. The authored Phase 08 and Phase 11 routes specifically passed the new movement → local observation → Pulse order, all three relays, decoy withdrawals, extraction, Victory, layout checks, and restart behavior.

`git diff --check` passed with no whitespace error. Godot parsed and exported the changed scenes/scripts with no broken reference or script warning.

## Browser and visual verification

The release Web export was exercised in Chromium 150 through a local HTTP server. The in-app browser endpoint was unavailable in this environment, so the page was driven through Chrome's local debugging protocol.

| Check | Observed result | Result |
|---|---|---|
| Start and focus | A real mouse click started the run and preserved the browser audio gesture; active element remained `CANVAS`. | PASS |
| Move → Local → Pulse | Real `W` input advanced the distinct 48 px and 132 px bands; the bounded local glow remained visible before the much larger Echo ring. | PASS |
| Pulse consequence | Real left mouse input produced the broad cyan Echo, orange accents, cooldown state, and orange Listener-danger banner. | PASS |
| Optional pad | Enabling the menu checkbox before Start produced the conditional hint and visible bounded pad without changing primary controls. | PASS |
| 1280×720 | Canvas was exactly 1280×720; all HUD and tutorial content remained inside safe bounds. | PASS |
| 1024×768 resize | Canvas resized exactly to 1024×768; tutorial, objectives, tool HUDs, and pause menu remained readable and separated. | PASS |
| Pause/resume | Escape opened the existing pause screen and resumed cleanly with tutorial state retained. | PASS |
| Console | 0 page-log errors, runtime exceptions, target crashes, or failed resource loads in the final passes. | PASS |

Final visual review also caught and corrected a progress-layer ordering issue: the segment track is now drawn above the frame fill and is visibly advancing in the Web canvas.

## Performance and Compatibility

Chromium sample during the active tutorial at 1280×720:

| Measurement | Result |
|---|---:|
| Animation frames sampled after warm-up | 115 |
| Mean frame time | 16.68 ms |
| Calculated mean rate | 59.96 FPS |
| p95 frame time | 17.60 ms |
| Maximum frame time | 17.80 ms |
| JavaScript heap used | 9,933,360 bytes |
| Runtime documents / frames / DOM nodes | 1 / 1 / 47 |

The orientation check is one distance calculation in the facility's existing `_process()` path and stops advancing completed stages. Tutorial progress draws seven short lines only on message/accessibility changes. Signal connections replace polling for the optional-pad setting, Listener reaction, interactions, objectives, and extraction. No scene-tree scan, new physics query, per-frame container allocation, shader, particle system, or WebAssembly gameplay thread was added.

Fresh release exports completed for `Web` and `Windows Desktop` using the Compatibility renderer. The Web artifact remains single-threaded and contains no thread worker file.

## Asset and scope review

No external or non-code asset was added. The revised onboarding presentation is original jam-authored Control/CanvasItem work recorded under `VIS-007`; the action/status interaction framing is recorded under `VIS-006`. The asset ledger's 2026-07-17 tutorial review is **Approved**.

The revision adds no mobile conversion, touch API, new mechanic, enemy radar, objective, narrative panel, level content, or third-party dependency. It stays inside the locked GDD, scope lock, revised visibility design, and GameJam technical constraints.

## Acceptance result

- Passive local visibility taught through observation: **PASS**
- Stronger/longer-range Echo taught through action: **PASS**
- Pulse danger demonstrated immediately and readably: **PASS**
- Keyboard/mouse remain primary: **PASS**
- Optional movement aid introduced contextually: **PASS**
- Interaction before decoy; decoy taught as misdirection: **PASS**
- Objectives before powered extraction: **PASS**
- Short, permanent per-run lessons: **PASS**
- Banner/prompt/wording consistency: **PASS**
- Browser resizing, focus, performance, and Compatibility: **PASS**
- Regression, export, asset, and scope compliance: **PASS**

Final result: **PASS**
