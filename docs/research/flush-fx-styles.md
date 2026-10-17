# Flush FX round 2: styles, toilet motion, comic burst (2026-10-17)

Root cause of "it still looks the same": round 1 built `flushFx` in `init.client.luau` but the
`Result` "Flush" handler never called `flushFx:Flush(item, payload)`. The CLI test called the
controller directly, so it passed while nothing played in a real session. The call now sits
next to `presentation.Reveal`. Settings defaults were already Full (`SkipAnimation = false`,
`RevealIntensity = "Full"`). Manual flushes no longer collapse on the toilet cooldown (only on
the observed gap), so a single flush on a fast toilet still plays in full.

- **Local toilet motion**: the server tweens the real toilet, so the client hides it with
  `BasePart.LocalTransparencyModifier` (client-only multiplier, not replicated; Decals have the
  same property) and animates a pooled clone. Restored on every exit path.
  https://devforum.roblox.com/t/hide-objects-locally/1139730
  https://devforum.roblox.com/t/making-tools-invisible-locally/585272?page=2
  The API page lists the property without a description:
  https://create.roblox.com/docs/reference/engine/classes/BasePart
- **Non-uniform spheres**: Ball parts stay uniform; a `SpecialMesh` with `MeshType.Sphere` can
  be resized freely on all axes (used for the bouncing comet and duck bodies). The toilet clone
  only moves Ball/Cylinder parts and squashes the rest.
  https://create.roblox.com/docs/reference/engine/classes/SpecialMesh
  https://devforum.roblox.com/t/improvements-to-part-shape-size/2443389
  An unconfirmed third-party report claims a 2026 bug resizing non-uniform spheres; check the
  comet bounce in Studio.
- **Beam curves (rainbow)**: P1 = Attachment0 + CurveSize0 along its +X axis, P2 = Attachment1
  - CurveSize1 along its +X axis. Both attachments are rotated so X points up and use
  `CurveSize0 = h`, `CurveSize1 = -h` for an arch. https://create.roblox.com/docs/effects/beams
- Emoji in `TextLabel` text are used for the screen emoji fountain and the poop party (no
  uploaded images). Check glyph rendering on a phone in Studio's device emulator.
- Budgets: live-particle ledger 400 desktop / 150 phone; rate-based streams (geyser, tornado)
  reserve budget for the whole window.
