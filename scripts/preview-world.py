"""Offline composition preview, NOT a Roblox rendering/permission test.

Export: ./scripts/check-visuals.ps1 -MeshMode Ready -Snapshot
Render: blender --background --factory-startup --python scripts/preview-world.py
Uses authored .blend geometry for mock-loaded MeshParts, and a heightfield instead
of Roblox voxels. Engine lighting, streaming, UI, particles and physics differ.
"""
from pathlib import Path
import math
import sys
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.cycles.use_denoising = True
scene.render.resolution_x = 1400
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "Standard"
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.36, .62, .85, 1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = .65
materials = {}


def material(color, neon=False):
    key = tuple(round(v, 3) for v in color) + (neon,)
    if key not in materials:
        m = bpy.data.materials.new(str(key))
        m.diffuse_color = (*color, 1)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1)
        bsdf.inputs["Roughness"].default_value = .65
        if neon:
            bsdf.inputs["Emission Color"].default_value = (*color, 1)
            bsdf.inputs["Emission Strength"].default_value = .7
        materials[key] = m
    return materials[key]


# Roblox X/Y/Z -> Blender X/-Z/Y (right-handed coordinate transform).
CONVERT = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def position(x, y, z):
    return Vector((x, -z, y))


prototypes = {}
for shape in ("Block", "Ball", "Cylinder", "Wedge"):
    if shape == "Block":
        bpy.ops.mesh.primitive_cube_add(size=1)
    elif shape == "Ball":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=.5)
    elif shape == "Cylinder":
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=.5, depth=1)
        for v in bpy.context.object.data.vertices:
            v.co = Vector((v.co.z, v.co.y, -v.co.x))
    else:
        mesh = bpy.data.meshes.new("Wedge")
        mesh.from_pydata([(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,.5),(.5,.5,.5)], [],
                        [(0,2,3,1),(0,1,5,4),(2,4,5,3),(0,4,2),(1,3,5)])
        ob = bpy.data.objects.new("Wedge", mesh)
        scene.collection.objects.link(ob)
        bpy.context.view_layer.objects.active = ob
    ob = bpy.context.object
    prototypes[shape] = ob.data.copy()
    bpy.data.objects.remove(ob, do_unlink=True)

asset_meshes = {}
heights = {}
last_part = None
for line in (ROOT / ".world-scene.txt").read_text(encoding="utf-8-sig").splitlines():
    fields = line.split("|")
    if fields[1] == "HEIGHT":
        x, z, height = map(float, fields[2].split(","))
        heights[(int(x), int(z))] = height
    elif fields[1] == "PART":
        _, _, name, cls, shape, mat, data = fields
        values = list(map(float, data.split(",")))
        size, color, pos, rotation = values[:3], values[3:6], values[6:9], values[9:]
        cf = Matrix(((rotation[0], rotation[1], rotation[2], pos[0]),
                     (rotation[3], rotation[4], rotation[5], pos[1]),
                     (rotation[6], rotation[7], rotation[8], pos[2]), (0, 0, 0, 1)))
        if cls == "MeshPart":
            if name not in asset_meshes:
                with bpy.data.libraries.load(str(ROOT / "assets/blender/generated" / (name + ".blend")), link=False) as (src, dst):
                    dst.objects = [name]
                source = dst.objects[0]
                mesh = source.data.copy()
                # Recenter to bounds, then normalize in Roblox axes to match MeshPart.Size.
                lo = Vector(tuple(min(v.co[i] for v in mesh.vertices) for i in range(3)))
                hi = Vector(tuple(max(v.co[i] for v in mesh.vertices) for i in range(3)))
                center = (lo + hi) * .5
                for v in mesh.vertices:
                    p = v.co - center
                    v.co = Vector((p.x/(hi.x-lo.x), p.z/(hi.z-lo.z), p.y/(hi.y-lo.y)))
                asset_meshes[name] = mesh
                bpy.data.objects.remove(source, do_unlink=True)
            mesh = asset_meshes[name]
        else:
            shape = "Wedge" if cls == "WedgePart" else shape.split(".")[-1]
            mesh = prototypes.get(shape, prototypes["Block"])
        ob = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(ob)
        ob.matrix_world = CONVERT @ cf @ Matrix.Diagonal((*size, 1))
        if cls != "MeshPart":
            m = material(color, mat.endswith("Neon"))
            if not ob.data.materials:
                ob.data.materials.append(m)
            ob.material_slots[0].link = "OBJECT"
            ob.material_slots[0].material = m
        last_part = (cf, size)
    elif fields[1] == "TEXT" and last_part:
        cf, size = last_part
        text = "|".join(fields[3:]).replace("~", "\n")
        curve = bpy.data.curves.new("Sign text", "FONT")
        curve.body, curve.align_x, curve.align_y = text, "CENTER", "CENTER"
        longest = max(map(len, text.splitlines()))
        curve.size = min(size[0] / max(1, longest) * 1.55, size[1] / len(text.splitlines()) * .72)
        curve.space_line = 1.2
        ob = bpy.data.objects.new("Sign text", curve)
        scene.collection.objects.link(ob)
        ob.matrix_world = CONVERT @ cf @ Matrix.Translation((0,0,-size[2]/2-.02)) @ Matrix.Rotation(math.pi,4,"Y")
        curve.materials.append(material((1,.95,.76)))

vertices, faces = [], []
for x in range(-320,321,4):
    for z in range(-320,321,4):
        vertices.append(position(x, heights[x,z], z))
for x in range(160):
    for z in range(160):
        a=x*161+z
        faces.append((a,a+1,a+162,a+161))
mesh = bpy.data.meshes.new("Island heightfield approximation")
mesh.from_pydata(vertices, [], faces)
terrain = bpy.data.objects.new("Island", mesh)
scene.collection.objects.link(terrain)
for color in ((.23,.61,.11),(.92,.72,.35),(.25,.39,.50)):
    mesh.materials.append(material(color))
for poly in mesh.polygons:
    center = sum((vertices[i] for i in poly.vertices), Vector()) / len(poly.vertices)
    radius = math.hypot(center.x,center.y)
    poly.material_index = 2 if radius>180 else (1 if radius>112 and center.z<2 else 0)
    poly.use_smooth = True
bpy.ops.mesh.primitive_plane_add(size=640, location=(0,0,-8))
bpy.context.object.data.materials.append(material((.025,.53,.68)))
bpy.ops.object.light_add(type="SUN", location=(80,-100,150))
sun = bpy.context.object
sun.data.energy, sun.data.angle = 2.2, .08
sun.rotation_euler = (math.radians(30), math.radians(-25), math.radians(-35))
bpy.ops.object.camera_add()
camera = bpy.context.object
scene.camera = camera
out = ROOT / "docs/world-previews"
out.mkdir(exist_ok=True)
for name, eye, target, lens in (
    ("overview", (180,185,-235), (0,0,0), 38),
    ("spawn", (9,8,-39), (0,9,12), 23),
    ("plot", (6,9,-64), (0,6,-89), 22),
):
    camera.location = position(*eye)
    camera.rotation_euler = (position(*target)-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.lens = lens
    suffix = "-fallback" if "--fallback" in sys.argv else ""
    scene.render.filepath = str(out / (name + suffix + ".png"))
    bpy.ops.render.render(write_still=True)
