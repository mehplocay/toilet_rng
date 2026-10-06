"""Original shop sculptures. Shared enamel, camera and outline come from render_icons."""
import math
import random
import bpy
from mathutils import Vector
import lib
import builders
import icon_models as ui

FONT = 'C:/Windows/Fonts/arialbd.ttf'


def group(build, loc=(0, 0, 0), scale=1, tilt=0):
    before = set(bpy.context.scene.objects)
    build()
    parent = bpy.data.objects.new('Shop sculpture placement', None)
    bpy.context.collection.objects.link(parent)
    created=set(bpy.context.scene.objects) - before - {parent}
    for obj in created:
        if obj.parent not in created:
            obj.parent = parent
    parent.location = loc
    parent.scale = (scale,) * 3
    parent.rotation_euler.y = math.radians(tilt)
    return parent


def sparkle(x, z, size=.19, color='white', y=-.40):
    ui.bevel(lib.star('Polished sparkle', (x, y, z), size, color), .018)


def label(body, loc, size, color='white'):
    return ui.text(body, loc, size, color, .035, .015, FONT)


def badge(body, x, z, width=1.02, color='navy', y=-.90):
    lib.box('Quantity badge dark edge', (x, y, z), (width, .20, .68), 'ink', .16)
    lib.box('Quantity badge enamel', (x, y-.11, z), (width-.10, .08, .56), color, .12)
    label(body, (x, y-.19, z), .52)


def nameplate(golden=False):
    lib.box('Nameplate dark edge', (0, 0, 1.2), (2.8, .38, 1.30), 'ink', .24)
    lib.box('Nameplate rim', (0, -.13, 1.2), (2.67, .23, 1.17), 'gold' if golden else 'violet', .20)
    lib.box('Nameplate face', (0, -.26, 1.2), (2.44, .12, .95), 'goldLight' if golden else 'navy', .16)
    if golden:
        label('NAME', (0, -.36, 1.21), .64, 'brown')
        sparkle(-1.12, 1.94, .23, 'goldLight')
        sparkle(1.13, .53, .18)
    else:
        for x, char, color in zip((-.78, -.27, .26, .77), 'NAME', ('red', 'yellow', 'mint', 'cyan')):
            label(char, (x, -.37, 1.21), .66, color)
        for i, color in enumerate(('red', 'orange', 'yellow', 'green', 'blue', 'magenta')):
            lib.box('Rainbow edge jewel', (-.95+i*.38, -.30, .65), (.33, .08, .12), color, .04)
        sparkle(-1.22, 1.94, .20, 'ice')
        sparkle(1.25, .53, .18, 'pink')


def confetti():
    def popper():
        lib.cylinder('Party cone', (0, 0, .60), .12, 1.2, 'magenta', radius_top=.52)
        for z, r in ((.38, .25), (.73, .37), (1.07, .48)):
            lib.torus('Gold party stripe', (0, 0, z), r, .055, 'goldLight')
        lib.cylinder('Popper opening', (0, 0, 1.22), .45, .05, 'purple')
        lib.torus('Popper lip', (0, 0, 1.23), .49, .07, 'pink')
    group(popper, (-.50, 0, .10), 1, 30)
    for i, (x, z, color) in enumerate(((-.73, 2.14, 'cyan'), (.18, 2.44, 'gold'), (.88, 2.1, 'pink'), (1.22, 1.36, 'cyan'), (-.96, 1.54, 'lime'), (.78, 2.75, 'violet'))):
        obj = lib.box('Flying confetti', (x, -.02, z), (.20, .10, .31), color, .035)
        obj.rotation_euler.y = .5+i*.6
    for x, z, color in ((-.30, 2.00, 'gold'), (.55, 1.80, 'cyan')):
        pts = [(x+.14*math.sin(t*5), -.16, z+t*.62) for t in [j/24 for j in range(25)]]
        lib.tube('Curled streamer', pts, [.042]*len(pts), color)
    sparkle(1.02, 2.65, .19)


def dance():
    # A dancing eighth-note pair with broad glossy note heads.
    for x, z in ((-.64, .51), (.66, .84)):
        lib.sphere('Music note head', (x-.18, 0, z), (.45, .25, .31), 'magenta')
        lib.box('Music note stem', (x+.10, .02, z+.83), (.23, .30, 1.60), 'purple', .09)
    ui.shape('Music beam', [(-.64, 2.01), (.79, 2.40), (.79, 1.96), (-.64, 1.58)], .33, 'magenta', rounding=.065)
    for s in (-1, 1):
        lib.tube('Dance motion', [(s*1.15, 0, 1.06), (s*1.36, 0, 1.31), (s*1.29, 0, 1.63)], [.055]*3, 'cyan')
    sparkle(-.83, 2.52, .24, 'goldLight')
    sparkle(.98, .38, .17)


