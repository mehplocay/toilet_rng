# Wave 1 B export checks

Checked 2026-10-06. This task produces static collectible FBX files; no Roblox APIs or uploads are used.

- Keep Unit System None, FBX Unit Scale, export Z Forward / Y Up and scale 1. Import with Stud / factor 1, Front / Top. These are confirmed by the current [official Blender workflow](https://create.roblox.com/docs/art/blender).
- The [official modeling specifications](https://create.roblox.com/docs/art/modeling/specifications) require closed geometry and a single material per mesh. The local briefs impose stricter 1,800–2,500-triangle limits; the build validates each individual budget.
- The [2026 importer announcement](https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371) and [May recap](https://devforum.roblox.com/t/weekly-recap-may-18-21-2026/4647113) document the June 16 non-Stud conversion change to 25:7 studs/meter. Stud-valued exports must not receive an extra meter conversion.
- [Blender's exporter operator reference](https://docs.blender.org/api/4.4/bpy.ops.export_scene.html) documents COPY paths, embedded textures, axis and FBX scale options. The 4.5 documentation URL returned an error during this check; actual execution uses the installed Blender 4.5.10 and the existing repository export helper. Round-trip checks verify exact embedded PNG bytes, dimensions, pivot, topology and UVs.
- Existing ToyPalette.png is read-only, reused byte-for-byte and embedded. No new palette colors are needed.
- A Blender reimport cannot establish Studio pivot preservation, moderation, permissions or in-game lighting. Those remain manager acceptance checks.
