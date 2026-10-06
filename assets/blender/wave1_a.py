"""Wave 1 A: original toy collectibles; shared lib and palette are read-only.

All surfaces have thickness. Front is -Y, authoring units are studs, Z is up.
The entry script establishes the brief's exact X/Y/Z bounds and base pivot.
"""
import math
import bpy
from mathutils import Vector

from lib import sphere, box as soft_box, cylinder, torus, tube, lathe, prism, finish, mesh, KEYS


def box(name, loc, size, color, bevel=.12):
    if bevel >= .15:
        return soft_box(name, loc, size, color, bevel)
    # Small trim uses one broad bevel, keeping the same chunky edge language.
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Broad toy bevel", "BEVEL")
        mod.width = min(bevel, min(size)*.45)
        mod.segments = 1
    return finish(obj, color, False)


def puff(name, loc, scale, color, segments=10, rings=6):
    return sphere(name, loc, scale, color, segments, rings)


def eye(x, y, z, size=.23, gaze=0, sleepy=False, lid=None):
    puff("Eye white", (x, y, z), (size, size*.48, size*(.70 if sleepy else 1.12)), "white")
    puff("Ink pupil", (x+gaze, y-size*.43, z-.015 if sleepy else z),
         (size*.55, size*.25, size*(.53 if sleepy else .77)), "ink", 8, 6)
    puff("Eye catchlight", (x+gaze-size*.15, y-size*.65, z+size*.28),
         (size*.22, size*.10, size*.23), "white", 8, 4)
    if sleepy and lid:
        puff("Heavy relaxed eyelid",(x,y-size*.32,z+size*.42),
             (size*1.02,size*.35,size*.25),lid,8,4)


def grin(x, y, z, width=.22):
    tube("Smile", [(x-width,y,z+.055),(x-width*.55,y-.015,z-.025),
                   (x+width*.35,y-.015,z-.04),(x+width,y,z+.045)], [.026]*4, "ink", 6)


def brow(x, y, z, tilt=0, width=.17):
    tube("Expressive eyebrow", [(x-width,y,z-tilt),(x,y-.015,z+.025),
                                (x+width,y,z+tilt)], [.033]*3, "ink", 6)


def suds_slug():
    puff("Long mint bean", (0,0,.36), (1.04,.62,.36), "mint", 16, 8)
    tube("Lifted curled tail", [(.55,.13,.32),(1,.18,.43),(1.23,.20,.65),(1.14,.18,.82)],
         [.32,.23,.14,.035], "mint", 10)
    puff("Soft cheek", (-.65,-.14,.49), (.47,.51,.42), "mint", 12, 6)
    box("Cream soap chip saddle", (.27,.04,.72), (.92,.66,.20), "cream", .09)
    for x,y,z,r in [(-.10,.05,.91,.28),(.32,.09,1.02,.32),(.73,.12,.91,.23)]:
        puff("White bath foam", (x,y,z), (r,r*.85,r), "white")
    for x,z,gaze in [(-.91,1.16,-.055),(-.43,1.24,.055)]:
        tube("Thick eye stalk", [(x+.05,-.24,.58),(x,-.30,z-.11)], [.12,.095], "mint", 8)
        eye(x,-.37,z,.205,gaze)
    puff("Cheeky mouth", (-.65,-.64,.45), (.19,.052,.085), "ink", 10, 6)
    puff("Tiny tongue", (-.61,-.70,.414), (.095,.045,.037), "pink", 8, 4)


