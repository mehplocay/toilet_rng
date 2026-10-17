# Flush FX (2026-10-17)

Presentation only. No new remotes, no uploaded asset IDs, no game values touched.

- **Engine-bundled particle textures**: confirmed locally in the installed Roblox client
  (`%LOCALAPPDATA%/Roblox/Versions/*/content/textures/particles/`): `sparkles_main.dds`,
  `explosion01_implosion_main.dds` (soft glow), `explosion01_shockwave_main.dds` (ring),
  `forcefield_vortex_main.dds` (thin spinning ring), `smoke_main.dds`, `SquareParticle.png`.
  Referenced as `rbxasset://textures/particles/...` from `Config/Assets.luau` (`Textures`).
  Web search found no official list of these files, so the local install is the source.
  https://create.roblox.com/docs/effects/particle-emitters
- **ParticleEmitter** shapes: a BasePart-parented emitter uses the part's size/shape; Disc +
  ShapeStyle Surface + ShapeInOut Inward gives the converging drain. `VelocityPerpendicular`
  orientation with an upward emission lays sprites flat (whirlpool/shockwave on the water).
  `Squash > 0` stretches particles vertically (droplet streaks). `Brightness` only applies
  when `LightInfluence = 0`. `Emit(n)` is the bounded one-shot used everywhere here.
  https://create.roblox.com/docs/effects/particle-emitters
  https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
- **Performance**: particles and transparent surfaces add draw calls and overdraw; let the
  client create visual effects locally; pool instead of re-instancing. Implemented as one
  pooled world rig + one pooled overlay set, a live-particle ledger (200 desktop / 90 phone),
  a mobile scale of 0.55 and hard pool caps. Repeated flushes allocate zero instances
  (asserted in `scripts/ui-flush-fx.luau`).
  https://create.roblox.com/docs/performance-optimization/improve
- **Beam**: needs two attachments; `FaceCamera` keeps the 2D strip visible from every angle;
  widths are numbers (animated directly). Visual quality depends on graphics level; check at
  lowest and highest quality in Studio. https://create.roblox.com/docs/effects/beams
- **Trail**: `Clear()` after teleporting the comet back to the bowl so no streak connects the
  old landing point. https://create.roblox.com/docs/reference/engine/classes/Trail
- **Camera**: `Enum.RenderPriority.Camera = 200`. Same undo/apply pattern as the reveal shake:
  undo our last write at 199, write a bounded offset at 201, unbind when done. FieldOfView is
  read back after writing so the equality check survives float precision. DevForum threads
  show FOV tweens fighting other per-frame writers; the undo pattern only restores values we
  wrote, so zoom or other scripts win.
  https://create.roblox.com/docs/reference/engine/enums/RenderPriority
  https://create.roblox.com/docs/reference/engine/classes/RunService
  https://devforum.roblox.com/t/how-to-tween-field-of-view/375560
  https://devforum.roblox.com/t/fov-resetting-randomly/3193471
- Only one camera CFrame writer at a time: Legendary+ leave shake to `RevealEffects`; flush FX
  uses FOV only for big tiers.
- The Camera and Beam API pages are property indexes with little behaviour text; behaviour
  above that is not stated there (default beam texture renders a solid strip, FOV precision)
  must be confirmed in Studio.