def toilet_glow():
    group(lambda: builders.toilet('Basic'), (0, 0, .18), .52)
    for r, color in ((1.34, 'purple'), (1.20, 'cyan')):
        lib.torus('Glowing aura halo', (0, .65, 1.44), r, .075, color, rotation=(math.pi/2, 0, 0), scale=(.85, 1, 1))
    lib.torus('Aura floor orbit', (0, -.08, .23), .92, .07, 'cyan')
    sparkle(-1.12, 1.79, .23, 'ice')
    sparkle(1.01, .90, .18, 'violet')
    sparkle(.83, 2.53, .20)


def companion():
    group(builders.paper, (0, 0, .27))
    lib.eyes(.29, -.80, 1.10, .24)
    lib.smile((0, -.855, .70), .20)
    for s in (-1, 1):
        lib.sphere('Blush cheek', (s*.53, -.70, .82), (.14, .06, .075), 'pink')
        lib.sphere('Tiny companion foot', (s*.44, -.29, .17), (.27, .32, .16), 'cyan')
    sparkle(-.88, 1.86, .18, 'goldLight')


def star_tag():
    for s in (-1, 1):
        ui.shape('Blue badge ribbon', [(s*.08, 1.14), (s*.49, 1.18), (s*.77, .10), (s*.44, .26), (s*.20, .04)], .16, 'blue', .10, .035)
    ui.disc('Badge gold rim', (0, 0, 1.54), .86, .25, 'gold')
    ui.disc('Badge indigo center', (0, -.17, 1.54), .72, .10, 'navy')
    ui.bevel(lib.star('Golden tag star', (0, -.30, 1.56), .64, 'goldLight', 5), .045)
    sparkle(.89, 2.23, .19)


def cash_bundle():
    lib.box('Banknote stack', (0, 0, .28), (1.68, .90, .50), 'green', .10)
    for z in (.13, .24, .35):
        lib.box('Banknote edges', (0, -.459, z), (1.45, .02, .025), 'mint', .005)
    lib.box('Top banknote', (0, 0, .55), (1.59, .86, .07), 'lime', .05)
    lib.box('Gold money band', (0, -.005, .29), (.40, .97, .63), 'gold', .06)


def double_cash():
    group(cash_bundle, (-.20, 0, .12), 1, -9)
    group(cash_bundle, (.10, .08, .78), 1, 9)
    badge('x2', .60, .41, color='green', y=-.83)
    sparkle(-.89, 1.83, .21, 'goldLight')


def coin_at(x, y, z, scale=.35, tilt=0):
    def coin_symbol():
        # Retain the UI coin's face; tiny milled spheres are invisible at this size.
        ui.disc('Mini coin gold edge', (0,0,1.3), 1.14, .28, 'orange')
        ui.disc('Mini coin face', (0,-.16,1.3), 1.07, .11, 'gold')
        lib.torus('Mini coin raised rim', (0,-.245,1.3), .95, .075, 'goldLight', rotation=(math.pi/2,0,0))
        label('$', (0,-.30,1.29), 1.40, 'goldLight')
    return group(coin_symbol, (x, y, z-1.3*scale), scale, tilt)


def auto_collect():
    pts = []
    for i in range(41):
        a = math.pi+i*math.pi/40
        pts.append((.76*math.cos(a), 1.32+.76*math.sin(a)))
    for i in range(41):
        a = math.tau-i*math.pi/40
        pts.append((.37*math.cos(a), 1.32+.37*math.sin(a)))
    ui.shape('Horseshoe magnet curve', pts, .43, 'red', rounding=.07)
    for s in (-1, 1):
        lib.box('Magnet upright', (s*.565, 0, 1.54), (.39, .43, .60), 'red', .075)
        lib.box('Silver magnetic pole', (s*.565, 0, 1.91), (.41, .46, .28), 'ice', .06)
    coin_at(0, -.10, 2.53, .28, -15)
    coin_at(.97, -.03, 2.37, .21, 15)
    for s in (-1, 1):
        ui.shape('Collect arrow', [(s*1.20, 1.15), (s*1.03, 1.45), (s*1.13, 1.43), (s*1.16, 1.81), (s*1.33, 1.79), (s*1.29, 1.39), (s*1.43, 1.39)], .14, 'cyan', -.10, .03)


