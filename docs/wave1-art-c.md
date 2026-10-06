# Wave 1 art — Group C

Twelve new item models from `docs/design/wave1-data.json`: four Godly, four Celestial and four Secret. No toilet upgrade models belong to this assignment; Comet Commode and The Last Toilet are collectible **items**. Work stays on `feature/wave1-art-c`, uncommitted.

## Rebuild

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-wave1-c.ps1
./scripts/build-wave1-c.ps1 -Only HaloHamster,CosmicCourtesy
./scripts/build-wave1-c.ps1 -NoRender
./scripts/build-wave1-c.ps1 -VerifyOnly
./scripts/build-wave1-c.ps1 -Draft
./scripts/build-wave1-c.ps1 -SheetsOnly
```

Requires Blender 4.5 and Windows PowerShell/System.Drawing. Override the local Blender path with `-Blender`. The default path matches the existing repository pipeline. No add-ons, downloads, Python packages, asset uploads or runtime changes are required. `-Only` preserves other entries and revalidates all entries currently in the Group C manifest. Use a full build after changing Group C's atlas. A clean partial render build produces a partial sheet; after a complete build, focused iterations regenerate the complete sheets.

`-Draft` writes 320px composition reviews under `assets/previews/wave1/c/draft/` and separate `_draft` sheets; it does not overwrite the final PNGs. The normal build writes 768px front and three-quarter images using the same Cycles lighting, floor, color transform, cameras and 16-sample ceiling as the original set. Adaptive sampling has a four-sample minimum. Source `.blend` files are saved before the preview rig is added.

Temporary drafts remain in this worktree because automatic approval review blocked optional cleanup. They are intermediate review images and may predate the last refinement; use the manifest-linked 768px images and `_sheet_c.png` / `_sheet_c_front.png` for acceptance.

The atlas is packed into each saved `.blend` as well as embedded in FBX. The entry script exits the background process explicitly only after every synchronous save and round-trip check succeeds: local Blender teardown otherwise remained hung after completion. Errors still fail with a nonzero exit code. The launcher accepts either a PowerShell array or a comma-separated `-Only` argument.

## Files

- Builders: `assets/blender/wave1_c.py`.
- Build, private atlas creation, export and independent round-trip checks: `assets/blender/build_wave1_c.py`.
- PowerShell launcher and labeled sheets: `scripts/build-wave1-c.ps1`.
- `assets/manifest-wave1-c.json`: authoritative measured triangle counts, sizes in Roblox X/Y/Z studs, IDs, exact display names, paths, budgets and FBX hashes.
- `assets/validation-wave1-c.json`: latest validation results for every manifest entry.
- `assets/textures/Wave1Palette_c.png`: opaque 256px atlas. The existing 32-slot painted-gradient layout is retained; unused `slate` becomes silver `#C4D4E5`, used only by Celestial gray details. Other colors retain the original values. `ToyPalette.png` is never written.
- `assets/models/wave1/c/<Id>.fbx`: one static joined mesh and one material, with the exact private PNG embedded.
- `assets/blender/generated/wave1/c/<Id>.blend`: editable asset-only scenes.
- `assets/previews/wave1/c/<Id>.png` and `<Id>_front.png`: final 768px previews.
- `assets/previews/wave1/_sheet_c.png` and `_sheet_c_front.png`: labeled final contact sheets.
- `docs/research/wave1-c-export.md`: current official-source checks.

The twelve stems are `DrainKraken`, `GeyserGorilla`, `ThroneColossus`, `PlungerPaladin`, `HaloHamster`, `CometCommode`, `ConstellationClam`, `StarlightSeraph`, `TheLastToilet`, `EmergencyUniverse`, `InfiniteOccupied`, and `CosmicCourtesy`.

## Technical contract

Authoring is Z-up, front -Y, in stud-valued units. FBX uses Z Forward / Y Up, FBX Unit Scale and scale 1. Import into Studio with Front / Top / Stud and scale factor 1. Origins are the horizontal bounds center at minimum height zero. Item bounds are uniformly normalized to the brief's largest target dimension, preserving the authored silhouette; the other dimensions are measured, not forced to the proposed target box.

