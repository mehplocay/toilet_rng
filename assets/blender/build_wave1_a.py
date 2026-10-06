"""Isolated Group A build, render and mandatory FBX round-trip verification."""
import argparse
import hashlib
import json
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from lib import ROOT, ASSETS, clean_scene, join_asset, validate, preview_stage, render_view
from wave1_a import BUILDERS

MANIFEST = ASSETS / "manifest-wave1-a.json"
VALIDATION = ASSETS / "validation-wave1-a.json"
ATLAS = ASSETS / "textures/ToyPalette.png"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def export(obj, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=str(path), use_selection=True, object_types={"MESH"},
        global_scale=1.0, apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="Z", axis_up="Y", bake_space_transform=True,
        use_mesh_modifiers=True, mesh_smooth_type="FACE", use_triangles=True,
        bake_anim=False, path_mode="COPY", embed_textures=True,
    )


def round_trip(entry):
    """Verify an isolated FBX copy, including exact embedded atlas and base pivot."""
    path = ROOT / entry["file"]
    assert digest(path) == entry["fbx_sha256"]
    assert ATLAS.read_bytes() in path.read_bytes(), entry["id"] + " missing exact embedded palette"
    assert ATLAS.read_bytes() in (ROOT / entry["source"]).read_bytes(), entry["id"] + " source palette is not packed"
    clean_scene()
    for img in list(bpy.data.images):
        if img.type != "RENDER_RESULT":
            bpy.data.images.remove(img)
    with tempfile.TemporaryDirectory(prefix="wave1-a-fbx-") as temp:
        isolated = Path(temp) / path.name
        isolated.write_bytes(path.read_bytes())
        bpy.ops.import_scene.fbx(filepath=str(isolated), use_custom_normals=True)
        meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        assert len(meshes) == 1 and len(bpy.context.scene.objects) == 1
        obj = meshes[0]
        tris = validate(obj, entry["budget"])
        assert tris == entry["tris"]
        corners = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
        lo = [min(v[i] for v in corners) for i in range(3)]
        hi = [max(v[i] for v in corners) for i in range(3)]
        expected = [entry["size_studs"][0], entry["size_studs"][2], entry["size_studs"][1]]
        error = max(abs(hi[i]-lo[i]-expected[i]) for i in range(3))
        assert error < .001, (entry["id"], error)
        assert abs(lo[2]) < .001 and obj.matrix_world.translation.length < .001
        assert abs(lo[0]+hi[0]) < .001 and abs(lo[1]+hi[1]) < .001
        images = [n.image for m in obj.data.materials for n in m.node_tree.nodes
                  if n.type == "TEX_IMAGE" and n.image]
        assert images and all(tuple(i.size) == (256, 256) for i in images)
        # Blender's FBX importer packs embedded Content into the image datablock.
        # It does not necessarily write an extracted .fbm file to disk.
        assert all(i.packed_file and hashlib.sha256(i.packed_file.data).hexdigest() == entry["atlas_sha256"]
                   for i in images), "Embedded packed atlas differs from the source"
        return {"id": entry["id"], "tris": tris, "fbx_round_trip": "passed",
                "closed_components": True, "nondegenerate_triangles": True,
                "single_mesh_material_uv": True, "embedded_atlas_sha256": entry["atlas_sha256"],
                "base_center_origin": True, "source_palette_packed": True, "max_dimension_error_studs": error}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="+")
    parser.add_argument("--no-render", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--review", action="store_true", help="384px geometry review only; never writes final exports or manifest")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    if args.only and set(args.only)-BUILDERS.keys():
        parser.error("Unknown Group A IDs: " + str(set(args.only)-BUILDERS.keys()))
    specs = json.loads((ROOT / "docs/design/wave1-data.json").read_text(encoding="utf-8"))["Items"]
    specs = [s for s in specs if s["New"] and s["Rarity"] in ("Common", "Uncommon", "Rare")]
    assert {s["Id"] for s in specs} == BUILDERS.keys() and len(specs) == 12
    atlas_hash = digest(ATLAS)
    previous = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"assets": []}
    records = {a["id"]: a for a in previous["assets"]} if args.only or args.verify_only else {}
    bpy.context.preferences.filepaths.save_version = 0
    for spec in specs:
        name = spec["Id"]
        if args.verify_only or (args.only and name not in args.only):
            continue
        clean_scene()
        BUILDERS[name]()
        obj = join_asset(name)
        bpy.context.view_layer.update()
        # Author proportions are deliberately fitted to the explicit brief bounds.
        target = spec["Model"]["SizeStuds"]
        factors = Vector((target[0]/obj.dimensions.x, target[2]/obj.dimensions.y, target[1]/obj.dimensions.z))
        for v in obj.data.vertices:
            v.co = Vector(tuple(v.co[i]*factors[i] for i in range(3)))
        obj.data.update()
        bpy.context.view_layer.update()
        budget = min(2500, spec["Model"]["TriangleBudget"])
        tris = validate(obj, budget)
        if args.review:
            camera = preview_stage(obj)
            scene = bpy.context.scene
            scene.render.resolution_percentage = 50
            scene.cycles.samples = 8
            scene.render.threads_mode = "FIXED"
            scene.render.threads = 6
            render_view(obj, camera, ASSETS / "previews/wave1/a/review" / (name + ".png"), 32, 19)
            render_view(obj, camera, ASSETS / "previews/wave1/a/review" / (name + "_front.png"), 0, 8)
            continue
        path = ASSETS / "models/wave1/a" / (name + ".fbx")
        export(obj, path)
        preview = ASSETS / "previews/wave1/a" / (name + ".png")
        front = preview.with_name(name + "_front.png")
        source = ASSETS / "blender/generated/wave1/a" / (name + ".blend")
        source.parent.mkdir(parents=True, exist_ok=True)
        # Editable scenes remain portable after the worktree path changes.
        for node in obj.data.materials[0].node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image and not node.image.packed_file:
                node.image.pack()
        bpy.ops.wm.save_as_mainfile(filepath=str(source), check_existing=False)
        record = {"id": name, "name": spec["Name"], "category": "items", "rarity": spec["Rarity"],
                  "file": path.relative_to(ROOT).as_posix(), "tris": tris, "budget": budget,
                  "size_studs": target, "pivot": "base-center", "mesh_count": 1, "material_count": 1,
                  "texture": ATLAS.relative_to(ROOT).as_posix(), "atlas_sha256": atlas_hash,
                  "fbx_sha256": digest(path), "source": source.relative_to(ROOT).as_posix(),
                  "preview": preview.relative_to(ROOT).as_posix(), "front_preview": front.relative_to(ROOT).as_posix()}
        records[name] = record
        print(f"ASSET_OK {name}: {tris}/{budget}", flush=True)
        if not args.no_render:
            camera = preview_stage(obj)
            bpy.context.scene.render.threads_mode = "FIXED"
            bpy.context.scene.render.threads = 6
            render_view(obj, camera, preview, 32, 19)
            render_view(obj, camera, front, 0, 8)
        # Save incremental progress only to this group's manifest.
        manifest = {"schema_version": 1, "group": "wave1/a", "generator": "assets/blender/build_wave1_a.py",
                    "units": "stud", "coordinate_system": "Y-up / Z-forward export; size_studs = Roblox X,Y,Z",
                    "import_settings": {"scale_unit": "Stud", "scale_factor": 1, "world_forward": "Front", "world_up": "Top"},
                    "atlas_sha256": atlas_hash, "assets": [records[s["Id"]] for s in specs if s["Id"] in records]}
        MANIFEST.write_text(json.dumps(manifest, indent=2)+"\n")
    assert digest(ATLAS) == atlas_hash, "Shared palette was changed"
    if args.review:
        return
    assert records, "No Group A exports to verify; build the assets first"
    results = [round_trip(records[s["Id"]]) for s in specs if s["Id"] in records]
    for result in results:
        print("ROUND_TRIP_OK", result["id"], flush=True)
    VALIDATION.write_text(json.dumps({"scope": "Blender FBX round trip; not Studio import acceptance",
                                     "manifest": "assets/manifest-wave1-a.json", "assets": results}, indent=2)+"\n")
    print(f"VALIDATION_OK {len(results)} assets", flush=True)


if __name__ == "__main__":
    main()
