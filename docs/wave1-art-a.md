# Wave 1 art — Group A

Twelve new Common, Uncommon and Rare items on `feature/wave1-art-a`. IDs, English display names, target bounds and individual triangle budgets come from `docs/design/wave1-data.json`. No toilets belong to this group. No runtime changes, uploads, asset IDs, commits or pushes.

## Rebuild

From the repository root, with Blender 4.5:

```powershell
# All FBX files, editable sources, 24 final 768px previews, both sheets and verification.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-wave1-a.ps1

# Fast geometry rebuild; still verifies every manifest FBX.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-wave1-a.ps1 -NoRender

# Focused render iteration, from a PowerShell session.
& ./scripts/build-wave1-a.ps1 -Only SpongeKnight,BubbleBeard

# Verify existing exports or recreate sheets without rebuilding meshes.
& ./scripts/build-wave1-a.ps1 -VerifyOnly
& ./scripts/build-wave1-a.ps1 -SheetsOnly

# Override the default local Blender executable path.
& ./scripts/build-wave1-a.ps1 -Blender 'D:\Tools\Blender\blender.exe'
```

`-NoRender` intentionally leaves existing previews unchanged. After changing geometry, run the focused or full render command before accepting its preview. Partial builds retain other Group A manifest records. Unknown IDs fail before writing. The script never calls the shared palette generator or shared build entry point.

For quick visual review, run Blender with `--background --factory-startup --python-exit-code 1 --python assets/blender/build_wave1_a.py -- --review`. This renders both three-quarter and front 384px, eight-sample drafts under `assets/previews/wave1/a/review/`, without exporting models, sources, manifests or validation. Add `--only Id ...` to focus the review. These scratch drafts are not the final deliverables.

## Files

- `assets/blender/wave1_a.py`: twelve builders and local low-cost trim/face helpers; imports shared geometry and palette helpers read-only.
- `assets/blender/build_wave1_a.py`: isolated export/render pipeline and its own FBX round-trip checks.
- `scripts/build-wave1-a.ps1`: build wrapper and labeled contact sheet generation using Windows System.Drawing.
- `assets/manifest-wave1-a.json`: IDs, exact English names, rarity/category, FBX paths, triangles/budgets, Roblox X/Y/Z sizes, source/preview paths and SHA-256 hashes.
- `assets/validation-wave1-a.json`: per-export verification results.
- `assets/models/wave1/a/<Id>.fbx`: twelve single-mesh, single-material, triangulated models with embedded texture.
- `assets/blender/generated/wave1/a/<Id>.blend`: twelve asset-only editable joined scenes with packed palette texture; the procedural builders retain named component construction.
- `assets/previews/wave1/a/<Id>.png` and `<Id>_front.png`: three-quarter and front views, 768 × 768.
- `assets/previews/wave1/_sheet_a.png` and `_sheet_a_front.png`: overview sheets in rarity order.
- `docs/research/wave1-a-export.md`: current-source export findings.
- `docs/research/wave1-a-sponge-redesign.md`: source checks for the scouring-pad redesign.

IDs: `SudsSlug`, `PocketPuddle`, `LoopyLoofah`, `SoggySock`, `TubTadpole`, `BrushBristle`, `RollMole`, `CapybaraCap`, `DrainCrab`, `ToothpasteGoose`, `SpongeKnight`, `BubbleBeard`.

## Style and interpretation

Uses the existing unmodified `assets/textures/ToyPalette.png`: all requested colors already exist, so no additional atlas is necessary. The FBX embeds the exact PNG bytes. Chunky closed forms, slightly faceted toy silhouettes, large ink pupils and white catchlights follow the existing items. Palette swatch UVs carry the same painted gradients; the final renders reuse the existing Cycles studio rig, Standard view transform, lighting, floor and 16-sample denoising.

Models are authored Z-up, face -Y, and exported Z-forward / Y-up. The entry script fits geometry to each brief's explicit size in Roblox X/Y/Z studs, with the horizontal center of the bounds and minimum height as the origin. All transform scales remain one. These task-specific paths override the proposal's generic `assets/models/items/` destination.

Counts explicitly preserved: three slug foam lobes; three puddle lobes; six loofah folds; three sock droplets; five white toothbrush bristle clumps; four capybara legs and three cap spots; six crab legs and four drain slots; seven beard foam lobes. SpongeKnight's superseded six pores are replaced with six closed woven scrub fibers. Drain slots are atlas-colored faces in the dome itself. Cap spots use shallow closed atlas-colored geometry. No new texture or transparency is required.