def extra_slots():
    lib.box('Display pedestal base', (0, 0, .20), (1.94, 1.25, .38), 'navy', .13)
    lib.box('Pedestal plinth', (0, 0, .75), (1.42, .98, .82), 'blue', .12)
    lib.box('Pedestal top edge', (0, 0, 1.22), (1.98, 1.30, .26), 'ice', .085)
    lib.box('Pedestal display surface', (0, 0, 1.38), (1.73, 1.06, .12), 'cyan', .05)
    points = [(-.18, 1.58), (.18, 1.58), (.18, 1.98), (.58, 1.98), (.58, 2.34), (.18, 2.34), (.18, 2.74), (-.18, 2.74), (-.18, 2.34), (-.58, 2.34), (-.58, 1.98), (-.18, 1.98)]
    ui.shape('Extra slot plus', points, .30, 'lime', -.08, .07)


def offline_plus():
    pts = [(math.cos(a), 1.54+math.sin(a)) for a in [math.radians(62+i*236/64) for i in range(65)]]
    pts += [(.44+.80*math.cos(a), 1.54+.90*math.sin(a)) for a in [math.radians(270-i*180/64) for i in range(65)]]
    ui.shape('Crescent moon', pts, .35, 'gold', .18, .055)
    ui.disc('Clock rim', (.57, -.22, .91), .69, .26, 'blue')
    ui.disc('Clock face', (.57, -.38, .91), .57, .08, 'white')
    for i in range(12):
        a = i*math.tau/12
        obj = lib.box('Clock hour', (.57+math.sin(a)*.46, -.435, .91+math.cos(a)*.46), (.045, .02, .09), 'navy', .009)
        obj.rotation_euler.y = a
    lib.tube('Clock hands', [(.57, -.49, 1.24), (.57, -.49, .91), (.85, -.49, .91)], [.047]*3, 'navy')
    coin_at(-.18, -.74, .36, .27)
    sparkle(.69, 2.42, .19, 'ice')


def vip():
    lib.box('Velvet cushion gold piping', (0, 0, .30), (2.33, 1.52, .43), 'gold', .20)
    cushion=lib.box('Royal purple velvet cushion', (0, 0, .37), (2.27, 1.49, .46), 'purple', .205)
    velvet=cushion.data.materials[0].copy()
    velvet.name='Royal velvet cushion'
    shader=velvet.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value=.68
    shader.inputs['Coat Weight'].default_value=.06
    shader.inputs['Sheen Weight'].default_value=.45
    cushion.data.materials[0]=velvet
    lib.crown((0, 0, .63), .78, 1.13)
    for s in (-1, 1):
        pts = [(s*(.89+.40*math.sin(t*math.pi)), .26, .43+t*1.48) for t in [.88*i/24 for i in range(25)]]
        lib.tube('Gold laurel stem', pts, [.042]*len(pts), 'gold')
        for i in range(6):
            t = .10+i*.145
            x, z = s*(.89+.40*math.sin(t*math.pi)), .43+t*1.48
            leaf = lib.sphere('Laurel leaf', (x+s*.09, .23, z+.10), (.115, .055, .22), 'goldLight')
            leaf.rotation_euler.y = s*.60
        lib.sphere('Cushion tassel', (s*1.09, -.68, .19), (.10, .10, .19), 'gold')
    sparkle(-.89, 2.04, .18)


def jewel(x, y, z, color, scale=.33):
    # A brilliant-cut silhouette, not a rounded rock: table, girdle, pointed base.
    vertices=[]
    for radius,height in ((.51,.64),(1,.13)):
        for i in range(8):
            a=math.tau*i/8
            vertices.append((x+math.cos(a)*radius*scale, y+math.sin(a)*radius*scale*.75, z+height*scale))
    vertices.append((x,y,z-.98*scale))
    faces=[tuple(range(7,-1,-1))]
    for i in range(8):
        j=(i+1)%8
        faces.extend(((i,j,j+8,i+8),(i+8,j+8,16)))
    obj=lib.mesh('Brilliant-cut treasure gem',vertices,faces,color)
    ui.bevel(obj,.008)


