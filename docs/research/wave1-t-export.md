# Wave 1 T export check

Checked 2026-10-06. Existing pipeline conventions remain appropriate:

- Roblox recommends FBX Unit Scale, other scales 1, Z Forward / Y Up. Keep authoring in stud-valued units and import with Stud / factor 1. https://create.roblox.com/docs/art/blender
- Closed surfaces with volume and one material per mesh fit the general mesh requirements. Our per-brief 4,300-5,000 triangle limits are stricter than the platform maximum. https://create.roblox.com/docs/art/modeling/specifications
- Blender 4.5 exposes `apply_scale_options='FBX_SCALE_UNITS'`, `axis_forward='Z'`, `axis_up='Y'`, `path_mode='COPY'`, and `embed_textures=True`; group T reuses the existing exporter unchanged. https://docs.blender.org/api/4.5/bpy.ops.export_scene.html
- Rechecked the official unit-conversion announcement URL. Its body was not available through the web reader in this session; the previously recorded June 2026 finding is retained rather than independently reasserted. https://devforum.roblox.com/t/more-control-over-importer-custom-scale-factor-and-updated-unit-conversions/4644371

Group T additionally compares every round-tripped world vertex to its source and verifies the embedded PNG bytes against the read-only shared atlas. Studio axis/scale/pivot preservation, permissions and final lighting still require the manager's import acceptance.
