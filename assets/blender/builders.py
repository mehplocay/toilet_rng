"""All original procedural asset designs. No external meshes or asset IDs."""
import math
import bpy
from mathutils import Vector
from lib import box, sphere, cylinder, torus, tube, lathe, prism, star, eyes, smile, crown, mesh


def poop(color="brown", royal=False):
    sphere("Soft swirl base",(0,0,.32),(.93,.72,.32),color,16,8)
    points,radii=[],[]
    for i in range(43):
        t=i/42
        a=math.pi/2+t*math.tau*2.55
        r=.56*(1-t)**.8
        points.append((r*math.cos(a),r*math.sin(a),.38+t*1.40))
        radii.append(.39*(1-t)**.60+.018)
    tube("Continuous piped swirl",points,radii,color,10)
    eyes(.27,-.88,.68,.255)
    smile((0,-.96,.36),.20)
    if royal:
        crown((0,.03,1.74),.51,.53)
        star("Royal sparkle left",(-1.13,-.02,1.55),.25)
        star("Royal sparkle right",(1.06,-.03,1.08),.18,"ice")


def paper():
    lathe("Paper roll",[(.29,0),(.78,0),(.83,.07),(.83,1.40),(.77,1.47),(.29,1.47)],(0,0,.04),"white",segments=24)
    lathe("Cardboard core",[(.235,0),(.285,0),(.285,1.47),(.235,1.47)],(0,0,.04),"woodLight",segments=16)
    # A real hanging strip with an unmistakable curled lower edge.
    box("Wide loose paper sheet",(.80,-.05,.69),(.13,.83,1.18),"white",.05)
    box("Folded paper end",(.95,-.05,.17),(.37,.83,.12),"cream",.04)
    for z in (.47,.91):
        for y in (-.28,-.08,.12):
            box("Subtle perforation",(.878,y,z),(.018,.10,.024),"gray",.004)
    torus("Top paper winding",(0,0,1.515),.59,.013,"cream",segments=24,sides=4)


def rat():
    sphere("Pear shaped body",(0,.20,.55),(.60,.81,.51),"gray",16,8)
    sphere("Chubby head",(0,-.40,.73),(.57,.51,.50),"gray",14,8)
    for s in (-1,1):
        sphere("Round ear",(s*.44,-.24,1.14),(.30,.14,.34),"slate",12,8)
        sphere("Pink inner ear",(s*.44,-.365,1.16),(.205,.04,.24),"pink",10,6)
        sphere("Paw",(s*.40,-.32,.14),(.24,.31,.14),"peach",10,6)
    eyes(.245,-.83,.82,.185)
    sphere("Snout",(0,-.88,.54),(.28,.24,.18),"cream",12,6)
    sphere("Nose",(0,-1.075,.59),(.12,.09,.09),"pink",10,6)
    for s in (-1,1):
        tube("Whisker",[(s*.15,-1.0,.53),(s*.54,-.99,.58)],[.018,.008],"ink",5)
    tube("Curled pink tail",[(.16,.69,.32),(.68,.94,.23),(1.03,.77,.20),(1.07,.33,.28),(.83,.20,.42)],[.09,.08,.06,.04,.012],"pink",8)


