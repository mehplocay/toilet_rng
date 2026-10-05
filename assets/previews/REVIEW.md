# Visual review — Blender asset set

Reviewed against `docs/reference/mockups.png` and `docs/reference/quality-reference-1.webp` at full preview size and in the labeled contact sheets. The intended treatment is saturated toy plastic, large simple silhouettes, chunky edges and expressive creature eyes. These are Blender renders, not screenshots from Roblox.

## Iterations made after rendering

- Unified the UV layer name on built-in primitives and custom geometry. The first joined export incorrectly sampled the cream swatch on some components; all exported geometry now has exactly one padded atlas UV layer and the FBX reimport checks it.
- Tightened the piped poop swirl so it reads as a continuous stack, moved the eyes forward to prevent their whites being covered, and kept the crown/sparkles within the item budget.
- Removed a narrow strip from Toilet Paper that looked like an attached cord.
- Moved Alien Toilet's pink lights to the outside of its UFO belt instead of leaving partly buried triangles.
- Added a plunger to the stained Dirty Toilet for a visibly different silhouette.
- Put Radioactive Toilet's barrels on the ground; changed Demon's lid inset to black so the red eyes have contrast.
- Aligned palm growth bands with the curved trunk; removed clipped pedestal side decorations; grounded the separate rocks and crystals together.
- Fixed bevel clamping that generated degenerate triangles on thin details. All final closed components pass topology and budget validation.

## Readability review

| Set | Assessment |
| --- | --- |
| Poop / Golden Poop / King Poop | Shared piped silhouette and large eyes; gold color and crown distinguish the upgrades. King has a full crown and two geometric sparkles. |
| Toilet Paper | Hollow cardboard center, paper roll, hanging sheet and perforations are recognizable. |
| Rat | Round ears, pink tail, snout, whiskers and large eyes read at icon size. |
| Fish / Sewer Shark | Bright blue fish with lips; shark has a larger dorsal fin, pectoral fins, gills and visible teeth. Both use a profile presentation. |
| Rubber Duck | Yellow body, orange bill, side wings and lifted tail are clear. |
| Toilet Baby | Oversized peach head, rosy cheeks, hands and cyan pacifier remain readable above the small bowl. |
| Alien Toilet / Mystery | Antennae and black almond eyes; dark orb with contrasting raised question mark and halo. |
| Seven toilet tiers | White porcelain; stained brown/plunger; golden crest/handles; cyan crystals; green hazard barrels; black/red horns/wings; purple orbital ring/stars. All preserve the same foot/seat datum. |
| Palm / Bush / Flowers / Foreground Foliage | Clear broad plant silhouettes and a shared green palette. Three flowers form one pack; foreground leaves are folded solid blades. |
| Bench / Lamp / Fence / Sign | Chunky readable silhouettes. The sign intentionally has a blank face for player text. |
| Golden Trophy | Large crowned toilet on an octagonal blue/gold base. |
| Pedestal / Portal | Strong cyan ring/trim with dark supporting shapes; plaque and portal opening are intentionally empty. |
| Clouds / Rocks and Crystals | Round white puffs contrast with low-poly purple rocks and tall cyan/violet crystal points. |

## Honest limitations

- Smooth shading hides many faces, but close 768px views still reveal faceting on eyes, tube bends and bowl rims. This is most noticeable on the small collectible toilets and poop curls. The set is designed for game and icon distances, not close-up cinematics.
- White paper/cloud highlights lose some subtle surface detail in the studio lighting. Check them against the game's sky and exposure; the atlas itself still contains their colors and gradients.
- Gold uses painted yellow/gold highlights, not a metallic PBR map. Glow-colored trim, lamps and question marks do not emit light. Studio effects are needed for the reference's bloom and aura intensity.
- Foliage is deliberately simpler and more geometric than the reference's dense scenery. Dressing a scene requires repeated/rotated placement and other world lighting work.
- Every FBX is one static mesh. The lids, crowns, ring slots and small packs have no independent motion or material channels. Decorative disconnected shells are closed but not boolean-unioned.
- Upload moderation, experience permissions, Studio pivot preservation, collision and mobile appearance remain manager acceptance checks. No Studio import or publication is claimed.

Exact triangle counts and sizes: `../manifest.json`. Local FBX reimport results: `../validation.json`. Import and integration instructions: `../../docs/asset-pipeline.md`.
