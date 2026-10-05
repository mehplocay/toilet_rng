# Blender asset pipeline

This set contains 11 collectible items, 7 interchangeable toilet tiers and 13 environment props. All names, source comments and labels are English. Source designs are original procedural geometry; no borrowed meshes, external asset IDs or runtime game changes are included.

## Files and regeneration

- `assets/blender/lib.py`: geometry, palette/UVs, validation, FBX export and studio preview helpers.
- `assets/blender/builders.py`: all 31 designs and their dimensions.
- `assets/blender/build.py`: build entry point; `verify.py`: FBX reimport validation.
- `assets/blender/generated/<Name>.blend`: editable, joined asset-only Blender scenes; no render floor or lighting is exported.
- `assets/models/{items,toilets,props}/<Name>.fbx`: one mesh, one material per asset, embedded texture.
- `assets/textures/ToyPalette.png`: shared opaque 256×256 color atlas. Padded UV swatches carry color gradients and painted highlights; shader nodes are not required in Studio.
- `assets/manifest.json`: every file, triangle count, budget, preview path and size in **Roblox X/Y/Z studs**.
- `assets/validation.json`: results from reimporting the exported FBX files. This is a Blender round trip, not a Studio upload test.
- `assets/previews/<Name>.png` and `<Name>_front.png`: 768×768 three-quarter and front images. `_sheet_items.png`, `_sheet_toilets.png`, `_sheet_props.png` are labeled overview sheets; `_front` sheets show the second view. `turntables/GoldenTrophy/00.png` through `07.png` demonstrate the eight-angle turntable.

From the repository root in PowerShell:

```powershell
# Full build: FBX + .blend + atlas + manifest + 62 previews + sheets + reimport checks.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-assets.ps1

# The policy flag affects only this child process, not system settings.
# With scripts already enabled, the equivalent direct command is:
./scripts/build-assets.ps1

# Faster geometry-only rebuild, still with FBX validation:
./scripts/build-assets.ps1 -NoRender

# Focused visual iteration:
./scripts/build-assets.ps1 -Only Poop,KingPoop

# Optional eight-angle 768px PNG turntables, in addition to the two main views:
./scripts/build-assets.ps1 -Only GoldenTrophy -Turntable

# Override Blender's location when needed:
./scripts/build-assets.ps1 -Blender 'D:\Tools\Blender\blender.exe'
```

Requires Blender 4.5 and Windows PowerShell/System.Drawing. No Python packages, package installer, Blender add-ons or network calls are needed. Scripts do not change `src/`, publish assets, or modify the Rojo project. A partial build preserves other manifest entries; a full build is required after palette or shared-helper changes. The build overwrites generated files with the same asset names. Blender logs and extracted FBX texture folders are ignored as scratch data.

The optional turntable uses the same orthographic studio rig, soft lights and pastel gradient as the main views, with eight evenly spaced camera angles. It exports still PNGs, not animation data in FBX.

## Scale, pivots and art constraints