def fish(shark=False):
    body="blue" if not shark else "slate"
    sphere("Fish body",(0,0,.85),(1.0,.45,.65),body,16,10)
    sphere("Pale belly",(.17,-.045,.64),(.81,.43,.35),"ice",14,8)
    # Tail sits to the left and has a thick, forked silhouette.
    prism("Forked tail",[(-.74,.85),(-1.52,1.43),(-1.39,.85),(-1.54,.27)],.24,body)
    if shark:
        prism("Tall dorsal fin",[(-.44,1.31),(-.04,2.03),(.48,1.30)],.24,body,.04)
        prism("Near pectoral fin",[(-.20,.88),(-.64,.23),(.40,.63)],.19,body,-.42)
        prism("Far pectoral fin",[(-.20,.86),(-.47,.29),(.51,.63)],.19,body,.40)
        sphere("Shark nose",(.76,-.015,.93),(.40,.37,.30),body,12,8)
        sphere("Friendly toothy grin",(.59,-.39,.70),(.42,.06,.17),"ink",12,6)
        for i in range(4):
            x=.30+i*.17
            prism("Little shark tooth",[(x,.82),(x+.105,.82),(x+.06,.69)],.045,"white",-.455)
        for x in (-.48,-.30,-.12):
            tube("Gill",[(x,-.448,.88),(x-.04,-.44,1.06)],[.023,.023],"navy",5)
    else:
        prism("Dorsal fin",[(-.45,1.32),(-.20,1.71),(.50,1.36)],.16,"cyan")
        sphere("Side fin",(-.12,-.44,.69),(.30,.10,.25),"cyan",12,6)
        sphere("Kissy lips",(.98,-.10,.76),(.16,.30,.12),"orange",10,6)
    # Side-facing fish eyes, visible in front and three-quarter icons.
    for y in (-.385,.385):
        sphere("Fish eye",(.54,y,1.05),(.225,.105,.245),"white",10,6)
        sphere("Fish pupil",(.60,y+(-.087 if y<0 else .087),1.06),(.115,.055,.155),"black",10,6)
        sphere("Fish glint",(.57,y+(-.13 if y<0 else .13),1.125),(.040,.020,.045),"white",8,4)


def duck():
    sphere("Rubber duck body",(0,.12,.48),(.74,.84,.48),"yellow",16,10)
    sphere("Duck head",(0,-.42,1.05),(.53,.50,.53),"yellow",16,10)
    for s in (-1,1):
        sphere("Wing",(s*.62,.05,.58),(.17,.45,.28),"gold",12,6)
    tube("Upturned tail",[(0,.69,.45),(0,.98,.68),(0,.98,.87)],[.30,.20,.025],"yellow",8)
    eyes(.235,-.84,1.18,.19)
    sphere("Orange duck bill",(0,-.97,.89),(.36,.33,.13),"orange",12,6)
    tube("Bill smile",[(-.22,-1.185,.875),(0,-1.27,.87),(.22,-1.185,.875)],[.018]*3,"brown",6)


def bowl(body="white",trim="cream",water="water",simple=False):
    cylinder("Broad foot",(0,.04,.15),.91,.30,body,16 if simple else 24,radius_top=.81)
    lathe("Flared pedestal",[(.48,.23),(.72,.23),(.59,.42),(.43,1.03),(.60,1.32),(.36,1.32)],(0,.13,0),body,scale=(1,1.10,1),segments=12 if simple else 20)
    lathe("Hollow bowl",[(.30,1.02),(.65,1.10),(.99,1.48),(1.14,1.98),(1.12,2.11),(.96,2.11),(.85,1.85),(.62,1.56),(.27,1.49)],(0,-.24,0),body,scale=(1,1.16,1),segments=16 if simple else 24)
    torus("Chunky seat rim",(0,-.24,2.08),1.025,.145,trim,scale=(1,1.16,1),segments=20 if simple else 28,sides=6 if simple else 8)
    sphere("Water inside bowl",(0,-.24,1.57),(.64,.75,.065),water,10 if simple else 16,6)


