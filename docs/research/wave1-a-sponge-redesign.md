# Wave 1 A scouring-pad redesign checks

Checked 2026-10-06 before the focused SpongeKnight rebuild.

- Current Creator Hub guidance still recommends Unit System None, FBX Unit Scale with other scales 1, Z Forward / Y Up, and Studio Front / Top / Stud. Preserve the existing export settings and verify the exported dimensions independently. https://create.roblox.com/docs/art/blender
- Blender's official current Object API search excerpt confirms that `Object.ray_cast` operates on evaluated geometry in object space. The six scrub fibers use the existing local ray-cast pattern: applied body scale, subtract object location from the ray origin, then add location back to the returned hit. https://docs.blender.org/api/current/bpy.types.Object.html?highlight=ray
- Official Blender 5.0 export API search results still list `apply_scale_options`, `axis_forward`, `axis_up`, `path_mode`, and `embed_textures`. Direct web reads of both 4.5 and current API pages returned HTTP 402; no claim is made that the newer documentation guarantees installed-version behavior. Blender 4.5.10's actual export/reimport validation remains the compatibility check. https://docs.blender.org/api/5.0/bpy.ops.export_scene.html
- Rojo's official command remains `rojo build -o build.rbxl`. https://rojo.space/docs/v7/getting-started/new-game/

No Roblox runtime API, Studio upload, moderation decision or legal clearance is part of this local art pass. The redesign and the other eleven model assessments are visual judgments documented in `docs/wave1-art-a.md`.