def pocket_puddle():
    for x,y,sx,sy in [(-.63,.13,.70,.70),(.65,.16,.66,.67),(0,-.41,.90,.63)]:
        puff("Puddle lobe", (x,y,.14), (sx,sy,.14), "water", 12, 6)
    puff("Raised worried center", (0,-.05,.53), (.70,.59,.51), "water", 12, 8)
    for s in (-1,1):
        tube("Stubby splash arm", [(s*.53,0,.32),(s*.99,-.02,.48),(s*1.13,-.03,.64)],
             [.23,.17,.065], "water", 8)
        eye(s*.26,-.57,.69,.255,s*.025)
    tube("Worried mouth", [(-.16,-.662,.36),(0,-.68,.42),(.16,-.662,.36)], [.035]*3,"ink",6)
    cylinder("Upside down orange pail", (0,.02,1.12), .55,.52,"orange",16,radius_top=.40)
    torus("Bucket rolled lip",(0,.02,.88),.54,.065,"orange",segments=16,sides=5)
    tube("Cream bucket handle", [(-.48,-.10,1.02),(-.66,-.14,1.31),(-.47,-.15,1.57),
                               (0,-.15,1.68),(.47,-.15,1.57),(.66,-.14,1.31),(.48,-.10,1.02)],
         [.065]*7,"cream",6)


def loopy_loofah():
    # Six wide, overlapping solid folds leave a scalloped toy silhouette.
    for x,y,z,sx,sz in [(-.55,0,.70,.55,.53),(.55,0,.74,.55,.55),
                        (-.47,.07,1.38,.59,.57),(.43,.10,1.43,.61,.59),
                        (0,.39,1.03,.72,.67),(0,-.29,1.02,.73,.70)]:
        puff("Broad pink loofah fold",(x,y,z),(sx,.53,sz),"pink",12,6)
    for s in (-1,1):
        puff("Peach mitten foot",(s*.46,-.21,.15),(.32,.40,.15),"peach")
        eye(s*.31,-.79,1.25,.25,s*.016)
    brow(-.31,-.85,1.63,.05)
    brow(.31,-.85,1.72,-.02)
    puff("Broad grin",(0,-.82,.84),(.31,.063,.135),"ink",12,6)
    puff("Grin tongue",(.06,-.875,.79),(.14,.021,.037),"pink",8,4)
    tube("Open cream hanging loop",[(-.32,.05,1.81),(-.42,.05,2.17),(-.30,.05,2.47),
                                  (0,.05,2.59),(.31,.05,2.46),(.41,.05,2.17),(.30,.05,1.86)],
         [.082]*7,"cream",8)


def soggy_sock():
    # The continuous swept boot has a sideways toe and a soft bend at the heel.
    tube("Bent sock",[(.56,0,.39),(.34,0,.44),(-.13,0,.45),(-.39,0,.68),
                      (-.37,0,1.18),(-.30,0,1.72),(-.29,0,2.09)],
         [.30,.42,.43,.40,.40,.37,.35],"blue",12)
    box("White folded cuff",(-.29,.01,2.11),(.87,.82,.32),"white",.12)
    puff("Orange heel patch",(-.56,-.34,.55),(.23,.08,.25),"orange")
    for x in (.29,.62):
        puff("Tiny folded toe foot",(x,-.11,.15),(.19,.35,.15),"blue",8,6)
    eye(-.53,-.367,1.55,.22,-.02,True,"blue")
    eye(-.08,-.367,1.50,.22,-.025,True,"blue")
    tube("Sideways mouth",[(-.37,-.435,1.12),(-.18,-.45,1.09),(-.08,-.44,1.14)], [.027]*3,"ink",6)
    for x,z in [(-.55,2.13),(-.29,2.04),(-.03,2.17)]:
        tube("Chunky wet forelock",[(x+.04,-.12,2.34),(x,-.40,z+.06),(x+.02,-.46,z-.12)],
             [.075,.12,.045],"ice",8)