## Verification and visual review

The builder enforces each individual brief budget, stricter than the 2,500-triangle global item maximum. Before export it checks finite coordinates, closed manifold component surfaces, nonzero triangle area, exactly one material and one padded atlas UV layer. Every FBX is copied to a temporary directory and reimported; checks cover triangle counts, dimensions within 0.001 stud, base-center pivot, one mesh/material, texture resolution and the exact packed embedded PNG hash. Temporary import data is cleaned automatically.

The first geometry pass exceeded some individual budgets; small trim bevels and foam tessellation were reduced while retaining the required silhouette features. A 384px review of every character was followed by focused corrections: visible dark rear tunnel for Roll Mole, four UV-colored drain slots for Drain Crab, taller exposed white bristles and a smaller quiff for Brush Bristle, and explicit heavy lids for the sleepy characters. Full-resolution review prompted exposed Capybara ears and conforming the Goose beak smile to the surface. SpongeKnight was subsequently redesigned as documented below. The existing palette and preview lighting were preserved.

All twelve FBX round trips passed. The largest dimension discrepancy was below 0.000002 stud. `rojo build -o build.rbxl` also passed; the FBX files are not wired into Rojo or runtime templates by this task. Selene/StyLua do not apply to the new Python/PowerShell files; no Luau was modified.

Final acceptance: all 24 full-resolution views and both labeled contact sheets were inspected. A temporary 64px-per-character sheet confirmed distinct silhouettes and primary color/accessory cues. Tiny face/paw detail is reduced at that size. Source palette packing was checked for all twelve `.blend` files as well as embedded FBX image bytes. Temporary review images and build logs were removed from the handoff.

| ID | Triangles | Brief budget | Size X/Y/Z (studs) |
|---|---:|---:|---|
| SudsSlug | 1,424 | 1,500 | 2.5 / 1.45 / 1.65 |
| PocketPuddle | 1,404 | 1,600 | 2.6 / 1.65 / 2.2 |
| LoopyLoofah | 1,716 | 1,800 | 2.3 / 2.5 / 2 |
| SoggySock | 1,184 | 1,400 | 1.8 / 2.6 / 1.5 |
| TubTadpole | 1,468 | 1,700 | 2.6 / 1.8 / 2 |
| BrushBristle | 1,418 | 1,600 | 1.6 / 2.8 / 1.2 |
| RollMole | 1,764 | 1,900 | 2.7 / 1.7 / 1.8 |
| CapybaraCap | 2,068 | 2,100 | 2.7 / 2.1 / 1.6 |
| DrainCrab | 1,892 | 2,200 | 2.8 / 1.8 / 2 |
| ToothpasteGoose | 1,788 | 2,300 | 2.6 / 2.5 / 1.6 |
| SpongeKnight | 1,908 | 2,200 | 2.4 / 2.7 / 1.5 |
| BubbleBeard | 2,080 | 2,100 | 2.2 / 2.6 / 1.8 |

## SpongeKnight originality pass — 2026-10-06

The earlier yellow rectangular sponge with paired large eyes was too close to SpongeBob's core visual cues. It is replaced by a tall oval teal scouring pad with six leaf-green woven fibers, mint pad feet and teal mittens. A tapered orange bucket helmet with a raised carry handle frames a single half-lidded eye in a dark horizontal visor. The right hand grips a wooden plunger lance with a hollow red rubber cup; the left carries a round mint soap-bar shield with a cream edge and two white bubble emblems. There is no yellow body, pore pattern, exposed paired-eye face, square clothing, tie or teeth. The sleepy little sink guard retains the faceted toy style and shared atlas.

The explicit redesign task overrides only the old SpongeKnight appearance brief and palette list in `docs/design/wave1-data.json`; that shared design file is left untouched. ID `SpongeKnight`, name `Sponge Knight`, Rare rarity, tier/economy data, 2.4 / 2.7 / 1.5 stud bounds, base-center pivot and 2,200-triangle budget remain unchanged. Final geometry is 1,908 triangles, leaving 292 spare.

Only SpongeKnight was rebuilt with `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-wave1-a.ps1 -Only SpongeKnight`. Its FBX, packed editable `.blend`, two final 768px previews, manifest triangle count/hash, validation and both contact sheets were refreshed. The build script's review mode now also produces a front draft. The mandatory round-trip check still covers every manifest FBX.

