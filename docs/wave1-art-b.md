# Wave 1 art — group B

Twelve new Epic, Legendary and Mythic collectibles from `docs/design/wave1-data.json`, using its exact IDs, display names, target X/Y/Z stud boxes and individual triangle budgets. No toilets belong to this group. No runtime edits, uploads, new asset IDs, commits or changes to shared builders/palette/assets.

## Rebuild

From the repository root, with Blender 4.5.10 installed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-wave1-b.ps1
# Geometry/export plus mandatory round trips, without rendering:
./scripts/build-wave1-b.ps1 -NoRender
# Focused rebuild; other B records are preserved:
./scripts/build-wave1-b.ps1 -Only Clogtopus,LaundryYeti
# Verify existing exports without rebuilding:
./scripts/build-wave1-b.ps1 -VerifyOnly
# Reassemble existing preview images:
./scripts/build-wave1-b.ps1 -SheetsOnly
```

Use `-Blender 'D:\Tools\Blender\blender.exe'` to override the executable. No add-ons or Python packages are needed. The PowerShell wrapper uses Windows System.Drawing for sheets. Full generation is deterministic in geometry; FBX metadata can change file hashes between runs.

## Files

- `assets/blender/wave1_b.py`: all twelve builders, local small-detail helpers.
- `assets/blender/build_wave1_b.py`: isolated build, exact stud sizing, FBX exports, previews and round-trip checks. Imports `lib.py` read-only and never calls its palette generator.
- `scripts/build-wave1-b.ps1`: rebuild and contact-sheet entry point.
- `assets/manifest-wave1-b.json`: IDs, names, rarity/category, files, triangle counts/budgets, dimensions, preview/source links and hashes.
- `assets/validation-wave1-b.json`: verification results for every FBX.
- `assets/models/wave1/b/<Id>.fbx`: twelve FBX exports with the unchanged original ToyPalette.png embedded byte-for-byte.
- `assets/blender/generated/wave1/b/<Id>.blend`: twelve editable, joined asset-only scenes with the palette packed; lights, cameras and floor are excluded.
- `assets/previews/wave1/b/<Id>.png` and `<Id>_front.png`: 24 studio previews, 768 × 768.
- `assets/previews/wave1/_sheet_b.png` and `_sheet_b_front.png`: labeled review sheets, Epic / Legendary / Mythic rows.
- `docs/research/wave1-art-b-pipeline.md`: current official-source checks and verification limits.

The IDs are PlungerPogo, BathMatBat, DiscoBidet, TowelTornado, PorcelainPoodle, FaucetPharaoh, RoyalFlushFrog, GoldenGargler, Clogtopus, LaundryYeti, SteamGenie and BathBombBehemoth. No new colors are required, so there is no separate Wave1Palette_b.png.

## Validation and integration

The build validates one joined mesh and one material, one padded UV layer, finite vertices, closed manifold component surfaces, no degenerate triangles and each brief's individual budget. Every FBX is reimported and checked against triangle count, exact embedded atlas bytes, texture dimensions, ground contact, horizontal bounds centering, origin and size within 0.001 stud. `rojo build -o build.rbxl` also passes.

The available Luau checkers were attempted read-only as requested by AGENTS.md: `selene src` cannot run because the local `roblox` standard-library definitions are missing. `stylua --check src` reports existing formatting differences, beginning at `src/admin-client/Bootstrap.client.luau`. No `src/` files or checker configuration were changed; these checks do not validate the Blender Python/art output.

Author space is Z-up with front -Y. Export is Y-up / Z-forward, FBX Unit Scale, all scale factors 1. Studio import must use Stud / factor 1, Front / Top, as detailed in `docs/asset-pipeline.md`. Target boxes are applied per axis after joining; the manifest lists Roblox X/Y/Z. The existing single painted palette material and preview light rig are shared for visual consistency. Clogtopus uses a slightly higher three-quarter camera to expose the radial arms.

## Weaknesses and assumptions

- Local validation is a Blender round trip, not a Roblox Studio import/upload test. Studio pivot handling, texture assignment, permissions, moderation and actual game lighting still need manager acceptance.
- These are static joined sculptures. Overlapping closed shells are intentional and are not boolean-unioned; use simple collision. Bubble decorations are static disconnected shells in the same mesh.
- Gold, porcelain and bubbles use painted colors, not physically different materials or transparency. No glow, motion, cloth simulation or particle behavior is included.
- The task-specific `wave1/b` output paths take precedence over the generic `models/items` paths in the brief. No central manifest or runtime mappings have been changed.
- Small hems, pupils and accessory openings lose detail at very small display sizes. Front and three-quarter views are provided so the manager can check the intended icon camera before integration.
- The Behemoth intentionally has much smaller eyes than the other creatures, following its brief. Its tiny expression and scoop interior are the first details to disappear at phone-thumbnail size.
- Angular elbows, towel folds and the poodle's curled tail show their low-poly construction at close zoom. Rear limbs overlap in straight-on views; use the three-quarter view to inspect them.

## Visual review and budgets

All twelve models were rendered and inspected in both views against the existing item sheets. The correction pass cleared the bidet's microphone/bowl intersection, moved the tornado and gargler faces in front of their surrounding geometry, rebuilt the poodle's spout lip, connected the pharaoh's right handle and the frog's crown/legs/seat pose, raised the two rear octopus cups, exposed the yeti's sock, followed the turban surface with its seam, and connected the behemoth feet and closed the scoop floor. A focused final pass adjusted the tornado mouth and octopus camera.

The completed front/three-quarter sheets and temporary 128px/64px thumbnail reductions were inspected. Main silhouettes and eyes remain recognizable; the behemoth's tiny mouth, fabric hems and small accessory details weaken at 64px as noted above. Final file checks found all 12 FBX, 12 packed Blender sources and 24 correctly sized 768px previews. A full final geometry rebuild passed all 12 round trips again. Git reported no changes to previously tracked files: all deliverables are new group-B files, left uncommitted on `feature/wave1-art-b`.

| ID | Triangles | Brief budget |
|---|---:|---:|
| PlungerPogo | 1,908 | 2,000 |
| BathMatBat | 1,132 | 1,800 |
| DiscoBidet | 2,316 | 2,400 |
| TowelTornado | 2,272 | 2,300 |
| PorcelainPoodle | 2,100 | 2,400 |
| FaucetPharaoh | 2,348 | 2,400 |
| RoyalFlushFrog | 2,000 | 2,300 |
| GoldenGargler | 2,096 | 2,100 |
| Clogtopus | 2,008 | 2,500 |
| LaundryYeti | 2,364 | 2,400 |
| SteamGenie | 1,960 | 2,400 |
| BathBombBehemoth | 1,924 | 2,200 |

Golden Gargler and Towel Tornado are close to their individual limits. Any future added detail must be followed by a rebuild; the budget checks intentionally fail rather than silently decimating the models.