def toilet(tier="Basic"):
    colors={"Basic":("white","cream","water"),"Dirty":("woodLight","cream","mud"),"Golden":("gold","goldLight","orange"),"Diamond":("ice","cyan","blue"),"Radioactive":("green","lime","glow"),"Demon":("black","red","orange"),"Galaxy":("purple","magenta","cyan")}
    body,trim,water=colors[tier]
    bowl(body,trim,water)
    box("Cistern",(0,.91,2.87),(1.89,.70,1.69),body,.19)
    box("Cistern lid",(0,.90,3.73),(2.05,.83,.20),trim,.09)
    box("Flush lever",(.87,.43,3.26),(.39,.15,.16),"goldLight" if tier=="Golden" else "ice",.04)
    # Raised lid echoes the big oval silhouette in the supplied mockup.
    lid=sphere("Raised lid",(0,.49,3.48),(1.015,.18,1.31),body,20,12,smooth=tier!="Diamond")
    sphere("Lid inset",(0,.309,3.48),(.83,.047,1.12),"black" if tier=="Demon" else trim,16,10,smooth=tier!="Diamond")
    for s in (-1,1):
        cylinder("Hinge",(s*.68,.44,2.18),.13,.29,trim,12).rotation_euler[1]=math.pi/2
    if tier=="Dirty":
        for x,z,sz in [(-.52,3.76,.20),(.37,3.40,.17),(-.27,2.84,.13)]:
            sphere("Lid mud stain",(x,.251,z),(sz,.018,sz*1.7),"mud",10,6)
        for x,y,z in [(-.75,-1.12,1.67),(.35,-1.46,1.84),(.74,-1.11,1.69)]:
            sphere("Bowl brown drip",(x,y,z),(.13,.038,.27),"brown",10,6)
        tube("Slime over tank",[(-1,.88,3.77),(-1.07,.77,3.65),(-1.07,.72,3.37)],[.13,.11,.055],"mud",8)
        box("Wonky repair patch",(.69,-.37,.74),(.22,.35,.42),"wood",.03)
        lathe("Plunger cup",[(.10,0),(.39,0),(.38,.15),(.23,.36),(.10,.41)],(1.36,.54,0),"brown",segments=16)
        cylinder("Plunger handle",(1.36,.54,1.47),.085,2.38,"wood",10)
        sphere("Plunger grip",(1.36,.54,2.69),(.13,.13,.19),"mud",10,6)
    elif tier=="Golden":
        star("Lid gold crest",(0,.232,3.60),.48,"gold",5)
        for s in (-1,1):
            torus("Gold side handle",(s*1.10,.55,2.67),.36,.08,"goldLight",rotation=(math.pi/2,0,0),segments=16)
        torus("Gold foot band",(0,.04,.26),.83,.07,"goldLight")
    elif tier=="Diamond":
        for s in (-1,1):
            crystal((s*1.02,.73,3.43),.30,1.05,"cyan")
            crystal((s*.94,.12,.15),.22,.87,"ice")
        crystal((0,.22,3.30),.33,.79,"blue")
        star("Crystal glint",(-.48,.20,4.07),.23,"white")
    elif tier=="Radioactive":
        for s in (-1,1):
            barrel(s*1.24,.64,0)
            for z in (2.46,2.73,3.0):
                box("Glow vent",(s*.73,.52,z),(.22,.17,.10),"glow",.035)
        sphere("Hazard medallion",(0,.225,3.54),(.54,.07,.54),"yellow",16,8)
        hazard((0,.144,3.54),.40)
    elif tier=="Demon":
        for s in (-1,1):
            tube("Curved demon horn",[(s*.75,.46,4.12),(s*1.28,.45,4.38),(s*1.37,.49,4.91),(s*1.13,.47,5.17)],[.25,.23,.13,.015],"red",8)
            prism("Demon bat wing",[(s*.98,2.89),(s*1.75,3.44),(s*1.57,2.59),(s*1.25,2.71),(s*1.1,2.29)],.22,"black",.72)
            eye=box("Demon glowing eye",(s*.35,.246,3.66),(.42,.06,.15),"red",.02)
            eye.rotation_euler[1]=s*-.25
        for x in (-.37,0,.37):
            prism("Seat fang",[(x-.1,1.99),(x+.1,1.99),(x,1.63)],.14,"cream",-1.43)
    elif tier=="Galaxy":
        torus("Orbital ring",(0,.40,3.48),1.48,.075,"cyan",rotation=(math.radians(64),math.radians(20),math.radians(-16)),segments=32)
        for x,z,r in [(-.37,3.82,.18),(.35,3.20,.15),(.18,4.18,.13),(-.24,3.40,.08)]:
            star("Lid constellation",(x,.227,z),r,"goldLight",5)
        sphere("Orbit planet",(1.34,.10,4.18),(.24,)*3,"pink",12,8)
        torus("Cosmic foot ring",(0,.04,.33),.88,.09,"cyan")