Authoring uses one Blender unit per stud, Z-up, front at -Y. Export uses Z Forward / Y Up and FBX Unit Scale; all scale multipliers are 1. These are the settings in [Roblox's Blender workflow](https://create.roblox.com/docs/art/blender). The physical convention is 0.28 m/stud; these files already use stud values, so do not multiply them by 0.28.

Items have a largest dimension of 2.4–3 studs. Toilet bodies share a 4.79-stud lid top, a 2.08-stud seat center and the center of the bottom foot as their origin. Decorations can extend slightly beyond this silhouette; Demon horns reach about 5.2 studs. Their geometry is not individually normalized. The 9-stud trophy is intentionally larger. The manifest is the source of truth for actual bounds.

The minimum mesh height is zero. Other assets use the horizontal center of their bounds as the base pivot. All meshes are static and joined: raised lids, sparkles, flowers and crystals do not animate independently. Packs are small arrangements in a single MeshPart. Use the source builders to produce separate components if a future task needs movable lids or individual flowers.

All decorative components have closed surfaces with thickness, but intersecting components are not boolean-unioned. Render geometry is not intended as detailed collision geometry. Use simple collision settings or existing gameplay collision parts.

## Studio: validate one asset before importing the batch

The verified rules and platform changes are recorded in [pipeline research](research/blender-roblox-pipeline.md). The current workflow uses **File → Import** (called **Import 3D** in some Studio layouts), or the import button in **Asset Manager**. The old “Bulk Import” button now routes to the importer queue. [Importer documentation](https://create.roblox.com/docs/studio/importer), [Asset Manager](https://create.roblox.com/docs/projects/assets/manager).

1. Open the intended experience in Studio, under the correct owning user/group. Save/publish that experience so uploads can receive the correct permissions. Pause Rojo sync while staging imports in Workspace.
2. Choose File → Import and select `assets/models/toilets/BasicToilet.fbx`.
3. In the preview, set **World Forward = Front**, **World Up = Top**, **Scale Unit = Stud**, **Scale Factor = 1**. Do not use Meter or a historic 0.01/100 correction. Roblox changed non-Stud conversion ratios in June 2026; Stud with factor 1 remains unchanged. [Official change notice](https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371).
4. For this first check, disable **Upload to Roblox** if you want a local iteration. Enable **Add to Workspace** and **Insert Using Scene Position**. Use **Import Only as a Model** if exposed in your importer version. No avatar setup, rig, skinning, cages or animation import is needed.
5. Confirm there is one mesh, no triangle/material warnings, a white toilet with a raised lid, and a visible textured seat. Compare dimensions to the BasicToilet manifest entry. Its height must be approximately 4.79 studs, not hundreds of studs. Compare front/three-quarter orientation to the PNGs.
6. Confirm the imported object stands upright on its bottom foot. Inspect the pivot with Studio's pivot tools. If Studio has centered the MeshPart pivot on its bounds, use **Model → Pivot → Edit Pivot** to move the containing Model's pivot to the center of the foot on the ground. This is a required Studio acceptance check: Blender round-trip validation does not prove Studio preserves custom pivots.
7. Use the same foot-centered pivot for every upgrade tier. Keep their common seat height; do not resize each toilet independently to its bounding-box height. Set static template parts **Anchored = true**, **CanCollide = false** for decorative placement, and **CollisionFidelity = Box** if collision is enabled later. Leave actual playable collision to the existing game setup. Keep MeshPart Color white so it does not tint the atlas.

If the preview loses its colors, verify the texture assignment in the import preview. The FBX embeds `ToyPalette.png`; an external copy is available in `assets/textures`. Upload that PNG once and apply its image asset to **MeshPart.TextureID**. If the importer created a **SurfaceAppearance**, apply the texture to its **ColorMap/ColorMapContent** instead and avoid competing color-texture setups. Blender roughness/emission is not assumed to transfer. [Mesh texture options](https://create.roblox.com/docs/parts/meshes).

## Studio: bulk import and publish

1. Open File → Import or Asset Manager's import button. Multi-select all `.fbx` files in `assets/models/items`. Add files from `toilets` and `props` through **Add file** in the queue. The file picker does not need to import the parent folder recursively; select its actual FBX files. Do not import generated `.blend` files.
2. Apply/save the checked import settings above as a preset, then apply them to the queue. Verify **Creator** is the intended owning group/user, **Upload to Roblox = on**, **Add to Workspace = on**, and **Import as Package = off** for this static repository handoff. Import the enabled queue.
3. Review import errors and wait for mesh/image moderation. Inspect all tiers and creatures in Studio under the game's real lighting. The pastel preview floor, studio lights and camera are absent from the exported model.
4. Rename each containing Model to its filename stem, e.g. `RubberDuck`, `BasicToilet`, `PortalGate`. If Studio inserts just a MeshPart, group it into a Model and use that name. Preserve or correct base pivots as above. Imported children may have a different center from their Model pivot; do not confuse the two.
5. To publish an organized model separately, right-click its Model in Explorer → **Save to Roblox**, choose the owner/name and submit. An FBX uploaded by the importer may already have a model inventory asset; do not create a duplicate unless needed. A model asset ID, a mesh asset ID and an image asset ID are different identifiers. [Upload models](https://create.roblox.com/docs/parts/models).
6. Test in the intended experience. Importing into another unsaved scratch place does not prove the experience has permission to load the restricted meshes/images.

The bright ring slots, portal trim, radioactive water and mystery question mark use saturated color geometry. They do **not** emit real light. Optional Studio bloom, lights or an emissive SurfaceAppearance can be added during integration; no dependency on those effects is required for recognition. Gold is painted stylized gold; diamonds are opaque faceted blue crystals, not transparent glass.

## Save .rbxm files and connect Rojo

1. Create `assets/roblox/items`, `assets/roblox/toilets`, and `assets/roblox/props` in the repo after accepting the Studio imports.
2. For each corrected **Model**, right-click it in **Explorer → Save to File…**, choose the binary `.rbxm` type, and save to `assets/roblox/<category>/<Name>.rbxm`. `.rbxmx` XML is also supported if the manager prefers reviewable XML. Verify the selected type instead of relying on the last-used extension. This instance export is distinct from the **File menu's Save to File**, which saves a whole `.rbxl` place. [Instance export](https://create.roblox.com/docs/education/build-it-play-it-island-of-move/sharing-animations), [model menu corroboration](https://devforum.roblox.com/t/export-help-for-rbx-format-file/1061048).
3. As a **separate integration change**, add a sibling to `Shared` under the existing `ReplicatedStorage` entry in `default.project.json`:

```json
"ArtModels": { "$path": "assets/roblox" }
```

4. Run `rojo build -o build.rbxl`, open that built place, and confirm the folders/models appear under `ReplicatedStorage.ArtModels`. MeshPart.MeshId has Rojo live-sync limitations; rebuild/reopen the place when replacing meshes instead of assuming a live update succeeded. [Rojo 7 sync details](https://rojo.space/docs/v7/sync-details/).
5. Clone the stored Model templates during game integration and position their base pivots. The binary model references uploaded mesh/image assets; it does not make those dependencies offline or remove their permission requirements. Rojo does not upload FBX/PNG files.

No `.rbxm` or fake asset IDs are supplied by this build: valid uploaded IDs and a Studio serialization are deliberately the manager's next step.

## Assets.luau integration contract (manager-owned follow-up)

Keep all references in `src/shared/Config/Assets.luau`, preserving any other sessions' changes. Prefer template names/paths into `ReplicatedStorage.ArtModels`; these preserve textures and pivots and avoid runtime assignment to protected MeshId properties. A possible record shape is:

```lua
-- Example only: zero means not yet uploaded, never a fabricated ID.
Models = {
    Items = {
        Duck = {
            Template = "items/RubberDuck",
            ModelId = 0,
            MeshId = 0,
            TextureId = 0,
        },
    },
    Toilets = {
        Basic = { Template = "toilets/BasicToilet", ModelId = 0 },
    },
    Props = {
        PalmTree = { Template = "props/PalmTree", ModelId = 0 },
    },
}
```

Adapt this record shape to the game builder's agreed interface; this task does not implement that interface. Existing item ID `Duck` maps to file `RubberDuck`; `Mystery` displays `???`. Toilet config IDs `Basic`, `Dirty`, `Golden`, `Diamond`, `Radioactive`, `Demon`, `Galaxy` map to filenames with `Toilet` appended. Other item IDs match filenames.

Copy the **ModelId** from the importer/Asset Manager model entry. Copy the actual **MeshId** and **TextureID**, or SurfaceAppearance ColorMap, from the child mesh's Properties. Record only IDs verified in Studio. Do not put a ModelId into MeshId. Runtime code should clone the imported template and retain the current primitive fallback until the template/permissions are available. [MeshPart API restrictions](https://create.roblox.com/docs/reference/engine/classes/MeshPart).

## Acceptance and known limits

- Local build: every model must fit its category budget, have one mesh/material, nondegenerate closed component surfaces, finite vertices, UVs and an atlas. FBX reimport must match triangle count and dimensions within 0.001 stud. Main/front PNGs must be 768×768.
- Visual review: inspect all three sheets and individual front views for color, eye placement, silhouette and clipping. Detailed review notes belong in `assets/previews/REVIEW.md`.
- Manager: still needs to validate Studio axes/units/pivots, moderation, asset ownership/permissions, collision, final in-game lighting and appearance at phone size. These local renders cannot verify that last stage.
- Static joined geometry means material-specific glow, moving lids and separable prop packs require a future export variant. The blank plot-sign face and pedestal plaque intentionally leave live player/item text to the game's UI.
