"""Blender 4.5 headless art build. Does not export meshes or modify game code."""
import argparse
import json
import math
import random
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Vector
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lib
import builders
import icon_models as ui
import pass_models as passes
from icon_pixels import read_png, write_png, over, downsample, sticker, backdrop, blur

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'assets/icons'
SCRATCH = OUT/'.scratch'
SPECS = {name: (category, build, span) for name, category, build, span in builders.ASSET_SPECS}
FONT = 'C:/Windows/Fonts/arialbd.ttf'
TIERS = ('Basic','Dirty','Golden','Diamond','Radioactive','Demon','Galaxy')


def linear(v):
    return v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4


def material(color):
    name = 'Icon enamel '+color
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    rgb = [int(lib.PALETTE[color][i:i+2],16)/255 for i in (0,2,4)]
    shader.inputs['Base Color'].default_value = (*map(linear,rgb),1)
    shader.inputs['Roughness'].default_value = .27
    shader.inputs['Coat Weight'].default_value = .36
    shader.inputs['Coat Roughness'].default_value = .19
    shader.inputs['Metallic'].default_value = .48 if color in ('gold','goldLight','orange') else .04
    if color in ('ink','black'):
        shader.inputs['Roughness'].default_value = .33
    return mat


def install_render_geometry():
    """Reuse designs at render density, without changing gameplay mesh sources."""
    original_finish = lib.finish
    def finish(obj,color,smooth=True):
        obj = original_finish(obj,color if color in lib.KEYS else 'red',smooth)
        obj.data.materials.clear()
        obj.data.materials.append(material(color))
        return obj
    lib.finish = finish
    lib.icon_material = material
    original = {name:getattr(lib,name) for name in ('sphere','torus','cylinder','lathe','tube','box')}
    def sphere(name,loc,scale,color,segments=12,rings=8,smooth=True):
        return original['sphere'](name,loc,scale,color,max(40,segments) if smooth else segments,max(24,rings) if smooth else rings,smooth)
    def torus(name,loc,major,minor,color,scale=(1,1,1),rotation=(0,0,0),segments=24,sides=6):
        return original['torus'](name,loc,major,minor,color,scale,rotation,max(64,segments),max(16,sides))
    def cylinder(name,loc,radius,depth,color,vertices=16,radius_top=None):
        o=original['cylinder'](name,loc,radius,depth,color,64 if vertices>=12 else vertices,radius_top)
        return ui.bevel(o,min(.035,depth*.15))
    def lathe(name,profile,loc,color,scale=(1,1,1),segments=24,smooth=True):
        return original['lathe'](name,profile,loc,color,scale,max(64,segments),smooth)
    def tube(name,points,radii,color,sides=8):
        o=original['tube'](name,points,radii,color,max(16,sides))
        if name in ('Continuous piped swirl','Curled pink tail','Baby hair curl','Curved demon horn'):
            sub=o.modifiers.new('Smooth sculpted curve','SUBSURF')
            sub.levels=2
        return o
    def box(name,loc,size,color,bevel=.12):
        bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
        o=bpy.context.object
        o.name,o.scale=name,size
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        if bevel:
            mod=o.modifiers.new('Soft moulded corners','BEVEL')
            mod.width,mod.segments=min(bevel,min(size)*.45),5
        o=finish(o,color,False)
        for p in o.data.polygons:
            p.use_smooth=True
        mod=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL')
        mod.keep_sharp=True
        return o
    for name, fn in dict(sphere=sphere,torus=torus,cylinder=cylinder,lathe=lathe,tube=tube,box=box).items():
        setattr(lib,name,fn)
        setattr(builders,name,fn)


def meshes():
    return [o for o in bpy.context.scene.objects if o.type in ('MESH','FONT','CURVE')]


def bounds(objects):
    bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get()
    points=[]
    for obj in objects:
        ev=obj.evaluated_get(dg)
        points.extend(ev.matrix_world@Vector(corner) for corner in ev.bound_box)
    return points


