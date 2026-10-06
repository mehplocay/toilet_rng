"""Wave 1 group T. Read-only reuse of the original toy palette and bowl.

All coordinates are stud-valued, Z-up / front -Y. The entry script applies the
original toilet foot datum (0, .04, 0), without bounding-box normalization.
"""
import math

import bpy
from lib import box, sphere, cylinder, torus, tube, lathe, prism, star, eyes, mesh, finish
from builders import bowl, crystal


def recolor(name, color):
    finish(bpy.data.objects[name], color)


def core(body="white", seat="white", lid="white", inset="cream", tank=None,
         foot=None, pedestal=None, handle=True):
    bowl(body, seat, "cyan")
    if foot:
        recolor("Broad foot", foot)
    if pedestal:
        recolor("Flared pedestal", pedestal)
    box("Cistern", (0, .91, 2.87), (1.89, .70, 1.69), tank or body, .19)
    box("Cistern lid", (0, .90, 3.73), (2.05, .83, .20), seat, .09)
    sphere("Raised lid", (0, .49, 3.48), (1.015, .18, 1.31), lid, 20, 12)
    sphere("Lid inset", (0, .309, 3.48), (.83, .047, 1.12), inset, 16, 10)
    for s in (-1, 1):
        cylinder("Hinge", (s*.68, .44, 2.18), .13, .29, seat, 12).rotation_euler.y = math.pi/2
    if handle:
        box("Flush lever", (.98, .43, 3.26), (.49, .15, .16), "ice", .04)


def coral():
    core(seat="cream", lid="teal", inset="teal", tank="ice", handle=False)
    # Five overlapping lobes turn the oval into a broad scallop shell.
    for a in (-64, -32, 0, 32, 64):
        t = math.radians(a)
        x, z = .80*math.sin(t), 3.68+.98*math.cos(t)
        sphere("Shell scallop", (x, .46, z), (.27, .17, .26), "teal", 10, 6)
    for s in (-1, 1):
        tube("Silver shell ridge", [(s*.15, .22, 2.65), (s*.51, .22, 3.34),
                                    (s*.66, .28, 4.12), (s*.43, .37, 4.55)],
             [.065, .075, .065, .04], "gray", 6)
        # Three blunt tips per arm, attached to a single thick trunk.
        tube("Coral arm trunk", [(s*.80, .52, 1.38), (s*1.26, .30, 2.05),
                                  (s*1.38, -.05, 2.62)], [.24, .22, .17], "orange", 8)
        tips = [(s*1.63, -.26, 3.10), (s*1.23, -.40, 3.37), (s*.96, -.06, 2.99)]
        for tip in tips:
            tube("Thick coral branch", [(s*1.34, -.06, 2.54), tip], [.16, .12], "orange", 8)
            sphere("Rounded coral tip", tip, (.13,)*3, "orange", 8, 4)
    for x in (-.72, 0, .72):
        sphere("Cream pearl tank knob", (x, .98, 3.96), (.19,)*3, "cream", 10, 6)
    sphere("Cyan shell medallion", (0, .225, 3.36), (.31, .08, .38), "cyan", 12, 8)


def cloud():
    core(seat="ice", lid="ice", inset="ice", tank="blue", handle=False)
    for x, y, z, sx in [(-.88, .03, .40, .77), (0, -.32, .45, .90), (.88, .03, .40, .77)]:
        sphere("Broad cloud foot lobe", (x, y, z), (sx, .73, z), "white", 12, 6)
    for x, z in [(-.98, 3.03), (.98, 3.03), (-.65, 3.70), (.65, 3.70)]:
        box("Stepped raincloud tank", (x, .95, z), (.66, .67, .60), "blue", .18)
    for x, z, r in [(-.38, 3.64, .31), (0, 3.82, .40), (.38, 3.64, .31)]:
        sphere("Smiling cloud applique", (x, .22, z), (r, .105, r), "white", 10, 6)
    sphere("Cloud applique lower puff", (0, .22, 3.51), (.50, .11, .16), "white", 10, 6)
    for s in (-1, 1):
        tube("Peaceful closed eye", [(s*.20-.10+i*.05, .086, 3.65+.045*math.sin(i*math.pi/4))
                                     for i in range(5)], [.026]*5, "ink", 5)
    tube("Cloud smile", [(-.10+i*.05, .077, 3.51-.045*math.sin(i*math.pi/4))
                         for i in range(5)], [.025]*5, "ink", 5)
    tube("Droplet stem", [(1.03, .50, 3.20), (1.31, .40, 3.20)], [.085]*2, "cyan", 8)
    prism("Droplet handle", [(1.30, 3.49), (1.08, 3.15), (1.11, 3.02),
                              (1.30, 2.92), (1.49, 3.02), (1.52, 3.15)], .19, "cyan", .35)
    torus("Gold towel ring", (-1.23, .61, 2.64), .33, .085, "goldLight",
          rotation=(math.pi/2, 0, 0), segments=20, sides=6)
    box("Towel ring bracket", (-1.03, .73, 2.92), (.37, .27, .20), "goldLight", .05)


