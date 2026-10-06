# Wave 1 art: group T

Eight new toilet models for tiers 8-15, built on `feature/wave1-art-t`. No commit, push, asset upload, or runtime integration. Only new group-owned asset, script, and documentation files are added.

## Rebuild

Requires Blender 4.5 and Windows PowerShell/System.Drawing. The wrapper defaults to the same Blender 4.5.10 installation as the existing asset build.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-wave1-t.ps1

# Geometry, editable sources and mandatory FBX checks, without rendering:
./scripts/build-wave1-t.ps1 -NoRender

# Focused iteration; preserves the other group T manifest records:
./scripts/build-wave1-t.ps1 -Only CloudCushion,ClockworkCloset

# Recompose both contact sheets from existing 768px renders:
./scripts/build-wave1-t.ps1 -SheetsOnly

# Optional Blender location:
./scripts/build-wave1-t.ps1 -Blender 'D:\Tools\Blender\blender.exe'
```

The Python entry also works directly with `blender --background --factory-startup --python-exit-code 1 --python assets/blender/build_wave1_t.py --`. It always reimports each exported FBX; there is no skip-validation switch. `--only` takes exact IDs. `--no-render` intentionally leaves any existing previews unchanged, so render after geometry edits before handing off.

## Files

- Builders: `assets/blender/wave1_t.py`.
- Build/export/validation: `assets/blender/build_wave1_t.py`.
- PowerShell runner and labeled sheets: `scripts/build-wave1-t.ps1`.
- Manifest: `assets/manifest-wave1-t.json`; includes exact IDs/display names, measured Roblox X/Y/Z dimensions, per-brief budgets, FBX/source/preview paths, and toilet datums.
- Round-trip report: `assets/validation-wave1-t.json`.
- Research: `docs/research/wave1-t-export.md`.
- Sheets: `assets/previews/wave1/_sheet_t.png` and `_sheet_t_front.png`.

Each ID below has one FBX at `assets/models/wave1/t/<Id>.fbx`, an asset-only editable scene at `assets/blender/generated/wave1/t/<Id>.blend`, and `assets/previews/wave1/t/<Id>.png` plus `<Id>_front.png`.

| Tier | Exact ID | Display name | Distinguishing geometry |
| --- | --- | --- | --- |
| 8 | CoralCommode | Coral Commode | Six blunt coral tips, teal scalloped lid, gray ridges, cream pearls |
| 9 | CloudCushion | Cloud Cushion | Three broad cloud feet, stepped blue tank, smiling cloud, droplet and towel ring |
| 10 | ClockworkCloset | Clockwork Closet | Navy clock, brass cabinet, six gear teeth, fixed red plunger pendulum |
| 11 | DragonKiln | Dragon Kiln | Friendly large-eyed dragon, cream horns, broad wings, scaled wrapping tail |
| 12 | AuroraThrone | Aurora Throne | Three solid folded fan panels, blue crystal buttresses, cyan star knob |
| 13 | AstralAltar | Astral Altar | Crescent columns supporting cyan halo, silver hexagonal plinth, five-node constellation |
| 14 | ParadoxPotty | Paradox Potty | Three offset rectangular frames, bright inset borders, inverted gold faucet |
| 15 | InfinityFlush | Infinity Flush | Crossing gold/cyan ellipses, dark hourglass foot, starfield inset, white glove lever |

## Shared conventions

`lib.py` and the original `builders.py` are imported read-only. The existing `bowl()` generates the exact bowl, seat rim and water geometry. Every tier keeps seat center **2.08 studs**, the raised oval lid core top **4.79 studs**, and the original foot-centered ground pivot. Decorations are not normalized to a common height. The source brief's size values are targets; actual measured bounds are in the manifest.

The existing `ToyPalette.png` is used unchanged, with exactly one material and one UV layer per mesh. No additional colors or atlas are needed. Its exact PNG bytes are embedded in every FBX; editable Blender scenes pack the image as well. Models face authoring -Y, use Z-up stud-valued coordinates, and export using the existing Z Forward / Y Up, FBX Unit Scale, factor-1 settings. Import in Studio with **Stud / 1**, following `docs/asset-pipeline.md`.

## Verification and visual review

- All eight exports are checked against their individual JSON budgets (4,300-5,000 tris), not merely a blanket 5,000 cap.
- Each FBX is reimported into a clean scene. Checks cover exactly one mesh/material/UV set, finite vertices, padded UVs, closed component surfaces, no zero-area triangles, unchanged triangle count, embedded atlas bytes, 256px texture resolution, ground origin, and dimensions within 0.001 stud.
- Every reimported world-space vertex is compared against source geometry, catching axis/position errors that a bounding-box-only test can miss. Maximum errors and FBX hashes are recorded.
- The common seat and lid datums are asserted before joining. Source `.blend` files contain the asset only; no preview floor, lights or camera enter the FBX.
- Front and three-quarter images use the original 768px studio rig and palette. Review includes the existing model sheets and individual new renders. Cloud facial curves and clock face shading were revised after the first renders; Aurora's side buttresses were extended to ground. Infinity's first tall loops read as a heart, so the final ellipses are broader and cross above the lid, with thick tank supports and explicit star reliefs on the side inset.
- `rojo build -o build.rbxl` passes. No Luau changes are made, so Selene/StyLua have no changed source to lint or format.

## Weaknesses and assumptions

- Studio import, in-game lighting, small-screen appearance, permissions, moderation, collision settings and Roblox pivot preservation are not locally verified. No `.rbxm` or invented IDs are supplied.
- **Clock placement deviation:** the readable clock face overlaps the upper front of the raised lid. Putting the full disk literally behind the unchanged 4.79-stud lid would hide its hands at the requested overall height. Cabinet and pendulum remain at the rear.
- Decorative shells intersect and are joined as one static mesh, rather than boolean-unioned. Lids, pendulum, halo, glove and loops cannot animate separately. Do not use detailed mesh collision for the decorations.
- Silver/gold, water and luminous edges are opaque painted colors, without transparency, emission or VFX. The aurora fan uses solid faceted panels; it does not simulate moving ribbons.
- The raised lids obscure some rear details in straight-on views, especially Coral's three tank pearls and the raincloud tank. The 3/4 images show more of those details. Check the actual camera in Studio before deciding whether to exaggerate them further.
