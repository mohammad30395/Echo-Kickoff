# Echo Kickoff — Phase 12 Visual Audit

Audit date: **2026-07-15 (Asia/Dhaka)**

Scope: **Approved visual-production pass, original branding assets, and deterministic raster outputs**

Engine: **Godot 4.7.stable.official.5b4e0cb0f**

## Outcome

The visual-production pass is complete. Echo Kickoff now has one coherent original visual language across the menu, gameplay HUD, procedural facility, reveal system, export icon, and itch cover draft:

- near-black industrial fields preserve uncertainty;
- cool cyan and pale-ink geometry communicates Echo, information, and player control;
- restrained orange communicates danger, invalid targets, interruption, and objective pressure;
- gold identifies the limited targeted decoy resource;
- minimal geometric construction remains legible without detailed illustration or image sprites.

No gameplay rule, level topology, mission count, enemy behavior, shader, particle effect, audio asset, external dependency, or locked-scope feature was added. The optional noise texture was deliberately omitted: the existing bounded procedural grid and facility drawing already provide surface variation without adding a sampler, import, or raster dependency.

## Visual system

| Role | Color | Use |
|---|---|---|
| Void | `#02060C` | Near-black environment and cover ground |
| Panel | `#05111C` | Restrained industrial UI surfaces |
| Echo | `#5BE7F2` | Reveal arcs, player-facing information, active outlines |
| Ink | `#D9FAFF` | High-priority centers and readable logo strokes |
| Warning | `#FF6B35` | Hostility, danger accents, invalid/interrupted state |
| Decoy | `#F7C84B` | Targeted limited sound resource |

The four gameplay icons share a 64x64 canvas and 4 px line weight. The logo uses a 640x160 transparent canvas with a 4 px echo motif and a 6 px wordmark stroke so it remains readable at menu scale. All SVGs use geometry only: there are no `<text>`, embedded images, filters, scripts, external links, or font dependencies.

## Produced assets

| Asset | Exact dimensions | Background/alpha | Purpose |
|---|---:|---|---|
| `assets/branding/echo-kickoff-logo.svg` | 640x160 | Transparent | Menu wordmark and original echo/warning mark |
| `assets/ui/icons/pulse.svg` | 64x64 | Transparent | Echo Pulse HUD identity |
| `assets/ui/icons/interact.svg` | 64x64 | Transparent | Interaction prompt identity |
| `assets/ui/icons/decoy.svg` | 64x64 | Transparent | Limited decoy HUD identity |
| `assets/ui/icons/relay.svg` | 64x64 | Transparent | Objective/relay identity |
| `assets/branding/game-icon.png` | 512x512 RGBA | Transparent surround | Project, Web, and Windows application identity |
| `marketing/itch-cover-draft.png` | 630x500 RGBA | Intentionally opaque | Edge-to-edge itch cover draft |

The cover is intentionally opaque because the delivery surface is a complete cover image; all reusable logo/icon assets and the game-icon surround retain transparency.

## Deterministic PNG production

`tools/generate_assets.py` is the source of truth for the two exact-size PNGs. It uses only original Pillow drawing primitives and fixed constants:

- no random seed or nondeterministic input;
- no network access;
- no external image or texture;
- no font lookup or rasterized typeface;
- no prompt-driven or generative-image service;
- 4x supersampling followed by fixed Lanczos downsampling;
- PNG compression level 9 with optimization disabled.

`assets/generated-assets.json` records the generator version, supersample factor, size, mode, transparency policy, and SHA-256 for each output. `python3 tools/generate_assets.py --check` regenerates in memory and compares exact committed bytes.

| Output | SHA-256 |
|---|---|
| `assets/branding/game-icon.png` | `e17893d1e63c4245eda97935ea868de196690c10b90eecd436ac39cd7bfad339` |
| `marketing/itch-cover-draft.png` | `a3767e6b9724dc9afa08c882db8fb867e3cc53a3c1145a7ba3745dec0568721c` |

## Integration

- Main Menu replaces the built-in-font title with the transparent original SVG logo in an aspect-preserving `TextureRect`.
- Pulse, interaction, decoy, and objective HUD scenes use the matching SVG symbols as small semantic anchors while retaining their existing text and procedural state feedback.
- The relay SVG is a low-alpha watermark; authoritative 0/3 state nodes and text remain unchanged and readable without color.
- `project.godot` uses the generated 512x512 PNG as the application icon.
- Windows application and console-wrapper icon settings use the same original PNG.
- Marketing output, the generator, tests, build output, and the generated provenance manifest are excluded from release resource packs. Required runtime branding and UI icons remain included.

Every integrated `TextureRect` preserves aspect ratio. Live Web inspection confirmed crisp line weights and no stretching, overlap, clipping, or unreadable state at exact 1280x720 and 1024x768 canvases.

