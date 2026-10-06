"""Isolated Group C export, preview and FBX round-trip entry point."""
import argparse
import hashlib
import json
import math
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
import lib
from wave1_c import BUILDERS

ROOT = lib.ROOT
ASSETS = lib.ASSETS
MANIFEST = ASSETS / "manifest-wave1-c.json"
ATLAS = ASSETS / "textures/Wave1Palette_c.png"


def palette():
    """Same padded painted swatches; Group C gets its own silver highlight hue."""
    colors = dict(lib.PALETTE)
    # Leave the existing gray swatch unchanged; use previously unused slate
    # for the new silver. Builders select it through a local UV remap below.
    colors["slate"] = "C4D4E5"
    rows=[]
    for py in range(256):
        row=bytearray()
        for px in range(256):
            key=lib.KEYS[((255-py)//64)*8+px//32]
            base=[int(colors[key][i:i+2],16)/255 for i in (0,2,4)]
            u=min(1,max(0,((px%32)-3)/25))
            v=min(1,max(0,(((255-py)%64)-6)/51))
            gloss=.15*math.exp(-((u-.32)/.20)**2-((v-.80)/.10)**2)
            if key in ("ink","black"):
                gloss*=.18
            row.extend(round(255*min(1,c*(.82+.18*v)*(1-gloss)+gloss)) for c in base)
        rows.append(bytes(row))
    lib.png(ATLAS,256,256,rows)


def bind_palette(celestial):
    mat=lib.material()
    mat.name="Wave1Palette_c"
    for node in mat.node_tree.nodes:
        if node.type=="TEX_IMAGE":
            node.image=bpy.data.images.load(str(ATLAS),check_existing=True)
            node.image.pack()
    # Remap only Celestial gray parts to the private silver tile. The other
    # 31 swatches retain the established saturated toy colors verbatim.
    if celestial:
        delta=(lib.KEYS.index("slate")-lib.KEYS.index("gray"))/8
        for obj in bpy.context.scene.objects:
            if obj.type=="MESH" and obj.get("palette")=="gray":
                for uv in obj.data.uv_layers[0].data:
                    uv.uv.x+=delta
    return mat


def verify(entries):
    results=[]
    for entry in entries:
        lib.clean_scene()
        path=ROOT/entry["file"]
        assert ATLAS.read_bytes() in path.read_bytes(), entry["id"]+" missing exact embedded atlas"
        bpy.ops.import_scene.fbx(filepath=str(path),use_custom_normals=True)
        objects=list(bpy.context.scene.objects)
        meshes=[o for o in objects if o.type=="MESH"]
        assert len(meshes)==len(objects)==1, entry["id"]+" not one mesh only"
        obj=meshes[0]
        tris=lib.validate(obj,entry["budget"])
        assert all(len(p.vertices)==3 for p in obj.data.polygons)
        assert tris==entry["tris"]
        corners=[obj.matrix_world@Vector(v) for v in obj.bound_box]
        lo=[min(p[i] for p in corners) for i in range(3)]
        hi=[max(p[i] for p in corners) for i in range(3)]
        dims=[hi[i]-lo[i] for i in range(3)]
        expected=[entry["size_studs"][0],entry["size_studs"][2],entry["size_studs"][1]]
        assert max(abs(a-b) for a,b in zip(dims,expected))<.001,(entry["id"],dims,expected)
        assert abs(lo[2])<.001,entry["id"]+" floating base"
        assert abs(lo[0]+hi[0])<.001 and abs(lo[1]+hi[1])<.001
        assert obj.matrix_world.translation.length<.001
        textures=[n.image for m in obj.data.materials for n in m.node_tree.nodes
                  if n.type=="TEX_IMAGE" and n.image]
        assert textures and all(tuple(img.size)==(256,256) for img in textures)
        # Reimport must retain the actual Base Color image link, not only an
        # unused image datablock somewhere in a material.
        shader=next(n for n in obj.data.materials[0].node_tree.nodes if n.type=="BSDF_PRINCIPLED")
        assert shader.inputs["Base Color"].is_linked
        results.append({"id":entry["id"],"tris":tris,"fbx_round_trip":"passed",
                        "closed_component_surfaces":True,"single_uv_material_mesh":True,
                        "exact_embedded_atlas":True,"base_center_origin":True,
                        "dimensions":"matched within 0.001 stud"})
        print("ROUND_TRIP_OK",entry["id"],flush=True)
    (ASSETS/"validation-wave1-c.json").write_text(json.dumps({
        "scope":"Blender FBX round trip; not a Roblox Studio import test",
        "manifest":"assets/manifest-wave1-c.json","assets":results},indent=2)+"\n")


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--only",nargs="+")
    parser.add_argument("--no-render",action="store_true")
    parser.add_argument("--verify-only",action="store_true")
    parser.add_argument("--draft",action="store_true",help="320px composition review; final paths stay reserved")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    if args.only and set(args.only)-BUILDERS.keys():
        parser.error("Unknown Group C item IDs: "+str(set(args.only)-BUILDERS.keys()))
    if args.verify_only:
        verify(json.loads(MANIFEST.read_text())["assets"])
        return
    data=json.loads((ROOT/"docs/design/wave1-data.json").read_text(encoding="utf-8"))
    specs=[a for a in data["Items"] if a["New"] and a["Rarity"] in ("Godly","Celestial","Secret")]
    assert {a["Id"] for a in specs}==set(BUILDERS) and len(specs)==12
    previous=json.loads(MANIFEST.read_text()) if MANIFEST.exists() and args.only else {"assets":[]}
    records={a["id"]:a for a in previous["assets"]}
    palette()
    bpy.context.preferences.filepaths.save_version=0
    for spec in specs:
        name=spec["Id"]
        if args.only and name not in args.only:
            continue
        lib.clean_scene()
        BUILDERS[name]()
        # Update texture without editing or invoking lib.palette_texture().
        mat=bind_palette(spec["Rarity"]=="Celestial")
        obj=lib.join_asset(name,max(spec["Model"]["SizeStuds"]))
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        budget=spec["Model"]["TriangleBudget"]
        tris=lib.validate(obj,budget)
        path=lib.export_asset(obj,"wave1/c")
        bpy.context.view_layer.update()
        dims=obj.dimensions
        source=ASSETS/"blender/generated/wave1/c"/(name+".blend")
        source.parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(source),check_existing=False)
        record={"id":name,"name":spec["Name"],"display_name":spec["Name"],
                "rarity":spec["Rarity"],"category":"items","tris":tris,"budget":budget,
                "size_studs":[round(dims.x,4),round(dims.z,4),round(dims.y,4)],
                "brief_target_studs":spec["Model"]["SizeStuds"],
                "file":path.relative_to(ROOT).as_posix(),"source":source.relative_to(ROOT).as_posix(),
                "texture":ATLAS.relative_to(ROOT).as_posix(),
                "preview":f"assets/previews/wave1/c/{name}.png",
                "front_preview":f"assets/previews/wave1/c/{name}_front.png",
                "pivot":"base-center","mesh_count":1,"material_count":1,
                "fbx_sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
        records[name]=record
        manifest={"schema_version":1,"generator":"assets/blender/build_wave1_c.py / Blender 4.5",
                  "coordinate_system":"Export Y-up / Z-forward; author Z-up; size_studs is Roblox X,Y,Z",
                  "units":"stud","import_settings":{"scale_unit":"Stud","scale_factor":1,
                  "world_forward":"Front","world_up":"Top"},
                  "atlas_sha256":hashlib.sha256(ATLAS.read_bytes()).hexdigest(),
                  "assets":[records[s["Id"]] for s in specs if s["Id"] in records]}
        MANIFEST.write_text(json.dumps(manifest,indent=2)+"\n")
        print(f"ASSET_OK {name} {tris}/{budget}",flush=True)
        if not args.no_render:
            camera=lib.preview_stage(obj)
            # Keep the shared Cycles toy studio; bound threads for parallel worktrees.
            bpy.context.scene.render.threads_mode="FIXED"
            bpy.context.scene.render.threads=4
            scene=bpy.context.scene
            scene.cycles.use_adaptive_sampling=True
            scene.cycles.adaptive_min_samples=4
            scene.cycles.adaptive_threshold=.08
            if args.draft:
                scene.render.resolution_x=320
                scene.render.resolution_y=320
                scene.cycles.samples=8
            for key,az,el in [("preview",32,19),("front_preview",0,8)]:
                target=ROOT/record[key]
                if args.draft:
                    target=target.parent/"draft"/target.name
                lib.render_view(obj,camera,target,az,el)
    verify([records[s["Id"]] for s in specs if s["Id"] in records])
    print("GROUP_C_OK",len(records),flush=True)


if __name__=="__main__":
    main()
    # On this Windows CPU renderer, Blender teardown hung after GROUP_C_OK.
    # All writes and validation above are synchronous; only a successful
    # background run bypasses teardown. Exceptions still exit nonzero.
    if bpy.app.background:
        sys.stdout.flush()
        sys.stderr.flush()
        os._exit(0)