def baby():
    bowl("white","pink","water",simple=True)
    # Keep the bowl small enough that the baby, not the plumbing, dominates.
    for obj in list(bpy.context.scene.objects):
        obj.scale*=.55
        obj.location*=.55
    sphere("Baby head",(0,-.03,1.61),(.63,.54,.65),"peach",14,8)
    for s in (-1,1):
        sphere("Baby ear",(s*.61,-.03,1.60),(.14,.11,.18),"peach",8,5)
        sphere("Baby hand on rim",(s*.53,-.47,1.20),(.20,.18,.18),"peach",8,5)
        sphere("Rosy cheek",(s*.40,-.474,1.45),(.12,.034,.08),"pink",8,5)
    eyes(.24,-.511,1.72,.185)
    sphere("Tiny nose",(0,-.586,1.53),(.08,.09,.08),"peach",10,6)
    sphere("Pacifier shield",(0,-.58,1.33),(.26,.06,.17),"cyan",12,6)
    torus("Pacifier handle",(0,-.67,1.29),.12,.035,"goldLight",rotation=(math.pi/2,0,0),segments=16)
    tube("Baby hair curl",[(-.16,-.03,2.20),(0,-.04,2.35),(.16,-.04,2.29),(.09,-.04,2.20)],[.065,.055,.045,.017],"brown",8)


def alien():
    bowl("purple","lime","cyan",simple=True)
    sphere("Alien toilet lid head",(0,.51,3.20),(1.03,.28,1.09),"lime",14,8)
    for s in (-1,1):
        eye=sphere("Alien almond eye",(s*.40,.24,3.34),(.29,.06,.43),"black",12,8)
        eye.rotation_euler[1]=s*-.30
        sphere("Alien eye shine",(s*.38,.181,3.52),(.08,.025,.10),"white",8,4)
        tube("Alien antenna",[(s*.60,.53,4.03),(s*.95,.52,4.50)],[.075,.045],"green",8)
        sphere("Antenna bulb",(s*.95,.52,4.51),(.20,)*3,"cyan",8,6)
    smile((0,.19,2.85),.22)
    torus("UFO bowl belt",(0,-.17,1.70),1.22,.12,"cyan",scale=(1,1.15,1))
    for x in (-.60,0,.60):
        y=-.17-math.sqrt(1.22**2-x*x)*1.15-.13
        sphere("UFO light",(x,y,1.72),(.12,.06,.12),"pink",10,6)


def mystery():
    sphere("Dark mystery orb",(0,0,1.04),(1,1,1),"black",20,12)
    torus("Mystery halo",(0,.15,1.04),1.19,.055,"violet",rotation=(math.pi/2,0,.16),segments=32)
    # A chunky curved question mark made of an actual closed tube.
    pts=[(-.35,-.94,1.47),(-.34,-.98,1.68),(-.12,-1.0,1.81),(.17,-1.0,1.78),(.35,-.98,1.59),(.31,-1.02,1.36),(.07,-1.04,1.19),(0,-1.055,.99)]
    tube("Question mark",pts,[.105]*len(pts),"cyan",8)
    sphere("Question dot",(0,-1.01,.65),(.115,.10,.115),"pink",12,6)
    star("Unknown sparkle",(-1.09,-.1,1.85),.20,"cyan")
    star("Unknown sparkle small",(1.10,-.1,.38),.15,"pink")


def crystal(loc,radius,height,color="cyan"):
    x,y,z=loc
    verts=[]
    n=6
    for zz,r in [(z,radius*.80),(z+height*.65,radius),(z+height,radius*.08)]:
        verts.extend((x+r*math.cos(j*math.tau/n),y+r*math.sin(j*math.tau/n),zz) for j in range(n))
    faces=[tuple(reversed(range(n))),tuple(range(2*n,3*n))]
    for i in range(2):
        faces.extend((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j) for j in range(n))
    return mesh("Crystal prism",verts,faces,color)


def hazard(loc,radius):
    x,y,z=loc
    sphere("Hazard center",loc,(radius*.20,.035,radius*.20),"ink",10,6)
    for i in range(3):
        a=math.pi/2+i*math.tau/3
        outline=[]
        for r,theta in [(radius*.34,a-.50),(radius,a-.50),(radius,a+.50),(radius*.34,a+.50)]:
            outline.append((x+r*math.cos(theta),z+r*math.sin(theta)))
        prism("Radiation trefoil",outline,.04,"ink",y)


