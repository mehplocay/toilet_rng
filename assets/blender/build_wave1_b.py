"""Isolated Wave 1 B build and strict FBX round-trip verification."""
import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from lib import ROOT, ASSETS, clean_scene, join_asset, validate, export_asset, preview_stage, render_view
from wave1_b import BUILDERS

MANIFEST=ASSETS/'manifest-wave1-b.json'
VALIDATION=ASSETS/'validation-wave1-b.json'
PREVIEWS=ASSETS/'previews/wave1/b'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(entries):
    results=[]
    atlas=(ASSETS/'textures/ToyPalette.png').read_bytes()
    for entry in entries:
        clean_scene()
        path=ROOT/entry['file']
        assert digest(path)==entry['fbx_sha256']
        # Exact embedded atlas bytes, not just an incidental PNG signature.
        assert atlas in path.read_bytes(),entry['id']+' missing embedded palette'
        bpy.ops.import_scene.fbx(filepath=str(path),use_custom_normals=True)
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        assert len(meshes)==1 and len(bpy.context.scene.objects)==1
        obj=meshes[0]
        tris=validate(obj,entry['budget'])
        assert tris==entry['tris']
        corners=[obj.matrix_world@Vector(v) for v in obj.bound_box]
        lo=[min(v[i] for v in corners) for i in range(3)]
        hi=[max(v[i] for v in corners) for i in range(3)]
        dims=[hi[i]-lo[i] for i in range(3)]
        expected=[entry['size_studs'][i] for i in (0,2,1)]
        assert max(abs(a-b) for a,b in zip(dims,expected))<.001
        assert abs(lo[2])<.001 and abs(lo[0]+hi[0])<.001 and abs(lo[1]+hi[1])<.001
        assert obj.matrix_world.translation.length<.001
        textures=[n.image for m in obj.data.materials for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
        assert textures and all(tuple(img.size)==(256,256) for img in textures)
        results.append({'id':entry['id'],'tris':tris,'fbx_round_trip':'passed','one_mesh_one_material':True,
                        'closed_components':True,'finite_vertices':True,'padded_uvs':True,
                        'exact_embedded_atlas':True,'base_center_origin':True,'size_tolerance_studs':.001})
        print('ROUND_TRIP_OK',entry['id'],flush=True)
    VALIDATION.write_text(json.dumps({'scope':'Blender FBX round trip; no Studio upload performed','assets':results},indent=2)+'\n')


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--only',nargs='+',choices=list(BUILDERS))
    parser.add_argument('--no-render',action='store_true')
    parser.add_argument('--verify-only',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    atlas_hash=digest(ASSETS/'textures/ToyPalette.png')
    specs=[i for i in json.loads((ROOT/'docs/design/wave1-data.json').read_text(encoding='utf-8'))['Items']
           if i['New'] and i['Rarity'] in ('Epic','Legendary','Mythic')]
    assert set(BUILDERS)=={i['Id'] for i in specs} and len(specs)==12
    if args.verify_only:
        manifest=json.loads(MANIFEST.read_text())
        assert manifest['atlas_sha256']==atlas_hash
        verify(manifest['assets'])
        return
    previous=json.loads(MANIFEST.read_text())['assets'] if MANIFEST.exists() and args.only else []
    records={e['id']:e for e in previous}
    bpy.context.preferences.filepaths.save_version=0
    for spec in specs:
        name=spec['Id']
        if args.only and name not in args.only:
            continue
        clean_scene()
        BUILDERS[name]()
        obj=join_asset(name)
        bpy.context.view_layer.update()
        # Brief boxes are authoritative Roblox X/Y/Z stud targets.
        target=[spec['Model']['SizeStuds'][i] for i in (0,2,1)]
        factors=[target[i]/obj.dimensions[i] for i in range(3)]
        for vertex in obj.data.vertices:
            for i in range(3):
                vertex.co[i]*=factors[i]
        obj.data.update()
        bpy.context.view_layer.update()
        budget=spec['Model']['TriangleBudget']
        tris=validate(obj,budget)
        path=export_asset(obj,'wave1/b')
        source=ASSETS/'blender/generated/wave1/b'/(name+'.blend')
        source.parent.mkdir(parents=True,exist_ok=True)
        for mat in obj.data.materials:
            for node in mat.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image and not node.image.packed_file:
                    node.image.pack()
        bpy.ops.wm.save_as_mainfile(filepath=str(source),check_existing=False)
        records[name]={'id':name,'name':spec['Name'],'category':'items','rarity':spec['Rarity'],
                       'file':path.relative_to(ROOT).as_posix(),'tris':tris,'budget':budget,
                       'size_studs':spec['Model']['SizeStuds'],'pivot':'base-center','mesh_count':1,'material_count':1,
                       'texture':'assets/textures/ToyPalette.png','fbx_sha256':digest(path),
                       'source':source.relative_to(ROOT).as_posix(),
                       'preview':f'assets/previews/wave1/b/{name}.png',
                       'front_preview':f'assets/previews/wave1/b/{name}_front.png'}
        manifest={'schema_version':1,'generator':'assets/blender/build_wave1_b.py','group':'Wave 1 B',
                  'units':'stud','coordinate_system':'Y-up/Z-forward export; Z-up/-Y-front author; size order Roblox X/Y/Z',
                  'import_settings':{'scale_unit':'Stud','scale_factor':1,'world_forward':'Front','world_up':'Top'},
                  'atlas_sha256':atlas_hash,'assets':[records[i['Id']] for i in specs if i['Id'] in records]}
        MANIFEST.write_text(json.dumps(manifest,indent=2)+'\n')
        print(f'ASSET_OK {name} {tris}/{budget}',flush=True)
        if not args.no_render:
            camera=preview_stage(obj)
            bpy.context.scene.cycles.samples=16
            bpy.context.scene.cycles.use_adaptive_sampling=True
            bpy.context.scene.cycles.adaptive_threshold=.08
            bpy.context.scene.cycles.adaptive_min_samples=4
            elevation=30 if name=='Clogtopus' else 19
            azimuth=22 if name=='Clogtopus' else 32
            render_view(obj,camera,PREVIEWS/(name+'.png'),azimuth,elevation)
            render_view(obj,camera,PREVIEWS/(name+'_front.png'),0,8)
    assert digest(ASSETS/'textures/ToyPalette.png')==atlas_hash
    verify(manifest['assets'])
    print('WAVE1_B_OK',len(records),flush=True)


if __name__=='__main__':
    main()
