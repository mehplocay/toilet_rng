# Wave 1: collectible character and tooling research

Checked 2026-10-06. Supports the proposal in [wave1.md](../design/wave1.md); no assets uploaded or engine APIs introduced.

## Character direction

- BIG Games' own [Pet Simulator 99 Meme Cards update](https://www.biggames.io/post/pet-simulator-99-update-49), published March 1, 2025, presents short adjective/creature names, themed sets, expressive joke characters and exaggerated prestige sizes. Examples on the page include Fancy Axolotl and Sensei Penguin. **Design inference:** a familiar animal plus one unexpected role or object is easy to recognize and describe to a friend. We borrow that design principle, not their characters, names, assets, paid packs or variants.
- The official [Steal a Brainrot listing](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot) centers character acquisition, generated money and rebirth. **Design inference:** a unit is both a visual joke and a visible earning achievement. A recognizable silhouette and an immediately readable income label help make a player's collection worth showing. The listing does not prove that any particular naming formula causes virality. No current ranking, retention lift or copying permission is inferred.
- The owner's reference analysis and the local item/toilet contact sheets establish our own visual baseline: rounded toy geometry, large eyes, clear color blocks and one exaggerated accessory. Wave 1 varies body shape, face placement and accent color, not just rarity recolors. Common characters must also be funny. Celestial uses white/gray/ice/cyan, halos and broad constellation marks; Secret uses impossible compositions. All humor stays original, unbranded and family friendly.

Art acceptance: identify the object and joke at 64px; distinguish the silhouette in black; recognize it with glow disabled; pronounce the name without explanation. These are proposed review criteria, not measured engagement results.

## Technical checks

- [Luau standard library](https://luau.org/library/) and [sandbox documentation](https://luau.org/sandbox/): standalone Luau is a host-sandboxed language without ordinary file I/O. The balance runner therefore converts the canonical JSON to a temporary Luau module in PowerShell. All probabilities, expected values and simulations run in pure Luau; no HttpService, Studio, filesystem shim or third-party JSON package is required.
- [Roblox general mesh specifications](https://create.roblox.com/docs/art/modeling/specifications) and [Importer](https://create.roblox.com/docs/studio/importer): use supported meshes, textures, pivots and explicit import scale. Our 2,500/5,000-triangle budgets are project limits. Reuse the existing atlas and one joined mesh/material per model; an exported shader glow is not assumed to work in Studio.
- [Roblox importer scale-change announcement](https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371) and the existing [pipeline research](blender-roblox-pipeline.md): retain Stud / scale 1, validate one import first, and preserve the shared foot pivot and seat height. The DevForum page returned limited text during this check; the detailed June 2026 unit-conversion history remains sourced by the earlier repository research, not newly revalidated here.
- [StyLua official repository](https://github.com/JohnnyMorganz/StyLua) and [Selene official repository](https://github.com/Kampfkarren/selene): use the available local tools on the added Luau proof only. Rojo's documentation pages were unavailable to the web reader during this check; the repository's existing build command and local CLI help are used for the unchanged project build. No new Rojo behavior is assumed.

No mutation system, Divine tier, new world, copyrighted character, brand, voice line or asset ID is proposed.