def barrel(x,y,z):
    cylinder("Hazard barrel",(x,y,z+.63),.39,1.26,"lime",16)
    for zz in (.14,1.13):
        torus("Barrel hoop",(x,y,z+zz),.38,.05,"ink",segments=16)
    sphere("Barrel warning badge",(x,y-.39,z+.65),(.24,.032,.25),"yellow",10,6)
    hazard((x,y-.426,z+.65),.19)


def leaf(name,origin,length,width,angle=0,color="green",drop=.35):
    # Thick, folded leaf with a curved central ridge, closed underneath.
    origin=Vector(origin)
    verts=[]
    for lower in (False,True):
        for i in range(6):
            t=i/5
            w=width*(math.sin(math.pi*t)*.95+.035)
            z=math.sin(math.pi*t)*length*.13-drop*t*t
            for side in (-1,0,1):
                local=Vector((t*length,side*w,z+(w*.18 if side==0 else 0)-(.08 if lower else 0)))
                rot=Vector((local.x*math.cos(angle)-local.y*math.sin(angle),local.x*math.sin(angle)+local.y*math.cos(angle),local.z))
                verts.append(origin+rot)
    faces=[]
    for i in range(5):
        for j in range(2):
            a=i*3+j
            faces.extend([(a,a+3,a+4,a+1),(a+18,a+19,a+22,a+21)])
        for j in (0,2):
            a=i*3+j
            faces.append((a,a+18,a+21,a+3))
    faces.extend([(0,1,19,18),(1,2,20,19),(15,33,34,16),(16,34,35,17)])
    return mesh(name,verts,faces,color)


def palm():
    trunk_points=[Vector(p) for p in [(0,0,0),(-.12,.04,1.5),(.07,.12,3.0),(.42,.16,4.4),(.61,.16,5.8)]]
    trunk_radii=[.42,.37,.31,.27,.23]
    tube("Curving palm trunk",trunk_points,trunk_radii,"wood",10)
    for i in range(8):
        z=.4+i*.66
        j=next(j for j in range(4) if trunk_points[j].z<=z<=trunk_points[j+1].z)
        t=(z-trunk_points[j].z)/(trunk_points[j+1].z-trunk_points[j].z)
        center=trunk_points[j].lerp(trunk_points[j+1],t)
        radius=trunk_radii[j]*(1-t)+trunk_radii[j+1]*t
        ring=torus("Trunk growth ring",center,radius+.02,.04,"woodLight",segments=10,sides=4)
        ring.rotation_euler=(trunk_points[j+1]-trunk_points[j]).to_track_quat("Z","Y").to_euler()
    for i in range(8):
        leaf("Palm frond",(.61,.16,5.72),3.0+(i%2)*.55,.51,i*math.tau/8,"green" if i%2 else "lime",.91)
    for x,y in [(.32,-.17),(.86,-.13),(.60,.48)]:
        sphere("Coconut",(x,y,5.37),(.30,.30,.36),"brown",10,6)


def bush():
    for x,y,z,s,c in [(0,0,.68,.92,"green"),(-.65,-.10,.51,.68,"leaf"),(.66,.07,.53,.72,"green"),(.06,.18,1.04,.64,"lime"),(.20,-.55,.54,.60,"green")]:
        sphere("Bush puff",(x,y,z),(s,s*.83,s*.81),c,12,8)
    for x,y,z in [(-.57,-.57,.89),(.52,-.52,.97),(.11,-.70,.56)]:
        sphere("Berry",(x,y,z),(.10,)*3,"pink",8,6)


def flowers():
    for x,y,h,c in [(-.72,.02,1.04,"pink"),(.10,.24,1.47,"violet"),(.78,-.07,.93,"orange")]:
        tube("Flower stem",[(x,y,0),(x+.06,y,h)],[.045,.045],"green",6)
        leaf("Flower leaf",(x,y,h*.32),.49,.15,.3,"lime",-.1)
        for i in range(5):
            a=i*math.tau/5
            sphere("Flower petal",(x+math.cos(a)*.27,y-.03,h+math.sin(a)*.27),(.23,.10,.24),c,10,6)
        sphere("Flower center",(x,y-.14,h),(.18,.09,.18),"yellow",10,6)


