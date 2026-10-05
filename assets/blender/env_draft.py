"""Fast design review from generated sources, independent of the build manifest.

Blender --background --python env_draft.py -- ToiletCastle ShopKiosk
Drafts are intentionally separate from the final 768px acceptance previews.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from lib import ASSETS, preview_stage, render_view

names=sys.argv[sys.argv.index("--")+1:]
for name in names:
    assert name.isalnum(), "Expected an environment asset name"
    bpy.ops.wm.open_mainfile(filepath=str(ASSETS/"blender/generated/env"/(name+".blend")))
    obj=bpy.data.objects[name]
    camera=preview_stage(obj)
    bpy.data.objects["Preview only - pastel floor"].scale=(8,8,8)
    bpy.context.scene.cycles.samples=12
    bpy.context.scene.render.resolution_x=512
    bpy.context.scene.render.resolution_y=512
    render_view(obj,camera,ASSETS/"previews/env-drafts"/(name+".png"),32,25)
    print("DRAFT_OK",name,flush=True)