def tub_tadpole():
    puff("Lime pear head",(-.35,-.01,.80),(.76,.62,.73),"lime",14,8)
    tube("Tapered swimming body",[(-.05,.15,.62),(.47,.16,.51),(.79,.15,.62)], [.50,.33,.16],"lime",10)
    puff("Single wide paddle tail",(1.02,.18,.76),(.53,.23,.53),"teal",12,6).rotation_euler.y=-.40
    for s in (-1,1):
        puff("Peach foot nub",(-.32+s*.39,-.12,.13),(.22,.28,.13),"peach",8,6)
    for x in (-.69,-.09):
        eye(x,-.53,1.03,.28,.025)
        torus("Thick cyan goggle ring",(x,-.615,1.03),.283,.069,"cyan",rotation=(math.pi/2,0,0),segments=12,sides=5)
    tube("Goggle bridge",[(-.43,-.65,1.10),(-.35,-.68,1.15)], [.065]*2,"cyan",6)
    grin(-.38,-.638,.65,.20)
    tube("Whistle cord",[(-.63,-.53,.49),(-.33,-.64,.31),(-.01,-.49,.49)],[.028]*3,"orange",6)
    puff("Orange whistle",(-.28,-.67,.29),(.17,.13,.13),"orange",10,6)
    box("Whistle mouthpiece",(-.10,-.68,.34),(.20,.15,.11),"orange",.025)


def brush_bristle():
    box("Rounded teal handle",(0,0,.93),(.43,.38,1.50),"teal",.17)
    box("Cream brush head",(0,0,1.98),(.95,.49,.92),"cream",.19)
    for s in (-1,1):
        tube("Short teal arm",[(s*.19,0,1.14),(s*.48,-.02,1.06),(s*.61,-.05,1.22)], [.09,.085,.06],"teal",7)
        puff("Orange slipper",(s*.23,-.14,.12),(.24,.34,.12),"orange",10,6)
        eye(s*.225,-.27,1.94,.205,0,True,"cream")
    for i in range(5):
        x=-.39+i*.195
        tube("Swept white bristle clump",[(x,.04,2.23),(x+.04,0,2.65),(x+.14,0,2.80+i*.02)],
             [.135,.115,.045],"white",7)
    tube("Pink toothpaste quiff",[(.02,-.06,2.79),(.18,-.10,2.84),(.38,-.08,2.91),(.51,-.03,3.04),(.46,0,3.14)],
         [.10,.13,.12,.075,.018],"pink",8)
    grin(0,-.282,1.66,.16)
    brow(-.22,-.33,2.12,-.025,.135)
    brow(.22,-.33,2.12,.025,.135)


def roll_mole():
    # Tube axis runs along X. The open cream annulus surrounds an ink recess.
    roll=lathe("Cream cardboard cylinder",[(.56,-.62),(.73,-.62),(.77,-.55),(.77,.55),(.71,.62),(.56,.62)],
               (0,0,0),"cream",segments=20)
    roll.rotation_euler.y=math.pi/2
    roll.location=(.44,.10,.78)
    hole=cylinder("Dark tunnel recess",(-.19,.10,.78),.565,.035,"ink",20)
    hole.rotation_euler.y=math.pi/2
    rear=cylinder("Dark visible far tunnel opening",(.98,.10,.78),.559,.035,"ink",20)
    rear.rotation_euler.y=math.pi/2
    puff("Mole emerging body",(-.43,-.03,.62),(.75,.48,.48),"brown",14,8)
    puff("Mole face",(-.85,-.20,.72),(.49,.45,.47),"brown",12,8)
    for x,z in [(-1.10,.88),(-.68,.92)]:
        eye(x,-.596,z,.155,.018)
    puff("Raised cheek",(-.63,-.52,.64),(.21,.18,.17),"brown",10,6)
    puff("Round pink nose",(-.94,-.685,.65),(.20,.13,.15),"pink",10,6)
    for x,y in [(-1.0,-.38),(-.23,-.48)]:
        puff("Digging paw",(x,y,.17),(.26,.30,.17),"peach",10,6)
        for dx in (-.085,.035):
            tube("Paw crease",[(x+dx,y-.24,.20),(x+dx,y-.17,.25)],[.012,.012],"brown",5)
    flap=box("One loose white paper flap",(.57,-.15,1.55),(1.10,.72,.10),"white",.035)
    flap.rotation_euler.x=.12
    box("Paper folded lip",(.57,-.52,1.46),(1.10,.10,.25),"white",.04)