def clockwork():
    core(seat="cream", lid="woodLight", inset="goldLight", tank="woodLight", foot="gold", handle=False)
    for s in (-1, 1):
        box("Cabinet upright", (s*1.03, .98, 2.94), (.30, .83, 2.0), "gold", .07)
        for z in (3.27, 3.77, 4.27):
            tooth = box("Three chunky gear teeth", (s*1.36, .83, z), (.54, .42, .28), "gold", .065)
            tooth.rotation_euler.y = s*(z-3.77)*.55
    box("Cabinet cornice", (0, .95, 4.03), (2.46, .86, .23), "goldLight", .06)
    disc = cylinder("Large navy clock disk", (0, .16, 4.15), .96, .18, "navy", 32)
    finish(disc, "navy", False)
    disc.rotation_euler.x = math.pi/2
    torus("Clock gold bezel", (0, .05, 4.15), .94, .09, "gold",
          rotation=(math.pi/2, 0, 0), segments=32, sides=6)
    for a in (0, 90, 180, 270):
        t = math.radians(a)
        tick = box("Clock quarter marker", (.74*math.sin(t), -.06, 4.15+.74*math.cos(t)),
                   (.085, .055, .15), "goldLight", .015)
        tick.rotation_euler.y = t
    tube("Long cream clock hand", [(0, -.11, 4.15), (-.39, -.11, 4.65)], [.065]*2, "cream", 6)
    tube("Short cream clock hand", [(0, -.12, 4.15), (.40, -.12, 4.34)], [.075]*2, "cream", 6)
    sphere("Clock pin", (0, -.17, 4.15), (.13, .06, .13), "orange", 10, 6)
    # Offset at the rear so the plunger remains visible from the standard camera.
    tube("Fixed pendulum shaft", [(1.12, 1.06, 3.51), (1.56, .93, 1.20)], [.07]*2, "wood", 8)
    lathe("Red plunger pendulum", [(.08, 0), (.30, 0), (.32, .13), (.19, .33), (.08, .38)],
          (1.56, .93, .86), "red", segments=16)
    box("Pendulum attachment", (1.09, 1.05, 3.52), (.40, .35, .24), "gold", .05)


def dragon():
    core(body="red", seat="white", lid="red", inset="orange", tank="red", foot="black", pedestal="black", handle=False)
    for x, y in [(-.55, .10), (.55, .10), (0, -.42)]:
        sphere("Black kiln foot lobe", (x, y, .20), (.58, .55, .20), "black", 10, 6)
    for s in (-1, 1):
        shape = [(s*.78, 2.92), (s*1.82, 4.19), (s*1.78, 3.39),
                 (s*1.43, 3.54), (s*1.38, 3.01), (s*1.06, 3.20)]
        prism("Broad ceramic dragon wing", shape, .25, "red", .91)
        tube("Raised wing rib", [(s*.94, .755, 3.13), (s*1.68, .755, 4.00)], [.075, .035], "orange", 6)
    tail = []
    for i in range(13):
        a = -.40 + i*math.pi*1.55/12
        tail.append((1.04*math.cos(a), .10+1.04*math.sin(a), .53+.036*i))
    tube("Orange wrapping dragon tail", tail, [.21-.012*i for i in range(13)], "orange", 8)
    for i in (2, 5, 8, 11):
        x, y, z = tail[i]
        cylinder("Broad tail scale", (x, y, z+.16), .14, .22, "goldLight", 5, radius_top=.025)
    # Head sits proud of the tank, over the lid's top; no face in the bowl.
    sphere("Friendly dragon head", (0, .18, 4.54), (.66, .35, .51), "red", 14, 8)
    sphere("Soft dragon muzzle", (0, -.15, 4.38), (.48, .30, .23), "orange", 12, 6)
    eyes(.28, -.15, 4.73, .235)
    for s in (-1, 1):
        tube("Cream horn", [(s*.45, .22, 4.88), (s*.60, .22, 5.15), (s*.49, .20, 5.30)],
             [.14, .09, .015], "cream", 8)
        sphere("Nostril", (s*.18, -.408, 4.47), (.053, .026, .038), "brown", 8, 4)
    tube("Toothless smile", [(-.27, -.405, 4.34), (0, -.449, 4.28), (.27, -.405, 4.34)], [.035]*3, "ink", 6)


