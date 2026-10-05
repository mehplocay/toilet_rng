"""Original, chunky UI sculptures for the Blender-only image pipeline."""
import math
import bpy
from mathutils import Vector
import lib


def bevel(obj, width=.055):
    for p in obj.data.polygons:
        p.use_smooth=True
    mod = obj.modifiers.new('Rounded enamel edge', 'BEVEL')
    mod.width, mod.segments = width, 4
    mod = obj.modifiers.new('Weighted highlights', 'WEIGHTED_NORMAL')
    mod.keep_sharp = True
    return obj


def shape(name, points, depth, color, y=0, rounding=.05):
    return bevel(lib.prism(name, points, depth, color, y), rounding)


def text(body, loc, size, color, extrude=.06, bevel_depth=.025, font=None):
    curve = bpy.data.curves.new('Sculpted lettering', 'FONT')
    curve.body, curve.align_x, curve.align_y = body, 'CENTER', 'CENTER'
    curve.size, curve.extrude, curve.bevel_depth = size, extrude, bevel_depth
    curve.bevel_resolution, curve.resolution_u = 4, 16
    if font:
        curve.font = bpy.data.fonts.load(font, check_existing=True)
    obj = bpy.data.objects.new(body, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler.x = math.pi/2
    obj.data.materials.append(lib.icon_material(color))
    return obj


def disc(name, loc, radius, depth, color):
    obj = lib.cylinder(name, loc, radius, depth, color, 64)
    obj.rotation_euler.x = math.pi/2
    return bevel(obj, .035)


def coin():
    disc('Gold coin edge', (0,0,1.3), 1.14, .28, 'orange')
    disc('Gold coin face', (0,-.16,1.3), 1.07, .11, 'gold')
    lib.torus('Raised coin rim', (0,-.245,1.3), .95,.075,'goldLight',rotation=(math.pi/2,0,0))
    text('$',(0,-.30,1.29),1.40,'goldLight',font='C:/Windows/Fonts/arialbd.ttf')
    for j in range(36):
        a=j*math.tau/36
        lib.sphere('Milled coin edge',(1.10*math.cos(a),0,1.3+1.10*math.sin(a)),(.03,.12,.03),'gold')


def shop():
    shape('Red basket front',[(-.90,.26),(.90,.26),(1.13,1.49),(-1.13,1.49)],.16,'red',-.52)
    shape('Red basket back',[(-.90,.26),(.90,.26),(1.13,1.49),(-1.13,1.49)],.16,'red',.52)
    lib.box('Basket floor',(0,0,.28),(1.78,1.10,.20),'red')
    for s in (-1,1):
        lib.box('Basket side',(s*.97,0,.86),(.16,1.1,1.1),'red')
        lib.box('Rim side',(s*1.07,0,1.49),(.19,1.27,.19),'pink')
    for y in (-.56,.56):
        lib.box('Rolled basket lip',(0,y,1.49),(2.31,.19,.19),'pink')
    for x in (-.65,-.22,.22,.65):
        lib.box('Basket slot',(x,-.610,.85),(.16,.018,.56),'basketSlot',.065)
    lib.tube('Raised navy handle',[(-.94,0,1.52),(-.90,0,2.30),(-.67,0,2.46),(.67,0,2.46),(.90,0,2.30),(.94,0,1.52)],[.105]*6,'ink',16)
    lib.box('Soft handle grip',(0,0,2.45),(1.08,.26,.26),'ice')


def collection():
    lib.box('Ivory page block',(.07,-.04,1.3),(1.69,.51,2.09),'cream',.10)
    for y in (-.34,.30):
        lib.box('Blue hard cover',(0,y,1.3),(1.95,.15,2.40),'blue',.10)
    lib.box('Rounded spine',(-.86,0,1.3),(.27,.76,2.40),'navy',.12)
    shape('Bookmark ribbon',[(.40,.45),(.72,.45),(.72,-.11),(.56,.02),(.40,-.11)],.06,'gold',-.32)
    bevel(lib.star('Collection cover star',(.05,-.46,1.48),.60,'ice',5),.035)
    for z in (.60,.69,.78):
        lib.box('Page stripe',(.22,-.307,z),(1.2,.014,.014),'woodLight',0)


def upgrades():
    points=[(-.48,.13),(.48,.13),(.48,1.34),(1.06,1.34),(0,2.54),(-1.06,1.34),(-.48,1.34)]
    shape('Emerald up arrow',points,.48,'green',rounding=.10)
    shape('Arrow glossy inset',[(-.27,.38),(.27,.38),(.27,1.55),(.56,1.55),(0,2.18),(-.56,1.55),(-.27,1.55)],.04,'lime',-.27,.035)


def daily():
    lib.box('Calendar body',(0,0,1.30),(2.04,.46,2.18),'white',.16)
    lib.box('Cherry calendar header',(0,-.08,2.09),(2.08,.48,.61),'red',.15)
    for x in (-.62,.62):
        lib.torus('Calendar binder',(x,0,2.40),.23,.085,'ink',rotation=(math.pi/2,0,0))
    for x in (-.58,0,.58):
        for z in (.55,1.05,1.52):
            lib.box('Calendar day',(x,-.25,z),(.31,.07,.27),'ice',.07)
    bevel(lib.star('Reward day',(.08,-.39,1.04),.55,'gold',5),.055)


def home():
    lib.box('House body',(0,0,1.03),(1.87,1.08,1.74),'blue',.13)
    shape('Thick cobalt roof',[(-1.25,1.60),(0,2.78),(1.25,1.60),(.99,1.35),(0,2.30),(-.99,1.35)],1.37,'navy',rounding=.07)
    shape('Sky blue gable',[(-.94,1.58),(0,2.40),(.94,1.58)],1.04,'cyan')
    lib.box('Door frame',(0,-.59,.66),(.70,.15,1.17),'navy',.08)
    lib.box('Door',(0,-.68,.64),(.46,.07,.93),'ice',.06)
    lib.sphere('Door knob',(.13,-.76,.64),(.055,)*3,'gold')
    lib.box('Chimney',(.69,.23,2.26),(.33,.35,.74),'blue',.055)


def hub():
    lib.box('Trophy podium',(0,0,.20),(1.55,1.06,.40),'navy',.15)
    lib.box('Gold podium cap',(0,0,.44),(1.41,.97,.15),'goldLight',.05)
    lib.cylinder('Trophy stem',(0,0,.83),.19,.73,'gold')
    lib.lathe('Golden trophy cup',[(.19,1.02),(.52,1.17),(.72,1.70),(.77,2.10),(.65,2.10),(.58,1.73),(.40,1.37),(.18,1.28)],(0,0,0),'gold')
    lib.torus('Cup rolled rim',(0,0,2.10),.72,.075,'goldLight')
    for s in (-1,1):
        lib.torus('Trophy handle',(s*.74,0,1.70),.39,.10,'gold',rotation=(math.pi/2,0,0))
    bevel(lib.star('Victory crest',(0,-.69,1.69),.28,'goldLight',5),.025)


def teleport():
    lib.torus('Portal dark frame',(0,0,1.43),1.02,.24,'navy',rotation=(math.pi/2,0,0))
    lib.torus('Violet portal rim',(0,-.11,1.43),1.01,.15,'purple',rotation=(math.pi/2,0,0))
    lib.torus('Cyan energy ring',(0,-.23,1.43),.91,.075,'cyan',rotation=(math.pi/2,0,0))
    disc('Portal surface',(0,.06,1.43),.88,.07,'purple')
    for j in range(3):
        a=j*2.1
        pts=[(.12*math.cos(a+t)*t,-.15,1.43+.12*math.sin(a+t)*t) for t in [i*.12 for i in range(56)]]
        lib.tube('Portal spiral',pts,[.035]*len(pts),'violet',10)
    for s in (-1,1):
        lib.box('Portal foot',(s*.82,0,.24),(.67,.71,.32),'navy')
    bevel(lib.star('Portal sparkle',(.71,-.35,2.33),.25,'white'),.025)


def settings():
    lib.torus('Gear hub',(0,0,1.35),.68,.33,'gray',rotation=(math.pi/2,0,0))
    for i in range(8):
        a=i*math.tau/8
        o=lib.box('Gear tooth',(math.sin(a)*.99,0,1.35+math.cos(a)*.99),(.49,.50,.53),'gray',.09)
        o.rotation_euler.y=a
    lib.torus('Inset gear bevel',(0,-.30,1.35),.44,.075,'ice',rotation=(math.pi/2,0,0))


def flush():
    disc('Flush plate',(0,.08,1.32),1.08,.31,'navy')
    disc('Chrome inset',(0,-.11,1.32),.92,.20,'ice')
    disc('Lever hub',(-.31,-.27,1.35),.31,.25,'gray')
    lib.box('Chunky flush handle',(.26,-.48,1.45),(1.38,.35,.42),'white',.18)
    lib.box('Blue handle inset',(.39,-.667,1.49),(.66,.035,.13),'cyan',.055)


def luck():
    lib.tube('Clover stem',[(.10,0,1.18),(.23,0,.51),(.03,0,.03)],[.12,.10,.065],'leaf')
    for i in range(4):
        a=i*math.pi/2
        # Heart lobes meet at a shared center; four hearts, eight rounded lobes.
        points=[]
        for j in range(64):
            t=j*math.tau/64
            x=.032*(16*math.sin(t)**3)
            z=.032*(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))+.46
            points.append((x*math.cos(a)-z*math.sin(a),1.39+x*math.sin(a)+z*math.cos(a)))
        shape('Heart clover leaf',points,.28,'green' if i%2 else 'lime',rounding=.08)
    lib.sphere('Clover center',(0,-.20,1.39),(.19,.10,.19),'lime')


