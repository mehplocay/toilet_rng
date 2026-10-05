"""Author explicit resort transforms. No runtime randomness; all dimensions are studs.
Run python scripts/generate-map-layout.py after editing this recipe, then StyLua.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
env = json.loads((ROOT / 'assets/manifest-env.json').read_text())['assets']
catalog = {a['name']: a for a in env}
catalog.update({a['name']: a for a in json.loads((ROOT/'assets/manifest.json').read_text())['assets']})

def vec(values):
    return 'Vector3.new(' + ', '.join(f'{x:.5f}'.rstrip('0').rstrip('.') if x else '0' for x in values) + ')'

def lua(value):
    if isinstance(value, str): return json.dumps(value)
    if isinstance(value, bool): return str(value).lower()
    if isinstance(value, dict): return '{ ' + ', '.join(k+' = '+lua(v) for k,v in value.items()) + ' }'
    if isinstance(value, (list,tuple)): return '{ '+', '.join(lua(v) for v in value)+' }'
    return str(round(value,5))

placements=[]
def put(asset,x,y,z,yaw=0,scale=1,**kw):
    p=dict(Asset=asset,Position=[x,y,z],Yaw=yaw,Scale=scale,**kw)
    placements.append(p)
    return p

def arc(asset,x,y,z,yaw,scale):
    socket=catalog[asset]['sockets_studs']['arc_center']
    a=math.radians(yaw)
    dx=(socket[0]*math.cos(a)+socket[2]*math.sin(a))*scale
    dz=(-socket[0]*math.sin(a)+socket[2]*math.cos(a))*scale
    return put(asset,x-dx,y,z-dz,yaw,scale)

# Tiled, not a monolithic baseplate. Stepped shoulder corners expose cliffs/water.
cells=[]
for ix in range(-4,5):
    for iz in range(-6,7):
        if abs(ix)==4 and abs(iz)==6: continue
        x,z=ix*48,iz*48
        cells.append((ix,iz))
        for ox in [-12,12]:
            for oz in [-12,12]:
                put('GrassSlab',x+ox,-1.4,z+oz,Size=[24,1.4,24],Tint=([232,255,239] if (ox+oz)==0 else [255,255,255]),Group='Island')
        # Four exposed, slightly inset pavers give turf a chunky tiled surface without thousands of studs.
        if abs(ix)>=3 and iz%2==0:
            put('ShoreRocks',x+17,0,z+19,25+ix*11,.65,Group='Gardens')

for ix,iz in cells:
    for dx,dz,yaw in [(0,-1,0),(1,0,-90),(0,1,180),(-1,0,90)]:
        if (ix+dx,iz+dz) in cells: continue
        for shift in [-12,12]:
            x,z=ix*48+dx*19.5,iz*48+dz*19.5
            x+=shift if dx==0 else 0
            z+=shift if dz==0 else 0
            asset=['CliffStraightA','CliffStraightB','CliffStraightC'][(ix+iz+int(shift))%3]
            put(asset,x,-13.38,z,yaw,Group='Coast')
            put('BeachStrip',x+dx*14,-13.5,z+dz*14,yaw,Group='Coast')

# Broad blue promenades; short spatial modules remain independently streamable.
for x in [-114,114]:
    for z in range(-264,265,48):
        put('HubPathStrip',x,-.96,z,Size=[24,1.05,48],Group='Routes')
for z in [-288,-192,-96,96,192,288]:
    for x in [-78,-26,26,78]:
        put('HubPathStrip',x,-.93,z,90,Size=[20,1.05,52],Group='Routes')
for z in [-264,-216,-168,-120,120,216,264]:
    put('HubPathStrip',0,-.90,z,Size=[24,1.05,48],Group='Routes')
for x in [-36,36]:
    put('HubPathStrip',x,-.89,156,Size=[20,1.05,72],Group='Routes')
for z in [120,192]:
    put('HubPathStrip',0,-.88,z,90,Size=[20,1.05,92],Group='Routes')

# 192-stud diameter plaza. Ring sockets, not bounding-box centers, define seam alignment.
put('HubMedallion',0,-2.8,0,0,3,Group='Hub')
for yaw in range(0,360,36):
    arc('HubRingSegment',0,-2.8,0,yaw,3)['Group']='Hub'
    arc('HubCurbSegment',0,-3,0,yaw+18,3)['Group']='Hub'
put('ToiletCastle',0,.15,0,0,3,Group='Landmark')
put('PlazaSteps',0,-1.8,-39,0,2,Group='Landmark')
put('FountainPedestal',-36,0,-51,0,1.5,Group='Landmark')
put('GoldenTrophy',-36,4.95,-51,0,1,Group='Landmark')

stations=[
    dict(Name='Shop',Asset='ShopKiosk',X=-66,Z=-66,Yaw=-35,Panel='Shop'),
    dict(Name='Upgrades',Asset='ShopKiosk',X=66,Z=-66,Yaw=35,Panel='Upgrades'),
    dict(Name='Index',Asset='ShopKiosk',X=-76,Z=58,Yaw=-140,Panel='Collection'),
    dict(Name='Daily',Asset='ShopKiosk',X=76,Z=58,Yaw=140,Panel='Daily'),
    dict(Name='Passes',Asset='ShopKiosk',X=0,Z=-182,Yaw=0,Panel='Passes'),
]
for s in stations:
    put(s['Asset'],s['X'],.15,s['Z'],s['Yaw'],1.65,Group='Stations')
    if s['Name']=='Index':
        put('IndexBookPedestal',-61,.15,45,-140,1.25,Group='Stations')
for asset,x in [('PortalSewer',-64),('PortalSpace',0),('PortalHell',64)]:
    put(asset,x,.15,260,0,2,Group='Portals')
    put('HubMedallion',x,-.65,250,0,1,Group='Portals')

# Composed foreground, middle and far silhouettes; never place trunks inside routes.
for x,z,s,yaw in [(-204,-182,2,20),(204,-90,2.3,-30),(-204,112,2.2,50),(204,200,2,160),(-88,-240,1.7,10),(88,224,1.7,50)]:
    put('GiantPalmCluster',x,0,z,yaw,s,Group='Foreground')
for x,z in [(-68,-120),(68,-120),(-74,202),(76,202),(-30,-238),(32,-238)]:
    put('PalmTree',x,0,z,15,4.8,Group='Gardens')
    put('RoundBush',x+6,0,z+4,0,1.8,Group='Gardens')
    put('FlowerPack',x-5,0,z+3,20,1.2,Group='Gardens')
    put('ForegroundFoliage',x+4,0,z-6,0,1.3,Group='Gardens')
for x,z,yaw in [(-92,-155,-90),(92,-155,90),(-91,148,-90),(91,148,90)]:
    put('Bench',x,0,z,yaw,2,Group='Gardens')
    put('LampPost',x+7,0,z,0,2,Group='Gardens')
put('SmallCove',-191,-13,-314,20,1.8,Group='Coast')
put('CliffCorner',-188,-13.4,-292,180,1,Group='Coast')
put('BeachCorner',-203,-13.5,295,0,1.5,Group='Coast')
put('TreeStump',197,0,272,10,2,Group='Gardens')
put('Lighthouse',-178,0,279,15,2.25,Group='Coast')
put('PortalGate',-178,0,252,0,1.5,Group='Coast')
put('PlotSignboard',-12,0,-299,0,1.5,Group='Dock')
# Raised side terraces supply a second green height band.
for x,z in [(-242,-120),(242,144),(-242,216),(242,-264)]:
    put('CliffStraightB',x,0,z,90 if x<0 else -90,1.8,Group='Headland')
    put('GrassSlab',x,22.77,z,Size=[42,1.4,32],Group='Headland')
    put('PalmTree',x,24.17,z,30,3,Group='Headland')

for layer,entries in [
    ('Middle',[(-300,-160,2.5,75),(-282,110,2.8,95),(-204,374,2.8,0),(70,385,2.6,-10),(295,230,3,-80),(300,-150,2.4,-100)]),
    ('Far',[(-435,-210,4.5,80),(-438,235,4.2,100),(-230,510,4.5,0),(155,515,4.7,-8),(445,235,4.5,-85),(445,-210,4.1,-100),(0,-495,4.2,180)])]:
    for i,(x,z,s,yaw) in enumerate(entries):
        put('MountainRidge'+ 'ABC'[i%3],x,-18,z,yaw,s,Group=layer,Tint=([70,149,192] if layer=='Middle' else [142,199,232]),NoShadow=True)
for i,(x,y,z) in enumerate([(-290,120,360),(140,155,450),(400,100,80),(-415,150,-140),(180,120,-420),(-135,95,-355)]):
    put('CloudBankTall' if i%2 else 'CloudBankWide',x,y,z,i*17,3.5,Group='Skyline',NoShadow=True)
for i,(x,y,z) in enumerate([(-250,65,170),(245,80,-130),(-150,110,355),(185,90,350)]):
    put('FloatingIslet'+'ABC'[i%3],x,y,z,30*i,2,Group='Skyline',NoShadow=True)
put('CloudPuffs',-215,70,-285,15,12,Group='Skyline',NoShadow=True)

# A scenic pier extension at the same walk datum, fenced by collision rails.
put('RopeBridge',0,-2.625,-324,0,1,Group='Dock')
put('DockPier',0,-2.625,-344,0,1,Group='Dock')
put('IslandStairs',0,-2.12,-303,0,1,Group='Dock')

plots=[]
for side in [-1,1]:
    for z in [-240,-144,-48,48,144,240]:
        plots.append(dict(X=side*162,Z=z,Yaw=-90 if side<0 else 90))

plotPieces=[]
def pp(asset,x,y,z,yaw=0,scale=1,**kw):
    plotPieces.append(dict(Asset=asset,Position=[x,y,z],Yaw=yaw,Scale=scale,**kw))
pp('PlotPlatform',0,-1.45,0,Size=[48,1.65,60])
pp('GrassSlab',0,.025,-2,Size=[13,.08,52],Solid=[244,74,143])
pp('PlotGateArch',0,0,-26,0,1.55)
# Rear pavilion roof/beams reuse architectural kit meshes, preserving open collection sightlines.
pp('HubPathStrip',0,14.4,22,Size=[42,1.05,12])
for x in [-20,20]:
    for z in [16,28]: pp('HubEdgeStraight',x,0,z,Size=[1.4,14.4,1.4],Solid=[30,61,107])
pp('PlotSignPost',-19,0,-22,0,1.2)
pp('PlotCornerGarden',-19,0,23,0,1.2)
pp('PlotCornerGarden',19,0,23,0,1.2)
pp('PalmTree',22,0,26,0,2.7)
pp('RoundBush',-21,0,14,0,1.6)
pp('FlowerPack',20,0,14,25,1)
pp('PlotPathStraight',0,-.95,-32,Size=[14,1.05,6])
pp('PlotPathCorner',-19,-.96,-13,0,1)
for x in [-16,0,16]: pp('PlotFenceSection',x,0,28.4,Size=[16.5,3.5,.8])
for x in [-22.4,22.4]:
    for z in [4,20]: pp('PlotFenceSection',x,0,z,90,Size=[16.5,3.5,.8])
pp('WoodenFence',-22.2,0,-19,90,1.8)

path=ROOT/'src/shared/Config/MapLayout.luau'
lines=['-- Generated by scripts/generate-map-layout.py. Explicit base-pivot transforms; studs, +Z north.',
       '-- Owner scale overrides the smaller Flush Resort proposal. Do not randomize gameplay geometry.',
       'return {',
       '\tFloorY = 0, PlotRise = 0.35, PlotWidth = 48, PlotDepth = 60, PromenadeWidth = 24,',
       '\tHubRadius = 96, RefreshSeconds = 10,',
       '\tHubArrival = Vector3.new(0, 4, -108), ShopArrival = Vector3.new(-56, 4, -83),',
       '\tToiletOffset = Vector3.new(0, 0.15, 20),',
       '\tBudget = { HubParts = 1600, PlotParts = 180, TotalParts = 3600, Meshes = 1700, Triangles = 1400000, Instances = 11000, Beams = 140, Highlights = 144 },',
       '\tPlots = {']
lines += ['\t\t'+lua(p)+',' for p in plots]
lines+=['\t},','\tStations = {']+['\t\t'+lua(s)+',' for s in stations]+['\t},',
        '\tBoards = { { Key = "Rarest", Title = "RAREST FIND", X = -72, Z = 150 }, { Key = "Flushes", Title = "TOTAL FLUSHES", X = 0, Z = 150 }, { Key = "Coins", Title = "COINS", X = 72, Z = 150 } },',
        '\tSlots = {']
for i in range(10):
    lines.append('\t\t'+vec([-14 if i%2==0 else 14,0,-19+(i//2)*8])+',')
lines+=['\t},','\tLandCells = {']+['\t\t'+lua([x*48,z*48])+',' for x,z in cells]+['\t},']
for name,rows in [('Pieces',placements),('PlotPieces',plotPieces)]:
    lines.append('\t'+name+' = {')
    for p in rows:
        content=[]
        for k,v in p.items():
            content.append(k+' = '+(vec(v) if k in ['Position','Size'] else lua(v)))
        lines.append('\t\t{ '+', '.join(content)+' },')
    lines.append('\t},')
lines.append('}')
path.write_text('\n'.join(lines)+'\n')
# Independently checked against the manifest and serialized imports by check-world.ps1.
path=ROOT/'src/shared/Config/MeshCatalog.luau'
original=path.read_text().split('\n\t-- Environment kit')[0].rstrip()
if original.endswith('}'): original=original[:-1].rstrip()
lines=[original,'\t-- Environment kit; canonical sizes from assets/manifest-env.json.']
for a in env:
    lines.append('\t'+a['name']+' = { Size = '+vec(a['size_studs'])+', Triangles = '+str(a['tris'])+', Folder = "EnvTemplates"'+(', NoShadow = true' if a['family']=='background' and a['name']!='GiantPalmCluster' else '')+' },')
lines.append('}')
path.write_text('\n'.join(lines)+'\n')
print(f'Authored {len(placements)} shared placements, {len(plotPieces)} pieces per plot, {len(plots)} plots; 44 environment catalog entries.')

# Review diagram shares authored coordinates; +Z is up, one SVG unit is one stud.
svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="850" viewBox="0 0 1100 850">',
       '<rect width="1100" height="850" fill="#102439"/>',
       '<style>text{font-family:Arial,sans-serif;fill:#edf8ff;font-size:12px}.small{font-size:10px}.title{font-size:23px;font-weight:bold}.sub{fill:#9acbdc}</style>',
       '<text x="30" y="35" class="title">FLUSH RESORT / ASSEMBLED LAYOUT</text>',
       '<text x="30" y="57" class="sub">Stud coordinates • +Z up • X right • decorative skyline omitted</text>']
def rect(x,z,w,d,fill,stroke='none'):
    svg.append(f'<rect x="{360+x-w/2}" y="{420-z-d/2}" width="{w}" height="{d}" fill="{fill}" stroke="{stroke}"/>')
def label(x,z,text,cls='small'):
    svg.append(f'<text x="{360+x}" y="{424-z}" text-anchor="middle" class="{cls}">{text}</text>')
for ix,iz in cells: rect(ix*48,iz*48,48,48,'#3f975d','#4b9f68')
for x in [-114,114]: rect(x,0,24,600,'#6dbad4')
for z in [-288,-192,-96,96,192,288]: rect(0,z,208,20,'#6dbad4')
rect(0,0,24,600,'#6dbad4')
svg.append('<circle cx="360" cy="420" r="96" fill="#316f98" stroke="#9ee6e7" stroke-width="3"/>')
rect(0,0,84,70,'#d5ab52')
label(0,0,'CASTLE')
for i,p in enumerate(plots,1):
    rect(p['X'],p['Z'],60,48,'#273e61','#f8d681')
    rect(p['X'],p['Z'],52,13,'#e55191')
    label(p['X'],p['Z'],f'P{i}')
for s in stations:
    rect(s['X'],s['Z'],27,18,'#ebac44')
    label(s['X'],s['Z'],s['Name'].upper())
for x,title in [(-72,'RAREST'),(0,'FLUSHES'),(72,'COINS')]:
    rect(x,150,46,8,'#b9fcf6')
    label(x,170,title)
for x,title in [(-64,'SEWER'),(0,'SPACE'),(64,'HELL')]:
    svg.append(f'<circle cx="{360+x}" cy="160" r="12" fill="#a66bd7"/>')
    label(x,235,title)
rect(0,-332,8,40,'#af794b')
label(0,-370,'BRIDGE / PIER')
label(-178,288,'LIGHTHOUSE')
svg += ['<path d="M144 758H576M144 752V764M576 752V764" stroke="#a8d2e1"/>',
        '<text x="360" y="786" text-anchor="middle">432 studs / main island width</text>',
        '<path d="M660 108V732M654 108H666M654 732H666" stroke="#a8d2e1"/>',
        '<text x="674" y="420" transform="rotate(90 674 420)" text-anchor="middle">624 studs / main island length</text>']
notes = [
    'CORE DIMENSIONS', '12 plots: 48 x 60 each (2,880 sq. studs)',
    'Plot columns X = -162 / +162', 'Rows Z = -240, -144, -48, 48, 144, 240',
    'Each plot faces its 24-stud promenade', '48-stud clear gap between plot rows',
    'Hub diameter 192; castle height ~98', '',
    'PLAY SPACE', 'Continuous land floor Y = 0', 'Plot floor Y = 0.35; water Y = -15',
    'Walkable pier ends at Z = -352', '40-high invisible coastline walls',
    'Castle and boards have box exclusion proxies', '',
    'PLOT LOCAL COORDINATES', 'Entry Z = -30; toilet Z = +20',
    'Carpet 13 x 52; spawn Z = +15', 'Stands X = -14 / +14, 8-stud row pitch',
    'Ten visible stands; green collect pads', '',
    'DEPTH LAYERS (outside this diagram)', 'Foreground palms / raised headlands',
    'Middle mountains ~280-385 from center', 'Far ridges ~435-515; clouds and islets',
    '', 'Exact placements: MapLayout.luau', 'Diagram regenerated by generate-map-layout.py'
]
for i,line in enumerate(notes):
    svg.append(f'<text x="724" y="{102+i*23}" class="{"sub" if i in (0,8,15,22) else ""}">{line}</text>')
svg.append('</svg>')
(ROOT/'docs/map-layout.svg').write_text('\n'.join(svg)+'\n',encoding='utf-8')