def chest():
    lib.box('Royal chest body', (0, 0, .67), (2.06, 1.31, 1.04), 'purple', .16)
    lib.box('Chest bottom gold rim', (0, 0, .22), (2.12, 1.37, .18), 'gold', .05)
    lib.box('Chest mouth dark well', (0, 0, 1.21), (1.86, 1.08, .12), 'ink', .06)
    for x in (-.79, .79):
        lib.box('Chest gold binding', (x, -.02, .71), (.17, 1.39, 1.12), 'gold', .04)
    def lid():
        lib.box('Open chest lid', (0, 0, .40), (2.09, .30, .92), 'purple', .14)
        for x in (-.80, .80):
            lib.box('Lid gold binding', (x, -.02, .40), (.18, .33, .93), 'gold', .035)
        lib.box('Lid gold lip', (0, -.03, -.01), (2.08, .34, .15), 'gold', .04)
    group(lid, (0, .57, 1.32))
    for x, y, z, color, scale in ((-.55, -.10, 1.39, 'cyan', .41), (.02, .1, 1.66, 'pink', .43), (.61, .01, 1.46, 'lime', .39), (-.20, -.39, 1.30, 'violet', .34), (.48, -.83, .29, 'cyan', .32)):
        jewel(x, y, z, color, scale)
    lib.box('Gift ribbon front', (0, -.688, .70), (.31, .055, .95), 'pink', .025)
    for s in (-1, 1):
        lib.sphere('Ribbon bow loop', (s*.23, -.78, 1.0), (.26, .12, .16), 'magenta')
    lib.sphere('Bow knot', (0, -.88, 1.0), (.12, .10, .13), 'pink')
    sparkle(-1.10, 1.94, .20, 'goldLight')
    sparkle(.98, 2.17, .18)


def stack(x, y, count, r=.34):
    for j in range(count):
        lib.cylinder('Stacked gold coin', (x, y, .12+j*.12), r, .115, 'gold')
        lib.torus('Coin stack milled rim', (x, y, .16+j*.12), r*.88, .027, 'goldLight')


def coin_mini():
    for x, y, count in ((-.56, .13, 4), (.20, .27, 6), (.69, -.20, 3)):
        stack(x, y, count, .39)
    coin_at(-.24, -.53, .42, .34, -13)
    sparkle(.49, 1.15, .18)


def sack(large=False):
    color = 'orange' if large else 'blue'
    def bag():
        lib.lathe('Plump coin sack', [(.06, .10), (.53, .10), (.79, .33), (.84, .85), (.69, 1.32), (.39, 1.58), (.47, 1.80), (.34, 1.79), (.28, 1.58)], (0, 0, 0), color, scale=(1, .72, 1))
        lib.torus('Drawstring gold cord', (0, 0, 1.56), .37, .075, 'goldLight', scale=(1, .73, 1))
        label('$', (0, -.625, .90), .81, 'goldLight')
        for s in (-1, 1):
            lib.tube('Sack drawstring', [(s*.16, -.30, 1.58), (s*.36, -.49, 1.32), (s*.44, -.49, 1.15)], [.055]*3, 'goldLight')
        coin_at(-.06, -.01, 1.84, .23, -12)
    group(bag, scale=1.18 if large else 1)
    stack(-.72, -.36, 4 if large else 2, .30)
    coin_at(.56, -.55, .38, .30, 20)
    if large:
        for x, y, count in ((.75, .19, 6), (-.76, .18, 6), (.40, -.70, 3)):
            stack(x, y, count, .30)
    sparkle(.69, 2.26 if large else 2.02, .19)


def huge():
    rng = random.Random(71)
    for x, y, count in ((-.93, .20, 5), (-.43, .45, 9), (.20, .49, 12), (.77, .32, 8), (1.03, -.18, 4), (-.45, -.32, 5), (.17, -.36, 7)):
        stack(x, y, count, .36)
    for i in range(8):
        coin_at(-.95+i*.27, -.65-rng.random()*.15, .29+rng.random()*.22, .23, rng.uniform(-30, 30))
    jewel(-.83, -.85, .19, 'cyan', .27)
    jewel(.82, -.76, .26, 'magenta', .27)
    sparkle(-.66, 1.73, .22)
    sparkle(.91, 1.43, .18, 'goldLight')


def lucky(quantity=1):
    if quantity > 1:
        group(ui.luck, (-.52, .33, .50), .64, -17)
        group(ui.luck, (.51, .18, .58), .66, 18)
    if quantity == 20:
        group(ui.luck, (0, .51, .91), .65)
    group(ui.luck, (-.12, -.12, .05), .80, -8)
    # A small porcelain flush handle establishes the product's toilet connection.
    group(ui.flush, (.85, -.50, .20), .40, -12)
    badge('x'+str(quantity), -.25, .26, 1.12 if quantity == 20 else .91, 'green', -1.0)
    sparkle(-.77, 2.31, .22, 'goldLight')
    sparkle(.91, 2.11, .18)


