"""Huge resort composition preview, NOT a Roblox rendering/permission test.

Export: ./scripts/check-visuals.ps1 -MeshMode Ready -Snapshot
Render: blender --background --factory-startup --python scripts/preview-map.py
Uses authored .blend geometry for mock-loaded MeshParts and a flat water surface.
Engine lighting, streaming, UI, particles and physics differ.
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
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "Standard"
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.36, .62, .85, 1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = .65
materials = {}
label_font = bpy.data.fonts.load("C:/Windows/Fonts/arialbd.ttf")


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
labels = []
last_part = None
for line in (ROOT / ".world-scene.txt").read_text(encoding="utf-8-sig").splitlines():
    fields = line.split("|")
    if fields[1] == "HEIGHT":
        x, z, height = map(float, fields[2].split(","))
        heights[(int(x), int(z))] = height
    elif fields[1] == "PART":
        _, _, name, cls, shape, mat, data, solid = fields
        values = list(map(float, data.split(",")))
        size, color, pos, rotation = values[:3], values[3:6], values[6:9], values[9:]
        cf = Matrix(((rotation[0], rotation[1], rotation[2], pos[0]),
                     (rotation[3], rotation[4], rotation[5], pos[1]),
                     (rotation[6], rotation[7], rotation[8], pos[2]), (0, 0, 0, 1)))
        if cls == "MeshPart":
            if name not in asset_meshes:
                source_path = ROOT / "assets/blender/generated" / (name + ".blend")
                if not source_path.exists():
                    candidates = list((ROOT / "assets/blender/generated").rglob(name + ".blend"))
                    if len(candidates) != 1:
                        raise ValueError(f"Expected one authored mesh for {name}, found {len(candidates)}")
                    source_path = candidates[0]
                with bpy.data.libraries.load(str(source_path), link=False) as (src, dst):
                    dst.objects = [name]
                source = dst.objects[0]
                mesh = source.data.copy()
                # Recenter to bounds, then normalize in Roblox axes to match MeshPart.Size.
                lo = Vector(tuple(min(v.co[i] for v in mesh.vertices) for i in range(3)))
                hi = Vector(tuple(max(v.co[i] for v in mesh.vertices) for i in range(3)))
                center = (lo + hi) * .5
                for v in mesh.vertices:
                    p = v.co - center
                    v.co = Vector((-p.x/(hi.x-lo.x), p.z/(hi.z-lo.z), -p.y/(hi.y-lo.y)))
                asset_meshes[name] = mesh
                bpy.data.objects.remove(source, do_unlink=True)
            mesh = asset_meshes[name]
        else:
            shape = "Wedge" if cls == "WedgePart" else shape.split(".")[-1]
            mesh = prototypes.get(shape, prototypes["Block"])
        ob = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(ob)
        ob.matrix_world = CONVERT @ cf @ Matrix.Diagonal((*size, 1))
        if cls != "MeshPart" or solid == "true":
            m = material(color, mat.endswith("Neon"))
            if not ob.data.materials:
                ob.data.materials.append(m)
            ob.material_slots[0].link = "OBJECT"
            ob.material_slots[0].material = m
        elif min(color) < .99:
            tinted = ob.data.materials[0].copy()
            bsdf = tinted.node_tree.nodes.get("Principled BSDF")
            texture = next((n for n in tinted.node_tree.nodes if n.type == "TEX_IMAGE"), None)
            if texture:
                mix = tinted.node_tree.nodes.new("ShaderNodeMixRGB")
                mix.blend_type = "MULTIPLY"
                mix.inputs[0].default_value = 1
                mix.inputs[2].default_value = (*color,1)
                tinted.node_tree.links.new(texture.outputs["Color"], mix.inputs[1])
                tinted.node_tree.links.new(mix.outputs[0], bsdf.inputs["Base Color"])
            else: bsdf.inputs["Base Color"].default_value = (*color,1)
            ob.material_slots[0].link = "OBJECT"
            ob.material_slots[0].material = tinted
        last_part = (cf, size)
    elif fields[1] == "LABEL":
        text = fields[2].replace("~", "\n")
        values = list(map(float, fields[3].split(",")))
        size, pos, r = values[:3], values[3:6], values[6:]
        cf = Matrix(((r[0],r[1],r[2],pos[0]),(r[3],r[4],r[5],pos[1]),(r[6],r[7],r[8],pos[2]),(0,0,0,1)))
        curve = bpy.data.curves.new("World label approximation", "FONT")
        curve.font = label_font
        curve.body, curve.align_x, curve.align_y = text, "CENTER", "CENTER"
        longest = max(map(len, text.splitlines())) if text else 1
        curve.size = min(size[0] / max(1, longest) * 1.55, size[1] / max(1,len(text.splitlines())) * .72)
        curve.space_line = 1.2
        ob = bpy.data.objects.new("World label approximation", curve)
        scene.collection.objects.link(ob)
        ob.matrix_world = CONVERT @ cf @ Matrix.Translation((0,0,-size[2]/2-.02)) @ Matrix.Rotation(math.pi,4,"Y")
        color = tuple(map(float, fields[6].split(','))) if len(fields)>6 else (1,.95,.76)
        curve.materials.append(material(color, True))
        labels.append((ob, fields[4] if len(fields)>4 else 'SurfaceGui', float(fields[5]) if len(fields)>5 else 1000))

bpy.ops.mesh.primitive_plane_add(size=1536, location=(0,0,-15))
bpy.context.object.data.materials.append(material((.025,.53,.68)))
bpy.ops.object.light_add(type="SUN", location=(80,-100,150))
sun = bpy.context.object
sun.data.energy, sun.data.angle = 2.2, .08
sun.rotation_euler = (math.radians(30), math.radians(-25), math.radians(-35))
bpy.ops.object.camera_add()
camera = bpy.context.object
scene.camera = camera
camera.data.clip_end = 5000
out = ROOT / "docs/map-previews"
out.mkdir(exist_ok=True)
for name, eye, target, lens in (
    ("overview", (470,480,-670), (0,0,0), 40),
    ("hub", (5,10,-143), (0,39,0), 22),
    ("plot", (-112,20,-84), (-162,4,-48), 25),
    ("boards", (0,13,73), (0,21,150), 16),
):
    camera.location = position(*eye)
    camera.rotation_euler = (position(*target)-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.lens = lens
    for label, kind, distance in labels:
        label.hide_render = (label.location-camera.location).length > distance
        if kind == 'BillboardGui':
            label.rotation_euler = camera.rotation_euler
    suffix = "-fallback" if "--fallback" in sys.argv else ""
    scene.render.filepath = str(out / (name + suffix + ".png"))
    bpy.ops.render.render(write_still=True)