def bench():
    for x in (-1.64,1.64):
        for y in (-.53,.53):
            box("Bench leg",(x,y,.63),(.22,.24,1.26),"teal",.065)
        box("Back post",(x,.63,1.60),(.22,.24,2.15),"teal",.06)
        box("Arm support",(x,-.39,1.63),(.17,.19,.58),"teal",.045)
        box("Arm rest",(x,0,1.95),(.29,1.55,.19),"woodLight",.09)
    for y in (-.47,0,.47):
        box("Seat plank",(0,y,1.29),(3.84,.42,.19),"woodLight",.065)
    for z in (1.89,2.40):
        box("Back plank",(0,.66,z),(3.84,.22,.42),"wood",.065)
        for x in (-1.62,1.62):
            sphere("Bolt",(x,.532,z),(.055,.025,.055),"gold",8,4)


def lamp():
    cylinder("Lamp foot",(0,0,.16),.57,.32,"navy",16)
    cylinder("Lamp post",(0,0,2.21),.17,4.10,"teal",12)
    torus("Post collar",(0,0,3.96),.23,.09,"gold")
    box("Lantern base",(0,0,4.20),(1.02,1.02,.19),"navy",.09)
    box("Warm lamp lens",(0,0,4.78),(.76,.76,1.07),"goldLight",.13)
    for x in (-.43,.43):
        for y in (-.43,.43):
            box("Lantern frame",(x,y,4.79),(.11,.11,1.20),"teal",.03)
    cylinder("Lantern roof",(0,0,5.51),.77,.43,"navy",4,radius_top=.18).rotation_euler.z=math.pi/4
    sphere("Lantern finial",(0,0,5.80),(.15,)*3,"gold",10,6)


def fence():
    for x in (-1.80,1.80):
        box("Fence post",(x,0,1.13),(.35,.40,2.26),"wood",.09)
        sphere("Post cap",(x,0,2.30),(.27,.29,.16),"woodLight",10,6)
    for z in (.58,1.48):
        box("Fence rail",(0,.08,z),(3.76,.24,.24),"wood",.055)
    for x in (-1.12,-.56,0,.56,1.12):
        prism("Rounded picket",[(x-.18,.16),(x+.18,.16),(x+.18,1.76),(x,1.98),(x-.18,1.76)],.25,"woodLight",-.13)
        for z in (.58,1.48):
            sphere("Fence nail",(x,-.273,z),(.041,.025,.041),"brown",8,4)


def trophy():
    toilet("Golden")
    crown((0,.49,4.73),.86,.83)
    # Statue plinth is below the shared toilet shape.
    for obj in list(bpy.context.scene.objects):
        obj.location.z+=.65
    cylinder("Trophy plinth",(0,0,.28),1.57,.56,"navy",8)
    cylinder("Trophy plinth gold trim",(0,0,.60),1.51,.15,"goldLight",8)
    star("Trophy plinth crest",(0,-1.43,.30),.19,"gold",5)


def signboard():
    for x in (-1.56,1.56):
        box("Sign post",(x,.12,1.20),(.26,.29,2.40),"wood",.07)
        sphere("Sign post cap",(x,.12,2.50),(.22,)*3,"gold",10,6)
    box("Thick sign frame",(0,0,2.17),(3.91,.34,1.58),"woodLight",.17)
    box("Blank text panel",(0,-.191,2.17),(3.47,.09,1.18),"navy",.13)
    for s in (-1,1):
        star("Frame star",(s*1.70,-.26,2.18),.115,"gold",5)


def pedestal():
    cylinder("Pedestal foot",(0,0,.16),1.06,.32,"navy",16)
    cylinder("Pedestal column",(0,0,.63),.89,.76,"purple",16,radius_top=.95)
    cylinder("Display pad",(0,0,1.05),1.12,.21,"navy",24)
    torus("Glowing item slot",(0,0,1.18),.87,.095,"cyan",segments=32)
    cylinder("Inset slot",(0,0,1.145),.77,.05,"teal",24)
    box("Pedestal label plaque",(0,-.87,.68),(1.05,.12,.35),"ink",.055)