def instantiate(name,loc=(0,0,0),scale=1,angle=0):
    # Some legacy builders deliberately move everything in their fresh scene.
    # Restore existing transforms when composing several assets in one scene.
    bpy.context.view_layer.update()
    previous={o:o.matrix_world.copy() for o in bpy.context.scene.objects}
    if name in SPECS:
        SPECS[name][1]()
    elif name in passes.MODELS:
        passes.MODELS[name]()
    else:
        ui.UI[name]()
    created=[o for o in bpy.context.scene.objects if o not in previous]
    for o,matrix in previous.items():
        o.matrix_world=matrix
    parent=bpy.data.objects.new(name+' placement',None)
    bpy.context.collection.objects.link(parent)
    for o in created:
        # Preserve nested sculpture transforms (coin stacks, clovers, chest lid).
        if o.parent not in created:
            o.parent=parent
    parent.location=loc
    parent.scale=(scale,)*3
    parent.rotation_euler.z=math.radians(angle)
    return created


def setup(width,height,samples=48):
    lib.clean_scene()
    s=bpy.context.scene
    s.render.engine='CYCLES'
    s.cycles.samples=samples
    s.cycles.use_denoising=True
    s.cycles.seed=17
    s.cycles.max_bounces=7
    s.render.resolution_x,s.render.resolution_y=width,height
    s.render.resolution_percentage=100
    s.render.film_transparent=True
    s.render.image_settings.file_format='PNG'
    s.render.image_settings.color_mode='RGBA'
    s.render.image_settings.color_depth='8'
    s.render.image_settings.compression=30
    s.view_settings.view_transform='Standard'
    s.view_settings.look='None'
    s.view_settings.exposure=-.35
    s.world.use_nodes=True
    s.world.node_tree.nodes.get('Background').inputs[0].default_value=(.36,.46,.67,1)
    s.world.node_tree.nodes.get('Background').inputs[1].default_value=.40
    return s


def light(name,loc,target,power,size,color=(1,1,1)):
    data=bpy.data.lights.new(name,'AREA')
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.location=loc
    data.energy,data.shape,data.size,data.color=power,'DISK',size,color
    lib.aim(obj,target)


def studio_lights(target,span):
    t=Vector(target)
    k=span/3
    light('Warm key',t+Vector((-3,-4,6))*k,t,520*k*k,3.5*k,(1,.87,.73))
    light('Sky fill',t+Vector((4,-3,2))*k,t,220*k*k,4*k,(.63,.83,1))
    light('Soft rim',t+Vector((1,3,5))*k,t,760*k*k,2.6*k,(.73,.86,1))
    light('Gloss strip',t+Vector((-2,-4,3))*k,t,65*k*k,.75*k)


def camera(target,direction,ortho):
    data=bpy.data.cameras.new('Art camera')
    obj=bpy.data.objects.new('Art camera',data)
    bpy.context.collection.objects.link(obj)
    obj.location=Vector(target)+Vector(direction).normalized()*ortho*5
    lib.aim(obj,target)
    data.type='ORTHO'
    data.ortho_scale=ortho
    bpy.context.scene.camera=obj
    return obj


def frame(objects,azimuth=25,elevation=16,padding=1.19,aspect=1):
    pts=bounds(objects)
    lo=Vector([min(p[i] for p in pts) for i in range(3)])
    hi=Vector([max(p[i] for p in pts) for i in range(3)])
    target=(lo+hi)/2
    a,e=map(math.radians,(azimuth,elevation))
    direction=(math.sin(a)*math.cos(e),-math.cos(a)*math.cos(e),math.sin(e))
    cam=camera(target,direction,1)
    inverse=cam.rotation_euler.to_matrix().transposed()
    pp=[inverse@(p-target) for p in pts]
    x0,x1=min(p.x for p in pp),max(p.x for p in pp)
    y0,y1=min(p.y for p in pp),max(p.y for p in pp)
    span=max(x1-x0,(y1-y0)*aspect)*padding
    offset=cam.rotation_euler.to_matrix()@Vector(((x0+x1)/2,(y0+y1)/2,0))
    cam.location+=offset
    cam.data.ortho_scale=span
    studio_lights(target,max(hi-lo))
    return cam


