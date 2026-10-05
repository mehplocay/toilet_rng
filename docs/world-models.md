# World models and island handoff

Implemented on `feature/world-models`, without committing or pushing. Client UI and client initialization files are untouched. All 31 mesh/texture ID pairs remain empty; the playable world currently uses primitive fallbacks. [Research and current API sources](research/world-models.md).

## Fill the upload IDs

1. Follow [the asset pipeline](asset-pipeline.md), starting with **BasicToilet** in the intended published experience. Import the FBX files using **Stud**, factor **1**, **Front/Top**, under the experience's owning user/group. Do not change individual toilet scales or substitute model/container IDs.
2. After uploading and moderation, select the actual imported **MeshPart** and copy its **MeshId** property. This is the geometry content ID, not a Creator Store model ID, place ID, package ID or asset-version ID.
3. Upload `assets/textures/ToyPalette.png` once under the same owner. Copy the image content ID from the imported part's **TextureID**, or its SurfaceAppearance **ColorMap** if the importer used one. Use the underlying image ID, not a Decal container ID. Check the preview shows the shared colored palette.
4. In `src/shared/Config/Assets.luau`, fill **both** string fields for that exact manifest asset name. The existing entry starts as:

   ```luau
   BasicToilet = { MeshId = "", TextureId = "" },
   ```

   Replace each empty string with the copied `rbxassetid://...` content value. Numeric ID strings are also accepted. Keep IDs as strings. Repeat the same uploaded palette image ID in every entry's `TextureId`. Do not put IDs in builders, catalog entries or scripts. Leave unuploaded pairs empty.
5. Repeat for all 31 entries, preserving their exact names. Items use their gameplay IDs except **Duck → RubberDuck**. Toilet tiers map to **BasicToilet, DirtyToilet, GoldenToilet, DiamondToilet, RadioactiveToilet, DemonToilet, GalaxyToilet**. The other 13 keys match the prop filenames, including **PlotSignboard**, **DisplayPedestal**, **GoldenTrophy**, **PortalGate**, **CloudPuffs**, **RocksCrystals** and **ForegroundFoliage**.
6. Grant the **experience** permission to use both restricted mesh and image assets. Creator access in an unrelated Studio place is insufficient evidence. Test a fresh server in the intended published experience, with a second account/mobile client. No EditableMesh opt-in or third-party model loading is needed.
7. Restart Play/the server after editing IDs. Inspect `ServerStorage.WorldMeshTemplates` for cached MeshParts and Workspace models' `MeshAsset`, `MeshFallback`, `MeshStatus` attributes. An unconfigured or failed pair keeps its primitive model. A permission/download failure warns once per asset per server. Check the Studio output and asset permissions if the status is `Unavailable`.

Start with a single pair; confirm color, front direction, stud dimensions, ground contact and prompt activation before filling the batch. Uploaded MeshParts are white to avoid tinting the atlas. Material is SmoothPlastic; gold/green/purple colors come from the atlas. Glow is separate Neon geometry/lights, not an assumed Blender emission transfer.

## Placement and loader behavior

`src/server/World/MeshLoader.luau` is the shared **server-only** loader used by the world adapters and decor builders. It warms four workers, attempts each configured asset once, creates with `InsertService:CreateMeshPartAsync` inside `pcall`, checks mesh/texture preload status, caches in ServerStorage, and clones per placement. Creation uses **Box** collision fidelity and **Automatic** render fidelity. Decoration is anchored, non-colliding, non-touching and non-queryable. Gameplay floors/spawns and Terrain provide walkable geometry.

Startup waits at most eight seconds for warming. In-flight calls cannot be cancelled; at most four can be outstanding. Slow successful loads become available for later placements. Already-built fallback scenery stays in place until the next server, avoiding surprise replacement and loss of sign/prompt references. Errors and failed textures destroy incomplete templates and never retry on a flush. `Build` does not yield or make network requests. Both empty/invalid IDs and absent texture IDs fall back. Server preloading cannot guarantee every client's content delivery succeeds.

`src/shared/Config/MeshCatalog.luau` mirrors the manifest sizes/triangle counts. Items and toilets use the manifest's stud size; intentional uniform prop scales are in `WorldModels.luau` or the relevant decor placement. MeshParts use bounds centers, with an explicit base pivot. The seven toilet bounds-center offsets were measured from the generated Blender meshes to preserve their common foot datum, including the Dirty tier's offset plunger. This still needs Studio import acceptance: Roblox axis/pivot behavior has not been validated with uploaded assets.

If the authored assets change, regenerate this catalog from the existing manifest and generated `.blend` files (does not change asset IDs or save the Blender scenes):

```powershell
& 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe' --background --factory-startup --python-exit-code 1 --python scripts/sync-world-catalog.py
stylua src/shared/Config/MeshCatalog.luau
```

Client viewport previews retain the existing shared primitive builders; this task changes server world placements and does not modify the parallel UI work.

## World and record board

