"""Modular resort environment. Stud-valued geometry, original designs, shared atlas.

Author Z-up, front -Y. Structural seams are exact; decorative bevels stay inside
the grid. Metadata sockets use the uncentered author space and are converted by
build_env.py after the base-center pivot is established.
"""
import math
import random
import bpy
from mathutils import Vector
from lib import box, sphere, cylinder, torus, tube, lathe, prism, star, crown, mesh
from builders import leaf, palm, toilet, crystal


def group(build, scale=1, offset=(0, 0, 0), angle=0):
    before = set(bpy.context.scene.objects)
    build()
    c, s = math.cos(angle), math.sin(angle)
    for obj in set(bpy.context.scene.objects) - before:
        p = obj.location * scale
        obj.location = (p.x*c-p.y*s+offset[0], p.x*s+p.y*c+offset[1], p.z+offset[2])
        obj.scale *= scale
        obj.rotation_euler.z += angle


def slab(name, outline, bottom, top, color):
    n = len(outline)
    verts = [(x, y, z) for z in (bottom, top) for x, y in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
    return mesh(name, verts, faces, color)


def clipped(w, d, cut=.6):
    x, y = w/2, d/2
    return [(-x+cut,-y),(x-cut,-y),(x,-y+cut),(x,y-cut),(x-cut,y),(-x+cut,y),(-x,y-cut),(-x,-y+cut)]


def arc(name, inner, outer, start, end, bottom, top, color, segments=12):
    # Sector points use polar zero at the front (-Y), and positive toward +X.
    angles = [math.radians(start+(end-start)*i/segments) for i in range(segments+1)]
    outline = [(outer*math.sin(a), -outer*math.cos(a)) for a in angles]
    outline += [(inner*math.sin(a), -inner*math.cos(a)) for a in reversed(angles)]
    return slab(name, outline, bottom, top, color)


def badge(loc, radius=1, color="gold"):
    x,y,z = loc
    disc = cylinder("Coin medallion", loc, radius, radius*.22, color, 20)
    disc.rotation_euler.x = math.pi/2
    torus("Coin rolled edge", (x,y-radius*.13,z), radius*.82, radius*.07, "goldLight", rotation=(math.pi/2,0,0), segments=20, sides=4)
    star("Coin star stamp", (x,y-radius*.27,z), radius*.56, "goldLight", 5)


def hub_medallion():
    cylinder("Navy foundation", (0,0,.32), 12, .64, "navy", 80)
    cylinder("Gold reveal", (0,0,.71), 11.95, .14, "gold", 80)
    cylinder("Blue mosaic field", (0,0,.84), 11.75, .12, "blue", 80)
    for i in range(10):
        a = i*36
        arc("Radial mosaic", 6.0, 11.5, a-16.5,a+16.5,.90,1,"cyan" if i%2 else "ice",8)
        t=math.radians(a)
        points=[]
        for r,da in [(6.7,0),(8.7,-5),(10.9,0),(8.7,5)]:
            aa=t+math.radians(da)
            points.append((r*math.sin(aa),-r*math.cos(aa)))
        slab("Compass lozenge",points,1,1.035,"goldLight")
    cylinder("Medallion border",(0,0,.96),5.95,.10,"gold",40)
    cylinder("Trophy inset",(0,0,1.02),5.52,.08,"navy",40)
    # The large sun is visible when used without the fountain.
    sun=star("Central sun",(0,0,0),4.2,"goldLight",10)
    sun.scale.y=.06
    sun.rotation_euler.x=math.pi/2
    sun.location.z=1.08


def hub_ring():
    arc("Ring foundation",12,32,-18,18,0,.66,"navy",8)
    arc("Gold inner seam",12,12.7,-18,18,.66,1,"gold",8)
    arc("Outer gold seam",31.25,32,-18,18,.66,1,"gold")
    for row,(a,b) in enumerate([(12.7,18.8),(18.8,24.9),(24.9,31.25)]):
        for col in range(4):
            aa=-18+col*9
            arc("Inlaid porcelain paver",a+.04,b-.04,aa+.12,aa+8.88,.66,1,"ice" if (row+col)%2 else "white",3)
    # A cyan carpet points toward each plot without obscuring the tile grid.
    arc("Spoke color band",12.75,31.2,-4.7,4.7,1,1.025,"blue",4)
    for r in (16,22,28):
        slab("Spoke arrow",[(-1,-r+1),(0,-r-.15),(1,-r+1),(0,-r+.55)],1.025,1.05,"goldLight")


def hub_curb():
    # Curbs occupy the gap between paths. Repeat with 36-degree headings.
    arc("Curb navy riser",32,33.5,-10,10,0,1.05,"navy",8)
    arc("Curb porcelain coping",32,33.5,-10,10,1.05,1.35,"ice",8)
    arc("Curb gold inlay",32.5,33,-9.6,9.6,1.35,1.40,"goldLight",8)


def path(length=12, width=8, plot=False):
    box("Path foundation",(0,0,.35),(width,length,.7),"navy",.12)
    box("Path color field",(0,0,.80),(width-.7,length,.30),"blue" if not plot else "teal",.09)
    for x in (-width/2+.24,width/2-.24):
        box("Porcelain path edge",(x,0,.86),(.30,length,.28),"ice",.07)
    for i in range(int(length/3)):
        y=-length/2+1.5+i*3
        box("Path stepping tile",(0,y,.98),(width-1.7,2.7,.12),"cyan" if not plot else "cream",.08)
    for x in (-width/2+.70,width/2-.70):
        box("Gold lane line",(x,0,1),(.10,length,.07),"gold",.02)


def edge_straight():
    box("Edge foundation",(0,0,.5),(12,1.5,1),"navy",.15)
    box("Edge cap",(0,0,1.1),(12,1.5,.35),"ice",.12)
    box("Gold edge ribbon",(0,-.76,.82),(11.6,.07,.12),"gold",.02)


def fountain():
    cylinder("Fountain step",(0,0,.25),5.4,.5,"navy",40)
    cylinder("Gold base rim",(0,0,.58),5.15,.16,"goldLight",40)
    lathe("Scalloped basin wall",[(4.35,.65),(5,.65),(5.15,.9),(5.15,1.7),(4.85,1.9),(4.35,1.9)],(0,0,0),"ice",segments=40)
    cylinder("Opaque stylized water",(0,0,1.31),4.45,.12,"water",40)
    for r in (2.9,3.75):
        torus("Water ripple",(0,0,1.395),r,.045,"cyan",segments=40,sides=4)
    cylinder("Trophy column",(0,0,1.95),2.15,2.30,"navy",16,radius_top=1.85)
    for z in (.8,2.85):
        torus("Column gold collar",(0,0,z),2.04,.12,"goldLight",segments=24,sides=4)
    cylinder("Trophy socket",(0,0,3.15),2.45,.3,"cream",24)
    for a in range(0,360,72):
        x,y=5.16*math.sin(math.radians(a)),-5.16*math.cos(math.radians(a))
        o=star("Basin star",(0,0,0),.33,"gold",5)
        o.location=(x,y,1.23)
        o.rotation_euler.z=math.radians(a)


def steps(width=10):
    for i in range(4):
        y=-3+i*2
        box("Stone step",(0,y,(i+1)*.25),(width,2,(i+1)*.5),"navy",.10)
        box("Step tread",(0,y,(i+1)*.5+.06),(width,1.96,.12),"ice",.05)
        box("Safety gold nosing",(0,y-.91,(i+1)*.5+.10),(width-.3,.16,.12),"goldLight",.035)


def plot_platform():
    slab("Plot beveled foundation",clipped(32,32,1),0,.75,"navy")
    slab("Plot porcelain lip",clipped(32,32,1),.75,1.2,"ice")
    slab("Inset lawn",clipped(27.6,27.6,.7),1.2,1.4,"green")
    # Recessed 0.7-wide channels at +/-14.35; no fake painted sockets.
    for x in (-15.35,15.35):
        box("Outer fence slot wall",(x,0,1.44),(1.3,29.8,.48),"cream",.12)
    for x in (-13.85,13.85):
        box("Inner fence slot wall",(x,0,1.39),(.3,28,.38),"lime",.06)
    box("Back fence outer wall",(0,15.35,1.44),(30,1.3,.48),"cream",.12)
    box("Back fence inner wall",(0,13.85,1.39),(27.8,.3,.38),"lime",.06)
    for x in (-9,9):
        box("Front welcome border",(x,-15.35,1.40),(12,1.3,.40),"cream",.1)
    # Broad low-contrast turf panels leave a clear center for the collection.
    for x in (-7,7):
        for y in (-7,7):
            box("Turf panel",(x,y,1.425),(12.7,12.7,.05),"green",.02)


def gate_arch():
    for x in (-5.5,5.5):
        box("Gate shoe",(x,0,.35),(2,2,.7),"navy",.22)
        box("Porcelain gate pillar",(x,0,4),(1.3,1.4,7),"ice",.18)
        box("Gold pillar band",(x,0,6.9),(1.55,1.65,.35),"gold",.08)
        cylinder("Pillar cap",(x,0,7.8),1,.6,"navy",8,radius_top=.60)
        sphere("Cap pearl",(x,0,8.27),(.27,)*3,"goldLight",10,6)
    pts=[(-5.5,0,6.2),(-4.5,0,7.6),(-2.8,0,8.5),(0,0,8.9),(2.8,0,8.5),(4.5,0,7.6),(5.5,0,6.2)]
    tube("Sweeping garden arch",pts,[.48]*7,"navy",8)
    tube("Arch cyan piping",[(x,-.45,z) for x,y,z in pts],[.10]*7,"cyan",6)
    box("Arch sign frame",(0,-.68,8.25),(6,.7,1.8),"goldLight",.25)
    box("Player name canvas",(0,-1.07,8.25),(5.5,.12,1.3),"navy",.16)
    star("Arch crest",(0,-.05,9.62),.72,"gold",5)


def plot_corner_path():
    # L piece, 8-wide on a 12 by 12 grid, thickness matches straight path.
    outline=[(-6,-6),(6,-6),(6,2),(2,2),(2,6),(-6,6)]
    slab("Corner foundation",outline,0,.7,"navy")
    slab("Corner top",[(x*.95,y*.95) for x,y in outline],.7,1,"cream")
    for x,y in [(-2,-2),(2,-2),(-2,2)]:
        box("Corner inset tile",(x,y,1.02),(3.65,3.65,.08),"ice",.08)


def garden():
    box("Corner planter foot",(0,0,.25),(4.6,4.6,.5),"navy",.35)
    box("Porcelain planter",(0,0,.84),(4.4,4.4,1.2),"ice",.4)
    box("Dark soil",(0,0,1.43),(3.7,3.7,.15),"mud",.35)
    for x,y,h in [(-.75,.5,3.1),(.7,.75,2.2)]:
        cylinder("Topiary stem",(x,y,2),.12,1.4,"wood",8)
        for z,r in [(1.9,.72),(2.65,.65),(3.25,.4)]:
            sphere("Clipped topiary",(x,y,z*h/3.1+.3),(r,r,r*.95),"green" if z<3 else "lime",10,6)
    for x in (-1.1,0,1.1):
        cylinder("Flower stalk",(x,-1.05,1.72),.06,.58,"leaf",6)
        for i in range(5):
            a=i*math.tau/5
            sphere("Candy flower petal",(x+.25*math.cos(a),-1.1,2.05+.25*math.sin(a)),(.22,.13,.22),"pink" if x else "violet",8,5)
        sphere("Flower button",(x,-1.26,2.05),(.14,.08,.14),"yellow",8,4)
    star("Planter star",(0,-2.23,.83),.30,"gold",5)


def sign_post():
    cylinder("Sign foot",(0,0,.16),.75,.32,"navy",12)
    box("Single chunky sign post",(0,.15,2.6),(.55,.6,5.2),"wood",.12)
    box("Sign gold frame",(0,0,4.7),(5.6,.6,2.3),"goldLight",.28)
    box("Live text face",(0,-.34,4.7),(5.05,.14,1.78),"navy",.18)
    for s in (-1,1):
        star("Sign finial star",(s*2.56,-.43,4.7),.22,"gold",5)
    sphere("Post finial",(0,.15,6.02),(.30,)*3,"gold",10,6)


def fence():
    for x in (-4,4):
        box("Slot sized post",(x,0,1.6),(.6,.6,3.2),"navy",.1)
        sphere("Fence gold cap",(x,0,3.28),(.42,.42,.22),"goldLight",10,6)
    for z in (.9,2.1):
        box("Fence rail",(0,0,z),(8,.28,.3),"ice",.06)
    for x in (-3,-2,-1,0,1,2,3):
        box("Fence spindle",(x,0,1.6),(.22,.24,2.1),"ice",.06)


def cliff(seed=0):
    rng=random.Random(seed+83)
    n=8
    xs=[-12+i*3 for i in range(n+1)]
    # Continuous strip with exact side joints and a jagged faceted front.
    verts=[]
    for level in range(4):
        z=[0,4,10,12][level]
        front=[-2.2,-5.5,-6,-5.8][level]
        for i,x in enumerate(xs):
            jitter=0 if i in (0,n) else rng.uniform(-.85,.85)
            verts.append((x,front+jitter,z+(rng.uniform(-.65,.65) if level in (1,2) and i not in (0,n) else 0)))
        verts.extend([(12,6,z),(-12,6,z)])
    m=n+3
    faces=[tuple(reversed(range(m))),tuple(range(3*m,4*m))]
    for level in range(3):
        for i in range(m):
            j=(i+1)%m
            a,b,c,d=level*m+i,level*m+j,(level+1)*m+j,(level+1)*m+i
            faces += [(a,b,c),(a,c,d)]
    mesh("Carved cliff mass",verts,faces,"slate")
    slab("Warm exposed soil",[(x,y) for x,y,z in verts[3*m:]],12,12.6,"wood")
    slab("Overhanging grass lip",[(-12,-6),(12,-6),(12,6),(-12,6)],12.6,13.4,"green")
    box("Sunlit turf edge",(0,-5.96,13.12),(24,.12,.35),"lime",.035)


def cliff_corner():
    # A quarter-circle outside corner, radius 12, matching 13.4-high strips.
    arc("Corner faceted cliff",.5,12,0,90,0,12,"slate",6)
    arc("Corner soil band",.5,12,0,90,12,12.6,"wood",6)
    arc("Corner turf",.5,12,0,90,12.6,13.4,"green",6)
    arc("Corner grass rim",11.5,12,0,90,13.4,13.55,"lime",6)


def beach(corner=False):
    if corner:
        arc("Sand curve foundation",12,20,0,90,0,.6,"caramel",12)
        arc("Sand curve top",12,19.3,0,90,.6,.8,"woodLight",12)
        arc("Shore wet sand",19.3,20,0,90,.60,.66,"goldLight",12)
    else:
        outline=[(-12,-4),(-6,-4.3),(0,-3.7),(6,-4.25),(12,-4),(12,4),(-12,4)]
        slab("Sand foundation",outline,0,.6,"caramel")
        slab("Warm sand top",outline,.6,.8,"woodLight")
        for x in (-7,3,8):
            sphere("Beach pebble",(x,1,.93),(.55,.37,.20),"cream",8,4,False)
        for x,y in [(-3,-2),(5,-1)]:
            shell=star("Beach starfish",(0,0,0),.55,"orange",5)
            shell.rotation_euler.x=math.pi/2
            shell.location=(x,y,.92)


def grass_slab():
    # Tile boundaries deliberately remain square and exact.
    box("Soil block",(0,0,.45),(24,24,.9),"wood",0)
    box("Turf slab",(0,0,1.15),(24,24,.5),"green",0)


def cove():
    arc("Cove rock wall",9,16,-130,130,0,6,"slate",20)
    arc("Cove sand ledge",7,15.7,-130,130,6,6.7,"woodLight",20)
    arc("Cove grass shoulder",12.5,16,-125,125,6.7,7.5,"green",20)
    for a in (-110,-55,20,95):
        t=math.radians(a)
        sphere("Cove boulder",(14*math.sin(t),-14*math.cos(t),7.65),(1.7,1.4,1.5),"gray",8,5,False)


def rock_cluster():
    for x,y,z,s in [(-2,0,1.5,(2.7,2.2,1.5)),(1.9,.5,1.1,(1.9,1.7,1.1)),(.3,-1.5,.7,(1.3,1.2,.7))]:
        sphere("Faceted shoreline boulder",(x,y,z),s,"slate" if x<0 else "gray",8,5,False)
    for i in range(3):
        leaf("Rock grass tuft",(-1,1,2.5),1.7,.22,i*1.5,"lime",-.5)


def stump():
    cylinder("Flared stump root",(0,0,.4),2.1,.8,"wood",9,radius_top=1.35)
    cylinder("Stump bark",(0,0,1.4),1.35,2,"wood",9,radius_top=1.15)
    cylinder("Fresh cut top",(0,0,2.44),1.12,.12,"woodLight",18)
    for r in (.35,.68,.96):
        torus("Tree age ring",(0,0,2.51),r,.035,"caramel",segments=18,sides=4)
    for i in range(7):
        a=i*math.tau/7
        tube("Bark groove",[(1.6*math.cos(a),1.6*math.sin(a),.25),(1.24*math.cos(a),1.24*math.sin(a),1),(1.1*math.cos(a),1.1*math.sin(a),2.3)],[.10,.07,.035],"brown",5)
    tube("Broken branch",[(1,0,1.2),(1.9,0,2),(2.2,0,2.2)],[.45,.36,.30],"wood",8)
    sphere("Tiny mushroom",(-1.4,-.6,.72),(.6,.55,.22),"red",10,6)
    cylinder("Mushroom stalk",(-1.4,-.6,.34),.14,.68,"cream",8)


def bridge(dock=False):
    length=24 if not dock else 16
    for x in (-3.8,3.8):
        box("Long structural beam",(x,0,1.8),(.5,length,1),"wood",.10)
    for i in range(int(length/2)):
        y=-length/2+1+i*2
        box("Deck plank",(0,y,2.4),(8,1.86,.45),"woodLight" if i%3 else "caramel",.09)
        for x in (-3.4,3.4):
            cylinder("Deck peg",(x,y,2.64),.09,.045,"brown",8)
    positions=(-length/2+1,0,length/2-1)
    for x in (-4.2,4.2):
        for y in positions:
            cylinder("Chunky pier post",(x,y,2),.38,4,"wood",10)
            cylinder("Post cut cap",(x,y,4.03),.44,.18,"woodLight",10)
            for z in (3.35,3.55):
                torus("Rope binding",(x,y,z),.38,.07,"cream",segments=10,sides=4)
        if not dock:
            tube("Safety rope",[(x,positions[0],3.7),(x,-length/4,3.2),(x,0,3.7),(x,length/4,3.2),(x,positions[2],3.7)],[.12]*5,"cream",8)


def lighthouse():
    cylinder("Tower foundation",(0,0,.45),5.3,.9,"navy",12)
    cylinder("Tower gold curb",(0,0,1),4.9,.2,"goldLight",12)
    for i in range(5):
        cylinder("Tapered lighthouse stripe",(0,0,2.5+i*3),3.7-i*.29,3,"white" if i%2==0 else "red",12,radius_top=3.41-i*.29)
    # Inset door and framed windows are graphic reliefs, not collision holes.
    box("Door surround",(0,-3.61,3.0),(2.2,.35,3.9),"goldLight",.5)
    box("Tower door",(0,-3.83,3),(1.7,.18,3.35),"navy",.4)
    sphere("Door handle",(.48,-3.96,2.8),(.12,)*3,"gold",8,4)
    for z,r in [(7.2,3.13),(12.8,2.56)]:
        box("Window frame",(0,-r,z),(1.5,.3,1.8),"navy",.35)
        box("Sky window",(0,-r-.17,z),(1.04,.12,1.28),"cyan",.24)
    cylinder("Lookout balcony",(0,0,16.1),3.5,.6,"navy",16)
    torus("Balcony gold rail",(0,0,17.1),3.25,.10,"goldLight",segments=24,sides=4)
    for i in range(12):
        a=i*math.tau/12
        cylinder("Balcony spindle",(3.25*math.cos(a),3.25*math.sin(a),16.7),.065,.8,"ice",6)
    cylinder("Lantern lens",(0,0,18),2.1,3,"goldLight",12)
    for i in range(8):
        a=i*math.tau/8
        box("Lantern frame",(2.12*math.cos(a),2.12*math.sin(a),18),(.22,.22,3.2),"navy",.04)
    cylinder("Lantern roof",(0,0,20.3),3.3,1.7,"navy",12,radius_top=.48)
    sphere("Tower gold finial",(0,0,21.3),(.48,)*3,"gold",12,6)


def mountain(variant=0):
    # Neutral atlas swatch keeps each silhouette tintable in Studio.
    peaks=[[( -32,12),(-18,34),(-6,22),(8,49),(24,20),(34,31)],
           [(-34,18),(-22,44),(-9,26),(5,32),(17,57),(31,21)],
           [(-32,28),(-16,18),(-3,51),(10,27),(24,42),(35,15)]][variant]
    for i,(x,h) in enumerate(peaks):
        r=15 if i%2 else 19
        verts=[(x-r,-8,0),(x+r,-8,0),(x+r*.8,9,0),(x-r*.8,9,0),(x+3,-1,h)]
        faces=[(0,3,2,1),(0,1,4),(1,2,4),(2,3,4),(3,0,4)]
        mesh("Chunky distant peak",verts,faces,"white")


def cloud_bank(variant=0):
    for x,y,z,s in [(-18,0,4,(9,7,4)),(-9,1,7,(11,8,7)),(2,0,9,(12,9,9)),(13,2,6,(10,7,6)),(21,0,3.8,(7,5,3.8))]:
        if variant:
            z*=.65; s=(s[0]*1.2,s[1],s[2]*.65)
        sphere("Broad cloud lobe",(x,y,z),s,"white",12,8)


def islet(variant=0):
    rng=random.Random(40+variant)
    n=10
    ring=[(math.cos(i*math.tau/n)*(9+rng.random()*2),math.sin(i*math.tau/n)*(7+rng.random()*2)) for i in range(n)]
    verts=[]
    for z,s in [(0,.18),(4,.65),(10,1),(12,.94)]:
        verts += [(x*s,y*s,z) for x,y in ring]
    faces=[tuple(reversed(range(n))),tuple(range(3*n,4*n))]
    for k in range(3):
        for i in range(n):
            j=(i+1)%n
            faces.extend([(k*n+i,k*n+j,(k+1)*n+j),(k*n+i,(k+1)*n+j,(k+1)*n+i)])
    mesh("Floating island facets",verts,faces,"slate")
    slab("Floating island soil",[(x*.95,y*.95) for x,y in ring],12,12.5,"woodLight")
    slab("Floating island grass",ring,12.5,13.1,"green")
    if variant==0:
        group(palm,1.3,(1,0,13.1))
        sphere("Islet boulder",(-4,0,14),(2,1.5,.9),"gray",8,5,False)
    elif variant==1:
        for x,y,r,h,c in [(-2,0,1.8,7,"cyan"),(2,1,1.5,4,"violet"),(1,-2,1,3,"ice")]:
            crystal((x,y,13.1),r,h,c)
    else:
        group(stump,1.2,(0,0,13.1))
        for x,y in [(-3,1),(3,-1)]:
            sphere("Islet shrub",(x,y,14.3),(1.8,1.5,1.2),"lime",10,6)


def palm_cluster():
    group(palm,3.0,(-5,1,0),-.35)
    group(palm,2.5,(5,2,0),1.9)
    group(palm,1.8,(0,-4,0),.65)
    for x,y in [(-4,-2),(4,-3)]:
        sphere("Palm root boulder",(x,y,.65),(2.4,1.9,.65),"woodLight",8,5,False)


def portal(theme):
    body,light,accent={"Sewer":("teal","lime","green"),"Space":("purple","cyan","violet"),"Hell":("black","red","orange")}[theme]
    for x in (-4.5,4.5):
        box("Portal foundation",(x,0,.45),(2.6,3,.9),"navy",.28)
        box("Theme footing",(x,0,1.1),(2.1,2.4,.5),body,.2)
    pts=[(-4.5,0,1.2),(-4.5,0,6.5),(-3.6,0,8.8),(-2.1,0,10.1),(0,0,10.6),(2.1,0,10.1),(3.6,0,8.8),(4.5,0,6.5),(4.5,0,1.2)]
    tube("PortalGate extended arch",pts,[.68]*len(pts),body,10)
    tube("Luminous inset piping",[(x,-.6,z) for x,y,z in pts],[.18]*len(pts),light,8)
    for s in (-1,1):
        for z in (2.6,4.1,5.6):
            prism("Portal direction marker",[(s*4.8,z-.35),(s*4.3,z),(s*4.8,z+.35),(s*4.5,z+.58),(s*3.8,z),(s*4.5,z-.58)],.18,"goldLight",-.75)
    if theme=="Sewer":
        for x in (-4.5,4.5):
            for z in (1.8,6.4):
                cylinder("Pipe flange",(x,0,z),.94,.3,accent,12)
            pipe=cylinder("Outlet pipe",(x,-.35,8),1.03,.6,body,12)
            pipe.rotation_euler.x=math.pi/2
            torus("Outlet flange",(x,-.70,8),.84,.17,light,rotation=(math.pi/2,0,0),segments=16)
            for xx in (-.42,0,.42):
                box("Drain grille",(x+xx,-.91,8),(.1,.15,1.3),"navy",.02)
        badge((0,-.65,10.65),1,light)
    elif theme=="Space":
        torus("Orbital keystone ring",(0,0,11),1.6,.16,"goldLight",rotation=(math.pi/2,.35,.25),segments=28)
        sphere("Keystone planet",(0,-.2,11),(.87,)*3,accent,16,8)
        for x,z in [(-3,9.1),(3,9.1),(-4.9,7),(4.9,7)]:
            star("Cosmic sparkle",(x,-.70,z),.52,"ice",4)
    else:
        for s in (-1,1):
            tube("Sweeping infernal horn",[(s*3,0,9.4),(s*4.8,0,10.5),(s*5.1,0,12),(s*4.5,0,12.8)],[.68,.48,.27,.05],accent,8)
        prism("Lava keystone",[(-.8,10.3),(0,12),( .8,10.3),(0,9.6)],.55,light,-.55)
        for x in (-5.7,5.7):
            crystal((x,0,.3),.55,2.7,accent)


def castle():
    box("Castle navy terrace",(0,0,.65),(28,19,1.3),"navy",.6)
    box("Castle gold reveal",(0,0,1.4),(27.3,18.3,.25),"goldLight",.12)
    box("Castle porcelain podium",(0,1,4.25),(23,14,5.5),"ice",.6)
    # Colossal toilet silhouette is the building, not a small prop on a box.
    group(lambda:toilet("Golden"),4.6,(0,0,6.9))
    group(lambda:crown((0,0,0),1.1,.95),3.8,(0,2.2,28.7))
    for x in (-10.5,10.5):
        cylinder("Porcelain castle turret",(x,2,10),2.7,16,"white",12)
        for z in (3,14.9,17.8):
            cylinder("Turret navy band",(x,2,z),2.9,.55,"navy",12)
            torus("Turret gold molding",(x,2,z+.33),2.75,.12,"gold",segments=24,sides=4)
        cylinder("Turret blue roof",(x,2,19.3),3.3,3.1,"blue",12,radius_top=.35)
        sphere("Turret roof finial",(x,2,21),(.48,)*3,"gold",12,6)
        for z in (7,11.3):
            box("Turret window border",(x,-.62,z),(1.65,.32,2.3),"goldLight",.65)
            box("Turret window",(x,-.83,z),(1.16,.14,1.8),"navy",.48)
            box("Window reflected sky",(x-.22,-.92,z+.28),(.22,.05,.8),"cyan",.07)
    for x in (-8,-4,0,4,8):
        box("Podium merlon",(x,6.8,7.2),(2.2,1.4,1.7),"white",.20)
    box("Door gold arch surround",(0,-6.15,4.2),(5.8,.45,5.4),"goldLight",1)
    box("Door deep blue inset",(0,-6.45,4.1),(4.8,.25,4.6),"navy",.9)
    for x in (-.9,.9):
        box("Door leaf",(x,-6.62,3.8),(1.7,.18,3.5),"blue",.25)
        sphere("Castle door ring stud",(x*.4,-6.76,3.7),(.14,)*3,"gold",8,4)
    for x in (-7.5,7.5):
        prism("Royal swallowtail banner",[(x-1.1,6.2),(x+1.1,6.2),(x+1.1,3),(x,3.7),(x-1.1,3)],.20,"blue",-6.2)
        star("Royal banner emblem",(x,-6.36,5),.58,"goldLight",5)
    group(lambda:steps(8),1,(0,-10,0))


def kiosk():
    box("Shop foundation",(0,0,.25),(12,8,.5),"navy",.35)
    box("Shop counter body",(0,-1,2.4),(9.6,3.6,4),"teal",.3)
    for x in (-3.3,0,3.3):
        box("Counter inset",(x,-2.84,2.5),(2.8,.15,2.7),"mint",.20)
    box("Countertop",(0,-1,4.55),(10.5,4.2,.40),"goldLight",.17)
    for x in (-4.6,4.6):
        box("Shop canopy pillar",(x,1.8,4.6),(.5,.5,8.4),"navy",.12)
    # Curved striped canvas with a real underside and scalloped valance.
    for i in range(8):
        x=-5.6+i*1.4
        outline=[(-3.7,7.5),(-3.2,8.1),(-1.5,9),(1.2,9.6),(3.1,9.7),(3.1,9.4),(1.2,9.3),(-1.5,8.7),(-3.2,7.8),(-3.7,7.2)]
        # prism uses X/Z; turn into a Y/Z cross-section.
        panel=prism("Striped canopy",outline,1.4,"cream" if i%2 else "green",0)
        panel.location.x=x+.7
        # Local X maps to Y, putting the valance on the customer (-Y) side.
        panel.rotation_euler.z=math.pi/2
        box("Canvas valance",(x+.7,-3.55,7.4),(1.32,.27,.88),"cream" if i%2 else "green",.20)
    box("Shop sign frame",(0,-.4,10.5),(7,.60,2.25),"goldLight",.35)
    box("Shop label canvas",(0,-.74,10.5),(6.35,.16,1.6),"navy",.24)
    badge((0,-.4,12.5),1.25)
    # Small sealed goods read as wares without fragile lettering.
    for x,c,h in [(-3,"purple",1.1),(-1.2,"pink",.8),(1.2,"cyan",1.2)]:
        cylinder("Potion bottle",(x,-.9,4.85+h/2),.37,h,c,10,radius_top=.25)
        cylinder("Potion cork",(x,-.9,4.9+h),.23,.20,"goldLight",10)
    box("Cash register",(3,-.8,5),(1.2,1.1,.8),"navy",.18)
    box("Register screen",(3,-1.37,5.1),(.76,.08,.36),"cyan",.06)


def book_pedestal():
    cylinder("Index foot",(0,0,.25),2.9,.5,"navy",12)
    cylinder("Index gold base",(0,0,.65),2.65,.3,"goldLight",12)
    cylinder("Index column",(0,0,2.0),1.75,2.5,"purple",12,radius_top=2)
    torus("Index collar",(0,0,3.18),2.05,.14,"cyan",segments=24,sides=4)
    box("Book rest",(0,0,3.5),(5.4,3.6,.5),"navy",.25)
    # Open book, gently pitched toward the player; chunky colored cover.
    for s in (-1,1):
        panel=box("Book cover",(s*1.3,-.15,4.02),(2.7,3.5,.24),"blue",.12)
        panel.rotation_euler.y=s*-.13
        pages=box("Thick page block",(s*1.3,-.15,4.27),(2.5,3.25,.35),"cream",.12)
        pages.rotation_euler.y=s*-.13
        for j in range(4):
            y=-1.1+j*.60
            rule=box("Page gold rules",(s*1.32,y,4.472),(1.55,.10,.045),"gold",.02)
            rule.rotation_euler.y=s*-.13
    tube("Book stitched spine",[(0,-1.85,4.25),(0,1.55,4.25)],[.16,.16],"goldLight",8)
    box("Ribbon bookmark",(.7,-1.92,3.86),(.4,.16,1.3),"red",.055)
    star("Index crest",(0,-1.98,2),.58,"goldLight",5)


def coin_jar():
    cylinder("Collection pedestal foot",(0,0,.25),3.3,.5,"navy",16)
    cylinder("Collection pedestal",(0,0,1.15),2.7,1.3,"purple",16)
    cylinder("Collection gold rim",(0,0,1.85),2.95,.20,"goldLight",20)
    lathe("Open golden coin jar",[(1.0,0),(1.5,0),(2.1,.4),(2.35,1.3),(2.2,2.6),(1.65,3.2),(1.6,3.6),(1.25,3.6),(1.25,3.1),(1.8,2.5),(1.9,1.3),(1.6,.7),(1,.6)],(0,0,1.95),"gold",segments=28)
    torus("Jar rolled mouth",(0,0,5.5),1.47,.22,"goldLight",segments=28,sides=6)
    for s in (-1,1):
        torus("Jar side handle",(s*2.22,0,4),.67,.16,"goldLight",rotation=(math.pi/2,0,0),segments=16)
    badge((0,-2.24,3.55),.85)
    # A dense, supported pile makes the mouth read as full, not a floating lid.
    cylinder("Coin pile fill",(0,0,5.24),1.30,.34,"orange",20)
    for i,(x,y,z,a) in enumerate([(-.75,0,5.7,.2),(.1,.35,5.85,-.2),(.75,.2,5.63,.35),(0,-.55,5.85,-.12)]):
        group(lambda:badge((0,0,0),.62),1,(x,y,z),a)
    for x,y in [(-2,-1.9),(1.9,-1.7)]:
        cylinder("Spilled coin",(x,y,2.05),.5,.18,"gold",16)


# name, family, builder, triangle budget, assembly metadata in author space.
SPECS=[
    ("HubMedallion","hub",hub_medallion,4000,{"radius":12,"surface":1.112}),
    ("HubRingSegment","hub",hub_ring,3500,{"arc_center":[0,0,0],"radii":[12,32],"sector_degrees":36,"surface":1}),
    ("HubCurbSegment","hub",hub_curb,1000,{"arc_center":[0,0,0],"radii":[32,33.5],"sector_degrees":20}),
    ("HubPathStrip","hub",path,2500,{"grid":[8,12],"surface":1.04}),
    ("HubEdgeStraight","hub",edge_straight,800,{"grid":[12,1.5]}),
    ("FountainPedestal","hub",fountain,4000,{"trophy_socket":[0,0,3.3]}),
    ("PlazaSteps","hub",steps,1800,{"rise":2.12,"run":8}),
    ("PlotPlatform","plot",plot_platform,3500,{"grid":[32,32],"surface":1.45,"fence_channels":[-14.35,14.35],"fence_slot_floor":1.2,"fence_slot_width":.7}),
    ("PlotGateArch","plot",gate_arch,4000,{"clear_width":9.7,"text_face":[0,-1.14,8.25]}),
    ("PlotPathStraight","plot",lambda:path(12,8,True),2500,{"grid":[8,12],"surface":1.04}),
    ("PlotPathCorner","plot",plot_corner_path,1200,{"grid":[12,12],"surface":1.06}),
    ("PlotCornerGarden","plot",garden,3000,{}),
    ("PlotSignPost","plot",sign_post,1500,{"text_face":[0,-.42,4.7]}),
    ("PlotFenceSection","plot",fence,2000,{"post_spacing":8,"post_width":.6}),
    *[("CliffStraight"+chr(65+i),"island",lambda i=i:cliff(i),1500,{"grid":[24,12],"surface":13.4}) for i in range(3)],
    ("CliffCorner","island",cliff_corner,1000,{"arc_center":[0,0,0],"radii":[.5,12],"sector_degrees":90,"surface":13.4}),
    ("BeachStrip","island",beach,1200,{"grid":[24,8],"surface":.8}),
    ("BeachCorner","island",lambda:beach(True),1000,{"arc_center":[0,0,0],"radii":[12,20],"sector_degrees":90,"surface":.8}),
    ("GrassSlab","island",grass_slab,200,{"grid":[24,24],"surface":1.4}),
    ("SmallCove","island",cove,2200,{"arc_center":[0,0,0],"radii":[9,16],"sector_degrees":260}),
    ("ShoreRocks","island",rock_cluster,1200,{}),
    ("TreeStump","island",stump,2000,{}),
    ("RopeBridge","island",bridge,4500,{"grid":[8,24],"deck_height":2.625}),
    ("IslandStairs","island",lambda:steps(8),1800,{"rise":2.12,"run":8}),
    ("DockPier","island",lambda:bridge(True),3500,{"grid":[8,16],"deck_height":2.625}),
    ("Lighthouse","island",lighthouse,6000,{}),
    *[("MountainRidge"+chr(65+i),"background",lambda i=i:mountain(i),300,{"tintable":True,"suggested_rgb":[58,141+i*20,235]}) for i in range(3)],
    ("CloudBankTall","background",cloud_bank,1800,{"cast_shadow":False}),
    ("CloudBankWide","background",lambda:cloud_bank(1),1800,{"cast_shadow":False}),
    *[("FloatingIslet"+chr(65+i),"background",lambda i=i:islet(i),4000,{}) for i in range(3)],
    ("GiantPalmCluster","background",palm_cluster,6000,{}),
    ("ToiletCastle","hero",castle,14000,{}),
    *[("Portal"+t,"hero",lambda t=t:portal(t),6500,{"extends":"PortalGate","clear_width":7.6}) for t in ("Sewer","Space","Hell")],
    ("ShopKiosk","hero",kiosk,8000,{"text_face":[0,-.83,10.5]}),
    ("IndexBookPedestal","hero",book_pedestal,4000,{}),
    ("CollectCoinJar","hero",coin_jar,6000,{}),
]
