"""Reimport all emitted FBX files; validate geometry, UVs and embedded texture."""
import json
import argparse
import hashlib
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from lib import ROOT, ASSETS, clean_scene, validate

parser=argparse.ArgumentParser()
parser.add_argument("--manifest",default="assets/manifest.json")
parser.add_argument("--output",default="assets/validation.json")
args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
manifest=json.loads((ROOT/args.manifest).read_text())
if "atlas_sha256" in manifest:
    assert hashlib.sha256((ASSETS/"textures/ToyPalette.png").read_bytes()).hexdigest()==manifest["atlas_sha256"]
results=[]
for entry in manifest["assets"]:
    clean_scene()
    assert b"\x89PNG\r\n\x1a\n" in (ROOT/entry["file"]).read_bytes(), entry["name"]+" missing embedded PNG"
    bpy.ops.import_scene.fbx(filepath=str(ROOT/entry["file"]),use_custom_normals=True)
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    assert len(meshes)==1,entry["name"]
    obj=meshes[0]
    tris=validate(obj,entry["budget"])
    assert tris==entry["tris"]
    corners=[obj.matrix_world@Vector(v) for v in obj.bound_box]
    dims=[max(p[i] for p in corners)-min(p[i] for p in corners) for i in range(3)]
    expected=[entry["size_studs"][0],entry["size_studs"][2],entry["size_studs"][1]]
    assert max(abs(a-b) for a,b in zip(dims,expected))<.001,(entry["name"],dims,expected)
    assert abs(min(v.z for v in corners))<.001,entry["name"]+" floating base"
    if entry.get("category")=="env":
        assert max(dims)<manifest["maximum_dimension_studs"]
        assert obj.matrix_world.translation.length<.001,entry["name"]+" displaced origin"
        assert abs(min(v.x for v in corners)+max(v.x for v in corners))<.001
        assert abs(min(v.y for v in corners)+max(v.y for v in corners))<.001
        assert hashlib.sha256((ROOT/entry["file"]).read_bytes()).hexdigest()==entry["fbx_sha256"]
    textures=[n.image for m in obj.data.materials for n in m.node_tree.nodes if n.type=="TEX_IMAGE" and n.image]
    assert textures and all(img.size[0]==256 and img.size[1]==256 for img in textures)
    results.append({"name":entry["name"],"tris":tris,"fbx_round_trip":"passed","closed_components":True,"embedded_png":True,"texture":"256x256","dimensions":"matched within 0.001 stud"})
    print("ROUND_TRIP_OK",entry["name"],flush=True)
(ROOT/args.output).write_text(json.dumps({"scope":"Blender FBX round trip, not Roblox Studio upload", "manifest":args.manifest, "assets":results},indent=2)+"\n")
print("VALIDATION_OK",len(results),flush=True)