- A finite 640 × 640-stud Terrain region supplies a flat playable island core, scalloped sand shore, turquoise ocean, grassy headlands, cliffs and distant mountain ridges. Startup writes 100 grid-aligned chunks at 4-stud resolution, 819,200 voxel entries including air, yielding between chunks. No whole-Terrain clear, per-cell API calls or ongoing terrain loop. Only this documented region is overwritten.
- Ten plots remain on the existing 85-stud ring, with the existing spawn, reservation, display pagination and flush rules. Colored approach strips, checkerboard plaza, compass inlays, palms, coastal gardens, benches, lamps and foreground foliage use a fixed seed. Joined plot-sign meshes retain separate SurfaceGui text faces; display pedestals retain names/odds and rarity rings.
- GoldenTrophy anchors the hub fountain. Three inactive Sewer/Space/Hell gates show **Coming soon**, with colored aura rings and bounded idle effects. They grant no access or gameplay rewards.
- Warm afternoon lighting, blue Atmosphere, engine-default Sky textures, one Terrain Clouds layer, static cloud props, mild bloom/color correction and shadowless local lights provide depth. No external skybox IDs or new per-frame callbacks.
- `Workspace.StreamingEnabled` is authored in Rojo (minimum 128, target 384). Individual assets are Atomic; the whole hub/plot is not Persistent or Atomic. Distant geometry can stream out; the sky/cloud atmosphere remains. Verify live streaming and Home teleport behavior on mobile.

The **BEST FLUSH EVER** board records only server-awarded flushes through the existing `World:Animate` path, including animation-skipped/automatic flushes. “Best” means the largest configured **1/X denominator** (rarest base odds), not sale value or current luck-adjusted odds. Equal odds retain the first winner. This is a session record, not a DataStore/global leaderboard, and survives the winner leaving.

Client-readable Workspace attributes:

| Attribute | Value |
| --- | --- |
| `BestFlushChance` | Base odds denominator; initially 0 |
| `BestFlushRarity` / `BestFlushItemId` | Config rarity / item ID; initially empty |
| `BestFlushPlayer` / `BestFlushUserId` | Winner display name / user ID; initially empty / 0 |
| `BestFlushEver` | English board text, including the initial invitation |

No new remotes, RNG changes, currency changes or client authority were introduced.

## Checks and budgets

```powershell
rojo build -o build.rbxl
./scripts/check-world.ps1
./scripts/check-visuals.ps1
./scripts/check-audit.ps1
# Run each remaining scripts/check-*.luau with luau.
# check-audit.luau is bundled by check-audit.ps1, not run bare.
```

The headless harness executes the production builders. `check-world.ps1` exercises empty IDs, all successful loads, mixed success, denied meshes, failed textures, and startup timeouts/late completion. Synthetic IDs are confined to mocks; it never contacts Roblox. It verifies catalog/manifest parity, all 31 placement paths, clone isolation, pivots, request caching, failure cleanup, every toilet/item, all 100 display slots, terrain array/material validity, lighting idempotence, record updates/ties/spoof rejection, flags and budgets.

| Mode | Hub parts | Hub MeshParts / fallback models | Worst plot + one transient drop |
| --- | ---: | ---: | ---: |
| Empty IDs / all failures | 1,535 | 0 / 185 | 348 |
| Simulated uploaded meshes | 594 | 185 / 0 | 147 |
| Budget from Visuals config | 2,499 | — | 399 |

The checks also reserve two overlapping drop visuals for FastFlush: at most 378 fallback parts or 156 simulated-mesh parts per plot, still below 399. The simulated uploaded hub contains 225,340 authored mesh triangles; the largest populated plot contains 57,536, excluding primitives, terrain, particles and the transient drop. Part counts do not certify GPU cost. Streaming/LOD and shared mesh/texture reuse help, but mobile profiling is still required. These figures include the five-stand maximum; saved capacities above five retain existing pagination.

Rojo build, StyLua checks for owned Luau changes, compilation, all standalone `check-*.luau`, all six world scenarios, visual checks and all 28 audit regressions pass. Selene was attempted but cannot run because the repository's `roblox` standard library is missing.

## Visual review and remaining Studio acceptance

Offline composition views were rendered from the headless builders in Blender and reviewed twice, improving mountain ridges, ground alignment, palm scale, sign proportions and plaza detail. [Overview](world-previews/overview.png), [spawn](world-previews/spawn.png), [own plot](world-previews/plot.png) show **simulated successful meshes using local Blender sources**, not actual Roblox uploads. Fallback views have `-fallback` filenames in the same folder. The preview uses an approximate heightfield, different renderer/sky/text, and a deterministic mock RNG; it does not reproduce Roblox voxels, lighting, streaming, particles or UI.

Regenerate previews (optional, requires the local Blender installation):

```powershell
./scripts/check-visuals.ps1 -MeshMode Ready -Snapshot
& 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe' --background --factory-startup --python scripts/preview-world.py
# For primitive views: use -MeshMode Empty above, then append -- --fallback to Blender.
```

No Studio instance was connected. Still untested: real uploaded mesh/image permissions and moderation, front/pivot preservation, client content failures, Terrain shore seams/contact/collision, spawn and prompt feel, flushing upgraded meshes, sign readability with long names, low/high graphics effects, streaming transitions/teleports, multiplayer and mobile frame/memory/startup time. Fallbacks intentionally look simpler than uploaded art. Finite ocean/mountain edges may need adjustment after the Studio camera/streaming review. The uploaded success test is a mock, not an asset-delivery test.

Primary changed files: `src/server/World/{MeshLoader,Models,WorldService}.luau`, its `Builders/{Island,Hub,Plot,Decor,Lighting}.luau`, `src/shared/Config/{Assets,MeshCatalog,WorldModels}.luau`, `default.project.json`, the headless checks/preview helpers and these documents. Nothing is committed or pushed.
