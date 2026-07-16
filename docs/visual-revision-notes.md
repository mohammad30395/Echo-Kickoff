# Echo Kickoff — Visual Direction Revision Notes

Date: **2026-07-17**

Scope: **Documentation-only visual comfort, usability, and judge-facing presentation revision**

Implementation status: **NOT STARTED**

## Reason for revision

The released implementation successfully establishes the Echo-versus-danger loop, but its baseline world visibility is intentionally extreme:

- `EchoRevealable.darkness_visibility` defaults to `0.012`.
- Production sector geometry overrides it to `0.01`.
- Sector floors are close to black and grid alpha is approximately `0.045`.
- The player is visible, but wall and prop outlines are designed to be nearly absent between pulses.
- Echo currently provides a strong **345 px** reveal and the player has no separate local visibility field.
- No optional on-screen movement aid currently exists.

That baseline fulfilled the earlier “almost completely dark” direction but creates a visual-comfort and presentation risk: a player may understand the mechanic yet still experience blind collisions, fatigue, or an under-detailed first impression. This revision changes the baseline readability target without changing the stealth-horror identity or the central theme mechanic.

## Revised design decision

The facility will use three visibility layers:

| Layer | Range / presence | What it communicates | Noise / danger |
|---|---|---|---|
| Ambient world layer | Always present, very low contrast | Floor zoning, large structural mass, scene depth, broad orientation | Silent; never alerts Listeners |
| Passive player-local light | Small soft radius, target 120–160 px | Immediate floor, nearby collision edges, short pathing decisions | Silent; no `NoiseEvent`; navigation-only |
| Active Echo Pulse | Broad, temporary, current tuned radius 345 px | Strong outlines, long-range layout, hazards, objectives, Listener silhouettes | Emits the dangerous Echo noise event |

Passive local light is not a flashlight mechanic and is not player-triggered. It cannot be aimed, upgraded, consumed, or used to reveal the full route. It is a comfort/readability baseline. Echo remains the only broad, high-clarity information action and retains its existing cost.

After Echo fades, objects return to the ambient/local baseline—not to complete visual absence.

## Locked color roles

| Role | Direction | Anchor |
|---|---|---|
| Player | Cyan/white | `#5BE7F2`, `#D9FAFF` |
| Echo / information | Cyan-blue | `#52D9FF` |
| Listener danger / alert | Orange-red | `#FF5C3A` |
| Relay / objective | Yellow-gold or bright cyan | `#FFD166`, `#64F2FF` |
| Extraction | Green-cyan | `#45F0B0` |
| Walls / structures | Dark blue-gray with luminous edges | `#16283A`, `#31556B` |
| Hazard / blocked system | Orange-red | `#FF7043` |
| Background / floor | Blue-black and dark navy | `#050A12`, `#0B1624` |
| Primary text | Cool white | `#E8FBFF` |

These roles must also be expressed through silhouette, icon, text, fill pattern, motion, or brightness. Color alone is never authoritative.

## Presentation rules

- Preserve darkness and tension through limited range, low contrast, incomplete information, sound pressure, and enemy behavior.
- Keep the player as the clearest world-space focal point.
- Give structures visible mass through subtle fills, edge bands, floor zones, room motifs, and controlled accents.
- Use Echo for the strongest outlines and long-range detail.
- Make danger state apparent in both world feedback and HUD using orange-red plus shape/text/motion.
- Keep pulse readiness, relay progress, decoy count, interaction prompt, and danger state readable within browser safe areas.
- Support high-contrast and reduced-flash settings without removing immediate collision readability.
- Avoid expensive full-screen shader loops and Compatibility-unsafe features.

## Optional joystick policy

Keyboard and mouse remain the required and complete desktop control scheme. An on-screen movement control is permitted only as optional presentation/usability polish:

1. Prefer a simple directional movement pad or joystick-like visual aid.
2. If drag-based movement is tested, pointer capture must stay inside the control region.
3. The control must be hideable or disabled by default.
4. It must not overlap HUD, interaction prompts, player focus, or browser safe margins.
5. Mouse aim, left-click Pulse, right-click Decoy, keyboard movement, pause, and menu focus must remain unchanged.
6. It does not add mobile support to scope.
7. If it causes any input or layout regression, omit it.

## Scope preserved

This revision does not change:

- the theme statement or Echo/noise tradeoff;
- the three-relay and extraction mission;
- Listener behavior or noise hierarchy;
- the one-facility content scope;
- Godot 4, GDScript, Compatibility renderer, Web/Windows, or keyboard/mouse requirements;
- the asset-provenance policy;
- the combat, inventory, multiplayer, procedural-level, and third-party-asset cuts.

## Future implementation acceptance checks

- At rest with no recent pulse, a player can see the player marker, nearby floor, and collision boundaries without seeing the complete route.
- At least one before/after capture proves the world is layered and aesthetically composed rather than nearly black.
- A pulse is immediately distinguishable by range, intensity, outline detail, and temporary long-range information.
- Passive local visibility emits no sound event and does not change Listener state.
- Player, Echo, danger, relay, extraction, wall, and hazard roles match the locked hierarchy and retain non-color cues.
- HUD communicates local orientation, pulse readiness, relay count, decoys, interaction, and danger at 1280×720, 1024×768, and 1600×900.
- Keyboard/mouse-only completion still passes. Any optional movement aid also passes focus, pause, mouse-aim, resize, and hide/show tests.
- Web and Windows exports retain Compatibility behavior and acceptable frame time without new per-frame tree scans or full-screen shader loops.

## Documentation revision audit

**PASS — documentation only**

- New color system: documented.
- Ambient world visibility: documented.
- Player-local visibility rules: documented.
- Passive local light versus active long-range Echo: documented.
- Optional joystick/movement-pad policy: documented.
- UI hierarchy and danger-state expectations: documented.
- Scope, technical constraints, accessibility, provenance, and performance protections: preserved.
- Gameplay implementation: intentionally not changed in this revision.
