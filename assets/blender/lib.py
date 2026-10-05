"""Shared toy mesh tools. Author in studs, Z-up, with the face toward -Y."""
import math
import struct
import zlib
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
PALETTE = {
    "cream": "FFF3D1", "white": "F4FAFF", "ink": "19213F", "black": "101326",
    "brown": "AE572A", "caramel": "DC893C", "gold": "FFC51C", "goldLight": "FFE67A",
    "orange": "FF821E", "pink": "FF699F", "red": "EF3359", "peach": "FFC098",
    "blue": "278DF1", "cyan": "34DFFF", "ice": "A0F0FF", "navy": "314B9D",
    "purple": "8850EC", "violet": "C174FF", "magenta": "F74FE7", "mint": "80FFBE",
    "green": "26BD54", "lime": "ACF52E", "leaf": "10A276", "teal": "078D9C",
    "wood": "B66B3C", "woodLight": "F3B969", "mud": "76503B", "gray": "8499C3",
    "slate": "4C6091", "yellow": "FFE331", "water": "29BCD9", "glow": "DBFFAC",
}
KEYS = list(PALETTE)


def png(path, width, height, rows):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(b"".join(b"\x00" + row for row in rows))) + chunk(b"IEND", b""))


def palette_texture():
    """32 padded swatches: painted light band and soft warm/cool value gradient."""
    path = ASSETS / "textures" / "ToyPalette.png"
    rows = []
    for py in range(256):
        row = bytearray()
        for px in range(256):
            col, tile_y = px // 32, (255 - py) // 64
            key = KEYS[tile_y * 8 + col]
            base = [int(PALETTE[key][i:i+2], 16) / 255 for i in (0, 2, 4)]
            u = min(1, max(0, ((px % 32) - 3) / 25))
            v = min(1, max(0, (((255-py) % 64) - 6) / 51))
            dark = .82 + .18 * v
            gloss = .15 * math.exp(-((u-.32)/.20)**2 - ((v-.80)/.10)**2)
            if key in ("ink", "black"):
                gloss *= .18
            row.extend(round(255 * min(1, c * dark * (1-gloss) + gloss)) for c in base)
        rows.append(bytes(row))
    png(path, 256, 256, rows)
    return path


def clean_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for group in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(group):
            if datablock.users == 0:
                group.remove(datablock)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    scene.unit_settings.scale_length = 1.0


def material():
    mat = bpy.data.materials.get("ToyPalette")
    if mat:
        return mat
    mat = bpy.data.materials.new("ToyPalette")
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = .40
    shader.inputs["Metallic"].default_value = 0
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(ASSETS / "textures" / "ToyPalette.png"), check_existing=True)
    tex.interpolation = "Linear"
    mat.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])
    return mat


