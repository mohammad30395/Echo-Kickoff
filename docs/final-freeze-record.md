# Echo Kickoff — Final Freeze Record

Use this document at the moment the official submission is complete. Do not modify repository, builds, or submitted files after the official deadline.

## Project identity

- Game: Echo Kickoff
- Event: IUT 12th ICT FEST 2026 GameJam
- Theme: KICKOFF
- Theme statement: “Every echo pulse kicks off vision for the player and danger from the enemy.”
- Engine: Godot 4.7 / GDScript / Compatibility renderer
- Primary submission build: Web

## Team record

Team name: **[TEAM NAME]**

Registered members:

1. **Mohammad Mahmudul Kabir Fahmid** — **[Student ID / registration identifier]**
2. **Shashwata Nandi** — **[Student ID / registration identifier]**
3. **Animesh Singha Ayon** — **[Student ID / registration identifier]**

Team contact: **[Contact]**

## Source/build record

Repository URL: `https://github.com/mohammad30395/Echo-Kickoff.git`

Current source baseline before Phase 17 documentation commit:

```text
476727f release: finalize Echo Kickoff submission build
```

Final submitted commit hash: **[fill after committing final documentation and before freeze]**

Suggested final tag after all submission files are confirmed:

```bash
git tag jam-submission
git push origin main --tags
```

Only tag after the itch.io submission is confirmed and no further repository changes are expected.

## Build artifacts

Primary itch.io Web ZIP:

```text
build/final/package/echo-kickoff-web-itch.zip
```

Web export directory:

```text
build/final/web/
```

Windows export directory:

```text
build/final/windows/
```

Checksums:

```text
build/final/SHA256SUMS.txt
```

Vercel preview:

```text
https://echo-kickoff.vercel.app
```

Official itch.io page URL: **[fill after page is published]**

YouTube pitch URL: **[fill after upload]**

Submission timestamp: **[YYYY-MM-DD HH:MM timezone]**

Uploader/account: **[itch.io account name]**

## Repository freeze checklist

- [ ] Final commit hash recorded above.
- [ ] `git status --short` is clean.
- [ ] Final source pushed to GitHub.
- [ ] GitHub repository visibility verified as public.
- [ ] itch.io page published and visible.
- [ ] itch.io build launches from the public page.
- [ ] Jam submission entry appears in the jam submissions list.
- [ ] Pitch video uploaded.
- [ ] Pitch video URL added to itch.io submission.
- [ ] Final source/build/archive copied to local backup storage.
- [ ] `jam-submission` tag created only after final verification.
- [ ] No further commits, force-pushes, build replacements, or itch.io file changes after the official deadline.

## Onsite demonstration checklist

Bring:

- [ ] Laptop with the exact submitted source repository.
- [ ] Exact submitted Web ZIP.
- [ ] Exact submitted Windows export folder.
- [ ] Internet-independent local copy of the game.
- [ ] Godot 4.7 editor installed.
- [ ] Matching export templates installed.
- [ ] Mouse.
- [ ] Keyboard if not using laptop keyboard.
- [ ] Charger/power adapter.
- [ ] Registered student ID cards for all team members.
- [ ] Local copy of pitch video.
- [ ] Screenshots or notes proving itch.io submission timestamp and page visibility.

Before demo:

- [ ] Open the submitted itch.io page.
- [ ] Open the public GitHub repository.
- [ ] Confirm audio works after pressing Start.
- [ ] Confirm pulse, decoy, relay activation, death/restart, and victory route are demonstrable.
- [ ] Keep a fallback local Web server command ready:

```bash
python3 -m http.server 8770 --directory build/final/web
```

- [ ] Keep Windows executable folder intact: `echo-kickoff.exe` beside `echo-kickoff.pck`.

Demo route:

1. Show main menu and state the theme adaptation.
2. Start game and show darkness.
3. Use one Echo Pulse to reveal the world.
4. Show that the pulse attracts a Listener.
5. Throw a decoy and show the Listener investigating it.
6. Activate one relay.
7. Show objective progress.
8. If time allows, show extraction/victory or a prepared clip.
