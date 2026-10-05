# World models and Studio template handoff

Implemented in the `feature/templates` worktree, uncommitted. `assets/rbxm/ModelTemplates.rbxm` is mapped directly to `ReplicatedStorage.ModelTemplates` in `default.project.json`. Its single root contains all 31 named Models, each with one MeshPart and uploaded mesh/palette references. The binary import is unchanged. [Current API research and evidence](research/model-templates.md).

## Loading and normalization

`src/server/World/MeshLoader.luau` delegates to `src/shared/Visuals/TemplateLoader.luau`. The shared loader clones local templates; it does not use InsertService, Assets.Meshes, preload workers, network calls or startup waits. The old empty Assets.Meshes slots are unused and do not need filling.

Normalization happens once per asset per Luau VM, in a detached cache. Every placement receives an independent clone. The loader:

1. Requires the imported one-MeshPart Model contract; unexpected descendants or invalid dimensions use the existing primitive builder.
2. Removes Studio staging transforms and applies the front correction from the imported PivotOffset. The verified batch is Y-up with a 180-degree Y correction.
3. Measures the imported bounding box, uniformly scales its largest dimension to `MeshCatalog` (checked against `assets/manifest.json`), and rejects an incompatible aspect ratio. It does not stretch individual axes.
4. Places the horizontal bounds center at the origin and the bottom at Y=0. Toilets additionally preserve their authored horizontal foot offsets, so the offset Dirty plunger and Galaxy ornament do not shift the body during tier swaps. Every tier retains its authored 2.08-stud seat height; horns are not compressed to Basic's height.
5. Sets the primary part's PivotOffset so Model:GetPivot is the base datum; subsequent ScaleTo/PivotTo calls preserve it. Sets anchored, non-colliding, non-queryable, non-touching, white SmoothPlastic mesh surfaces. Clouds do not cast shadows. Uploaded mesh and texture content are never reassigned.

Missing source models can arrive later and recover on a later build. Invalid sources warn once for an unchanged source/descendant count. A partially replicated Model is retried when its mesh arrives. Existing placed fallbacks are not asynchronously replaced. Cache refresh after editing existing mesh properties requires restarting Play; replacing the source instance also refreshes it.

`MeshAsset`, `MeshFallback`, `MeshStatus`, and `NormalizationScale` describe placed models. Ready means a local template normalized successfully, not proof of asset delivery to every client. Permission/download failures are not detected by this loader.

## Visual coverage

World item drops, display items, plot/hub toilet tiers and all 13 prop types use templates. Duck maps to RubberDuck. PlotSignboard retains a separate SurfaceGui text face; display pedestals retain labels and rarity rings. Lamps keep a real Neon light source; portal gates now have Neon segments following their imported arch trim. Palms, bushes, flowers, benches, fences, trophy, rocks/crystals, foliage and clouds all use the same loader.

Shared `Visuals.Items.Build` and `Visuals.Toilets.Build` also support templates in client viewport contexts, with effect-free `preview=true`. `BuildPrimitive` preserves explicit server fallbacks. The current Collection/Upgrade UI uses `UI/Preview.luau` icon Frames, not viewport models or these shared builders; its appearance is unchanged under the prohibition on UI edits. No client UI or audio files were edited.

`TemplateEffects.luau` and `TemplateAccents.luau` provide Golden sparkles, Diamond glints, green Radioactive light and three small bobbing bubbles, Demon ember glow, Galaxy star particles, Golden Poop sparkle, King Poop crown sparkle and purple Mystery light. Special assets use one shadowless 7-stud PointLight and at most one 2/sec emitter with 0.6-1.2-second lifetime. Radioactive bubbles use three tiny Neon Parts and the existing idle controller. Existing distance culling and flush suppression apply; no new update loop or texture IDs were added. Preview clones have no idle effects.

Walking collision uses invisible Box Parts on pedestals, the trophy base and fence sections; their rendered MeshParts remain non-colliding. Benches remain decorative. These boxes have CanTouch/CanQuery false. All 31 imported meshes already author RenderFidelity Automatic.

