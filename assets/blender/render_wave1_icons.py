"""Wave 1 icons: read-only reuse of the original toy builders and icon pipeline.

Run with Blender 4.5 --background --factory-startup --python-exit-code 1.
Only this batch's PNGs/manifest and its ignored scratch directory are written.
"""
import argparse
import hashlib
import importlib
import json
import math
import os
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
import numpy as np
import render_icons as pipeline
from icon_pixels import downsample, read_png, sticker, write_png

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/icons'
SCRATCH = OUT / '.scratch/wave1'
# Keep the established three-quarter view; exceptions are thumbnail review fixes.
VIEWS = {'Clogtopus': (25, 24)}
FILL = .78  # Sculpture only; the shared contour adds about two percent.


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def catalog():
    data = json.loads((ROOT / 'docs/design/wave1-data.json').read_text(encoding='utf-8'))
    specs = [(s, category) for key, category in [('Items', 'items'), ('Toilets', 'toilets')]
             for s in data[key] if s['New']]
    sources = {}
    for group in 'abct':
        manifest = json.loads((ROOT / f'assets/manifest-wave1-{group}.json').read_text())
        for entry in manifest['assets']:
            assert entry['id'] not in sources
            sources[entry['id']] = dict(entry, group=group)
    assert len(specs) == len(sources) == 44
    assert sum(category == 'items' for _, category in specs) == 36
    assert {s['Id'] for s, _ in specs} == set(sources)
    for spec, category in specs:
        source = sources[spec['Id']]
        assert source['category'] == category
        assert source.get('display_name', source.get('name')) == spec['Name']
        assert (ROOT / source['source']).is_file()
        assert (ROOT / source['file']).is_file()
    return specs, sources


def install_builders():
    pipeline.lib.PALETTE['red'] = 'F42B48'  # Same override as the original icon entry.
    pipeline.install_render_geometry()
    # Import AFTER the render-density hooks so from-lib aliases use those hooks.
    modules = {g: importlib.import_module('wave1_' + g) for g in 'abct'}
    # The model budget uses single-segment trim; icons use the shared smooth bevel.
    modules['a'].box = pipeline.lib.box
    modules['b'].softbox = lambda name, loc, size, color, bevel=.04: pipeline.lib.box(name, loc, size, color, bevel)
    modules['c'].block = lambda name, loc, size, color, bevel=.10: pipeline.lib.box(name, loc, size, color, bevel)
    return modules


def enamel_from_uv(objects, celestial=False):
    """Retain per-face painted accents, including the crab's four drain slots."""
    keys = pipeline.lib.KEYS
    for obj in objects:
        if obj.type != 'MESH':
            continue
        uv = obj.data.uv_layers.active.data
        obj.data.materials.clear()
        for key in keys:
            obj.data.materials.append(pipeline.material(key))
        for face in obj.data.polygons:
            u, v = uv[face.loop_start].uv
            index = min(3, int(v * 4)) * 8 + min(7, int(u * 8))
            assert 0 <= index < 32
            if celestial and keys[index] == 'gray':
                index = keys.index('slate')
            face.material_index = index


def fit_source(objects, source):
    """Match the supplied models' proportions, without joining or exporting them."""
    points = pipeline.bounds(objects)
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    if source['group'] in 'ab':
        target = Vector([source['size_studs'][i] for i in (0, 2, 1)])
        factors = [target[i] / (hi[i] - lo[i]) for i in range(3)]
    else:
        # C is uniformly normalized; T preserves the shared bowl/seat dimensions.
        factor = max(source['size_studs']) / max(hi - lo) if source['group'] == 'c' else 1
        factors = [factor] * 3
    parent = bpy.data.objects.new('Wave 1 source proportions', None)
    bpy.context.collection.objects.link(parent)
    for obj in objects:
        if obj.parent not in objects:
            obj.parent = parent
    parent.scale = factors
    bpy.context.view_layer.update()


def frame(objects, azimuth, elevation):
    cam = pipeline.frame(objects, azimuth, elevation)
    # Project actual evaluated vertices, avoiding wasted space from rotated AABBs.
    dg = bpy.context.evaluated_depsgraph_get()
    inverse = cam.rotation_euler.to_matrix().transposed()
    points = []
    for obj in objects:
        ev = obj.evaluated_get(dg)
        mesh = ev.to_mesh()
        points.extend(inverse @ (ev.matrix_world @ v.co) for v in mesh.vertices)
        ev.to_mesh_clear()
    x0, x1 = min(v.x for v in points), max(v.x for v in points)
    y0, y1 = min(v.y for v in points), max(v.y for v in points)
    old = inverse @ cam.location
    offset = Vector(((x0 + x1) / 2 - old.x, (y0 + y1) / 2 - old.y, 0))
    cam.location += cam.rotation_euler.to_matrix() @ offset
    cam.data.ortho_scale = max(x1 - x0, y1 - y0) / FILL
    return cam


