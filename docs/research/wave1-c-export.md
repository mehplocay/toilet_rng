# Wave 1 C export checks

Checked 2026-10-06 before building Group C. Existing pipeline research remains applicable.

- Roblox's [Blender workflow](https://create.roblox.com/docs/art/blender) still specifies None units, FBX Unit Scale, Z Forward / Y Up, other scales 1; Studio uses Front / Top / Stud. Group C reuses the read-only exporter with these settings.
- [General specifications](https://create.roblox.com/docs/art/modeling/specifications) require valid volumetric meshes. Group C enforces the stricter per-item brief budgets (2,300–2,500), closed component surfaces, finite vertices and nondegenerate triangles.
- [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications) and the [Blender FBX operator](https://docs.blender.org/api/current/bpy.ops.export_scene.html) support the atlas / COPY / embedded-texture workflow. Group C ships its own opaque 256px atlas and verifies the exact PNG bytes are embedded. The version-specific 4.5 API page failed to load during this check; the installed 4.5 exporter and round trip provide local verification.
- The [official importer unit-change thread](https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371) was checked alongside the current Creator docs. Stud / factor 1 is retained; no meter correction is applied.
- Starlight is portable cyan/white geometry and painted silver, not an assumed transfer of Blender emission. Real bloom/light is a later Studio integration decision. No API/runtime changes or uploads are part of this task.
- [Rojo build documentation](https://rojo.space/docs/v7/building/) is the reference for the repository build check; the asset scripts do not alter the Rojo mapping.