def finish(obj, color, smooth=True):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.materials.clear()
    obj.data.materials.append(material())
    uv = obj.data.uv_layers.new(name="PaletteUV") if not obj.data.uv_layers else obj.data.uv_layers[0]
    uv.name = "PaletteUV"
    index = KEYS.index(color)
    verts = obj.data.vertices
    lo = [min(v.co[i] for v in verts) for i in range(3)]
    hi = [max(v.co[i] for v in verts) for i in range(3)]
    for face in obj.data.polygons:
        face.use_smooth = smooth
        for li in face.loop_indices:
            co = verts[obj.data.loops[li].vertex_index].co
            u = (co.x-lo[0]) / max(.001, hi[0]-lo[0])
            v = (co.z-lo[2]) / max(.001, hi[2]-lo[2])
            uv.data[li].uv = ((index % 8 * 32 + 5 + u * 22) / 256, (index // 8 * 64 + 9 + v * 46) / 256)
    obj["palette"] = color
    obj.select_set(False)
    return obj


def sphere(name, loc, scale, color, segments=12, rings=8, smooth=True):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    return finish(obj, color, smooth)


def box(name, loc, size, color, bevel=.12):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Soft toy edges", "BEVEL")
        mod.width = min(bevel,min(size)*.45)
        mod.segments = 2
    return finish(obj, color, False)


def cylinder(name, loc, radius, depth, color, vertices=16, radius_top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius if radius_top is None else radius_top, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    return finish(obj, color)


def torus(name, loc, major, minor, color, scale=(1,1,1), rotation=(0,0,0), segments=24, sides=6):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments, minor_segments=sides, location=loc, major_radius=major, minor_radius=minor)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = rotation
    return finish(obj, color)


def mesh(name, verts, faces, color, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return finish(obj, color, smooth)


def tube(name, points, radii, color, sides=8):
    """Closed tapered tube. Parallel transport avoids camera-only curve geometry."""
    pts = [Vector(p) for p in points]
    verts, faces = [], []
    previous = Vector((0, 1, 0))
    for i, p in enumerate(pts):
        tangent = (pts[min(i+1, len(pts)-1)] - pts[max(0, i-1)]).normalized()
        normal = previous - tangent * previous.dot(tangent)
        if normal.length < .01:
            normal = tangent.cross(Vector((1, 0, 0)))
        normal.normalize()
        previous = normal
        other = tangent.cross(normal).normalized()
        for j in range(sides):
            a = j * math.tau / sides
            verts.append(p + radii[i] * (math.cos(a)*normal + math.sin(a)*other))
    for i in range(len(pts)-1):
        for j in range(sides):
            a, b = i*sides+j, i*sides+(j+1)%sides
            faces.append((a, b, b+sides, a+sides))
    faces.extend([tuple(reversed(range(sides))), tuple((len(pts)-1)*sides+j for j in range(sides))])
    return mesh(name, verts, faces, color, True)


def lathe(name, profile, loc, color, scale=(1,1,1), segments=24, smooth=True):
    """Closed profile, revolved without pole degeneracies (all radii > 0)."""
    verts, faces = [], []
    for radius, height in profile:
        for j in range(segments):
            a = j * math.tau / segments
            verts.append((loc[0]+radius*math.cos(a)*scale[0], loc[1]+radius*math.sin(a)*scale[1], loc[2]+height*scale[2]))
    for i in range(len(profile)):
        nxt = (i+1) % len(profile)
        for j in range(segments):
            k = (j+1) % segments
            faces.append((i*segments+j, i*segments+k, nxt*segments+k, nxt*segments+j))
    return mesh(name, verts, faces, color, smooth)


def prism(name, outline, depth, color, y=0):
    """Extruded shape in the front X/Z plane, with real thickness."""
    n = len(outline)
    verts = [(x, y+d, z) for d in (-depth/2, depth/2) for x,z in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name, verts, faces, color)


def star(name, loc, radius, color="goldLight", points=4):
    shape = []
    for i in range(points*2):
        a = math.pi/2 + i*math.pi/points
        r = radius if i%2 == 0 else radius*.34
        shape.append((loc[0]+r*math.cos(a),loc[2]+r*math.sin(a)))
    return prism(name, shape, radius*.25, color, loc[1])


def eyes(xspread, y, z, size=.23, x=0):
    for side in (-1,1):
        xx = x+side*xspread
        sphere("Eye white", (xx,y,z), (size,size*.48,size*1.16), "white", 10, 6)
        sphere("Pupil", (xx+.025,y-size*.43,z+.01), (size*.61,size*.25,size*.79), "black", 10, 6)
        sphere("Eye catchlight", (xx-size*.14,y-size*.65,z+size*.38), (size*.23,size*.10,size*.25), "white", 8, 4)


def smile(loc, width=.25):
    sphere("Happy mouth", loc, (width,.06,width*.48), "ink", 12, 6)
    sphere("Tongue", (loc[0],loc[1]-.05,loc[2]-width*.14), (width*.57,.024,width*.21), "pink", 8, 4)


def crown(loc, radius=.60, height=.66):
    x,y,z = loc
    # Continuous closed gold zigzag wall, rather than detached triangles.
    n = 20
    verts, faces = [], []
    for inner in (False,True):
        r = radius-(.12 if inner else 0)
        for upper in (False,True):
            for j in range(n):
                a = math.tau*j/n
                zz = z + (height*(1 if j%4 == 0 else .48) if upper else 0)
                verts.append((x+r*math.cos(a),y+r*math.sin(a),zz))
    for j in range(n):
        k=(j+1)%n
        faces.extend([(j,k,n+k,n+j),(2*n+j,3*n+j,3*n+k,2*n+k),(n+j,n+k,3*n+k,3*n+j),(j,2*n+j,2*n+k,k)])
    mesh("Five point crown",verts,faces,"gold")
    torus("Crown rolled band",(x,y,z+.04),radius-.03,.065,"goldLight",segments=20,sides=4)
    for j in range(5):
        a=math.tau*j/5
        sphere("Crown tip",(x+radius*math.cos(a),y+radius*math.sin(a),z+height),(.085,)*3,"goldLight",8,4)
    sphere("Crown ruby",(x,y-radius-.035,z+height*.30),(.14,.065,.17),"red",10,6)


def join_asset(name, target_span=None, toilet_datum=False):
    objects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    vs=obj.data.vertices
    lo=Vector(tuple(min(v.co[i] for v in vs) for i in range(3)))
    hi=Vector(tuple(max(v.co[i] for v in vs) for i in range(3)))
    factor=target_span/max(hi-lo) if target_span else 1
    offset=Vector((0,.04,0)) if toilet_datum else Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for v in vs:
        v.co=(v.co-offset)*factor
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    # Collapse joined copies of the shared slot to exactly one material.
    for p in obj.data.polygons:
        p.material_index=0
    obj.data.materials.clear()
    obj.data.materials.append(material())
    tri=obj.modifiers.new("Export triangles","TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=tri.name)
    obj.data.update()
    return obj


def validate(obj,budget):
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bad=sum(not e.is_manifold for e in bm.edges)
    tiny=sum(f.calc_area()<1e-10 for f in bm.faces)
    bm.free()
    tris=len(obj.data.polygons)
    assert tris<=budget, f"{obj.name}: {tris} > {budget}"
    assert bad==0, f"{obj.name}: {bad} non-manifold edges"
    assert tiny==0, f"{obj.name}: {tiny} zero-area triangles"
    assert len(obj.data.materials)==1 and obj.data.uv_layers
    assert len(obj.data.uv_layers)==1, f"{obj.name}: mixed UV layers would lose palette assignments"
    assert all(.01<float(c)<.99 for uv in obj.data.uv_layers[0].data for c in uv.uv), f"{obj.name}: UV outside padded atlas"
    assert all(math.isfinite(c) for v in obj.data.vertices for c in v.co)
    return tris


def export_asset(obj,category):
    path=ASSETS/"models"/category/(obj.name+".fbx")
    path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,object_types={"MESH"},global_scale=1.0,apply_unit_scale=True,apply_scale_options="FBX_SCALE_UNITS",axis_forward="Z",axis_up="Y",bake_space_transform=True,use_mesh_modifiers=True,mesh_smooth_type="FACE",use_triangles=True,bake_anim=False,path_mode="COPY",embed_textures=True)
    return path


def aim(obj,target):
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat("-Z","Y").to_euler()


def preview_stage(obj):
    scene=bpy.context.scene
    scene.render.engine="CYCLES"
    scene.cycles.samples=16
    scene.cycles.use_denoising=True
    scene.render.resolution_x=768
    scene.render.resolution_y=768
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.view_settings.view_transform="Standard"
    scene.view_settings.look="None"
    scene.view_settings.exposure=0
    scene.view_settings.gamma=1
    scene.world.use_nodes=True
    scene.world.node_tree.nodes.get("Background").inputs[0].default_value=(.40,.49,.66,1)
    scene.world.node_tree.nodes.get("Background").inputs[1].default_value=.32
    extent=max(obj.dimensions)
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.025))
    floor=bpy.context.object
    floor.name="Preview only - pastel floor"
    mat=bpy.data.materials.new("Preview pastel gradient")
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    shader=nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value=.9
    geo=nodes.new("ShaderNodeNewGeometry")
    sep=nodes.new("ShaderNodeSeparateXYZ")
    remap=nodes.new("ShaderNodeMapRange")
    remap.inputs["From Min"].default_value=-extent*2
    remap.inputs["From Max"].default_value=extent*3
    ramp=nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color=(.63,.77,.85,1)
    ramp.color_ramp.elements[1].color=(.71,.63,.88,1)
    links=mat.node_tree.links
    links.new(geo.outputs["Position"],sep.inputs[0])
    links.new(sep.outputs["Y"],remap.inputs[0])
    links.new(remap.outputs[0],ramp.inputs[0])
    links.new(ramp.outputs[0],shader.inputs["Base Color"])
    floor.data.materials.append(mat)
    for name,xyz,power,size in [("Large softbox",(-3,-4,7),650,5),("Cool fill",(4,-1,4),280,4),("Top rim",(1,5,6),750,3)]:
        data=bpy.data.lights.new(name,"AREA")
        light=bpy.data.objects.new(name,data)
        bpy.context.collection.objects.link(light)
        light.location=Vector(xyz)*(extent/3)
        data.energy=power*.65*(extent/3)**2
        data.shape="DISK"
        data.size=size*extent/3
        aim(light,(0,0,obj.dimensions.z/2))
    data=bpy.data.cameras.new("Preview camera")
    camera=bpy.data.objects.new("Preview camera",data)
    bpy.context.collection.objects.link(camera)
    scene.camera=camera
    data.type="ORTHO"
    data.lens=50
    return camera


def render_view(obj,camera,path,azimuth=32,elevation=19):
    scene=bpy.context.scene
    target=Vector((0,0,obj.dimensions.z*.48))
    a,e=math.radians(azimuth),math.radians(elevation)
    direction=Vector((math.sin(a)*math.cos(e),-math.cos(a)*math.cos(e),math.sin(e)))
    camera.location=target+direction*max(obj.dimensions)*4
    aim(camera,target)
    # Frame projected bounds rather than clipping wide foliage or long fish tails.
    inverse=camera.rotation_euler.to_matrix().transposed()
    projected=[inverse@(obj.matrix_world@Vector(corner)-target) for corner in obj.bound_box]
    span=max(max(v.x for v in projected)-min(v.x for v in projected),max(v.y for v in projected)-min(v.y for v in projected))
    camera.data.ortho_scale=span*1.25
    path.parent.mkdir(parents=True,exist_ok=True)
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)