def folded_panel(name, x, width, top, color, lean=0):
    # Solid folded fan wedge: central ridge has depth, not a transparent plane.
    outline = [(x-width*.32, 2.88), (x+width*.32, 2.88),
               (x+width/2+lean, top-.22), (x+lean, top), (x-width/2+lean, top-.14)]
    n = len(outline)
    verts = [(xx, 1.0, z) for xx, z in outline] + [(x+lean*.5, .70, (top+2.88)/2)]
    verts += [(xx, 1.24, z) for xx, z in outline]
    faces = [(i, (i+1)%n, n) for i in range(n)]
    faces += [tuple(range(n+1, 2*n+1))]
    faces += [(i, n+1+i, n+1+(i+1)%n, (i+1)%n) for i in range(n)]
    mesh(name, verts, faces, color)


def aurora():
    core(seat="ice", lid="white", inset="white", tank="gray", foot="gray", handle=False)
    folded_panel("Ice folded fan", -1.02, 1.08, 5.13, "ice", -.28)
    folded_panel("Mint folded fan", 0, 1.10, 5.40, "mint", 0)
    folded_panel("Cyan folded fan", 1.02, 1.08, 4.92, "cyan", .28)
    for s in (-1, 1):
        crystal((s*1.25, .64, 0), .36, 2.75, "blue")
        crystal((s*1.43, .77, 2.38), .27, 1.18, "ice")
    star("Cyan star flush knob", (1.19, .26, 3.40), .28, "cyan", 5)
    box("Star knob stem", (1.03, .46, 3.40), (.32, .23, .14), "gray", .04)


def astral():
    core(seat="ice", lid="white", inset="white", tank="gray", foot="gray", handle=False)
    cylinder("Silver hexagonal plinth", (0, .04, .14), 1.21, .28, "gray", 6)
    for s in (-1, 1):
        shape = [(s*.91, 2.69), (s*1.40, 2.94), (s*1.77, 3.67),
                 (s*1.66, 4.42), (s*1.18, 5.20), (s*.92, 5.31),
                 (s*1.23, 4.39), (s*1.31, 3.76), (s*1.07, 3.26)]
        prism("White crescent column", shape, .34, "white", 1.01)
        box("Stepped silver arm", (s*1.15, .49, 2.55), (.41, .95, .25), "gray", .07)
        box("Silver arm riser", (s*1.09, .81, 2.87), (.31, .31, .65), "gray", .06)
    torus("Supported cyan halo", (0, .87, 5.25), 1.12, .13, "cyan", scale=(1, .61, 1), segments=32, sides=8)
    # Five connected nodes form a constellation rather than a religious symbol.
    points = [(-.42, .233, 3.83), (0, .228, 4.16), (.46, .233, 3.66),
              (.26, .228, 3.13), (-.35, .233, 3.30)]
    tube("Ice constellation inlay", points+[points[0]], [.045]*6, "ice", 6)
    for p in points:
        star("Constellation node", (p[0], p[1]-.035, p[2]), .12, "ice", 5)
    star("White star handle", (1.34, .10, 2.84), .24, "white", 5)


def frame(name, x, y, bottom, top, width, color, thickness=.18, depth=.22):
    # One closed ring mesh, avoiding four overlapping corner blocks.
    outer = [(x-width/2, bottom), (x+width/2, bottom), (x+width/2, top), (x-width/2, top)]
    inner = [(x-width/2+thickness, bottom+thickness), (x+width/2-thickness, bottom+thickness),
             (x+width/2-thickness, top-thickness), (x-width/2+thickness, top-thickness)]
    verts = [(xx, yy, z) for yy in (y-depth/2, y+depth/2) for loop in (outer, inner) for xx, z in loop]
    faces = []
    for i in range(4):
        j = (i+1)%4
        faces += [(i,j,j+4,i+4), (i+8,i+12,j+12,j+8), (i,i+8,j+8,j), (i+4,j+4,j+12,i+12)]
    return mesh(name, verts, faces, color)


