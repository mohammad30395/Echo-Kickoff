# Phase 17 Submission Package

Result: **PASS — documentation package prepared**

Date: 2026-07-15

## Scope

This phase prepared final submission copy and pitch planning documents only. Gameplay code was not modified.

Source documents reviewed:

- `docs/00-gamejam-compliance.md`
- `docs/phase-16-final-qa.md`
- `docs/known-issues.md`
- `docs/04-asset-ledger.md`

## Created submission documents

- `docs/itch-page-copy.md`
- `docs/pitch-script.md`
- `docs/final-freeze-record.md`
- `docs/phase-17-submission-package.md`

## Submission materials prepared

| Required material | Location |
|---|---|
| itch.io short description | `docs/itch-page-copy.md` |
| itch.io full game description | `docs/itch-page-copy.md` |
| How to Play section | `docs/itch-page-copy.md` |
| Controls section | `docs/itch-page-copy.md` |
| Team/member placeholders | `docs/itch-page-copy.md`, `docs/pitch-script.md`, `docs/final-freeze-record.md` |
| Engine/framework statement | `docs/itch-page-copy.md` |
| Public GitHub repository field | `docs/itch-page-copy.md` |
| Asset credits | `docs/itch-page-copy.md` |
| Known non-breaking issues | `docs/itch-page-copy.md`, `docs/known-issues.md` |
| Pitch-video script | `docs/pitch-script.md` |
| Pitch-video shot list | `docs/pitch-script.md` |
| YouTube title | `docs/pitch-script.md` |
| YouTube description with hashtag | `docs/pitch-script.md` |
| Final submission checklist | This file |
| Repository freeze checklist | `docs/final-freeze-record.md` |
| Onsite demonstration checklist | `docs/final-freeze-record.md` |

## Final submission checklist

### Build/package

- [ ] Upload `build/final/package/echo-kickoff-web-itch.zip` as the primary playable Web build.
- [ ] Confirm the itch.io Web ZIP has `index.html` at the ZIP root.
- [ ] If uploading Windows too, upload both `echo-kickoff.exe` and `echo-kickoff.pck` from `build/final/windows/`.
- [ ] Do not upload source files inside the itch.io Web ZIP.
- [ ] Do not upload debug/test builds as the primary submission.
- [ ] After upload, open the itch.io page from a browser and start the game.
- [ ] Complete at least one smoke path: Start → Pulse → Relay interaction → Decoy → Pause → Resume.
- [ ] If time allows, complete a full run through extraction.

### itch.io page

- [ ] Copy the short description from `docs/itch-page-copy.md`.
- [ ] Copy the full description from `docs/itch-page-copy.md`.
- [ ] Copy the How to Play and Controls sections.
- [ ] Replace `[TEAM NAME]`.
- [ ] Confirm Mohammad Mahmudul Kabir Fahmid, Shashwata Nandi, and Animesh Singha Ayon match the registered roster; fill their IDs.
- [ ] Add repository URL: `https://github.com/mohammad30395/Echo-Kickoff.git`.
- [ ] Verify the repository is public from a logged-out browser session.
- [ ] Add asset credits.
- [ ] Add known non-breaking issues.
- [ ] Add the pitch video URL when available.
- [ ] Confirm the page is published/public as required by the jam.
- [ ] Confirm the entry appears in the jam submissions list.

### Pitch/video

- [ ] Record footage using the shot list in `docs/pitch-script.md`.
- [ ] Keep the opening hook within the first 10 seconds.
- [ ] Show one pulse revealing the world and alerting a Listener.
- [ ] Show a sound decoy.
- [ ] Show one relay activation.
- [ ] Show extraction or victory.
- [ ] Use a YouTube title containing `IUT_ICT_FEST_2026`.
- [ ] Include `#IUT_ICT_FEST_2026_GAMEJAM` in the YouTube description.
- [ ] Add the video link to the itch.io submission before the video deadline listed by the organizers.

### External compliance checks

- [ ] Confirm exact live deadline in itch.io dashboard and official Discord/organizer announcements.
- [ ] Confirm team eligibility and registered roster.
- [ ] Confirm no member substitution.
- [ ] Confirm no post-deadline changes are made.
- [ ] Preserve screenshots of final itch.io upload status if possible.

## Deployment note

The live Vercel URL was repaired after Phase 16 by deploying only the static Web export files to the existing Vercel project:

`https://echo-kickoff.vercel.app`

This is useful for previewing, but the official jam submission should still use itch.io according to the compliance document.

## PASS/FAIL

**PASS**

The requested submission copy, pitch script, video shot list, YouTube metadata, final submission checklist, freeze checklist, and onsite checklist are prepared. Remaining work is external submission execution: replacing placeholders, uploading builds/video, verifying public visibility, and freezing the repository after the official deadline.
