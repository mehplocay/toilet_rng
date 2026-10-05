"""Reimport all emitted FBX files; validate geometry, UVs and embedded texture."""
import json
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from lib import ROOT, ASSETS, clean_scene, validate

manifest=json.loads((ASSETS/"manifest.json").read_text())
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
    textures=[n.image for m in obj.data.materials for n in m.node_tree.nodes if n.type=="TEX_IMAGE" and n.image]
    assert textures and all(img.size[0]==256 and img.size[1]==256 for img in textures)
    results.append({"name":entry["name"],"tris":tris,"fbx_round_trip":"passed","closed_components":True,"embedded_png":True,"texture":"256x256","dimensions":"matched within 0.001 stud"})
    print("ROUND_TRIP_OK",entry["name"],flush=True)
(ASSETS/"validation.json").write_text(json.dumps({"scope":"Blender FBX round trip, not Roblox Studio upload", "assets":results},indent=2)+"\n")
print("VALIDATION_OK",len(results),flush=True)
