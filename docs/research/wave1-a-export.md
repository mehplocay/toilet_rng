# Wave 1 A export checks

Checked 2026-10-06. Existing pipeline helpers are reused read-only.

- Creator Hub still specifies Unit System None, FBX Unit Scale, Z Forward / Y Up, other scales 1; Studio uses Front / Top and Stud. https://create.roblox.com/docs/art/blender
- Closed, volumetric, outward-facing geometry remains the mesh guideline. The local individual brief budgets (1,400–2,300 triangles) are stricter than the platform limit. https://create.roblox.com/docs/art/modeling/specifications
- Blender 4.5's FBX exporter exposes `apply_scale_options`, `axis_forward`, `axis_up`, `path_mode`, and `embed_textures`. Use the existing pipeline's `FBX_SCALE_UNITS`, COPY and embedded PNG settings. https://docs.blender.org/api/4.5/bpy.ops.export_scene.html
- Checked the existing unit-conversion announcement URL; the web reader returned no substantive post body this session. Do not infer new changes from it. The current Creator Hub instructions above independently support Stud import. https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371
- The installed Blender 4.5.10 importer (`4.5/scripts/addons_core/io_scene_fbx/import_fbx.py`, `blen_read_texture_image`) calls `image.pack(data=...)` for FBX embedded Content. Validate `image.packed_file.data`, not the existence of an extracted `.fbm` directory. The initial disk-extraction assertion was corrected after inspecting this implementation.
- Validation copies each FBX into a temporary directory, imports it, checks packed atlas bytes, one mesh/material/UV layer, closed nondegenerate triangles, dimensions and base-center origin. This does not replace Studio import/pivot/lighting acceptance.
- Rojo's documented binary build command is `rojo build -o build.rbxl`; it passed for this assets-only worktree. https://rojo.space/docs/v7/getting-started/new-game/
- Blender Object ray casting takes origin and direction in object space and returns hit, location, normal and face index. Used to fit the beak smile to the actual faceted surface instead of leaving an interrupted line. Drain slots ultimately use UV-colored faces in the dome itself, removing overlay surfaces entirely. https://docs.blender.org/api/current/bpy.types.Object.html#bpy.types.Object.ray_cast