def capybara_cap():
    box("Caramel rectangular bean",(0,.06,.81),(2.02,1.08,1.06),"caramel",.34)
    for x in (-.70,.70):
        for y in (-.34,.40):
            puff("Stubby capybara leg",(x,y,.22),(.23,.23,.25),"caramel",8,5)
    box("Broad peach muzzle",(-.24,-.61,.74),(1.23,.43,.53),"peach",.21)
    for s in (-1,1):
        puff("Tiny round ear",(s*1.04,-.30,1.24),(.18,.15,.20),"caramel",8,6)
        eye(-.22+s*.39,-.54,1.17,.23,.025,True,"caramel")
    for x in (-.48,-.12):
        puff("Nostril",(x,-.83,.85),(.043,.021,.030),"ink",8,4)
    grin(-.23,-.843,.65,.25)
    puff("Enormous shower cap",(.06,.12,1.67),(1.10,.67,.51),"pink",12,6)
    for i in range(10):
        a=i*math.tau/10
        puff("Scalloped elastic cap edge",(.06+.97*math.cos(a),.12+.54*math.sin(a),1.43),(.25,.20,.16),"pink",8,4)
    for x,y,z,sx in [(-.54,-.405,1.75,.15),(.03,-.51,1.86,.18),(.64,-.36,1.74,.16)]:
        puff("White cap spot",(x,y,z),(sx,.035,sx*.78),"white",8,4)


def knob_claw(x,y,z):
    outline=[(-.14,-.36),(.14,-.36),(.14,-.14),(.36,-.14),(.36,.14),
             (.14,.14),(.14,.36),(-.14,.36),(-.14,.14),(-.36,.14),(-.36,-.14),(-.14,-.14)]
    prism("Cream cross faucet knob",[(x+a,z+b) for a,b in outline],.27,"cream",y)
    puff("Knob hub",(x,y-.16,z),(.17,.075,.17),"cream",10,6)


