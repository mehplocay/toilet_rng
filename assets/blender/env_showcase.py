"""Render an assembly proof from the actual exported FBX meshes.

The JSON is an art placement recipe, not runtime configuration. No src changes.
Coordinates in the recipe use canonical Roblox X/Y/Z and corrected front -Z.
"""
import json
import math
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from lib import ROOT, ASSETS, clean_scene, aim

manifest=json.loads((ASSETS/"manifest-env.json").read_text())
entries={a["name"]:a for a in manifest["assets"]}
original=json.loads((ASSETS/"manifest.json").read_text())
entries.update({a["name"]:a for a in original["assets"]})
clean_scene()
templates={}
placements=[]


def template(name):
    if name not in templates:
        before=set(bpy.context.scene.objects)
        bpy.ops.import_scene.fbx(filepath=str(ROOT/entries[name]["file"]))
        obj=next(o for o in set(bpy.context.scene.objects)-before if o.type=="MESH")
        # Bake the FBX import matrix into the geometry, retaining author axes.
        obj.data.transform(obj.matrix_world)
        obj.matrix_world.identity()
        obj.hide_render=True
        obj.hide_set(True)
        templates[name]=obj
    return templates[name]


def put(name,x=0,y=0,z=0,angle=0,scale=1,tint=None,record=True):
    base=template(name)
    obj=base.copy()
    obj.data=base.data
    bpy.context.collection.objects.link(obj)
    obj.hide_render=False
    obj.hide_set(False)
    obj.location=(x,y,z)
    obj.rotation_euler.z=math.radians(angle)
    obj.scale=(scale,)*3
    if tint:
        obj.data=base.data.copy()
        mat=base.data.materials[0].copy()
        shader=mat.node_tree.nodes.get("Principled BSDF")
        tex=next(n for n in mat.node_tree.nodes if n.type=="TEX_IMAGE")
        mix=mat.node_tree.nodes.new("ShaderNodeMixRGB")
        mix.blend_type="MULTIPLY"
        mix.inputs[0].default_value=1
        mix.inputs[2].default_value=(*tint,1)
        mat.node_tree.links.new(tex.outputs["Color"],mix.inputs[1])
        mat.node_tree.links.new(mix.outputs[0],shader.inputs["Base Color"])
        obj.data.materials.clear(); obj.data.materials.append(mat)
    if record:
        p={"asset":name,"position_studs":[round(x,5),round(z,5),round(y,5)],"yaw_degrees":round(-angle,4),"scale":scale}
        if tint: p["preview_tint_linear"]=tint
        placements.append(p)
    return obj


def radial(name,r,angle,z,**kwargs):
    a=math.radians(angle)
    return put(name,r*math.sin(a),-r*math.cos(a),z,angle=angle,**kwargs)


def arc_at(name,cx,cy,z,angle=0):
    # Arc assets have base-center origins, not pivots at the remote arc center.
    offset=entries[name]["author_center_offset"]
    a=math.radians(angle)
    return put(name,cx+offset[0]*math.cos(a)-offset[1]*math.sin(a),cy+offset[0]*math.sin(a)+offset[1]*math.cos(a),z+offset[2],angle)


# Main island: regular 24-stud surface, 13.4-stud cliff datum.
for ix in range(10):
    for iy in range(10):
        put("GrassSlab",-108+ix*24,-108+iy*24,12)
for i in range(10):
    for heading,cx,cy in [(0,-108+i*24,-114),(180,-108+i*24,114),(90,114,-108+i*24),(270,-114,-108+i*24)]:
        arc_at("CliffStraight"+chr(65+i%3),cx,cy,-.01,heading)
        # Long sandy apron below the cliffs, visually softens the square coast.
        if i not in (0,9):
            a=math.radians(heading)
            put("BeachStrip",cx+9*math.sin(a),cy-9*math.cos(a),-.3,heading)

for x in (-12,12):
    for y in (132,156):
        put("GrassSlab",x,y,12)
for y in (132,156):
    arc_at("CliffStraightA",18,y,-.01,90)
    arc_at("CliffStraightB",-18,y,-.01,270)
for x in (-12,12): arc_at("CliffStraightC",x,162,-.01,180)

put("HubMedallion",z=13.4)
put("FountainPedestal",z=14.512)
put("GoldenTrophy",z=17.812)
for i in range(10):
    angle=i*36
    arc_at("HubRingSegment",0,0,13.4,angle)
    arc_at("HubCurbSegment",0,0,13.4,angle+18)
    for r in (38,50,62): radial("HubPathStrip",r,angle,13.4)
    a=math.radians(angle)
    px,py=85*math.sin(a),-85*math.cos(a)
    inward=angle+180
    put("PlotPlatform",px,py,13.4,inward)
    def local(name,x,y,z,rot=0,scale=1):
        t=math.radians(inward)
        return put(name,px+x*math.cos(t)-y*math.sin(t),py+x*math.sin(t)+y*math.cos(t),z,inward+rot,scale)
    local("PlotGateArch",0,-14,14.85)
    local("PlotPathStraight",0,-7,13.85)
    local("PlotSignPost",-11,-11.5,14.85,scale=.75)
    for x in (-11,11): local("PlotCornerGarden",x,10.5,14.85)
    for x in (-8,0,8): local("PlotFenceSection",x,14.35,14.6)
    for x in (-14.35,14.35):
        for y in (-8,0,8): local("PlotFenceSection",x,y,14.6,90)
    local(["BasicToilet","GoldenToilet","DiamondToilet","GalaxyToilet"][i%4],0,5,14.85,scale=1.45)
    for x in (-8,-4,4,8):
        local("DisplayPedestal",x,1,14.85,scale=1.35)
    for x,y in [(-8,1),(8,1)]:
        local("RubberDuck" if x<0 else "GoldenPoop",x,y,16.6,scale=.65)
    radial("PalmTree",53,angle+18,13.4,scale=2)
    radial("LampPost",34,angle+18,13.4,scale=1.35)