def render(spec, category, source, modules, args, output):
    name = spec['Id']
    resolution = 512 if args.draft else 1024
    pipeline.setup(resolution, resolution, args.samples)
    # Only Group C replaces the unused slate swatch with its private silver.
    pipeline.lib.PALETTE['slate'] = 'C4D4E5' if source['group'] == 'c' else '4C6091'
    modules[source['group']].BUILDERS[name]()
    objects = pipeline.meshes()
    enamel_from_uv(objects, spec.get('Rarity') == 'Celestial')
    fit_source(objects, source)
    azimuth, elevation = VIEWS.get(name, (25, 17))
    cam = frame(objects, azimuth, elevation)
    # Prefix the original pipeline's scratch name; no original render is replaced.
    raw = pipeline.render_raw('wave1/' + ('draft/' if args.draft else 'final/') + name)
    rgba = sticker(raw, radius=round(9 * resolution / 1024))
    for size in (512, 128):
        write_png(output / category / f'{name}_{size}.png', downsample(rgba, resolution // size))
    return dict(samples=args.samples, render_resolution=resolution, azimuth=azimuth,
                elevation=elevation, sculpture_fill=FILL, ortho_scale=round(cam.data.ortho_scale, 6),
                builder=f'assets/blender/wave1_{source["group"]}.py',
                builder_sha256=digest(ROOT / f'assets/blender/wave1_{source["group"]}.py'))


def records_for(specs, sources, output, settings):
    records = []
    for spec, category in specs:
        name = spec['Id']
        key = ('ItemIcons.' if category == 'items' else 'ToiletIcons.') + name
        for size in (512, 128):
            records.append(dict(id=name, name=name, display_name=spec['Name'], category=category,
                                file=(output / category / f'{name}_{size}.png').relative_to(ROOT).as_posix(),
                                size=[size, size], config_key=key, intended_assets_key='Assets.' + key,
                                transparent=True, source=sources[name]['source'],
                                integration_status='Not uploaded; manager-owned runtime integration',
                                render=settings.get(name)))
    return records


def validate(records, complete):
    count = 0
    for rec in records:
        path = ROOT / rec['file']
        if not path.exists():
            assert not complete, f'Missing {path}'
            continue
        assert rec['render'], f'Missing render provenance: {path}'
        a = read_png(path)
        h, w = a.shape[:2]
        assert [w, h] == rec['size'], path
        alpha = a[:, :, 3]
        assert alpha.min() == 0 and alpha.max() == 1, f'Invalid alpha: {path}'
        assert not any(edge.any() for edge in (alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1])), f'Clipped border: {path}'
        assert np.all(a[alpha == 0, :3] == 0), f'Matte RGB: {path}'
        yy, xx = np.where(alpha > .5)
        assert len(xx) > w * h * .065, f'Empty/tiny sculpture: {path}'
        span = max(xx.max() - xx.min() + 1, yy.max() - yy.min() + 1) / w
        assert .76 <= span <= .86, f'Inconsistent framing {span}: {path}'
        rec['validation'] = dict(passed=True, sha256=digest(path), bytes=path.stat().st_size,
                                 solid_bounds=[int(xx.min()), int(yy.min()), int(xx.max()+1), int(yy.max()+1)],
                                 longest_axis_percent=round(span * 100, 2), alpha='straight RGBA; zero RGB at zero alpha')
        count += 1
    return count


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--only', nargs='+')
    parser.add_argument('--samples', type=int, default=64)
    parser.add_argument('--draft', action='store_true')
    parser.add_argument('--validate-only', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    specs, sources = catalog()
    if args.only:
        args.only = [name for value in args.only for name in value.split(',') if name]
        unknown = set(args.only) - set(sources)
        if unknown:
            parser.error('Unknown Wave 1 IDs: ' + ', '.join(sorted(unknown)))
    if args.samples < 8:
        parser.error('At least eight samples are required')
    output = SCRATCH / 'draft' if args.draft else OUT / 'wave1'
    manifest_path = output / 'manifest-wave1.json' if args.draft else OUT / 'manifest-wave1.json'
    previous = json.loads(manifest_path.read_text()) if manifest_path.exists() else {'assets': []}
    settings = {r['id']: r['render'] for r in previous['assets']}
    if not args.validate_only:
        modules = install_builders()
        for spec, category in specs:
            if args.only and spec['Id'] not in args.only:
                continue
            print('WAVE1_ICON ' + spec['Id'], flush=True)
            settings[spec['Id']] = render(spec, category, sources[spec['Id']], modules, args, output)
    records = records_for(specs, sources, output, settings)
    count = validate(records, complete=not args.only)
    manifest = dict(version=1, renderer='Blender 4.5 / Cycles', generator='scripts/build-wave1-icons.ps1',
                    asset_count=44, png_count=88, validated=count, complete=count == 88,
                    draft=args.draft, assets=records,
                    notes=['36 new items and 8 new toilets; exact Wave 1 IDs and display names.',
                           '512px upload candidates; 128px inspection alternatives share the same intended key.',
                           'No rarity framing, uploads, runtime changes or mesh exports.',
                           'Shared studio lights, enamel, contour and soft alpha shadow from render_icons.py.',
                           'Geometry rebuilt at icon density in memory; sources and original pipeline are read-only.'])
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Validated {count}/88 Wave 1 PNGs. Complete: {count == 88}', flush=True)


if __name__ == '__main__':
    main()
    # Same local background-shutdown workaround as the Group C build; only after success.
    sys.stdout.flush()
    sys.stderr.flush()
    os._exit(0)
