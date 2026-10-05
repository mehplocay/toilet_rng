# Visual rendering research (2026-10-05)

## Lighting, sky and post processing

- Creator Docs: https://create.roblox.com/docs/environment/lighting and https://create.roblox.com/docs/reference/engine/classes/Lighting
  Technology is deprecated. LightingStyle Soft is the stylized option. Soft with PrioritizeLightingQuality enabled uses shadow maps. ShadowSoftness only applies to Realistic; do not claim it adjusts Soft shadows.
- Platform release: https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-is-fully-live/3401512/1
  Unified Lighting went live July 23, 2025. ShadowMap maps to Soft + prioritized quality. These settings are not scriptable: configure them in the Rojo project, not runtime scripts. Use Soft for this outdoor toy world, with a few shadowless local lights.
- https://create.roblox.com/docs/environment/atmosphere and https://create.roblox.com/docs/reference/engine/classes/Sky
  Atmosphere Color/Decay/Haze control sky scattering; Density obscures distant geometry and must be balanced with Offset. Use light blue scattering, low density and warm sunlight. Keep engine sky defaults rather than supply external skybox asset IDs; code-built cloud puffs provide silhouettes.
- https://create.roblox.com/docs/environment/post-processing-effects
  Bloom exaggerates bright surfaces; color correction controls saturation/contrast; SunRays follow sun occlusion. Effects can disappear at low graphics quality. Keep them subtle and ensure geometry/colors remain readable without them. DepthOfField blurs world detail; omit it for gameplay readability and mobile cost.

## Materials and lights

- https://create.roblox.com/docs/parts/materials
  Built-in materials avoid custom texture dependencies. MaterialVariant is a reusable tileable PBR material and would require texture assets, so omit it here. Glass refraction is not supported on mobile; Diamond needs a blue silhouette and opaque ice/seat accents as well as translucent glass. Use SmoothPlastic for toys, Metal for gold, Neon only for accents.
- https://create.roblox.com/docs/effects/light-sources and https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments
  PointLight emits in every direction; SpotLight emits a cone. Range controls affected area. Extra shadow casters cost low-end performance; keep short ranges and Shadows false. Neon visually glows but separate lights are needed to illuminate neighbors.
- https://devforum.roblox.com/t/spotlight-projections-have-significant-banding/3808569
  An engine response dated September 2, 2026 identifies spotlight banding as a current limitation. This world uses a few shadowless PointLights instead of broad overlapping spotlights.

## Particles, beams and trails

- https://create.roblox.com/docs/effects/particle-emitters
  Rate and Lifetime control live particle population; mobile emitters have lower limits. Avoid large overlapping translucent sprites/flipbooks. Keep idle rates 2-4/s, short lifetime, small sprites and distance-cull client idle effects. Sphere/cylinder emitter shapes need BasePart parents, not Attachments. Bursts use Rate 0 and Emit, with cleanup.
- https://devforum.roblox.com/t/improve-the-performance-of-particleemitters/3547121
  Community measurements disagree on absolute capacity but show that overlapping large particles can be expensive. Treat these as observations, not a universal FPS guarantee; profile actual mobile devices.
- https://create.roblox.com/docs/effects/beams and https://create.roblox.com/docs/effects/trails
  Both connect attachments; beams can use curves and low segment counts; trails accumulate geometry as attachments move. Use only four short fountain beams; omit permanent trails to avoid needless overdraw.
- https://create.roblox.com/docs/reference/engine/classes/Beam/LocalTransparencyModifier
  Official example identifies rbxasset://textures/particles/sparkles_main.dds as an engine-bundled sparkle texture. It is centralized in Assets, with no marketplace/external asset ID. It supplies sparkle, bubble and ember sprites; orbiting stars are code-built shapes with attached emitters.

## UI, fonts and prompts

- https://create.roblox.com/docs/reference/engine/classes/UIGradient
  Supported on Frames/buttons/labels, not TextBox or ScrollingFrame. Use two color stops; avoid rebuilding sequences each frame or combining gradients with legacy TextStroke. Button gradients belong to a background Frame, with a separate outlined label.
- https://create.roblox.com/docs/reference/engine/classes/UIStroke
  Border strokes use ApplyStrokeMode Border; text strokes use Contextual. Keep outlines static rather than animate thickness on every frame.
- https://create.roblox.com/docs/reference/engine/enums/Font
  FredokaOne is available in Enum.Font; the current enum no longer lists GothamBlack. Use FredokaOne consistently, without external font asset IDs.
- https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
  Custom style delegates visuals to the client; PromptShown/PromptHidden manage UI and InputHoldBegin/InputHoldEnd support custom touch input. Retain the existing server Triggered handler and owner attribute, keyboard and gamepad binding.
- https://create.roblox.com/docs/reference/engine/classes/TweenService and https://create.roblox.com/docs/reference/engine/classes/Model
  Infinite repeat tweens support Pause/Play/Cancel. A tweened NumberValue rotates the Galaxy star Model through PivotTo; reset from 2*pi to 0 has the same orientation. Destroying models cancels local tweens and disconnects their value listeners.
- https://create.roblox.com/docs/reference/engine/classes/BasePart and https://create.roblox.com/docs/reference/engine/classes/ViewportFrame
  Decorations are anchored and disable collision, touch and queries. Walkable floors retain collision. Viewport previews use the same primitive builders with their own Camera/WorldModel and omit auras, particles and lights.

## Tools and verification

- https://rojo.space/docs/v7/project-format/ documents service $properties and enum serialization. Installed Rojo 7.7.0 supports LightingStyle; build verifies project serialization.
- https://github.com/JohnnyMorganz/StyLua documents Luau formatting and --check. Use installed StyLua 2.5.2; run existing Luau checks after formatting.
- https://kampfkarren.github.io/selene/usage/standard-library.html documents custom standards. The repo's Roblox standard library may be unavailable; report actual lint result separately from build/tests.

## Implementation assumptions and budgets

The task's geometry sentence contradicts its cylinder/sphere requirements. Interpret it as permitting built-in Part shapes and WedgeParts, prohibiting MeshParts, SpecialMesh and runtime unions. Everything is generated in code. Hub budget excludes plot descendants; plot counts include its toilet and current display models. No server idle animation replication: clients run distance-limited, lifecycle-cleaned tweens. Actual rendering, touch prompt behavior and frame time still require Studio/device verification.

Existing saved profiles allow 100 display slots while gameplay currently grants three. To stay under 400 parts without changing reservations/remotes, capacities above five rotate through five physical stands every ten seconds, with a page indicator. All reserved items remain accessible in collection UI.