def render_raw(name):
    path=SCRATCH/(name+'.png')
    path.parent.mkdir(parents=True,exist_ok=True)
    bpy.context.scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)
    # Native PNG decoding is much faster than a Python Paeth-filter loop.
    # Non-Color returns the already display-transformed PNG byte values.
    # Verified against the independent PNG reader, including alpha edges.
    image=bpy.data.images.load(str(path),check_existing=False)
    image.colorspace_settings.name='Non-Color'
    image.alpha_mode='STRAIGHT'
    width,height=image.size
    pixels=np.empty(width*height*4,dtype=np.float32)
    image.pixels.foreach_get(pixels)
    rgba=pixels.reshape(height,width,4)[::-1].copy()
    bpy.data.images.remove(image)
    return rgba


def render_icon(name,category,samples):
    setup(1024,1024,samples)
    objects=instantiate(name)
    azimuth=13 if category in ('ui','passes') else 25
    elevation=11 if category in ('ui','passes') else 17
    if name in ('Fish','SewerShark'):
        azimuth=15
    if name in ('Coin','Pointer','Luck','OfferBurst','Check','Gem'):
        azimuth,elevation=8,7
    if name=='Collection':
        azimuth,elevation=28,18
    if name in ('Companion','VIPPack','UltimateBundle','Coins10Minutes','Coins1Hour','Coins6Hours','CoinPackHuge','ExtraSlots'):
        azimuth,elevation=18,20
    if name in ('RainbowName','GoldenName','OfflinePlus','LuckyFlush1','LuckyFlush5','LuckyFlush20'):
        azimuth,elevation=6,8
    padding=1.28 if name=='Companion' else 1.25 if name=='DoubleCash' else 1.19
    frame(objects,azimuth,elevation,padding=padding)
    raw=render_raw(name)
    rgba=sticker(raw,radius=9)
    if name=='ToiletGlow':
        # Soft colored halo behind the crisp sculpture, with transparent edges.
        glow=np.zeros_like(raw)
        glow[:,:,:3]=(.24,.66,1.0)
        cyan=(raw[:,:,2] > raw[:,:,0]*1.30) & (raw[:,:,1] > raw[:,:,0]*1.20)
        glow[:,:,3]=blur(raw[:,:,3]*cyan,16)*.65
        rgba=over(rgba,glow)
    for size in (512,128):
        write_png(OUT/category/f'{name}_{size}.png',downsample(rgba,1024//size))


def sparkles(points):
    for x,y,z,r,color in points:
        ui.bevel(lib.star('Celebration sparkle',(x,y,z),r,color),.025)


def royal_scene(icon=False):
    instantiate('GoldenToilet' if not icon else 'BasicToilet')
    drop=instantiate('KingPoop',(0,-.70,2.03),1.20 if icon else 1.48)
    for o in drop:
        if 'Royal sparkle' in o.name:
            bpy.data.objects.remove(o,do_unlink=True)
    sparkles([(-1.72,-.2,4.35,.33,'goldLight'),(1.83,0,3.95,.30,'ice'),(-1.45,-.8,1.35,.25,'cyan'),(1.5,-.4,1.90,.25,'gold'),(.91,-.1,5.35,.20,'white')])


def floor(color='navy',size=200,z=-.10):
    lib.box('Stage floor',(0,0,z-.12),(size,size,.24),color,.05)


def hub_scene():
    floor('water')
    lib.box('Floating garden island',(0,2,-.54),(29,29,1.0),'teal',.6)
    lib.box('Emerald lawns',(0,2,-.06),(28,28,.26),'green',.45)
    lib.box('Plaza promenade',(0,1,.10),(9.5,27,.22),'ice',.10)
    for x in (-4.9,4.9):
        lib.box('Promenade blue trim',(x,1,.24),(.20,26,.12),'cyan',.04)
    for x in (-3,-1,1,3):
        for y in range(-11,15,2):
            lib.box('Plaza paving',(x,y,.25),(1.92,1.92,.07),'white' if (y+x)%4 else 'ice',.025)
    instantiate('GoldenTrophy',(0,7,.33),1.55)
    lib.cylinder('Central statue dais',(0,7,.34),3.0,.40,'navy')
    lib.torus('Central dais rim',(0,7,.59),2.78,.12,'gold')
    for side in (-1,1):
        for i,tier in enumerate(('Basic','Golden','Diamond','Galaxy')):
            y=-7+i*5.1
            lib.box('Player plot pad',(side*7.25,y,.26),(4.6,4.3,.43),'navy',.25)
            lib.box('Plot highlight',(side*7.25,y,.50),(4.3,4.0,.09),'cyan',.08)
            instantiate(tier+'Toilet',(side*7.25,y,.57),.80,side*-12)
        for y in (-9,2,12):
            instantiate('PalmTree',(side*12,y,.12),1.40,side*20)
        for y in (-5,5):
            instantiate('RoundBush',(side*11,y,.13),1.1)
            instantiate('FlowerPack',(side*10.7,y-2,.13),.9)
        for y in (-6,3,12):
            instantiate('LampPost',(side*5.35,y,.26),.85)
    instantiate('PortalGate',(-9,15,.15),1.15)
    instantiate('PortalGate',(9,15,.15),1.15)
    instantiate('RubberDuck',(-3.1,-8,.32),1.23,-22)
    instantiate('ToiletPaper',(3.2,-8,.32),1.20)
    for x in (-22,-13,13,22):
        lib.cylinder('Distant candy mountain',(x,24,3.5),8,14,'blue',5,radius_top=.1)
        instantiate('CloudPuffs',(x,20,13),2.4)
    camera((0,3.8,2.5),(18,-30,24),37)
    studio_lights((0,2,0),24)


def rare_scene():
    floor('purple',100)
    instantiate('BasicToilet')
    drop=instantiate('KingPoop',(0,-.45,3.18),1.55)
    for o in drop:
        if 'Royal sparkle' in o.name:
            bpy.data.objects.remove(o,do_unlink=True)
    # The floating reward, lift particles and rays communicate the drop moment.
    raymat=bpy.data.materials.new('Translucent golden event rays')
    raymat.use_nodes=True
    nodes=raymat.node_tree.nodes
    nodes.clear()
    output=nodes.new('ShaderNodeOutputMaterial')
    mix=nodes.new('ShaderNodeMixShader')
    transparent=nodes.new('ShaderNodeBsdfTransparent')
    emission=nodes.new('ShaderNodeEmission')
    emission.inputs[0].default_value=(1,.55,.08,1)
    emission.inputs[1].default_value=4.0
    geometry=nodes.new('ShaderNodeNewGeometry')
    distance=nodes.new('ShaderNodeVectorMath')
    distance.operation='DISTANCE'
    distance.inputs[1].default_value=(0,2.0,4.1)
    fade=nodes.new('ShaderNodeMapRange')
    fade.interpolation_type='SMOOTHERSTEP'
    fade.inputs['From Min'].default_value=1.5
    fade.inputs['From Max'].default_value=4.5
    fade.inputs['To Min'].default_value=.45
    fade.inputs['To Max'].default_value=0
    raymat.node_tree.links.new(geometry.outputs['Position'],distance.inputs[0])
    raymat.node_tree.links.new(distance.outputs['Value'],fade.inputs['Value'])
    raymat.node_tree.links.new(fade.outputs['Result'],mix.inputs[0])
    raymat.node_tree.links.new(transparent.outputs[0],mix.inputs[1])
    raymat.node_tree.links.new(emission.outputs[0],mix.inputs[2])
    raymat.node_tree.links.new(mix.outputs[0],output.inputs[0])
    for j in range(20):
        a=j*math.tau/20
        length=3.85+(j%3)*.20
        points=[(math.cos(a-.025)*1.5,4.1+math.sin(a-.025)*1.5),
                (math.cos(a-.065)*length,4.1+math.sin(a-.065)*length),
                (math.cos(a+.065)*length,4.1+math.sin(a+.065)*length),
                (math.cos(a+.025)*1.5,4.1+math.sin(a+.025)*1.5)]
        ray=lib.prism('Golden discovery ray',points,.015,'gold',2.0)
        ray.data.materials.clear()
        ray.data.materials.append(raymat)
    for j in range(14):
        a=j*2.40
        z=2.10+j*.095
        lib.sphere('Rising gold mote',(.73*math.cos(a),-.24+.6*math.sin(a),z),(.045,)*3,'goldLight')
    for side in (-1,1):
        instantiate('DisplayPedestal',(side*3.9,1,0),1.1)
        instantiate('RubberDuck' if side<0 else 'SewerShark',(side*3.9,1,1.32),1.03,-side*17)
        instantiate('RocksCrystals',(side*5.9,3,0),1.15)
    # True 3D star rays behind the rare drop, with individually modelled sparks.
    for j in range(16):
        a=j*math.tau/16
        rr=4.2+(j%3)*.28
        x,z=math.cos(a)*rr,4.1+math.sin(a)*rr*.56
        if z>.3:
            sparkles([(x,1.6,z,.15+(j%3)*.05,'goldLight' if j%2 else 'cyan')])
    lib.torus('Rare drop energy ring',(0,-.15,2.45),1.40,.055,'goldLight')
    lib.torus('Ground energy ring',(0,-.15,.15),2.0,.065,'gold')
    camera((0,0,3.25),(1.2,-17,5.1),14.7)
    studio_lights((0,0,2.5),8)


def lineup_scene():
    floor('navy',100)
    for i,tier in enumerate(TIERS):
        x=(i-3)*3.30
        y=(i-3)*.38
        height=.18+i*.57
        lib.box('Tier display plinth',(x,y,height/2),(3.20,3.8,height),'navy',.13)
        lib.box('Tier luminous trim',(x,y-.01,height+.045),(3.13,3.61,.09),('ice','woodLight','gold','cyan','lime','red','magenta')[i],.05)
        instantiate(tier+'Toilet',(x,y,height+.09),1,-8)
        if i>1:
            sparkles([(x-.90,y+.18,height+5.13,.16,'goldLight'),(x+.99,y+.24,height+4.35,.11,'ice')])
    for x in (-15,15):
        instantiate('RocksCrystals',(x,4,0),1.4)
    camera((0,0,3.65),(3,-28,10),26.2)
    studio_lights((0,0,2),18)


def logo_scene():
    # Two stacked chunky words: white porcelain over bright cyan, as in mockup.
    for word,z,size,color in [('TOILET',1.80,2.05,'white'),('RNG',.40,2.08,'cyan')]:
        back=ui.text(word,(0,.12,z),size,'ink',.20,.10,FONT)
        front=ui.text(word,(0,-.20,z),size,color,.12,.065,FONT)
        for o in (back,front):
            o.rotation_euler.y=math.radians(-3)
    instantiate('ToiletPaper',(2.48,0,-.23),.86,-10)
    lib.crown((0,.12,2.88),.45,.48)
    sparkles([(-3.54,-.10,2.49,.21,'goldLight'),(3.92,0,2.35,.20,'cyan')])
    frame(meshes(),0,5,padding=1.17,aspect=2)


def render_art(name,samples):
    if name=='Logo':
        setup(2048,1024,samples)
        logo_scene()
        rgba=sticker(render_raw(name),radius=9)
        write_png(OUT/'art/Logo_2048x1024.png',rgba)
        write_png(OUT/'art/Logo_1024x512.png',downsample(rgba,2))
    elif name=='GameIcon':
        setup(1024,1024,samples)
        royal_scene(True)
        frame(meshes(),19,13,1.13)
        rgba=sticker(render_raw(name),radius=8)
        rgba=over(rgba,backdrop(1024,1024,'blue'))
        write_png(OUT/'art/GameIcon_512.png',downsample(rgba,2))
        write_png(OUT/'art/GameIcon_128.png',downsample(rgba,8))
    else:
        setup(1920,1080,samples)
        bpy.context.scene.view_settings.exposure=-.80
        {'HubScene':hub_scene,'RareDrop':rare_scene,'ToiletLineup':lineup_scene}[name]()
        rgba=render_raw(name)
        rgba=over(rgba,backdrop(1920,1080,'gold' if name=='RareDrop' else 'blue'))
        write_png(OUT/'art'/f'{name}_1920x1080.png',rgba)


def entries():
    records=[]
    for name,(cat,_,_) in SPECS.items():
        if cat not in ('items','toilets'):
            continue
        key='ItemIcons.'+('Duck' if name=='RubberDuck' else name) if cat=='items' else 'ToiletIcons.'+name.removesuffix('Toilet')
        for size in (512,128):
            records.append(dict(name=name,file=f'assets/icons/{cat}/{name}_{size}.png',size=[size,size],category=cat,config_key=key,config_key_exists=True,transparent=True))
    for name in ui.UI:
        key='Icons.'+('Coins' if name=='Coin' else name)
        for size in (512,128):
            records.append(dict(name=name,file=f'assets/icons/ui/{name}_{size}.png',size=[size,size],category='ui',config_key=key,config_key_exists=True,transparent=True))
    for name,display,key,kind in passes.CATALOG:
        for size in (512,128):
            rec=dict(name=name,display_name=display,file=f'assets/icons/passes/{name}_{size}.png',size=[size,size],category='passes',offer_kind=kind,config_key='Icons.'+key,intended_assets_key='Assets.Icons.'+key,config_key_exists=key in passes.EXISTING_KEYS,transparent=True,catalog_status='catalog' if name in passes.EXISTING_OFFERS else 'working-list; pending extended catalog')
            if name in passes.REUSE:
                rec['reused_from']=f'assets/icons/ui/{passes.REUSE[name]}_{size}.png'
            if name in ('Coins1Hour','Coins6Hours'):
                rec['current_catalog_key']='Icons.CoinPack'
                rec['integration_note']='Proposed dedicated art key; current catalog shares Icons.CoinPack.'
            records.append(rec)
    for name,filename,size,transparent in [
        ('GameIcon','GameIcon_512.png',[512,512],False),('GameIcon','GameIcon_128.png',[128,128],False),
        ('HubScene','HubScene_1920x1080.png',[1920,1080],False),('RareDrop','RareDrop_1920x1080.png',[1920,1080],False),
        ('ToiletLineup','ToiletLineup_1920x1080.png',[1920,1080],False),
        ('Logo','Logo_2048x1024.png',[2048,1024],True),('Logo','Logo_1024x512.png',[1024,512],True)]:
        records.append(dict(name=name,file='assets/icons/art/'+filename,size=size,category='art',config_key=None,config_key_exists=False,transparent=transparent,destination='Creator Hub game icon' if name=='GameIcon' else 'Creator Hub thumbnails' if name!='Logo' else 'Brand/UI image; integration key to be chosen by manager'))
    return records


def validate(records,complete=False):
    checks=[]
    for rec in records:
        path=ROOT/rec['file']
        if not path.exists():
            if complete:
                raise AssertionError(f'Missing {path}')
            continue
        a=read_png(path)
        h,w=a.shape[:2]
        assert [w,h]==rec['size'], path
        alpha=a[:,:,3]
        assert a[:,:,:3].max()>.1, f'Blank render: {path}'
        if rec['transparent']:
            assert alpha.min()==0 and alpha.max()==1, f'Invalid alpha: {path}'
            assert max(alpha[0].max(),alpha[-1].max(),alpha[:,0].max(),alpha[:,-1].max())==0, f'Clipped alpha: {path}'
            assert np.all(a[alpha==0,:3]==0), f'Matte RGB: {path}'
        else:
            assert alpha.min()==1, path
        if w==1920:
            assert path.stat().st_size<3_000_000, f'Thumbnail too large: {path}'
        check=dict(file=rec['file'],size=[w,h],bytes=path.stat().st_size,alpha='straight RGBA' if rec['transparent'] else 'opaque RGB',passed=True)
        if rec.get('reused_from'):
            assert path.read_bytes()==(ROOT/rec['reused_from']).read_bytes(), f'Reuse mismatch: {path}'
            check['reuse_identical']=True
        if rec['category']=='passes':
            yy,xx=np.mgrid[:h,:w]
            solid=alpha>.5
            assert solid.sum() > w*h*.08, f'Undersized icon: {path}'
            outside=(xx-(w-1)/2)**2+(yy-(h-1)/2)**2>(min(w,h)/2)**2
            check['solid_pixels_outside_circle']=int((solid & outside).sum())
            check['solid_coverage_percent']=round(float(solid.mean()*100),2)
        checks.append(check)
    (OUT/'validation.json').write_text(json.dumps(dict(complete=len(checks)==len(records),expected=len(records),validated=len(checks),checks=checks),indent=2)+'\n')
    return checks


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--only',nargs='+')
    parser.add_argument('--samples',type=int,default=64)
    parser.add_argument('--validate-only',action='store_true')
    parser.add_argument('--passes-only',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    pass_names=[row[0] for row in passes.CATALOG]
    names=[n for n,(cat,_,_) in SPECS.items() if cat in ('items','toilets')]+list(ui.UI)+pass_names+['GameIcon','HubScene','RareDrop','ToiletLineup','Logo']
    if args.passes_only:
        names=pass_names
    if args.only:
        unknown=set(args.only)-set(names)
        if unknown:
            raise ValueError(f'Unknown names: {sorted(unknown)}')
        names=[n for n in names if n in args.only]
    OUT.mkdir(parents=True,exist_ok=True)
    if not args.validate_only:
        lib.PALETTE['red']='F42B48'
        lib.PALETTE['basketSlot']='841530'
        install_render_geometry()
        # CPU fallback is deterministic and works on machines without CUDA.
        for name in names:
            print('ICON_BUILD '+name,flush=True)
            if name in passes.REUSE:
                (OUT/'passes').mkdir(parents=True,exist_ok=True)
                for size in (512,128):
                    shutil.copyfile(OUT/'ui'/f'{passes.REUSE[name]}_{size}.png',OUT/'passes'/f'{name}_{size}.png')
            elif name in ('GameIcon','HubScene','RareDrop','ToiletLineup','Logo'):
                render_art(name,args.samples)
            else:
                render_icon(name,SPECS[name][0] if name in SPECS else 'passes' if name in passes.MODELS else 'ui',args.samples)
    records=entries()
    manifest=dict(version=2,renderer='Blender 4.5 / Cycles',generator='scripts/build-icons.ps1',asset_count=len({r['name'] for r in records}),png_count=len(records),notes=['No uploaded IDs. src/ was not modified.','Gem is the requested Gem/Stamp symbol.','New keys are marked config_key_exists=false.','Only 512px UI/item/toilet/pass variants normally need upload.','Pass/product display names follow the checked-in catalog where present; other entries are working-list artwork only.','Lucky Flush art does not enable paid luck or change the current catalog.','Four existing pass symbols are byte-identical copies; see reused_from.'],assets=records)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    checks=validate(records,complete=not args.only)
    print(f'Validated {len(checks)}/{len(records)} PNGs.',flush=True)


if __name__=='__main__':
    main()
