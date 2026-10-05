# Blender → Roblox pipeline research

Verified 2026-10-05 against the live sources below. These are static environment and collectible meshes, not avatar accessories.

## Geometry and units

- General meshes have a 20,000 triangle limit per mesh. Use closed surfaces with volume and outward normals; triangulate for export. Our stricter budgets are 2,500/item, 5,000/toilet, 4,000/prop, counted across the complete asset, including disconnected decorative shells. [General specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Roblox's physical convention is 1 stud = 0.28 m. This pipeline authors directly in **stud-valued Blender units**, not meters; do not apply 0.28 again at import. [Units](https://create.roblox.com/docs/physics/units)
- Roblox's Blender guide specifies Unit System None, FBX Unit Scale, Z Forward / Y Up, all other scales 1. Import with World Forward Front, World Up Top, Scale Unit Stud. We use these settings and a base-center origin. Blender authoring is Z-up, faces toward -Y; exported coordinates are Y-up. Verify the first toilet against the manifest dimensions before uploading the batch. [Blender workflow](https://create.roblox.com/docs/art/blender)

## Materials and file format

- Import supports FBX, OBJ, glTF. FBX/glTF carry hierarchy, textures and vertex colors. FBX is used here, one joined MeshPart per asset. Vertex colors are supported but intentionally unnecessary for this pipeline. [Importer](https://create.roblox.com/docs/studio/importer)
- One material per mesh. Small objects commonly use 256px textures. We use one opaque 256×256 PNG atlas for the entire set with padded color tiles, painted gradients and highlight bands. Every exported face has UVs; the material uses a real Image Texture → Principled BSDF Base Color connection. [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications), [Blender texture assignment](https://create.roblox.com/docs/art/modeling/assign-textures)
- FBX export: Path Mode Copy and Embed Textures. An external PNG is also shipped for manual relinking. [Export requirements](https://create.roblox.com/docs/art/modeling/export-requirements)
- A MeshPart can use a basic color texture; PBR uses SurfaceAppearance maps. Blender shader graphs, lights, and emission effects are not a portable substitute for texture maps. This set uses baked color, not an assumed shader transfer. Optional runtime glow is a later Studio integration step. [Meshes](https://create.roblox.com/docs/parts/meshes), [SurfaceAppearance](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)

## Studio, IDs and repository handoff

- File → Import supports multi-selection and a batch queue. Upload to Roblox creates inventory assets; Add to Workspace in the intended saved/published experience grants that experience asset permissions. Select the correct user/group creator. Copy asset ID on an imported model gives the **model ID**, not its child mesh ID. [Importer](https://create.roblox.com/docs/studio/importer)
- Asset Manager's import button now routes to the Importer. Older tutorials call this Bulk Import. [Current Asset Manager](https://create.roblox.com/docs/projects/assets/manager)
- MeshPart has MeshId and TextureID; MeshId cannot simply be assigned by a normal runtime script. Prefer cloning pre-imported templates. A model ID is not a MeshId. [MeshPart API](https://create.roblox.com/docs/reference/engine/classes/MeshPart)
- Right-click the selected Model in Explorer → Save to File → .rbxm (or .rbxmx). This saves the instance tree; uploaded mesh/image dependencies still need permission. Do not use File → Save to File for this: that saves the whole place. The official instance export example demonstrates Save to File; the model-specific menu is corroborated by DevForum. [Official instance export](https://create.roblox.com/docs/education/build-it-play-it-island-of-move/sharing-animations), [Model-specific DevForum instructions](https://devforum.roblox.com/t/export-help-for-rbx-format-file/1061048), [Place files](https://create.roblox.com/docs/projects/place-files)
- Rojo 7 supports .rbxm and .rbxmx paths. MeshPart.MeshId has live-sync limitations; use `rojo build` and reopen the generated place when changing imported meshes. No mesh upload is performed by Rojo. [Rojo 7 sync details](https://rojo.space/docs/v7/sync-details/)
- Blender 4.5 exporter API maps FBX Unit Scale to `apply_scale_options='FBX_SCALE_UNITS'`, with `path_mode='COPY'`, `embed_textures=True`, `axis_forward='Z'`, `axis_up='Y'`. [Blender 4.5 API](https://docs.blender.org/api/4.5/bpy.ops.export_scene.html)

## Verification boundary

### Platform changes checked

- Roblox announced and then confirmed the June 16, 2026 switch of non-Stud import units to 25:7 studs per meter. Stud / Scale Factor 1 stays unchanged. This is why the handoff explicitly selects Stud rather than using older meter-conversion tutorials. [Official staff announcement and rollout update](https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371)
- The January 2026 Studio recap documents Asset Manager moving from the legacy Bulk Importer to the Universal Importer queue. Current Creator Hub documentation reflects that workflow. [Official platform recap](https://devforum.roblox.com/t/weekly-recap-january-26-30-2026/4317114)

The build checks triangle budgets, finite coordinates, closed manifold component surfaces, UVs, single material, origin and dimensions, then reimports FBX files into Blender for an export round trip. Render review is performed in Blender. Studio upload, moderation, exact importer UI, permissions, pivot preservation and final lighting remain an explicit manager acceptance step, not a claimed completed test.