**Remaining fidelity requirement:** CollisionFidelity cannot safely be set by the runtime loader. This export stores opaque PhysicalConfigData, without an explicit CollisionFidelity token. Mesh CollisionFidelity=Box has not been verified or changed; Box proxy parts provide walking collision meanwhile. In Studio edit mode, set all 31 MeshParts' CollisionFidelity to Box and RenderFidelity to Automatic, save the single ModelTemplates root back to the same rbxm, then rebuild/reopen. Do not change pivots, names or uploaded content. No Studio instance was connected during this task.

## World and record board

Existing gameplay is unchanged: ten plots on the 85-stud ring, five visible display stands with pagination, and the finite 640-by-640 Terrain island. Island startup writes 100 chunks at 4-stud resolution (819,200 voxel entries). Lighting/sky, three inactive Coming soon portals and the hub trophy remain. Workspace streaming stays minimum 128 / target 384; individual placed assets are Atomic.

BEST FLUSH EVER records server-awarded flushes only, including animation-skipped flushes. It compares base 1/X denominator, retains the first winner on ties, and survives that player leaving. It is a session record. Workspace attributes remain BestFlushChance, BestFlushRarity, BestFlushItemId, BestFlushPlayer, BestFlushUserId and BestFlushEver. No RNG, economy, remotes or authority changes.

## Checks and budgets

Run from the repository root (use a process-scoped `powershell -NoProfile -ExecutionPolicy Bypass -File` invocation where local script execution is disabled):

```powershell
stylua --check --line-endings Windows src scripts
rojo build -o build.rbxl
./scripts/check-world.ps1
./scripts/check-visuals.ps1
./scripts/check-audit.ps1
./scripts/check-ui.ps1
# Run all standalone scripts/check-*.luau with luau.
# check-audit.luau and check-ui-runtime.luau run through their PS1 bundlers.
```

`read-model-templates.ps1` builds the actual binary import to temporary rbxlx and verifies its hierarchy, exact manifest coverage, dimensions, pivot convention, 31 MeshParts, 62 content references and Automatic rendering. It feeds real serialized Size/CFrame/PivotOffset/content properties to the headless harness. No fake upload IDs are substituted.

Six world scenarios cover missing templates, all ready, one missing asset, malformed bounds, 37x scaled/displaced/rotated imports and late replication. Tests verify all 31 normalization/placement paths, shared toilet foot/seat datums, arbitrary placement yaw and uniform prop scale, clone/cache isolation, source preservation, protected-property write avoidance, partial replication recovery, preview clones, effect budgets/idempotence, all 100 paginated displays, terrain, lighting and record-board regressions. Network services are traps.

| Mode | Hub parts | Hub meshes / fallbacks | Worst plot + one drop | With two overlapping drops |
| --- | ---: | ---: | ---: | ---: |
| Missing / invalid | 1,536 | 0 / 185 | 356 | 386 |
| Imported templates | 627 | 185 / 0 | 184 | 194 |
| Missing palms | 787 | 165 / 20 | 200 | 210 |
| Budget | 2,499 | - | 399 | 399 |

The imported hub contains 225,340 mesh triangles; the largest populated plot contains 57,536, excluding terrain, primitives, particles and transient drops. Part counts do not establish GPU/memory performance.

Rojo binary build, StyLua, all six world scenarios, visual checks, all standalone Luau checks, UI checks and all 28 audit regressions pass. Selene cannot start because the repository's configured roblox standard library is missing.

## Remaining acceptance and weaknesses

Open the rebuilt place in the intended experience and verify uploaded content permissions/moderation, all seven tiers' front direction/seat/ground contact, long sign names, prompts, walking collisions, flush animation, effects at low/high graphics, streaming and mobile performance. Serialized transforms and mathematical tests do not replace a rendered engine review. Mesh-level Box fidelity needs the Studio resave above. Client download failure does not trigger a primitive replacement. The existing Blender world-preview images predate this integration and are not evidence of the imported assets rendering in Roblox.

Main changes: Rojo mapping; server MeshLoader/Models/Decor; shared TemplateLoader/TemplateAccents, Items/Toilets, WorldModels/TemplateEffects; world check scripts/harness; this document and research notes. Nothing committed or pushed.