def path_boost():
    ui.shape('Speed arrow dark edge', [(-1.19, .60), (.22, .60), (.22, .15), (1.46, 1.32), (.22, 2.49), (.22, 2.03), (-1.19, 2.03)], .44, 'navy', rounding=.10)
    ui.shape('Blue speed arrow', [(-1.03, .77), (.39, .77), (.39, .52), (1.22, 1.32), (.39, 2.12), (.39, 1.86), (-1.03, 1.86)], .12, 'blue', -.28, .05)
    for x in (-.80, -.30):
        ui.shape('Cyan speed chevron', [(x, .94), (x+.28, 1.32), (x, 1.70), (x+.19, 1.70), (x+.49, 1.32), (x+.19, .94)], .07, 'ice', -.38, .025)
    for x, z, width in ((-1.28, .36, .66), (-1.51, 1.31, .43), (-1.27, 2.27, .59)):
        lib.box('Speed streak', (x, .0, z), (width, .12, .12), 'cyan', .05)


MODELS = {
    'RainbowName': lambda: nameplate(False), 'ConfettiReveal': confetti,
    'GoldenName': lambda: nameplate(True), 'DancePack': dance,
    'ToiletGlow': toilet_glow, 'Companion': companion, 'StarTag': star_tag,
    'DoubleCash': double_cash, 'AutoCollect': auto_collect, 'ExtraSlots': extra_slots,
    'OfflinePlus': offline_plus, 'VIPPack': vip, 'UltimateBundle': chest,
    'Coins10Minutes': coin_mini, 'Coins1Hour': sack, 'Coins6Hours': lambda: sack(True),
    'CoinPackHuge': huge, 'LuckyFlush1': lucky, 'LuckyFlush5': lambda: lucky(5),
    'LuckyFlush20': lambda: lucky(20), 'PathBoost': path_boost,
}

# Internal filename, catalog display name, intended Assets.Icons suffix, offer kind.
# New names are provisional until the manager's extended catalog lands.
CATALOG = [
    ('RainbowName', 'Rainbow Name', 'RainbowName', 'pass'),
    ('ConfettiReveal', 'Confetti Reveal', 'ConfettiReveal', 'pass'),
    ('GoldenName', 'Golden Name', 'GoldenName', 'pass'),
    ('DancePack', 'Dance Pack', 'DancePack', 'pass'),
    ('ToiletGlow', 'Toilet Glow', 'ToiletGlow', 'pass'),
    ('Companion', 'Companion', 'Companion', 'pass'),
    ('StarTag', 'Star Tag', 'StarTag', 'pass'),
    ('DoubleCash', 'Double Cash', 'DoubleCash', 'pass'),
    ('AutoCollect', 'Auto Collect', 'AutoCollect', 'pass'),
    ('ExtraSlots', 'Extra Slots', 'ExtraSlots', 'pass'),
    ('OfflinePlus', 'Offline Plus', 'OfflinePlus', 'pass'),
    ('VIPPack', 'VIP Pack', 'VIPPack', 'pass'),
    ('UltimateBundle', 'Ultimate Bundle', 'UltimateBundle', 'pass'),
    ('FastFlush', 'Fast Flush', 'Flush', 'pass'),
    ('SparkleTrail', 'Sparkle Trail', 'Gem', 'pass'),
    ('VIPStar', 'VIP Star', 'Crown', 'pass'),
    ('CustomPlotColor', 'Custom Plot Color', 'Home', 'pass'),
    ('Coins10Minutes', 'Coin Pack: 10 Minutes', 'CoinPack', 'product'),
    ('Coins1Hour', 'Coin Pack: 1 Hour', 'CoinPackSmall', 'product'),
    ('Coins6Hours', 'Coin Pack: 6 Hours', 'CoinPackLarge', 'product'),
    ('CoinPackHuge', 'Coin Pack Huge', 'CoinPackHuge', 'product'),
    ('LuckyFlush1', 'Lucky Flush x1', 'LuckyFlush1', 'product'),
    ('LuckyFlush5', 'Lucky Flush x5', 'LuckyFlush5', 'product'),
    ('LuckyFlush20', 'Lucky Flush x20', 'LuckyFlush20', 'product'),
    ('PathBoost', 'Path Boost: 10 Minutes', 'PathBoost', 'product'),
]
REUSE = {'FastFlush': 'Flush', 'SparkleTrail': 'Gem', 'VIPStar': 'Crown', 'CustomPlotColor': 'Home'}
EXISTING_OFFERS = set(REUSE) | {'DoubleCash', 'AutoCollect', 'ExtraSlots', 'OfflinePlus', 'VIPPack', 'Coins10Minutes', 'Coins1Hour', 'Coins6Hours', 'PathBoost'}
EXISTING_KEYS = {'DoubleCash', 'AutoCollect', 'ExtraSlots', 'OfflinePlus', 'VIPPack', 'CoinPack', 'PathBoost', 'Flush', 'Gem', 'Crown', 'Home'}