Validation rejects over-budget exports, nonfinite vertices, zero-area triangles, nonmanifold component edges, extra meshes, missing or multiple materials/UV maps, UVs outside the padded atlas, missing exact embedded PNG bytes, missing Base Color image links, nonzero base height, displaced origins, or round-trip dimensions differing by 0.001 stud or more. The stricter individual brief budgets are used, not just the overall 2,500 ceiling. Render floors, lights and cameras are absent from the exported files.

Shared builders, helpers, manifests, existing assets and `src/` are read-only. No commits or uploads are made.

## Weaknesses and integration boundary

- Silver, gold and starlight are opaque painted colors and thick geometry. These FBXs do not create real illumination, bloom or particles. Celestial runtime glow still needs manager-owned Studio integration.
- Models are static, single meshes with intersecting closed components rather than boolean-unioned solids. Arms, doors, halos, glove and lever cannot animate separately. Use simple collision or existing gameplay collision parts.
- Brief size boxes are composition targets. Actual width/height/depth differ where needed to preserve readable silhouettes; consult the manifest when placing models.
- Tiny ribs, drain slots and constellation details will soften at phone thumbnail sizes. The principal shapes and faces carry identification.
- Blender round trips do not prove Studio's importer preserves pivots, moderation/ownership permissions, texture assignment, or final appearance under game lighting. No Studio import/upload test or fabricated asset IDs are supplied.

## Validation and visual review

The initial geometry pass passed all twelve FBX round trips; Halo Hamster and Comet Commode were simplified to meet their tighter brief budgets. `rojo build -o build.rbxl` passed. Luau format/lint tools do not apply to these Python/PowerShell-only additions; no Luau was changed.

The draft review inspected all twelve front and three-quarter views against the original item sheets. Corrections moved Halo Hamster's towel in front of its ear, raised the clam's soap pearl and constellation to reveal the grin, moved The Last Toilet's mouth out of the bowl surface, changed the cabinet inset to red for white-symbol contrast, and lowered Cosmic Courtesy's gold orbit while smoothing its three comet arcs. The revised affected views were inspected again before final rendering. Full-resolution review then widened the gap beside Comet Commode's shortest tail prong so all three tips remain distinct.

| Item | Triangles | Brief budget |
|---|---:|---:|
| Drain Kraken | 2,160 | 2,500 |
| Geyser Gorilla | 2,164 | 2,500 |
| Throne Colossus | 1,608 | 2,450 |
| Plunger Paladin | 1,760 | 2,400 |
| Halo Hamster | 2,260 | 2,300 |
| Comet Commode | 2,348 | 2,400 |
| Constellation Clam | 1,608 | 2,400 |
| Starlight Seraph | 1,596 | 2,500 |
| The Last Toilet | 1,788 | 2,500 |
| Emergency Universe | 2,292 | 2,500 |
| Infinite Occupied | 1,988 | 2,300 |
| Cosmic Courtesy | 2,092 | 2,500 |

Full-size review also raised and thickened the two miniature toilet seat rims to remove visible bowl/rim surface overlaps without adding triangles.

Final acceptance, 2026-10-06: all 12 FBX round trips passed after the last polish; 12 exact IDs/display names and brief budgets matched the JSON; all FBX/source/texture files exist; the 24 final PNGs are 768x768; FBX and atlas SHA-256 values match the manifest. Both final contact sheets were inspected. `rojo build -o build.rbxl` passed again. `git diff --exit-code` was clean: all deliverables are new, uncommitted files on `feature/wave1-art-c`.

Specific residual tradeoffs: the clam uses angular scalloped fans with raised silver ribs, so its shell is more graphic than organic; Comet Commode's opaque tail resembles icy jets; the hamster's towel partly overlaps one ear; Cosmic Courtesy's three arcs overlap in three-quarter view. These are visible toy geometry choices, not hidden particle dependencies. All six Seraph wing tips, six Kraken pipe ends and three nested door openings remain distinct in front view.
