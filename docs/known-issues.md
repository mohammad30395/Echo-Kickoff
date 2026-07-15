# Echo Kickoff — Known Issues

Date: 2026-07-15

## Non-breaking known issues

1. Native Windows launch was not executed on Windows hardware from this macOS build host.
   - Evidence available: Windows release export succeeded; executable is PE32+ GUI x86-64; matching `.pck` is present.
   - Mitigation: if a Windows machine becomes available before submission freeze, run `echo-kickoff.exe` from the same folder as `echo-kickoff.pck` and complete a short smoke test.

2. Firefox final QA was limited to launch/screenshot load verification in this session.
   - Evidence available: Phase 15 previously passed Firefox Web smoke testing, and the final Firefox run created a 1280×720 screenshot without process failure.
   - Mitigation: prioritize Chromium/Chrome for final manual upload verification, then perform a manual Firefox start/run check if time allows before the official deadline.

3. Browser audio requires a user gesture.
   - This is expected for Web builds.
   - The Start action confirms the gesture and starts ambience/audio routing.

4. Very large WebAssembly payload.
   - `index.wasm` is approximately 39.5 MB.
   - This is normal for a Godot Web export and remains suitable for itch.io/Vercel-style static hosting, but first load can take several seconds.

## Submission reminders

- Verify the itch.io page is public/visible to the jam before the official deadline.
- Verify public GitHub repository visibility.
- Include team name, member names, engine/framework, controls, credits, repository URL, and known issues on the itch.io page.
- Do not modify repository, builds, or submission files after the official deadline.