Final checks passed: all twelve FBX round trips; SpongeKnight's closed/nondegenerate geometry, one mesh/material/UV, exact embedded atlas and packed source palette, base-center pivot and dimensions (maximum error 0.0000004173 stud); and `rojo build -o build.rbxl`. Both final SpongeKnight views and both refreshed contact sheets were visually inspected. A 184-file SHA-256 baseline confirmed that the other eleven FBX/source/preview sets, every `src/` file, shared `lib.py` and `ToyPalette.png` remained byte-for-byte unchanged. Temporary redesign drafts were removed. Selene/StyLua are installed but do not apply to these Python/art changes; no Luau was edited. Work remains uncommitted on `feature/wave1-art-a`, with no uploads or pushes.

### Other eleven models: critical visual scan

Both contact sheets were examined; SudsSlug, TubTadpole, DrainCrab and BubbleBeard also received enlarged individual review. These are visual assessments of the current designs, not exhaustive IP searches or legal clearance.

| ID | Assessment and distinguishing cues |
|---|---|
| SudsSlug | Eye stalks invite a Gary comparison, but this is a mint, shell-less horizontal slug with a cream soap saddle and three foam lobes; no colored spiral shell or corresponding snail palette. Retain. |
| PocketPuddle | Generic animated liquid; three flat puddle lobes, splash arms and an orange pail. No recognizable named-character combination. Retain. |
| LoopyLoofah | Pink and cute can evoke Kirby; six scalloped loofah folds and the tall open hanging loop dominate instead of a spherical body, side arms and red shoes. Retain. |
| SoggySock | Blue bent sock, folded white cuff, wet cyan tufts and orange heel patch. Object anatomy remains distinctive; no close character match observed. Retain. |
| TubTadpole | A toy tadpole could invite Pokemon comparisons, but the lime pear form, broad teal paddle, cyan goggles and orange whistle do not reproduce a recognizable species' signature markings or palette. Retain. |
| BrushBristle | Upright toothbrush with five white bristle clumps, pink paste quiff, teal handle and sleepy face. No close named-character match observed. Retain. |
| RollMole | Brown mole plus generic pink nose; the large sideways open cardboard roll and paper flap dominate. No distinctive costume, mole-character markings or matching silhouette observed. Retain. |
| CapybaraCap | Generic capybara with broad peach muzzle and oversized pink spotted shower cap; no close mascot match observed. Retain. |
| DrainCrab | Raised claws and eye stalks invite a Mr. Krabs comparison; orange squat six-legged anatomy, cream cross-shaped faucet knobs and slotted gray drain shell substantially differ from the red upright clothed crab. Retain. |
| ToothpasteGoose | White/orange waterfowl cues are generic; long cream neck, toothpaste-tube torso, cyan stripe and pink/mint curled paste tail dominate. No sailor costume or matching duck proportions. Retain. |
| BubbleBeard | Generic bearded sage cues; cream soap-bar head, seven foam lobes, mint towel knot and pink comb differ from a named wizard/gnome's costume and silhouette. Retain. |

No other design crossed the close-resemblance threshold in this pass, so none of the eleven was rebuilt. SpongeKnight's orange bucket is shared with PocketPuddle as a bathroom-object motif, but its tall woven pad, visor and held lance distinguish it at contact-sheet scale. The single eye sits in a bucket visor above a tall teal pad; it does not copy a round lime cyclops with horns or a yellow goggled character with overalls.

## Weaknesses and acceptance boundary

- These are static, joined collectibles. Intersecting closed components are deliberately not boolean-unioned; they are unsuitable as detailed collision meshes or separately animated limbs/accessories.
- Atlas patches approximate drain slots and cap spots; there are no physically excavated drain holes. SpongeKnight's scrub weave is shallow closed geometry rather than simulated fibers. Materials are opaque toy colors, with no transparent water or foam.
- Thin smiles, paw creases, small comb teeth and whistle details will lose definition at very small in-game sizes; the larger silhouettes and color accents carry recognition.
- Roll Mole's dark tunnel is clearest in the three-quarter view; the straight front view shows mostly the tube wall. Drain Crab's top slots can pick up bright highlights in the low front preview, while their four dark bands read clearly from above/three-quarter.
- Exact brief dimensions are fitted per axis. This prioritizes the specified bounds over mathematically spherical bubbles and circular eyes after scaling.
- Blender verification does not prove Roblox Studio's pivot preservation, importer texture assignment, moderation, ownership/permissions or appearance in game lighting. Import with Stud / scale factor 1 / Front / Top and perform the manager's Studio acceptance described in `docs/asset-pipeline.md`.
- No `.rbxm`, icon exports, collision proxies, animations or Roblox asset IDs are included in this task.