def crown():
    lib.crown((0,0,.43),1.00,1.31)
    for s in (-1,1):
        lib.sphere('Side emerald',(s*.59,-.83,.81),(.13,.08,.16),'cyan')


def passes():
    points=[(-1.13,.45),(-.90,.45),(-.83,.63),(-.66,.68),(-.49,.63),(-.42,.45),(1.13,.45),(1.13,2.10),(.42,2.10),(.35,1.92),(.18,1.87),(.01,1.92),(-.06,2.10),(-1.13,2.10)]
    shape('VIP golden ticket',points,.32,'gold',rounding=.065)
    lib.box('Ticket inset',(0,-.18,1.27),(1.92,.08,1.24),'orange',.12)
    bevel(lib.star('Pass star',(-.15,-.30,1.28),.55,'goldLight',5),.055)
    for z in (.84,1.10,1.36,1.62):
        lib.box('Ticket perforation',(.71,-.245,z),(.045,.025,.12),'goldLight',.012)


def pointer():
    outline=[(-.38,.08),(.56,.08),(.78,.42),(.85,.93),(.79,1.43),(.66,1.54),(.52,1.49),(.45,1.66),(.31,1.70),(.18,1.60),(.09,1.79),(-.06,1.84),(-.22,1.71),(-.24,2.63),(-.32,2.78),(-.51,2.81),(-.67,2.67),(-.65,1.04),(-.96,1.32),(-1.13,1.34),(-1.26,1.17),(-1.23,1.02),(-.66,.37)]
    shape('White cartoon pointing glove',outline,.37,'white',rounding=.105)
    lib.box('Cuff',(.09,-.01,.12),(1.05,.47,.38),'ice',.10)
    for x,z in [(.11,1.35),(.40,1.25),(.64,1.12)]:
        lib.tube('Finger crease',[(x,-.205,z),(x+.025,-.214,z-.27)],[.019,.015],'gray',8)


