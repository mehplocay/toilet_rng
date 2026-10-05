"""Run with Blender --background --python build.py -- [--only Name ...]."""
import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from builders import ASSET_SPECS
from lib import ASSETS, ROOT, palette_texture, clean_scene, join_asset, validate, export_asset, preview_stage, render_view


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--only",nargs="*")
    parser.add_argument("--no-render",action="store_true")
    parser.add_argument("--turntable",action="store_true",help="Also render eight 768px turntable angles per asset")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    names={s[0] for s in ASSET_SPECS}
    if args.only and set(args.only)-names:
        parser.error("Unknown names: "+str(set(args.only)-names))
    palette_texture()
    bpy.context.preferences.filepaths.save_version=0
    manifest_path=ASSETS/"manifest.json"
    previous=json.loads(manifest_path.read_text()) if manifest_path.exists() else {"assets":[]}
    records={a["name"]:a for a in previous["assets"]} if args.only else {}
    for name,category,builder,target in ASSET_SPECS:
        if args.only and name not in args.only:
            continue
        clean_scene()
        builder()
        obj=join_asset(name,target,toilet_datum=category=="toilets")
        budget={"items":2500,"toilets":5000,"props":4000}[category]
        tris=validate(obj,budget)
        path=export_asset(obj,category)
        bpy.context.view_layer.update()
        dims=obj.dimensions
        record={"name":name,"display_name":"???" if name=="Mystery" else re.sub(r"(?<!^)(?=[A-Z])"," ",name),"category":category,"tris":tris,"budget":budget,"size_studs":[round(dims.x,4),round(dims.z,4),round(dims.y,4)],"file":path.relative_to(ROOT).as_posix(),"texture":"assets/textures/ToyPalette.png","preview":f"assets/previews/{name}.png","front_preview":f"assets/previews/{name}_front.png","pivot":"base-center","material_count":1,"mesh_count":1}
        records[name]=record
        manifest={"schema_version":1,"generator":"Blender 4.5 / assets/blender/build.py","coordinate_system":"Export Y-up / Z-forward; author Z-up; dimension order Roblox X,Y,Z","units":"stud (1 stud = 0.28 m)","import_settings":{"scale_unit":"Stud","scale_factor":1,"world_forward":"Front","world_up":"Top"},"assets":[records[s[0]] for s in ASSET_SPECS if s[0] in records]}
        manifest_path.write_text(json.dumps(manifest,indent=2)+"\n")
        source=ASSETS/"blender"/"generated"/(name+".blend")
        source.parent.mkdir(parents=True,exist_ok=True)
        # Save asset-only source before preview-only floor, lights and camera exist.
        bpy.ops.wm.save_as_mainfile(filepath=str(source),check_existing=False)
        print(f"ASSET_OK {name} {tris}/{budget} triangles",flush=True)
        if not args.no_render:
            camera=preview_stage(obj)
            render_view(obj,camera,ASSETS/"previews"/(name+".png"),32,19)
            render_view(obj,camera,ASSETS/"previews"/(name+"_front.png"),0,8)
            if args.turntable:
                for i in range(8):
                    render_view(obj,camera,ASSETS/"previews"/"turntables"/name/f"{i:02}.png",i*45,19)
    print(f"BUILD_OK {len(records)} assets in manifest",flush=True)


if __name__=="__main__":
    main()
