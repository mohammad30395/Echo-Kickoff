# Echo Kickoff — GameJam Compliance

Status: **Phase 0 planning gate**  
Audit date: **2026-07-15 (Asia/Dhaka)**  
Event: **IUT 12th ICT FEST 2026 GameJam**  
Official theme: **KICKOFF**

## Sources and precedence

This document was checked against the following official pages on 2026-07-15:

1. [Official GameJam rulebook](https://iutictfest26.tech/gamejam/rulebook)
2. [Official itch.io jam page](https://itch.io/jam/12th-iut-ict-fest-2026-gamejam)
3. [Official IUT ICT Fest GameJam page](https://iutictfest26.tech/gamejam)

If the sources conflict, follow the latest direct organizer announcement. Until clarified, use the earliest published deadline as the internal safety deadline. Save screenshots or links for any organizer clarification.

### Known schedule conflict

- The rulebook and itch.io prose describe the online round as July 14–20, 2026.
- The event landing page describes a July 13–19 build window.
- The itch.io page exposes its own submission-open/close timestamps.

Therefore, the team must target a tested, uploaded, public submission by **2026-07-19 17:00 Bangladesh time**, then verify the exact itch.io dashboard deadline and official Discord announcements. This internal target does not override an earlier organizer notice.

## Locked project identity

- Title: **Echo Kickoff**
- Format: 2D top-down stealth-horror
- Premise: A nearly dark facility can be perceived only through temporary sound-pulse echoes. Every pulse that reveals space also alerts sound-sensitive enemies called Listeners.
- Objective: Restore three reactor relays, then reach extraction.
- Theme statement: **“Every echo pulse kicks off vision for the player and danger from the enemy.”**

The pulse is not decorative: it initiates both the player's information window and the enemy response. This is the primary, repeated interpretation of **KICKOFF**.

## Rule compliance matrix

| Requirement | Echo Kickoff decision | Phase 0 evidence/status |
|---|---|---|
| New game made during the jam | No pre-existing project or game files will be imported. | PASS — initial commit contains only `.gitattributes`; Git history inspected. |
| Repository empty at jam start | The initial commit contains no game project or assets. | PASS — commit `d00df39`, dated 2026-07-15 +0600. |
| Maintain a Git repository | Work will be committed in meaningful, chronological increments. | PASS — repository exists; ongoing obligation. |
| Public GitHub repository | Submission repository must remain public. | PENDING EXTERNAL CHECK — remote is configured; visibility must be verified before submission. |
| Theme is KICKOFF | Each pulse kicks off revelation and danger. | PASS — mechanically central, documented in the GDD. |
| One new game per team | Only Echo Kickoff will be submitted. | PASS by project lock; ongoing obligation. |
| PC game, keyboard and mouse | WASD, mouse/Space pulse, E interact, Esc pause. | PASS by design; build test required. |
| Windows or Web | Produce both if stable; at least one verified working build is mandatory. | PASS by technical plan; export test required. |
| No extra runtime/software for player | Standalone Windows export and/or browser build. | PASS by design; clean-machine test required. |
| Working itch.io build | Upload, make public, download/reopen, and test before cutoff. | PENDING implementation/submission. |
| Team of 1–3 registered eligible members | Team roster is frozen and must match registration. | PENDING team verification; valid student IDs required onsite. |
| No member substitution | Freeze roster from registration onward. | PENDING ongoing compliance. |
| No NSFW content | Horror is tension-based; no sexual or graphic-gore content. | PASS by content policy; ongoing review. |
| No itch.io ToS violations | All content and page material must comply. | PASS by policy; final review required. |
| No copyrighted game materials | Use original procedural visuals and original/generated-in-project audio only; no ripped or franchise-derived content. | PASS by asset policy; ledger review required. |
| Required submission information | Include team name, members, engine/framework, how to install, how to play, repository, video, credits, and known critical bugs. | PENDING submission page. |
| Pitch/gameplay video | Short video explains mechanics, design, and theme link; upload by July 21, 11:59 PM Bangladesh time. | PENDING. |
| Submission freeze | No project, build, or Git changes after the online deadline and before onsite judging. | PENDING; mandatory freeze procedure below. |
| Onsite exact submitted game | Preserve submitted executable and source snapshot. | PENDING archive. |

## Technical compliance lock

These project-level constraints are stricter than the event rules and are mandatory:

- Godot 4.x only.
- GDScript only.
- Compatibility renderer.
- Web and Windows export targets.
- Keyboard and mouse only; a gamepad is not required.
- No C#, GDExtension, Phaser.js, or Three.js.
- No copyrighted third-party game assets; prefer procedural primitives and shaders compatible with the Compatibility renderer.
- No network, account, installer, external database, or extra runtime requirement.

Before implementation, pin the exact Godot editor version in the first implementation commit and use that version for all final exports.

## Submission checklist

### Before feature freeze

- [ ] Confirm team name, 1–3 member names, eligibility, registration, and repository visibility.
- [ ] Confirm the live deadline in itch.io and the official Discord.
- [ ] Confirm the exact Godot version and available Web/Windows export templates.
- [ ] Review every asset against `docs/04-asset-ledger.md`.
- [ ] Meet every must-have acceptance criterion in the GDD and scope lock.

### Build and itch.io

- [ ] Export a Windows build that starts without the editor or extra installs.
- [ ] Export a Web build and test browser audio/input/fullscreen behavior.
- [ ] Test from a clean folder and, where possible, a second Windows machine and a second browser.
- [ ] Upload at least one working build; upload both only if both pass.
- [ ] Set the itch.io project and jam submission visibility correctly.
- [ ] Include team name, member names, Godot 4/GDScript, controls, how to play, GitHub URL, credits, and known issues.
- [ ] Download/reopen the uploaded build and complete a full run.
- [ ] Confirm the entry appears in the jam submissions list.

### Pitch video

- [ ] Show the pulse revealing the world and simultaneously provoking a Listener.
- [ ] Show one relay activation, escalation, all three relays complete, and extraction.
- [ ] Explain the exact KICKOFF interpretation in one sentence.
- [ ] Use the official naming rules. The rulebook says `TeamName_GameName`; the itch.io page additionally requests `IUT_ICT_FEST_2026` in the YouTube title and `#IUT_ICT_FEST_2026_GAMEJAM` in the description. Satisfy both.
- [ ] Add the video link to the itch.io submission before **2026-07-21 23:59 Bangladesh time**.

### Freeze and onsite preservation

- [ ] Record the final commit hash and itch.io upload timestamp.
- [ ] Tag the commit `jam-submission` without changing it afterward.
- [ ] Archive the exact source, Windows build, Web build, video, and screenshots locally.
- [ ] Make no post-deadline repository or game changes before onsite judging.
- [ ] Bring project files, executable, laptop, mouse, keyboard, chargers, and registered student IDs if selected.

## Judging alignment

| Criterion | Weight | Planned evidence |
|---|---:|---|
| Theme | 25% | One pulse visibly kicks off both perception and enemy investigation. |
| Gameplay | 25% | Repeated information-versus-danger decisions, readable enemy state changes, three objectives, extraction. |
| Design | 25% | Compact hub-and-spoke layout, escalating relay sequence, quick restarts, tuned pulse costs. |
| Visual & Audio | 15% | High-contrast echo rings, temporary silhouettes, spatial cues, restrained procedural soundscape. |
| Video Pitch | 10% | Short capture that demonstrates the complete loop and directly states the theme adaptation. |

## Phase 0 decision

**PASS**

Reason: the repository began with only `.gitattributes`, its single initial commit is inside the jam period, the concept directly implements **KICKOFF**, and the documentation locks a feasible and rule-compatible production plan. This is a Phase 0 planning pass, not final submission approval. Eligibility, public visibility, implementation, exports, itch.io upload, video, asset review, and the post-deadline freeze remain mandatory later gates.
