"""Build the environment pack without modifying the original asset manifest."""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from env_builders import SPECS
from lib import ASSETS, ROOT, clean_scene, join_asset, validate, export_asset, preview_stage, render_view


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--only",nargs="+")
    parser.add_argument("--no-render",action="store_true")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    names={s[0] for s in SPECS}
    if args.only and set(args.only)-names:
        parser.error("Unknown environment names: "+str(set(args.only)-names))
    atlas=ASSETS/"textures/ToyPalette.png"
    assert atlas.exists(), "Build the original pack first; the environment reuses its atlas."
    bpy.context.preferences.filepaths.save_version=0
    manifest_path=ASSETS/"manifest-env.json"
    previous=json.loads(manifest_path.read_text()) if manifest_path.exists() else {"assets":[]}
    records={a["name"]:a for a in previous["assets"]} if args.only else {}
    for name,family,builder,budget,assembly in SPECS:
        if args.only and name not in args.only:
            continue
        clean_scene()
        builder()
        bpy.context.view_layer.update()
        vertices=[o.matrix_world@v.co for o in bpy.context.scene.objects if o.type=="MESH" for v in o.data.vertices]
        lo=Vector(tuple(min(v[i] for v in vertices) for i in range(3)))
        hi=Vector(tuple(max(v[i] for v in vertices) for i in range(3)))
        offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
        obj=join_asset(name)
        tris=validate(obj,budget)
        bpy.context.view_layer.update()
        dims=obj.dimensions
        assert max(dims)<256, f"{name}: exceeds the pack's conservative 256-stud bound"
        assert abs(min(v.co.z for v in obj.data.vertices))<.0001
        assert all(abs(obj.location[i])<.0001 for i in range(3))
        path=export_asset(obj,"env")
        sockets={}
        for key,value in assembly.items():
            if key in ("arc_center","trophy_socket","text_face"):
                p=Vector(value)-offset
                sockets[key]=[round(p.x,5),round(p.z,5),round(p.y,5)]
        record={
            "name":name,"display_name":re.sub(r"(?<!^)(?=[A-Z])"," ",name),
            "category":"env","family":family,"tris":tris,"budget":budget,
            "size_studs":[round(dims.x,4),round(dims.z,4),round(dims.y,4)],
            "file":path.relative_to(ROOT).as_posix(),"texture":"assets/textures/ToyPalette.png",
            "preview":f"assets/previews/{name}.png","front_preview":f"assets/previews/{name}_front.png",
            "source":f"assets/blender/generated/env/{name}.blend",
            "pivot":"base-center","material_count":1,"mesh_count":1,
            "author_center_offset":[round(v,6) for v in offset],
            "sockets_studs":sockets,"assembly":assembly,
            "fbx_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
        }
        records[name]=record
        manifest={
            "schema_version":1,"generator":"Blender 4.5 / assets/blender/build_env.py",
            "coordinate_system":"Export Y-up / Z-forward; author Z-up; dimension order Roblox X,Y,Z",
            "socket_convention":"Canonical front -Z after Studio orientation acceptance; socket order X,Y,Z",
            "units":"stud (1 stud = 0.28 m)",
            "import_settings":{"scale_unit":"Stud","scale_factor":1,"world_forward":"Front","world_up":"Top"},
            "atlas_sha256":hashlib.sha256(atlas.read_bytes()).hexdigest(),
            "maximum_dimension_studs":256,
            "assets":[records[s[0]] for s in SPECS if s[0] in records],
        }
        source=ROOT/record["source"]
        source.parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(source),check_existing=False)
        print(f"ENV_OK {name} {tris}/{budget} triangles",flush=True)
        if not args.no_render:
            camera=preview_stage(obj)
            bpy.data.objects["Preview only - pastel floor"].scale=(8,8,8)
            bpy.context.scene.cycles.samples=16
            flat=dims.z<max(dims.x,dims.y)*.23
            render_view(obj,camera,ROOT/record["preview"],32,48 if flat else 23)
            render_view(obj,camera,ROOT/record["front_preview"],0,65 if flat else 10)
    # Publish the complete manifest only after the selected build finishes.
    manifest_path.write_text(json.dumps(manifest,indent=2)+"\n")
    print(f"ENV_BUILD_OK {len(records)} assets",flush=True)


if __name__=="__main__":
    main()