def lock():
    lib.torus('Lock shackle',(0,0,1.83),.65,.18,'ice',rotation=(math.pi/2,0,0))
    lib.box('Gold lock body',(0,-.07,.99),(1.92,.71,1.49),'gold',.23)
    # One continuous face avoids coplanar overlap at the round/stem junction.
    keyhole=[(.10,1.02),(.16,.67),(-.16,.67),(-.10,1.02)]
    for i in range(41):
        a=math.radians(235-i*290/40)
        keyhole.append((.18*math.cos(a),1.15+.18*math.sin(a)))
    shape('Keyhole',keyhole,.045,'ink',-.46,.012)


def check():
    shape('Success check',[(-1.08,1.23),(-.75,1.57),(-.23,1.02),(.92,2.27),(1.27,1.94),(-.23,.31)],.39,'green',rounding=.11)


def gem():
    # A wide brilliant-cut gem, with intentionally crisp alternating facets.
    verts=[(-.63,0,2.25),(.63,0,2.25),(1.05,0,1.65),(0,0,.23),(-1.05,0,1.65),(-.53,-.43,1.65),(.53,-.43,1.65),(0,-.42,2.25)]
    faces=[(0,7,5,4),(7,1,2,6),(7,6,5),(4,5,3),(5,6,3),(6,2,3),(0,4,3,2,1)]
    o=lib.mesh('Faceted magic gem',verts,faces,'magenta')
    for c in ('pink','purple','violet','ice'):
        o.data.materials.append(lib.icon_material(c))
    for i,p in enumerate(o.data.polygons):
        p.material_index=[1,2,3,2,0,3,2][i]
    bevel(o,.025)
    bevel(lib.star('Gem sparkle',(.61,-.49,2.20),.24,'white'),.02)