def clouds():
    for x,y,z,scale in [(-1.45,0,.42,(.73,.57,.48)),(-.58,.12,.68,(.86,.69,.70)),(.35,0,.79,(1.0,.75,.88)),(1.37,.07,.50,(.80,.61,.54))]:
        sphere("Cloud puff",(x,y,z),scale,"white",14,8)


def portal():
    for s in (-1,1):
        box("Portal foot",(s*2.26,0,.23),(1.13,1.30,.46),"navy",.16)
    pts=[(-2.26,0,.44),(-2.26,0,3.79),(-1.89,0,4.89),(-1.06,0,5.62),(0,0,5.86),(1.06,0,5.62),(1.89,0,4.89),(2.26,0,3.79),(2.26,0,.44)]
    tube("Chunky portal arch",pts,[.36]*len(pts),"purple",8)
    glow=[(x,-.34,z) for x,y,z in pts]
    tube("Portal luminous trim",glow,[.105]*len(glow),"cyan",6)
    star("Gate keystone",(0,-.41,5.87),.39,"goldLight",5)
    for s in (-1,1):
        for z in (1.40,2.30,3.20):
            outline=[(s*2.42,z-.17),(s*2.23,z+.02),(s*2.42,z+.20),(s*2.25,z+.36),(s*1.87,z+.02),(s*2.25,z-.34)]
            prism("Directional chevron",outline,.13,"goldLight",-.42)


def rocks():
    for x,y,z,scale in [(-.92,.17,.58,(.82,.66,.58)),(-.18,-.49,.30,(.56,.49,.30)),(1.03,.33,.37,(.58,.49,.37))]:
        sphere("Faceted candy rock",(x,y,z),scale,"slate",8,5,False)
    for loc,r,h,c in [((.03,.22,0),.37,1.88,"cyan"),((.68,.24,0),.28,1.21,"violet"),((.12,-.31,0),.23,.91,"ice")]:
        crystal(loc,r,h,c)


def foliage():
    for angle,length,width,c in [(-.40,3.35,.65,"leaf"),(.30,3.72,.74,"green"),(.96,3.08,.59,"lime"),(1.70,2.81,.60,"green"),(2.70,2.52,.51,"leaf")]:
        leaf("Oversized foreground leaf",(0,0,.25),length,width,angle,c,-1.65)
        tube("Leaf stem",[(0,0,.06),(.5*math.cos(angle),.5*math.sin(angle),.36)],[.085,.065],"lime",6)


ASSET_SPECS = [
    ("Poop","items",lambda:poop(),2.45),
    ("ToiletPaper","items",paper,2.40),
    ("Rat","items",rat,2.70),
    ("Fish","items",fish,2.70),
    ("RubberDuck","items",duck,2.50),
    ("GoldenPoop","items",lambda:poop("gold"),2.45),
    ("ToiletBaby","items",baby,2.70),
    ("SewerShark","items",lambda:fish(True),3.0),
    ("KingPoop","items",lambda:poop("gold",True),3.0),
    ("AlienToilet","items",alien,3.0),
    ("Mystery","items",mystery,2.80),
] + [(tier+"Toilet","toilets",lambda t=tier:toilet(t),None) for tier in ("Basic","Dirty","Golden","Diamond","Radioactive","Demon","Galaxy")] + [
    ("PalmTree","props",palm,None),
    ("RoundBush","props",bush,None),
    ("FlowerPack","props",flowers,None),
    ("Bench","props",bench,None),
    ("LampPost","props",lamp,None),
    ("WoodenFence","props",fence,None),
    ("GoldenTrophy","props",trophy,9.0),
    ("PlotSignboard","props",signboard,None),
    ("DisplayPedestal","props",pedestal,None),
    ("CloudPuffs","props",clouds,None),
    ("PortalGate","props",portal,None),
    ("RocksCrystals","props",rocks,None),
    ("ForegroundFoliage","props",foliage,None),
]