put("ToiletCastle",0,143,13.4,scale=1.5)
put("PlazaSteps",0,121,13.4,180,1.5)
put("ShopKiosk",-36,-30,13.4,40,1.25)
put("IndexBookPedestal",-12,-36,13.4,25,1.1)
put("CollectCoinJar",12,-36,13.4,-25)
for name,x,y,angle in [("PortalSewer",-110,55,65),("PortalSpace",110,55,-65),("PortalHell",108,-40,-110)]:
    put(name,x,y,13.4,angle,1.2)
put("Lighthouse",-104,103,13.4,0)
put("GiantPalmCluster",-109,-105,13.4)
put("GiantPalmCluster",111,103,13.4,150)
put("SmallCove",-78,-137,-5,0)
for y in (-131,-147,-163): put("DockPier",28,y,-.3)
put("RopeBridge",0,181,10.775,0)
put("FloatingIsletB",0,201,0,0,1.03)
for x,y,z,v in [(-154,60,28,"A"),(160,115,40,"B"),(-125,175,53,"C")]:
    put("FloatingIslet"+v,x,y,z,0,1.4)
for i,(x,y,scale) in enumerate([(-150,208,1.4),(-42,234,1.8),(93,220,1.65),(182,169,1.4)]):
    put("MountainRidge"+chr(65+i%3),x,y,-1,0,scale,tint=(.16,.51,.90))
for i,(x,y,z) in enumerate([(-172,191,79),(-66,243,107),(65,239,88),(174,183,108)]):
    put("CloudBankTall" if i%2 else "CloudBankWide",x,y,z,0,1.5)
for i,(x,y) in enumerate([(-114,-64),(-118,24),(112,-90),(119,6),(-40,112),(52,111)]):
    put("ShoreRocks",x,y,13.4,i*51,1.4)
    put("TreeStump",x+3,y-5,13.4,i*35)

total_tris=sum(entries[p["asset"]]["tris"]*1 for p in placements)
(ASSETS/"env-layout.json").write_text(json.dumps({
    "scope":"Art assembly recipe only. Import acceptance and runtime integration are separate.",
    "coordinate_system":"Roblox X/Y/Z, front -Z; yaw about +Y after orientation correction",
    "surface_height_studs":13.4,"plot_radius_studs":85,"plot_count":10,
    "mesh_instances":len(placements),"placed_triangles":total_tris,
    "placements":placements},indent=2)+"\n")

# Ocean, lighting and cameras are presentation-only and never become kit assets.
scene=bpy.context.scene
scene.render.engine="CYCLES"
scene.cycles.samples=32
scene.cycles.use_denoising=True
scene.view_settings.view_transform="Standard"
scene.world.use_nodes=True
scene.world.node_tree.nodes.get("Background").inputs[0].default_value=(.12,.56,1,1)
scene.world.node_tree.nodes.get("Background").inputs[1].default_value=.75
bpy.ops.mesh.primitive_plane_add(size=2600,location=(0,0,-.55))
water=bpy.context.object
water.name="PREVIEW ONLY ocean"
mat=bpy.data.materials.new("Preview turquoise sea")
mat.diffuse_color=(.025,.56,.70,1)
mat.use_nodes=True
shader=mat.node_tree.nodes.get("Principled BSDF")
shader.inputs["Base Color"].default_value=(.025,.56,.70,1)
shader.inputs["Roughness"].default_value=.48
water.data.materials.append(mat)
lightdata=bpy.data.lights.new("Preview warm sunlight","SUN")
sun=bpy.data.objects.new("Preview warm sunlight",lightdata)
bpy.context.collection.objects.link(sun)
sun.rotation_euler=(math.radians(25),math.radians(-30),math.radians(-28))
lightdata.energy=2.4; lightdata.angle=.18
lightdata=bpy.data.lights.new("Preview sky softbox","AREA")
light=bpy.data.objects.new("Preview sky softbox",lightdata)
bpy.context.collection.objects.link(light)
light.location=(0,-60,150); lightdata.energy=180000; lightdata.size=160
aim(light,(0,0,0))
data=bpy.data.cameras.new("Environment art camera")
camera=bpy.data.objects.new("Environment art camera",data)
bpy.context.collection.objects.link(camera)
scene.camera=camera
scene.render.image_settings.file_format="PNG"


def render(filename,position,target,width,height,ortho=None):
    camera.location=position; aim(camera,target)
    data.type="ORTHO" if ortho else "PERSP"
    if ortho: data.ortho_scale=ortho
    else: data.lens=27
    data.clip_end=4000
    scene.render.resolution_x=width; scene.render.resolution_y=height
    scene.render.resolution_percentage=100
    scene.render.filepath=str(ASSETS/"previews"/filename)
    bpy.ops.render.render(write_still=True)


render("_env_assembled.png",(260,-365,300),(0,30,25),1600,1100,390)
render("_env_spawn.png",(0,-64,23),(0,40,22),1600,1000)
render("_env_plot.png",(43,-47,51),(0,-85,17),1400,1000,57)
print(f"ENV_LAYOUT_OK {len(placements)} mesh instances; {total_tris} placed triangles",flush=True)
