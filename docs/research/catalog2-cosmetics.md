# Catalog 2: cosmetics and tools

Checked 2026-10-06.

- https://create.roblox.com/docs/reference/engine/classes/TextChatService and https://create.roblox.com/docs/reference/engine/classes/ChatWindowMessageProperties — one client OnChatWindowAdded callback; derive properties from ChatWindowConfiguration, use PrefixTextProperties for name color, preserve filtered message/prefix content. Rainbow overhead animates; incoming chat names take the current rainbow hue. Native chat rendering still needs engine QA.
- https://create.roblox.com/docs/reference/engine/classes/Humanoid and https://create.roblox.com/docs/characters/emotes — PlayEmoteAsync depends on an emote in the character's HumanoidDescription and can error. No universal, safely sourced standard animation-ID set was established. Use the owner's permitted toggleable celebration-effect fallback; no animation assets.
- https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter and https://create.roblox.com/docs/reference/engine/classes/RunService — reuse the existing engine-bundled sparkle texture, bounded cosmetic updates, no per-particle connections. Local anchored/noncolliding/nonqueryable companion parts add no server physics.
- https://rojo.space/docs/v7/project-format/ — properties declared via $properties; restore missing baseline TextChatService declaration required by audit harness.
- https://github.com/JohnnyMorganz/StyLua and https://kampfkarren.github.io/selene/roblox.html — format/check changed Luau; Selene requires its Roblox standard library. Do not claim a lint pass if the installation lacks it.

Native Marketplace, PolicyService, filtered chat visuals, streaming and mobile FPS must be verified in an isolated published/Studio session; headless doubles only verify project logic.