def drain_hat():
    # Rings along X place four exact ink bands in the dome's own surface.
    # No raised strips, overlapping faces or fragile perforations are required.
    levels=[-.59,-.43,-.33,-.18,-.08,.08,.18,.33,.43,.59]
    verts=[(-.73,.10,1.18)]
    for x in levels:
        radius=math.sqrt(1-(x/.73)**2)
        for j in range(16):
            a=j*math.tau/16
            verts.append((x,.10+.55*radius*math.cos(a),1.18+.30*radius*math.sin(a)))
    verts.append((.73,.10,1.18))
    faces, slots=[],[]
    for j in range(16):
        faces.append((0,1+(j+1)%16,1+j))
    for i in range(len(levels)-1):
        for j in range(16):
            a,b=1+i*16+j,1+i*16+(j+1)%16
            if i in (1,3,5,7) and 2<=j<6:
                slots.append(len(faces))
            faces.append((a,b,b+16,a+16))
    for j in range(16):
        faces.append((len(verts)-1,145+j,145+(j+1)%16))
    obj=mesh("Gray dome with four atlas drain slots",verts,faces,"gray",True)
    index=KEYS.index("ink")
    for fi in slots:
        for li in obj.data.polygons[fi].loop_indices:
            obj.data.uv_layers[0].data[li].uv=((index%8*32+16)/256,(index//8*64+30)/256)


def drain_crab():
    puff("Squat orange shell",(0,0,.61),(.84,.61,.46),"orange",14,8)
    for s in (-1,1):
        for i in range(3):
            y=-.38+i*.36
            tube("Folded crab leg",[(s*.59,y,.52),(s*(1.02+i*.04),y-.04,.34),(s*(1.13+i*.02),y-.16,.09)],
                 [.115,.10,.035],"orange",7)
        z=1.10 if s==1 else .80
        tube("Claw arm",[(s*.63,-.26,.60),(s*1.00,-.37,z-.24),(s*1.20,-.40,z)], [.15,.13,.12],"orange",8)
        knob_claw(s*1.20,-.43,z+.10)
        tube("Short eye stalk",[(s*.30,-.33,.76),(s*.32,-.43,1.16)],[.105,.08],"orange",7)
        eye(s*.32,-.51,1.18,.205,-s*.02)
    grin(0,-.608,.66,.24)
    brow(-.32,-.57,1.43,-.04,.15)
    brow(.32,-.57,1.43,.04,.15)
    drain_hat()
    torus("Drain cover rim",(0,.10,1.19),.65,.055,"gray",scale=(1,.80,1),segments=16,sides=5)


def toothpaste_goose():
    box("Flattened toothpaste tube",(0,.02,.79),(1.72,.72,.92),"white",.28)
    box("Cyan tube stripe",(0,-.359,.83),(1.48,.06,.22),"cyan",.035)
    box("Tube crimp",(.85,.02,.72),(.19,.82,.69),"white",.055)
    for s in (-1,1):
        puff("Orange paddle foot",(s*.42,-.04,.16),(.29,.41,.16),"orange",12,6)
        puff("Folded white wing",(.03,s*.40,1.04),(.43,.115,.26),"white",12,6).rotation_euler.y=-.23
    tube("Long curved cream goose neck",[(-.62,0,.87),(-.90,0,1.17),(-.94,-.01,1.54),
                                         (-.83,-.03,1.91),(-.66,-.07,2.14)],
         [.30,.26,.21,.22,.29],"cream",12)
    puff("Goofy goose head",(-.68,-.05,2.12),(.42,.35,.34),"cream",12,8)
    eye(-.89,-.342,2.22,.20,-.02)
    eye(-.47,-.341,2.24,.235,.01)
    bill=puff("Broad orange beak",(-.73,-.43,1.99),(.31,.32,.13),"orange",12,6)
    seam=[]
    for xx in (-.96,-.85,-.73,-.61,-.50):
        hit, point, _, _ = bill.ray_cast(Vector((xx,-1,1.96))-bill.location,Vector((0,1,0)))
        assert hit
        seam.append((xx,point.y+bill.location.y-.008,1.96))
    tube("Continuous beak smile",seam,[.012]*5,"ink",6)
    curl=[(.78,.02,.81),(1.10,.03,1.06),(1.23,.05,1.42),(1.11,.05,1.67),(.90,.03,1.72),(.80,0,1.59)]
    tube("Solid pink paste tail",curl,[.22,.23,.20,.16,.115,.028],"pink",10)
    tube("Mint paste ribbon",[(x,y-.155,z+.055) for x,y,z in curl], [.085,.083,.071,.058,.038,.014],"mint",7)


def sponge_knight():
    # An oval woven scouring pad, with no rectangular sponge or costume clothes.
    body=puff("Tall teal scouring pad",(0,0,1.04),(.59,.43,.90),"teal",14,8)
    # Six broad diagonal fibers conform to the actual faceted pad surface.
    for slope in (-1,1):
        for height in (.58,.89,1.20):
            points=[]
            for x in (-.32,0,.32):
                z=height+slope*x*.38
                hit, point, _, _ = body.ray_cast(Vector((x,-1,z))-body.location,Vector((0,1,0)))
                assert hit
                points.append((x,point.y+body.location.y-.012,z))
            tube("Green woven scrub fiber",points,[.043]*3,"leaf",6)
    for s in (-1,1):
        puff("Mint pad foot",(s*.28,-.09,.14),(.22,.29,.14),"mint",10,6)
        puff("Teal scrub mitten",(-.67 if s<0 else .93,-.02,.96),(.17,.17,.18),"teal",10,6)
    tube("Lance holding scrub arm",[(.47,-.02,1.04),(.86,-.02,.96)],[.12,.10],"teal",8)
    cylinder("Orange tapered bucket helmet",(0,.02,1.97),.63,.64,"orange",16,radius_top=.46)
    torus("Orange bucket rolled brim",(0,.02,1.66),.63,.060,"orange",segments=16,sides=5)
    tube("Raised bucket carry handle",[(-.53,.13,2.00),(-.63,.13,2.30),(-.38,.13,2.56),
                                       (0,.13,2.65),(.38,.13,2.56),(.63,.13,2.30),(.53,.13,2.00)],
         [.055]*7,"woodLight",6)
    box("Single dark visor slit",(0,-.565,1.87),(.99,.13,.33),"ink",.11)
    eye(-.06,-.65,1.855,.23,.015,True,"orange")
    # A wooden handle with a hollow rubber plunger cup replaces the brush spear.
    tube("Wood plunger lance handle",[(.94,-.02,.14),(.94,-.02,2.39)],[.065,.065],"woodLight",8)
    lathe("Red hollow plunger lance cup",[(.075,2.36),(.15,2.40),(.27,2.62),(.29,2.68),
                                         (.23,2.68),(.21,2.61),(.075,2.44)],
          (.94,-.02,0),"red",segments=12)
    shield=cylinder("Round mint soap bar shield",(-.83,-.35,.96),.38,.20,"mint",16)
    shield.rotation_euler.x=math.pi/2
    torus("Cream soap shield edge",(-.83,-.458,.96),.32,.045,"cream",rotation=(math.pi/2,0,0),segments=12,sides=5)
    for x,z,r in [(-.88,1.00,.115),(-.69,.90,.065)]:
        puff("White soap bubble emblem",(x,-.485,z),(r,.035,r),"white",8,4)


def bubble_beard():
    box("Cream soap head",(0,.02,1.56),(1.43,.86,.86),"cream",.23)
    for s in (-1,1):
        puff("Peach slipper",(s*.42,-.05,.14),(.29,.37,.14),"peach",10,6)
        eye(s*.31,-.44,1.67,.235,s*.016)
    grin(0,-.443,1.35,.15)
    # Exactly seven foam lobes: three across the top, two middle, two tip.
    for x,y,z,r in [(-.58,-.10,1.01,.37),(0,-.32,1.01,.37),(.58,-.10,1.01,.37),
                     (-.32,-.21,.67,.32),(.32,-.21,.67,.32),(-.13,-.20,.39,.24),(.13,-.20,.35,.22)]:
        puff("White beard foam",(x,y,z),(r,r*.84,r),"white",10,6)
    puff("Mint towel turban",(0,.08,2.08),(.84,.55,.37),"mint",12,6)
    for s in (-1,1):
        fold=box("Diagonal towel fold",(s*.27,-.38,2.10),(.79,.17,.23),"mint",.09)
        fold.rotation_euler.y=s*.31
    puff("Turban knot",(.14,-.48,2.22),(.19,.13,.20),"mint",10,6)
    box("Pink comb spine",(.69,-.47,.87),(.79,.10,.12),"pink",.04)
    for i in range(5):
        box("Broad comb tooth",(.36+i*.155,-.47,1.015),(.075,.09,.27),"pink",.025)


BUILDERS = {
    "SudsSlug": suds_slug, "PocketPuddle": pocket_puddle,
    "LoopyLoofah": loopy_loofah, "SoggySock": soggy_sock,
    "TubTadpole": tub_tadpole, "BrushBristle": brush_bristle,
    "RollMole": roll_mole, "CapybaraCap": capybara_cap,
    "DrainCrab": drain_crab, "ToothpasteGoose": toothpaste_goose,
    "SpongeKnight": sponge_knight, "BubbleBeard": bubble_beard,
}
