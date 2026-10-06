"""Wave 1 Group C: twelve original collectible toys. Shared helpers are read-only.

Author Z-up, front -Y, one unit per stud. All decorations have real thickness.
"""
import math
import bpy
from mathutils import Vector
from lib import box, sphere, cylinder, torus, tube, lathe, prism, star, eyes, mesh, finish


def orb(name, loc, size, color, detail=10):
    return sphere(name, loc, size, color, detail, 6)


def block(name, loc, size, color, bevel=.10):
    """One bevel segment keeps small solid accents within the item budget."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Chunky edge", "BEVEL")
        mod.width = min(bevel, min(size)*.4)
        mod.segments = 1
    return finish(obj, color, False)


def line(name, pts, radius, color, sides=6):
    return tube(name, pts, [radius]*len(pts), color, sides)


def grin(loc, width=.22, color="ink"):
    x,y,z = loc
    line("Gentle curved smile", [(x-width,y,z+.055),(x-width*.55,y-.018,z-.025),
         (x,y-.025,z-.05),(x+width*.55,y-.018,z-.025),(x+width,y,z+.055)], .025, color)


def face(spread, y, z, size=.23, x=0, white="white"):
    for s in (-1,1):
        xx = x+s*spread
        orb("Eye white", (xx,y,z), (size,size*.48,size*1.16), white)
        orb("Ink pupil", (xx+.015,y-size*.44,z+.008), (size*.58,size*.24,size*.76), "ink")
        sphere("Eye glint", (xx-size*.14,y-size*.65,z+size*.38),
               (size*.23,size*.11,size*.25), "white", 8, 4)


def halo(loc, radius=.67, color="ice", tilt=0):
    return torus("Solid starlight halo", loc, radius, .075, color,
                 rotation=(tilt,0,0), segments=24, sides=6)


def moustache(loc, color):
    x,y,z=loc
    for s in (-1,1):
        tube("Upturned handlebar moustache", [(x,y,z),(x+s*.21,y-.025,z-.035),
             (x+s*.43,y,z+.02),(x+s*.50,y+.02,z+.16)], [.09,.115,.08,.025],color,6)


def drain_kraken():
    # Six separate angular pipe silhouettes, staggered in depth and height.
    for row,(yy,outer,zz) in enumerate([( .47,1.28,.77),(.02,1.57,.48),(-.55,.96,.21)]):
        for s in (-1,1):
            pts=[(s*.36,yy,.94),(s*outer,yy,.94),(s*outer,yy,zz),
                 (s*(outer-.23),yy-.24,zz),(s*(outer-.23),yy-.36,zz+.25)]
            tube("Squared pipe tentacle",pts,[.16]*5,"navy",6)
            torus("Orange pipe flange",pts[-1],.19,.058,"orange",segments=10,sides=4)
            cylinder("Dark pipe opening",(pts[-1][0],pts[-1][1],pts[-1][2]+.007),.132,.028,"ink",10)
    sphere("Armored pear head",(0,.04,1.66),(.83,.64,.92),"red",14,8)
    for s in (-1,1):
        prism("Broad red shell plate",[(s*.53,1.13),(s*.94,1.48),(s*.79,1.98),(s*.52,2.17)],.25,"red",.01)
    face(.31,-.54,1.81,.24)
    for s in (-1,1):
        line("Theatrical eyebrow",[(s*.10,-.70,2.025),(s*.52,-.62,2.14)],.065,"ink")
    moustache((0,-.71,1.47),"gold")
    line("Toothless scowl",[(-.18,-.59,1.23),(0,-.65,1.31),(.18,-.59,1.23)],.033,"ink")
    cylinder("Drain crown rim",(0,.07,2.45),.58,.15,"gray",16)
    cylinder("Drain crown cap",(0,.07,2.56),.45,.10,"gray",16)
    for x in (-.25,0,.25):
        block("Drain slot",(x,-.005,2.619),(.09,.49,.015),"ink",.008)


def geyser_gorilla():
    prism("Trapezoid chest",[(-.42,.48),(.42,.48),(.78,1.69),(-.78,1.69)],.87,"navy",.03)
    for s in (-1,1):
        block("Squat pipe leg",(s*.36,.01,.38),(.53,.67,.68),"navy",.16)
        block("Big toe foot",(s*.38,-.19,.17),(.58,.83,.31),"gray",.13)
        orb("Shoulder",(s*.78,0,1.51),(.36,.39,.38),"red")
        orb("Barrel forearm",(s*1.02,-.13,.93),(.46,.46,.67),"red",12)
        block("Gray knuckle pad",(s*1.05,-.52,.73),(.65,.19,.34),"gray",.12)
        for dx in (-.16,.16):
            line("Knuckle division",[(s*1.05+dx,-.622,.68),(s*1.05+dx,-.622,.80)],.018,"navy",4)
    orb("Gorilla head",(0,-.045,1.89),(.63,.51,.63),"navy",14)
    orb("Peach muzzle",(0,-.52,1.71),(.44,.19,.28),"peach",12)
    face(.245,-.49,2.06,.205)
    for s in (-1,1):
        line("Heavy kindly brow",[(s*.07,-.56,2.28),(s*.44,-.46,2.34)],.066,"navy")
        orb("Nostril",(s*.11,-.711,1.81),(.038,.018,.035),"ink",8)
    grin((0,-.716,1.64),.25)
    block("Orange belt",(0,-.44,.72),(.81,.16,.19),"orange",.06)
    knob=cylinder("Shower knob",(0,-.57,.76),.18,.12,"orange",10)
    knob.rotation_euler.x=math.pi/2
    block("Knob grip",(0,-.65,.76),(.25,.06,.07),"gray",.02)
    for s,h in [(-1,2.87),(0,3.13),(1,2.91)]:
        tube("Solid shower jet",[(s*.20,.015,2.30),(s*.26,.02,2.57),
             (s*.47,.04,h-.12),(s*.58,.10,h)], [.15,.145,.10,.025],"cyan",8)
        star("Water sparkle",(s*.47,-.06,h-.11),.10,"ice")


def throne_colossus():
    for s in (-1,1):
        block("Red pedestal leg",(s*.45,0,.42),(.59,.67,.74),"red",.1)
        block("Pedestal foot",(s*.45,-.12,.16),(.74,.88,.30),"red",.12)
        tube("Gray pipe arm",[(s*.73,.04,1.79),(s*1.10,.02,1.59),(s*1.16,-.25,1.11)], [.20]*3,"gray",8)
        torus("Gold toilet seat fist",(s*1.19,-.43,.98),.30,.145,"gold",
              scale=(1,1.16,1),rotation=(math.pi/2,0,0),segments=16,sides=6)
        block("Lid shoulder armor",(s*.83,.03,1.96),(.75,.94,.28),"navy",.13)
    box("Porcelain cistern chest",(0,0,1.55),(1.36,.91,1.44),"white",.18)
    box("Cistern lid",(0,0,2.30),(1.50,1.0,.21),"white",.09)
    block("Black visor",(0,-.47,1.96),(1.14,.13,.53),"black",.13)
    face(.275,-.57,1.97,.205)
    grin((0,-.489,1.47),.18)
    block("Flush chest button",(.34,-.477,1.19),(.27,.07,.13),"gold",.035)
    prism("Triangular red cape",[(-.56,2.20),(.56,2.20),(1.02,.31),(0,.55),(-1.02,.31)],.17,"red",.63)


def plunger_paladin():
    for s in (-1,1):
        block("Pipe boot",(s*.30,-.08,.24),(.43,.65,.46),"gray",.12)
    cylinder("Gold cylindrical tunic",(0,.02,.99),.51,1.21,"gold",14)
    torus("Tunic collar",(0,.02,1.52),.49,.06,"gold",segments=16,sides=4)
    lathe("Red plunger bell helmet",[(.20,0),(.67,0),(.66,.14),(.54,.31),(.41,.72),(.27,.83),(.13,.80)],
          (0,0,1.42),"red",segments=18)
    orb("Helmet opening",(0,-.52,1.76),(.48,.10,.30),"ink",12)
    face(.215,-.60,1.84,.17,white="ice")
    moustache((0,-.65,1.52),"white")
    for i in (-1,0,1):
        prism("Red crest fin",[(i*.18-.09,2.10),(i*.18-.07,2.52-abs(i)*.13),(i*.18+.10,2.31),(i*.18+.10,2.10)],.17,"red",.06)
    line("Shield arm",[(-.38,0,1.19),(-.73,-.15,1.12)],.15,"gray",8)
    box("White tile shield",(-.79,-.39,1.05),(.67,.24,.94),"white",.12)
    for zz in (.85,1.24):
        block("Tile grout",(-.79,-.516,zz),(.55,.02,.028),"gray",.007)
    block("Tile grout",(-.79,-.516,1.05),(.027,.02,.77),"gray",.007)
    line("Staff arm",[(.4,.01,1.22),(.90,-.06,1.20)],.15,"gray",8)
    cylinder("Wood staff",(.99,-.09,1.24),.070,2.40,"wood",10)
    lathe("Golden staff suction cup",[(.10,0),(.35,0),(.34,.11),(.24,.28),(.14,.39),(.07,.34)],
          (.99,-.09,2.13),"gold",segments=14)


def halo_hamster():
    sphere("Round white hamster",(0,.02,1.11),(.80,.63,.99),"white",16,8)
    for s in (-1,1):
        orb("Round hamster ear",(s*.59,.02,1.91),(.27,.17,.30),"white")
        orb("Silver inner ear",(s*.59,-.132,1.93),(.16,.034,.18),"gray")
        orb("Cream mitten foot",(s*.42,-.27,.16),(.28,.38,.16),"cream")
        orb("Silver cheek",(s*.45,-.493,1.15),(.27,.15,.23),"gray")
        orb("Tiny hand",(s*.72,-.13,.87),(.19,.22,.30),"white",8)
    face(.275,-.56,1.49,.235)
    star("Cyan star nose",(0,-.719,1.24),.125,"cyan",5)
    grin((0,-.637,1.06),.17)
    for x,z in [(-.28,.65),(0,.51),(.28,.65)]:
        star("Belly star stud",(x,-.56,z),.105,"cyan",4)
    halo((0,.02,2.33),.69)
    # Towel overlaps the near halo edge, clear of the eye and ear silhouette.
    block("Folded cyan towel",(.78,-.28,2.02),(.35,.22,.68),"cyan",.045)
    block("Towel bright hem",(.78,-.404,1.75),(.32,.026,.075),"white",.01)
    star("Towel sparkle",(.78,-.407,2.03),.09,"white")


def miniature_bowl(body, rim, loc=(0,0,0)):
    x,y,z=loc
    cylinder("Commode pedestal foot",(x,y,z+.12),.44,.24,body,14)
    cylinder("Commode pedestal",(x,y+.08,z+.40),.27,.58,body,12,radius_top=.35)
    lathe("Hollow egg bowl",[(.13,.48),(.40,.47),(.66,.71),(.74,.99),(.73,1.08),
          (.61,1.08),(.51,.85),(.16,.71)],(x,y-.19,z),body,scale=(1,1.12,1),segments=18)
    torus("Seat rim",(x,y-.19,z+1.105),.668,.10,rim,scale=(1,1.12,1),segments=20,sides=6)
    orb("Deep bowl water",(x,y-.19,z+.74),(.39,.43,.035),"cyan",10)


def comet_commode():
    miniature_bowl("white","cyan",(-.40,-.32,0))
    box("Silver comet tank",(-.42,.19,1.31),(.93,.45,1.12),"gray",.16)
    block("Tank cap",(-.42,.19,1.87),(1.00,.53,.16),"white",.07)
    face(.235,-.064,1.60,.185,x=-.42)
    orb("Surprised mouth",(-.42,-.055,1.24),(.085,.026,.115),"ink",8)
    for i,(x,h) in enumerate([(.70,2.34),(1.45,2.65),(1.70,1.92)]):
        tube("Three-prong comet tail",[(-.23,.44,.60),(.25,.55,.83),(.69,.57,1.22),
             (x,.50,h-.17),(x-.06,.48,h)], [.24,.25,.22,.11,.024],"ice",8)
    torus("Tilted tail-root halo",(.30,.47,1.02),.51,.073,"white",
          rotation=(.43,.55,.1),segments=20,sides=6)
    for x,z in [(.26,1.05),(.58,1.31),(.85,1.57),(1.11,1.94),(1.31,2.34)]:
        orb("Blue constellation dot",(x,.31,z),(.055,.040,.055),"blue",8)
    star("Comet starlight",(1.37,.30,2.31),.16,"white")


def shell_fan(name, base, radius, color, lower=False):
    # Thick scalloped fan with radial grooves, not a flat semicircle decal.
    bx,by,bz=base
    outline=[(0,0)]
    for i in range(19):
        a=math.pi*i/18
        r=radius*(1 if i%3 else .94)
        outline.append((r*math.cos(a),r*math.sin(a)))
    obj=prism(name,outline,.18,color)
    if lower:
        obj.rotation_euler.x=math.radians(72)
    obj.location=(bx,by,bz)
    return obj


def constellation_clam():
    # Lower fan projects toward viewer; upper fan is upright behind soap pearl.
    shell_fan("Lower ice scalloped shell",(0,.20,.25),1.23,"ice",True)
    shell_fan("Lower white shell inset",(0,.14,.31),1.11,"white",True)
    shell_fan("Upper ice scalloped shell",(0,.39,.38),1.29,"ice")
    shell_fan("Upper white shell inset",(0,.27,.40),1.17,"white")
    for angle in (20,48,76,104,132,160):
        a=math.radians(angle)
        line("Silver radial shell rib",[(.17*math.cos(a),.14,.45+.17*math.sin(a)),
             (.99*math.cos(a),.14,.45+.99*math.sin(a))],.040,"gray",6)
    box("Cyan soap-bar pearl",(0,-.49,.92),(1.11,.57,.65),"cyan",.20)
    face(.255,-.79,1.02,.18)
    grin((0,-.793,.77),.22)
    constellation=[(-.70,.07,1.31),(-.38,.07,1.60),(0,.07,1.50),(.40,.07,1.64),(.71,.07,1.29),(.27,.07,1.24)]
    line("Five cyan constellation links",constellation,.034,"cyan",6)
    for p in constellation:
        star("Constellation stud",(p[0],p[1]-.028,p[2]),.082,"white")
    halo((0,.39,1.91),.43,"white")


def starlight_seraph():
    for s in (-1,1):
        for row in range(3):
            z=1.87-row*.47
            tipz=2.45-row*.83
            pts=[(s*.29,z-.20),(s*.75,z-.25),(s*1.36,tipz-.17),
                 (s*1.53,tipz+.20),(s*1.02,tipz+.11),(s*.57,z+.12)]
            prism("Broad towel fan wing",pts,.23,"white",.18+row*.045)
            line("Silver wing hem",[(s*.75,.045+row*.045,z-.22),(s*1.36,.045+row*.045,tipz-.14),
                 (s*1.48,.045+row*.045,tipz+.13)],.052,"gray",6)
            line("Cyan folded wing seam",[(s*.59,.035,z),(s*1.18,.035,tipz-.02)],.029,"cyan",6)
    box("Folded towel body",(0,-.12,1.16),(.86,.53,1.95),"white",.13)
    block("Layered towel fold",(.27,-.412,.90),(.16,.05,1.31),"gray",.02)
    block("Cyan towel belt",(0,-.425,.96),(.85,.10,.22),"cyan",.06)
    block("Silver bottom hem",(0,-.407,.27),(.75,.035,.12),"gray",.02)
    face(.217,-.418,1.70,.19,white="cyan")
    grin((0,-.428,1.37),.145)
    for x,z in [(-.25,.64),(0,.53),(.25,.64)]:
        star("Raised white diamond",(x,-.437,z),.089,"white",4)
    halo((0,-.04,2.48),.57)


def last_toilet():
    miniature_bowl("black","magenta",(0,-.23,0))
    # Broken-looking offset masonry, connected by the thick portal spine.
    arch=[(-.99,.47,.21),(-.99,.47,1.96),(-.72,.47,2.46),
          (0,.47,2.73),(.72,.47,2.46),(.99,.47,1.96),(.99,.47,.21)]
    line("Solid white impossible arch",arch,.19,"white",6)
    line("Magenta inner portal rim",[(x*.84,y-.14,z*.90+.12) for x,y,z in arch],.09,"magenta",6)
    for s in (-1,1):
        prism("Angular broken arch seam",[(s*.72,2.54),(s*.69,2.43),(s*.84,2.35),(s*.87,2.43)],.055,"ink",.303)
    face(.26,-.33,1.39,.235)
    orb("Alarmed pink mouth",(0,-1.226,.82),(.13,.07,.15),"pink",10)
    line("Star flush handle stem",[(.58,.09,1.23),(.92,-.07,1.47)],.087,"gold",8)
    star("Enormous star flush handle",(1.00,-.09,1.62),.38,"gold",5)
    for i,(x,z) in enumerate([(-1.10,.93),(-1.34,1.48),(-1.16,2.09)]):
        line("Hidden tile support",[(x,.55,z),(-.91,.61,z-.12)],.10,"black",6)
        obj=block("Suspended cyan tile",(x,.21,z),(.49,.20,.39),"cyan",.055)
        obj.rotation_euler.y=(-.20+i*.19)
    star("Portal star at keystone",(0,.22,2.67),.18,"cyan")


def emergency_universe():
    for x in (-.49,.49):
        orb("Cream cabinet foot",(x,-.02,.15),(.25,.34,.15),"cream",10)
    box("Red emergency cabinet",(0,.14,1.43),(1.54,.74,2.47),"red",.16)
    orb("Circular black universe cavity",(0,-.267,1.09),(.656,.073,.75),"black",20)
    face(.31,-.289,2.26,.245)
    orb("Panicked mouth",(0,-.292,1.91),(.12,.035,.14),"ink",10)
    # Two interleaved true spiral arms with distinct silhouettes.
    for phase,color in [(0,"cyan"),(math.pi,"gold")]:
        pts=[]
        for i in range(21):
            t=i/20
            a=phase+t*math.pi*2.35
            r=.07+.46*t
            pts.append((r*math.cos(a),-.373,1.10+r*math.sin(a)))
        tube("Spare galaxy spiral",pts,[.035+.023*i/20 for i in range(21)],color,6)
    orb("White galaxy core",(0,-.397,1.1),(.095,.05,.095),"white",10)
    for x,z,r in [(-.42,1.44,.12),(.45,.86,.14),(.16,1.71,.085)]:
        orb("Violet orb planet",(x,-.47,z),(r,)*3,"violet",10)
    # Door swings left by 35 degrees; all insignia transform with the door.
    before=set(bpy.context.scene.objects)
    box("Open red cabinet door",(-.61,0,0),(1.18,.16,1.69),"red",.12)
    block("Door red inset",(-.61,-.091,0),(.96,.04,1.43),"red",.07)
    line("White plunger pictogram staff",[(-.61,-.128,.49),(-.61,-.128,-.18)],.047,"white",6)
    prism("White plunger pictogram cup",[(-.91,-.46),(-.31,-.46),(-.38,-.26),(-.51,-.16),(-.71,-.16),(-.84,-.26)],.052,"white",-.13)
    block("Door handle",(-1.05,-.16,.12),(.07,.13,.28),"gold",.02)
    angle=math.radians(35)
    for obj in set(bpy.context.scene.objects)-before:
        p=obj.location.copy()
        obj.location=(p.x*math.cos(angle)-p.y*math.sin(angle)-.78,
                      p.x*math.sin(angle)+p.y*math.cos(angle)-.20,p.z+1.10)
        obj.rotation_euler.z+=angle
    for z in (.43,1.75):
        cylinder("Door hinge",(-.77,-.19,z),.070,.26,"gold",8)


def rounded_frame(name, width, height, bottom, y, radius, color):
    x=width/2
    top=bottom+height
    pts=[(-x,y,bottom),(-x,y,top-.23),(-x+.10,y,top-.06),(-x+.25,y,top),
         (x-.25,y,top),(x-.10,y,top-.06),(x,y,top-.23),(x,y,bottom)]
    line(name,pts,radius,color,8)
    line(name+" sill",[(-x,y,bottom),(x,y,bottom)],radius,color,8)


def infinite_occupied():
    for s in (-1,1):
        orb("Orange slipper foot",(s*.58,-.21,.16),(.36,.52,.16),"orange",12)
    for i,(w,h,bot,y) in enumerate([(1.65,2.47,.31,-.21),(1.16,1.79,.44,.15),(.71,1.13,.57,.49)]):
        rounded_frame("Nested navy doorframe",w,h,bot,y,.14,"navy")
        rounded_frame("Alternating portal edge",w-.04,h-.055,bot+.03,y-.13,.041,"pink" if i%2==0 else "cyan")
    block("Black infinite center",(0,.72,1.12),(.56,.16,1.03),"black",.12)
    for s in (-1,1):
        line("Joined rear door braces",[(s*.79,-.17,.49),(s*.53,.15,.51),(s*.33,.55,.66)],.10,"navy",6)
    face(.335,-.405,2.41,.275)
    grin((0,-.381,2.04),.24,"white")
    orb("Occupied red status plaque",(0,-.40,.49),(.42,.085,.15),"red",12)
    # Tiny thick orbit diamonds emphasize the spatial recursion without text.
    for x,z in [(-.57,1.77),(.38,1.25)]:
        star("Threshold glint",(x,-.04,z),.10,"white")


def cosmic_courtesy():
    sphere("Black micro-universe",(-.17,.02,1.18),(.92,.80,.94),"black",18,10)
    torus("Broad golden toilet-seat orbit",(-.17,.02,.82),1.15,.135,"gold",
          scale=(1,1.03,.77),rotation=(.14,-.14,0),segments=28,sides=6)
    for s in (-1,1):
        x=-.17+s*.31
        star("White star eye",(x,-.738,1.59),.30,"white",5)
        orb("Star eye pupil",(x+.015,-.790,1.59),(.105,.042,.15),"ink",10)
        orb("Star eye glint",(x-.024,-.830,1.66),(.030,.012,.035),"white",8)
    prism("Cyan crescent grin",[(-.64,1.25),(-.44,1.12),(-.15,1.07),(.13,1.15),(.29,1.29),
          (.19,1.02),(-.02,.90),(-.27,.87),(-.49,.98)],.085,"cyan",-.82)
    for i in range(3):
        controls=[Vector(p) for p in [(-.65+i*.42,.45,.69),(-1.65+i*.50,.52,2.85),
                  (.10+i*.60,.50,3.02),(.52+i*.40,.44,2.20-i*.12)]]
        pts=[]
        for j in range(10):
            t=j/9
            pts.append((1-t)**3*controls[0]+3*(1-t)**2*t*controls[1]
                       +3*(1-t)*t*t*controls[2]+t**3*controls[3])
        tube("Thick arched magenta comet ribbon",pts,[.095]*8+[.07,.028],"magenta",6)
        star("Comet ribbon white tip",pts[-2],.13,"white")
    # Oversized four-digit glove bends down onto the side flush lever.
    block("Red lever socket",(.69,-.10,1.23),(.32,.30,.30),"red",.07)
    line("Red flush lever",[(.72,-.16,1.24),(1.19,-.31,1.37)],.10,"red",8)
    orb("Giant glove palm",(1.04,-.28,1.87),(.38,.23,.40),"white",12)
    for i in range(3):
        x=.79+i*.21
        tube("Glove curled finger",[(x,-.29,1.82),(x,-.48,1.62),(x+.035,-.47,1.43)],
             [.105,.11,.08],"white",8)
    tube("Glove thumb",[(1.27,-.22,1.93),(1.48,-.29,1.75),(1.37,-.41,1.62)],
         [.15,.14,.09],"white",8)
    torus("Glove cuff",(1.00,-.19,2.17),.24,.075,"white",scale=(1,.77,1),segments=14,sides=6)


BUILDERS = {
    "DrainKraken": drain_kraken, "GeyserGorilla": geyser_gorilla,
    "ThroneColossus": throne_colossus, "PlungerPaladin": plunger_paladin,
    "HaloHamster": halo_hamster, "CometCommode": comet_commode,
    "ConstellationClam": constellation_clam, "StarlightSeraph": starlight_seraph,
    "TheLastToilet": last_toilet, "EmergencyUniverse": emergency_universe,
    "InfiniteOccupied": infinite_occupied, "CosmicCourtesy": cosmic_courtesy,
}
