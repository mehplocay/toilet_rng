# Wave 1 icon rendering source checks

Checked 2026-10-06. This batch calls Blender APIs and the local Rojo CLI; it does not call Roblox Engine or upload APIs.

- [Blender 4.5 dependency graph API](https://docs.blender.org/api/4.5/bpy.types.Depsgraph.html): an evaluated object's `to_mesh()` includes modifiers; the temporary mesh must be freed with `to_mesh_clear()`. The new framing helper projects those vertices to fit actual silhouettes instead of rotated bounding boxes.
- [Blender 4.5 Cycles film](https://docs.blender.org/manual/en/4.5/render/cycles/render_settings/film.html): transparent film removes the world from the rendered background for later compositing. The existing pipeline retains its world lighting, transparent RGBA, contour and soft alpha shadow.
- [Blender 4.5 camera API](https://docs.blender.org/api/4.5/bpy.types.Camera.html) and [4.5 Cycles release notes](https://developer.blender.org/docs/release_notes/4.5/cycles/): checked current version-specific search results. Full-page fetches were unavailable, so no new camera feature is assumed; the existing orthographic pipeline is reused and checked by local render output.
- [Roblox Creator Docs: third-party tools](https://create.roblox.com/docs/projects/external-tools): documents `rojo build -o <name>.rbxl` and opening the generated place in Studio. Local build success is a packaging check, not image-upload or in-game acceptance.

The first two findings were also available in version-specific indexed documentation. No downloads, new renderer dependencies, external image generation, fabricated asset IDs or uploads are needed. All material/geometry adaptations are process-local; original Python, Blender, FBX, texture and icon files remain read-only.