def paradox():
    core(body="black", seat="white", lid="black", inset="navy", tank="navy", foot="cream", pedestal="cream", handle=False)
    box("Cream lower step", (0, .04, .12), (1.99, 1.80, .24), "cream", .12)
    box("Cream upper step", (0, .09, .33), (1.53, 1.36, .24), "cream", .10)
    for x, y, bottom, top, width, accent in [(-.29, 1.03, 2.55, 5.40, 3.10, "magenta"),
                                           (.29, .84, 2.82, 5.12, 2.70, "cyan"),
                                           (.27, .64, 3.00, 4.87, 2.18, "magenta")]:
        frame("Offset navy doorway", x,y,bottom,top,width,"navy", .24, .25)
        frame("Bright inset doorway edge", x,y-.145,bottom+.10,top-.10,width-.20,accent,.065,.075)
    for x in (-.93, .93):
        box("Rear joining bracket", (x, 1.05, 3.31), (.28, .92, .28), "navy", .04)
    # Gold plumbing hangs upside down from the smallest top lintel.
    tube("Upside down gold faucet", [(.27, .47, 4.79), (.27, .04, 4.71),
                                    (.27, -.02, 4.42), (.57, -.02, 4.42)], [.11]*4, "gold", 8)
    box("Faucet cross handle", (.27, .02, 4.24), (.54, .17, .12), "goldLight", .055)
    tube("Faucet valve stem", [(.27, .02, 4.42), (.27, .02, 4.23)], [.085]*2, "gold", 8)


def infinity():
    core(seat="white", lid="white", inset="purple", tank="black", foot="black", pedestal="black", handle=False)
    # Hourglass waist retains the unchanged bowl and the original ground datum.
    lathe("Black hourglass pedestal", [(.32,.25),(.79,.25),(.53,.59),(.30,.81),
                                      (.57,1.20),(.66,1.28),(.31,1.28)],
          (0,.10,0), "black", segments=20)
    for s, color in [(-1,"gold"), (1,"cyan")]:
        loop_y = 1.08 if s < 0 else .74
        torus("Crossing infinity ellipse", (s*.82,loop_y,4.68), 1, .14, color,
              scale=(1.02,.65,1), rotation=(math.pi/2,0,0), segments=40, sides=6)
        box("Loop tank anchor", (s*.97, .96, 3.15), (.37, .43, .44), color, .12)
        tube("Attached loop support", [(s*.97,.91,3.15), (s*1.39,loop_y,3.60), (s*1.44,loop_y,4.15)],
             [.14]*3, color, 8)
    for x,z,r in [(-.42,3.88,.16),(.33,4.14,.12),(.34,3.27,.17),(-.31,3.05,.11),(0,3.59,.09)]:
        star("Starfield inset", (x,.232,z), r, "ice" if x<0 else "goldLight", 5)
    box("Purple tank side inset", (1.0,.96,2.90), (.12,.52,.94), "purple", .055)
    for y, z in [(.85, 3.13), (1.08, 2.74)]:
        sparkle = star("Tank inset star", (0,0,0), .105, "ice", 5)
        sparkle.rotation_euler.z = math.pi/2
        sparkle.location = (1.075, y, z)
    tube("Magenta flush lever", [(1.01,.50,3.22),(1.40,.31,3.20),(1.48,.17,3.51)], [.115]*3, "magenta", 8)
    sphere("White glove palm", (1.48,.12,3.66), (.25,.17,.29), "white", 12, 6)
    for x,z in [(1.29,3.83),(1.44,3.94),(1.59,3.92)]:
        sphere("Mitten rounded finger", (x,.13,z), (.11,.145,.19), "white", 8, 5)
    sphere("Glove thumb", (1.72,.08,3.64), (.16,.15,.13), "white", 8, 5)
    torus("Glove cuff", (1.48,.16,3.44), .16,.055,"white",segments=12,sides=4)


BUILDERS = {
    "CoralCommode": coral,
    "CloudCushion": cloud,
    "ClockworkCloset": clockwork,
    "DragonKiln": dragon,
    "AuroraThrone": aurora,
    "AstralAltar": astral,
    "ParadoxPotty": paradox,
    "InfinityFlush": infinity,
}
