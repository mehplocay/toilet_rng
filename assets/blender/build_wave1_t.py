"""Isolated Wave 1 T build and FBX round-trip verification, Blender 4.5."""
import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector, kdtree
from lib import ROOT, ASSETS, clean_scene, join_asset, validate, export_asset, preview_stage, render_view
from wave1_t import BUILDERS

MANIFEST = ASSETS / "manifest-wave1-t.json"
VALIDATION = ASSETS / "validation-wave1-t.json"
TEXTURE = ASSETS / "textures/ToyPalette.png"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, indent=2)+"\n", encoding="utf-8")


def verify(entry, reference):
    """Verify every export immediately, including full geometry orientation.

    Equivalent to verify.py plus exact embedded atlas, pivot and vertex matching.
    This does not claim Roblox Studio acceptance.
    """
    path = ROOT / entry["file"]
    assert TEXTURE.read_bytes() in path.read_bytes(), "Embedded atlas bytes differ"
    clean_scene()
    # Remove cached image data so import must resolve the exported texture.
    for img in list(bpy.data.images):
        if img.name not in ("Render Result", "Viewer Node"):
            bpy.data.images.remove(img)
    bpy.ops.import_scene.fbx(filepath=str(path), use_custom_normals=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert len(meshes) == 1
    obj = meshes[0]
    assert validate(obj, entry["budget"]) == entry["tris"]
    assert obj.matrix_world.translation.length < .001, "Displaced foot origin"
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    lo = [min(p[i] for p in points) for i in range(3)]
    hi = [max(p[i] for p in points) for i in range(3)]
    dims = [hi[i]-lo[i] for i in range(3)]
    expected = [entry["size_studs"][i] for i in (0,2,1)]
    assert max(abs(a-b) for a,b in zip(dims, expected)) < .001
    assert abs(lo[2]) < .001, "Floating base"
    assert len(points) == len(reference)
    tree = kdtree.KDTree(len(points))
    for i, p in enumerate(points):
        tree.insert(p, i)
    tree.balance()
    error = max(tree.find(p)[2] for p in reference)
    assert error < .001, "FBX changed vertex positions/orientation"
    textures = [n.image for m in obj.data.materials for n in m.node_tree.nodes
                if n.type == "TEX_IMAGE" and n.image]
    assert textures and all(tuple(img.size) == (256,256) for img in textures)
    print("ROUND_TRIP_OK", entry["id"], flush=True)
    return {"id":entry["id"], "fbx_round_trip":"passed", "tris":entry["tris"],
            "single_mesh_material_uv":True, "closed_components":True,
            "no_degenerate_triangles":True, "embedded_atlas_bytes_match":True,
            "ground_and_origin":"within 0.001 stud", "dimensions":"within 0.001 stud",
            "all_vertex_max_error_studs":round(error,8), "fbx_sha256":sha(path)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="+")
    parser.add_argument("--no-render", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    if args.only and set(args.only)-set(BUILDERS):
        parser.error("Unknown group T IDs: "+str(set(args.only)-set(BUILDERS)))
    specs = [a for a in json.loads((ROOT/"docs/design/wave1-data.json").read_text(encoding="utf-8"))["Toilets"] if a["New"]]
    assert [a["Id"] for a in specs] == list(BUILDERS)
    atlas_hash = sha(TEXTURE)
    bpy.context.preferences.filepaths.save_version = 0
    records = {a["id"]:a for a in json.loads(MANIFEST.read_text())["assets"]} if args.only and MANIFEST.exists() else {}
    checks = {a["id"]:a for a in json.loads(VALIDATION.read_text())["assets"]} if args.only and VALIDATION.exists() else {}
    for spec in specs:
        name = spec["Id"]
        if args.only and name not in args.only:
            continue
        clean_scene()
        BUILDERS[name]()
        bpy.context.view_layer.update()
        seat = bpy.data.objects["Chunky seat rim"]
        lid = bpy.data.objects["Raised lid"]
        assert abs(seat.location.z-2.08) < 1e-6
        assert abs(max((lid.matrix_world @ v.co).z for v in lid.data.vertices)-4.79) < 1e-5
        obj = join_asset(name, toilet_datum=True)
        budget = min(5000, spec["Model"]["TriangleBudget"])
        tris = validate(obj, budget)
        bpy.context.view_layer.update()
        reference = [obj.matrix_world @ v.co for v in obj.data.vertices]
        dims = obj.dimensions.copy()
        path = export_asset(obj, "wave1/t")
        source = ASSETS/"blender/generated/wave1/t"/(name+".blend")
        source.parent.mkdir(parents=True, exist_ok=True)
        for node in obj.data.materials[0].node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image:
                node.image.pack()
        bpy.ops.wm.save_as_mainfile(filepath=str(source), check_existing=False)
        entry = {"id":name, "name":spec["Name"], "tier":spec["Tier"], "category":"toilets",
                 "file":path.relative_to(ROOT).as_posix(), "source":source.relative_to(ROOT).as_posix(),
                 "tris":tris, "budget":budget, "size_studs":[round(dims[i],4) for i in (0,2,1)],
                 "target_size_studs":spec["Model"]["SizeStuds"],
                 "texture":"assets/textures/ToyPalette.png", "pivot":"center of bottom foot at ground",
                 "seat_center_height_studs":2.08, "core_lid_top_studs":4.79,
                 "mesh_count":1, "material_count":1,
                 "preview":f"assets/previews/wave1/t/{name}.png",
                 "front_preview":f"assets/previews/wave1/t/{name}_front.png"}
        if not args.no_render:
            camera = preview_stage(obj)
            render_view(obj, camera, ROOT/entry["preview"], 32, 19)
            render_view(obj, camera, ROOT/entry["front_preview"], 0, 8)
        checks[name] = verify(entry, reference)
        records[name] = entry
        assert sha(TEXTURE) == atlas_hash, "Shared atlas changed"
        dump(MANIFEST, {"schema_version":1, "group":"T", "generator":"assets/blender/build_wave1_t.py",
                        "coordinate_system":"Export Y-up / Z-forward; author Z-up, front -Y; dimensions Roblox X/Y/Z",
                        "units":"stud", "atlas_sha256":atlas_hash,
                        "import_settings":{"scale_unit":"Stud", "scale_factor":1, "world_forward":"Front", "world_up":"Top"},
                        "assets":[records[n] for n in BUILDERS if n in records]})
        dump(VALIDATION, {"scope":"Blender FBX round trip; not Roblox Studio upload",
                          "assets":[checks[n] for n in BUILDERS if n in checks]})
        print(f"ASSET_OK {name} {tris}/{budget}", flush=True)
    print("BUILD_OK", len(records), flush=True)


if __name__ == "__main__":
    main()