def auto_flush():
    for j,color in enumerate(('cyan','blue')):
        a0=math.pi*.14+j*math.pi
        angles=[a0+i*math.pi*.70/40 for i in range(41)]
        outer=[(1.04*math.cos(a),1.39+1.04*math.sin(a)) for a in angles]
        inner=[(.75*math.cos(a),1.39+.75*math.sin(a)) for a in reversed(angles)]
        shape('Circular flush arrow',outer+inner,.27,color,rounding=.045)
        a=angles[-1]
        tip=Vector((.9*math.cos(a),1.39+.9*math.sin(a)))
        tangent=Vector((-math.sin(a),math.cos(a)))
        normal=Vector((math.cos(a),math.sin(a)))
        shape('Arrow head',[tip+tangent*.45,tip-tangent*.20+normal*.34,tip-tangent*.20-normal*.34],.31,color,rounding=.055)
    shape('Water droplet',[(0,1.98),(-.40,1.35),(-.34,1.02),(0,.86),(.34,1.02),(.40,1.35)],.36,'ice',-.18,.12)


def offer_burst():
    pts=[]
    for i in range(24):
        a=math.pi/2+i*math.tau/24
        r=1.23 if i%2==0 else .93
        pts.append((r*math.cos(a),1.35+r*math.sin(a)))
    shape('Offer star sticker',pts,.22,'gold',rounding=.025)
    text('OP!',(0,-.19,1.40),1.05,'red',font='C:/Windows/Fonts/arialbd.ttf')


UI = {'Coin':coin,'Shop':shop,'Collection':collection,'Upgrades':upgrades,
      'Daily':daily,'Home':home,'Hub':hub,'Teleport':teleport,'Settings':settings,
      'Flush':flush,'Luck':luck,'Crown':crown,'Passes':passes,'Pointer':pointer,
      'Lock':lock,'Check':check,'Gem':gem,'AutoFlush':auto_flush,'OfferBurst':offer_burst}
