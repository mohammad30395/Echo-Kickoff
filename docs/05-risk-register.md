# Echo Kickoff — Risk Register

Updated: 2026-07-15  
Scale: Probability and impact are Low, Medium, or High. Owners are roles until the team roster is recorded.

## Active risks

| ID | Risk | Probability | Impact | Prevention / mitigation | Trigger and fallback | Owner |
|---|---|---|---|---|---|---|
| R01 | Official pages disagree on the online build window/deadline. | High | High | Check itch.io dashboard and official Discord daily; use July 19, 17:00 BDT as internal upload target; keep evidence of clarification. | Any earlier organizer notice → freeze, upload, and submit immediately with the best passing build. | Producer |
| R02 | Repository visibility or history fails integrity review. | Low | Critical | Keep the public repo chronological; verify visibility in a logged-out browser; never rewrite jam history. | Repo cannot be viewed or history changed → resolve before cutoff and document organizer-approved action if needed. | Producer |
| R03 | Team eligibility/registration details do not match. | Medium | Critical | Verify 1–3 registered members, frozen roster, eligibility, team name, and student IDs now. | Any mismatch → contact official GameJam contacts/Discord before more production investment. | Team lead |
| R04 | Scope exceeds the remaining jam period. | Medium | High | Enforce M01–M10 order, Jul 18 feature freeze, stretch gate, and automatic cuts. | Miss a daily exit condition → cut polish/branch length/third enemy, not the core pulse–Listener–relay–extraction loop. | Producer |
| R05 | Pulse reveal is visually confusing in near-total darkness. | Medium | High | Prototype reveal first; retain fading geometry memory; safe onboarding corridor; high-contrast shapes. | Players collide or become lost repeatedly → lengthen afterimage, add landmark silhouettes, simplify layout. | Design/Visual |
| R06 | Pulse has no meaningful cost or feels unfair. | Medium | High | Keep Listener hearing radius larger than reveal radius; show investigation state; record pulse origin rather than tracking player. | Players spam safely → adjust cooldown/hearing/patrol. Players feel unavoidable → slow response or increase escape loops. | Design |
| R07 | Listener navigation/state machine gets stuck or oscillates. | Medium | High | Simple explicit states, few agents, authored navigation, timeouts, debug state display, repeated full runs. | More than one unresolved navigation bug after two focused hours → simplify route/state logic or reduce enemy count. | Engineering |
| R08 | Web renderer differs from editor/Windows. | Medium | High | Compatibility renderer from day one; simple CanvasItem primitives; export at every milestone. | Critical shader/effect fails → replace with lines/polygons; preserve Windows submission first if Web remains blocked. | Engineering |
| R09 | Web audio autoplay, latency, or mixing breaks gameplay cues. | Medium | Medium | Start audio only after player gesture; test target browsers; duplicate essential audio cues visually. | Audio unreliable → simplify audio bus/start flow; ensure muted play remains viable. | Audio/Engineering |
| R10 | Windows export fails on a clean machine. | Low | Critical | Install matching export templates early; avoid native dependencies; test unzipped download on second machine. | Failure near cutoff → diagnose packaging first; submit verified Web build if it fully passes and rules permit. | Engineering/QA |
| R11 | A third-party or generated asset has uncertain rights. | Low | Critical | Procedural/team-created-only policy; ledger before import; retain provenance; human review generated output. | Unclear rights or resemblance → remove and replace with primitive/original content. | Asset owner |
| R12 | Asset or content violates NSFW/itch.io/event restrictions. | Low | Critical | Non-graphic horror direction and final content audit. | Any questionable material → remove, do not debate at deadline. | Team lead |
| R13 | Essential information relies only on sound or color. | Medium | High | Pair cues with shapes, motion, rings, icons, and text; test muted and with color-independent states. | Muted tester cannot finish → add visual cue before polish; do not ship the inaccessible state. | Design/QA |
| R14 | Flashing, shake, or volume makes the game uncomfortable. | Medium | High | Smooth pulse fades, conservative defaults, reduced flash/shake, volume buses, no jump-scare spikes. | Tester reports discomfort → disable offending effect by default or remove it. | Visual/Audio |
| R15 | Relay/extraction state desynchronizes after death or restart. | Medium | High | One authoritative run state; explicit reset; restart acceptance tests after each stateful change. | UI and world disagree once → block new work until reset paths pass repeatedly. | Engineering |
| R16 | The level is too large to learn or too cramped to evade. | Medium | Medium | Single compact hub/spoke graybox, playtest timing, loops at relay rooms. | First run exceeds 10 minutes → shorten branches. Unavoidable catches → widen/loop critical areas. | Level design |
| R17 | Pitch video does not clearly show theme adoption. | Medium | High | Capture pulse reveal and simultaneous Listener response in the first gameplay segment; script one-sentence theme statement. | Footage is unclear → recapture from controlled build before video deadline; do not change frozen game. | Pitch owner |
| R18 | Required itch.io information, visibility, or jam entry is missing. | Medium | Critical | Draft page fields early; use compliance checklist; verify logged out; download and retest upload. | Entry absent/private/corrupt → correct and reverify before official cutoff. | Submission owner |
| R19 | Last-minute change breaks the final build. | Medium | Critical | Feature freeze Jul 18, rollback points, versioned artifacts, no stretch without both exports passing. | Regression after freeze → revert the offending change and rebuild from last known passing commit. | Team lead |
| R20 | Changes occur after deadline, causing disqualification. | Low | Critical | Record deadline, final hash and timestamp; tag/archive once authorized; switch to read-only work. | Any required exception → obtain and preserve explicit organizer authorization before changing anything. | Entire team |
| R21 | Browser/Windows performance drops during multiple pulses. | Medium | Medium | Pool/reuse transient visuals, cap trail lifetime/count, avoid per-frame tree scans and allocations. | Frame time spikes → reduce segment/particle counts and afterimage duration; preserve readable ring. | Engineering |
| R22 | A dependency or tool adds hidden runtime/export requirements. | Low | High | No addons/native extensions; Godot/GDScript-only review of every added file. | Dependency proposed → reject unless explicitly approved and proven on both targets before feature freeze. | Engineering |
| R23 | Power, network, or upload failure near deadline. | Medium | Critical | Upload an early playable build, keep local/versioned archives, finish ahead of cutoff, have alternate network/device ready. | Connection becomes unreliable → use earlier verified upload; move to backup connection while preserving freeze integrity. | Submission owner |

## Risk review cadence

- Review critical and high-impact risks at the start and end of each workday.
- Review R05–R16 after every external playtest.
- Review R01, R02, R03, R17, R18, R20, and R23 before any submission action.
- Any critical triggered risk blocks stretch work.
- New risks must be logged with an owner and fallback before related work continues.

## Release blockers

The build must not be called final while any of these are true:

- no verified working Windows or Web export;
- start-to-victory loop cannot complete reliably;
- Listener behaviour can deadlock the critical path;
- relay count or extraction lock can desynchronize;
- required controls/state cannot be understood with audio muted or without color distinction;
- any asset lacks approval/provenance;
- repository is not public or submission information is incomplete;
- uploaded build was not downloaded/reopened and tested;
- final commit/build/video identifiers are not archived;
- official deadline or freeze status is unresolved.

## Residual-risk acceptance

Before submission, the team lead must record any known non-blocking defects on the itch.io page and sign off below. A defect is non-blocking only if it does not prevent boot, keyboard/mouse play, the full objective loop, loss/restart, victory, rule compliance, or safe presentation.

Team lead: **TBD**  
Review time: **TBD**  
Accepted residual risks: **TBD**  
Decision: **PENDING**
