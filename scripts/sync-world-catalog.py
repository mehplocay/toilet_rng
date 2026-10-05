"""Refresh runtime sizes and toilet pivot centers from existing manifest/.blend files; run with Blender."""
import bpy, json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'assets/manifest.json').read_text())
lines=['-- Sizes copied from assets/manifest.json (Roblox X/Y/Z studs).','-- Toilet centers preserve the common foot datum; measured from the generated Blender meshes.','return {']
for a in manifest['assets']:
    size=', '.join(str(n) for n in a['size_studs'])
    extra=''
    if a['category']=='toilets':
        bpy.ops.wm.open_mainfile(filepath=str(root/'assets/blender/generated'/f"{a['name']}.blend"))
        ob=bpy.data.objects[a['name']]
        lo=[min(v.co[i] for v in ob.data.vertices) for i in range(3)]
        hi=[max(v.co[i] for v in ob.data.vertices) for i in range(3)]
        c=[(lo[i]+hi[i])/2 for i in range(3)]
        extra=', Center = Vector3.new('+', '.join(f'{c[i]:.6f}' for i in (0,2,1))+')'
    lines.append('\t'+a['name']+' = { Size = Vector3.new('+size+'), Triangles = '+str(a['tris'])+extra+' },')
lines.append('}')
(root/'src/shared/Config/MeshCatalog.luau').write_text('\n'.join(lines)+'\n')