## Import, alpha, and interpolation checks

| Check | Evidence | Result |
|---|---|---|
| SVG dimensions | Source width/height and Godot imported texture sizes match 640x160 or 64x64 exactly. | PASS |
| SVG transparency | Transparent source policy and transparent corner survive Godot import. | PASS |
| SVG safety | No text, image, filter, script, xlink, or external content. | PASS |
| PNG dimensions/mode | 512x512 and 630x500, both RGBA. | PASS |
| Game icon alpha | Transparent outer corners/surround verified in source and imported texture. | PASS |
| Cover alpha | Edge-to-edge opaque output verified at all corners. | PASS |
| Interpolation | Aspect-preserving UI layout; lossless source imports; mipmaps disabled; SVG scale 1.0. | PASS |
| Line consistency | All four icons assert the shared 4 px stroke; menu-scale logo uses documented 4/6 px hierarchy. | PASS |

## Compatibility and performance

- Renderer remains `gl_compatibility`; Web remains single-threaded.
- SVGs and PNGs import as ordinary Godot `Texture2D` resources supported by Web and Windows.
- No Compatibility-unsafe shader, full-screen sample loop, compute pass, C#, GDExtension, native plugin, Phaser.js, or Three.js was introduced.
- Runtime icons are static UI textures. Existing procedural environment and reveal effects remain bounded CanvasItem drawing.
- Mipmaps are disabled for the small UI/vector resources, avoiding unnecessary memory and preserving intended line work.
- Marketing and generation sources are not packed into runtime builds.

## Authorship and license review

VIS-011 and VIS-012 in `docs/04-asset-ledger.md` record the exact paths, creator/process, date, rights basis, modifications, and approval state. All new artwork is original jam work created for Echo Kickoff. The review found no protected character, recognizable third-party logo, copied game material, photograph, stock asset, downloaded font, external-license dependency, NSFW content, or itch.io-incompatible material.

The generator, manifest, SVG source, PNG source outputs, and Godot import records are retained in the repository as provenance evidence. No attribution is legally required for the new set; final credits should still identify the team's original visual production for transparency.

## Automated validation

Primary commands:

```bash
python3 tools/generate_assets.py --check
godot --headless --path . --script tests/phase_12_visual_test.gd
```

Observed evidence:

```text
ASSET_CHECK_OK
assets/branding/game-icon.png 512x512 RGBA transparent
marketing/itch-cover-draft.png 630x500 RGBA opaque
VISUAL_SVG_OK | original paths, exact canvases, transparent imports, shared 4 px icon weight
VISUAL_PNG_OK | game icon 512x512 transparent, itch cover 630x500 opaque, RGBA manifest recorded
VISUAL_INTEGRATION_OK | logo and four UI symbols load through responsive TextureRects
VISUAL_COMPATIBILITY_OK | project/export icons configured, Compatibility + single-threaded Web retained
PHASE_12_VISUAL_TEST_OK
```

## Regression and platform validation

| Check | Result |
|---|---|
| Clean headless editor import/parse | PASS — no broken reference, parse error, or warning. |
| Phase 1–11 regression suites | PASS — every prior automated phase marker observed with no warning/error diagnostics. |
| Phase 12 visual suite | PASS |
| Deterministic PNG byte check | PASS |
| Repository whitespace check | PASS |
| Web release export | PASS — HTML, WebAssembly, loader/worklets, PCK, and generated icon produced. |
| Windows Desktop release export | PASS — valid PE32+ x86-64 executable and PCK with configured icon; execution remains a Windows-hardware gate. |
| Live exported Web visual/input smoke | PASS — Main Menu, New Game, Echo, decoy, pause/resume, 1280x720, and 1024x768 inspected. |
| Browser application exceptions | PASS — none; software-WebGL screenshot readback emitted capture-only performance messages, not game exceptions. |

The live Web build showed the full geometric wordmark, readable HUD symbols, dark baseline, luminous Echo reveal, gold decoy charge feedback, restrained orange warning accents, and correctly dimmed pause overlay. Exact canvas backing and client sizes matched both inspected browser sizes.

## Remaining gates

- Launch and play the Windows artifact on Windows hardware before submission; the current host can verify export structure but not native execution.
- Obtain external human review for cover appeal, first-time icon comprehension, darkness comfort, and reduced-flash/readability expectations.
- The pre-submission asset checklist remains a final-build task because future original audio, final credits, archive evidence, and the exact submitted commit are not yet locked.

## Decision

**PASS**

The approved near-black industrial visual pass, cool Echo language, hostile warning hue, geometric logo/icon set, exact PNG branding outputs, deterministic reproduction path, responsive integration, alpha/import checks, source/license review, full regression suite, fresh Web and Windows exports, and live Web inspection all pass. Windows hardware execution and final external/submission review remain explicit release gates rather than hidden PASS claims.
