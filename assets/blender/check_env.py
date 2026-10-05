"""Audit the delivered environment files and the assembly recipe after rendering."""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/"assets"
manifest=json.loads((ASSETS/"manifest-env.json").read_text())
entries=manifest["assets"]
validation=json.loads((ASSETS/"validation-env.json").read_text())
names={a["name"] for a in entries}
assert len(entries)==len(names)==44
assert {a["name"] for a in validation["assets"]}==names
assert {f:sum(a["family"]==f for a in entries) for f in ("hub","plot","island","background","hero")}=={
    "hub":7,"plot":7,"island":14,"background":9,"hero":7}
assert {p.stem for p in (ASSETS/"models/env").glob("*.fbx")}==names
assert hashlib.sha256((ASSETS/"textures/ToyPalette.png").read_bytes()).hexdigest()==manifest["atlas_sha256"]
for a in entries:
    assert a["tris"]<=a["budget"]<20000
    assert max(a["size_studs"])<256 and min(a["size_studs"])>0
    assert hashlib.sha256((ROOT/a["file"]).read_bytes()).hexdigest()==a["fbx_sha256"]
    assert (ROOT/a["source"]).stat().st_size>0
    for key in ("preview","front_preview"):
        data=(ROOT/a[key]).read_bytes()
        assert data[:8]==b"\x89PNG\r\n\x1a\n"
        assert struct.unpack(">II",data[16:24])==(768,768),(a["name"],key)
    result=next(v for v in validation["assets"] if v["name"]==a["name"])
    assert result["fbx_round_trip"]=="passed" and result["tris"]==a["tris"]
lookup={a["name"]:a for a in entries}
# Critical modular contracts: the fence fits its recess; ring sectors close;
# and three path strips meet the plot ring's one-stud grass threshold.
platform=lookup["PlotPlatform"]["assembly"]
fence=lookup["PlotFenceSection"]["assembly"]
assert abs(platform["fence_slot_width"]-fence["post_width"]-.1)<1e-6
assert platform["fence_channels"]==[-14.35,14.35]
assert lookup["HubRingSegment"]["assembly"]["sector_degrees"]*10==360
assert 32+3*lookup["HubPathStrip"]["assembly"]["grid"][1]+1==85-32/2

layout=json.loads((ASSETS/"env-layout.json").read_text())
original=json.loads((ASSETS/"manifest.json").read_text())
lookup.update({a["name"]:a for a in original["assets"]})
placements=layout["placements"]
assert len(placements)==layout["mesh_instances"]
assert sum(lookup[p["asset"]]["tris"] for p in placements)==layout["placed_triangles"]
plots=[p for p in placements if p["asset"]=="PlotPlatform"]
assert len(plots)==10
for p in plots:
    x,y,z=p["position_studs"]
    assert abs(math.hypot(x,z)-85)<.0001 and y==13.4
assert all(all(math.isfinite(v) for v in p["position_studs"]) and p["scale"]>0 for p in placements)
for p in placements:
    if p["asset"] in ("IndexBookPedestal","CollectCoinJar"):
        x,y,z=p["position_studs"]
        dims=lookup[p["asset"]]["size_studs"]
        foot_radius=max(dims[0],dims[2])*p["scale"]/2
        assert math.hypot(x,z)-foot_radius>33.5, "Pedestal foot intersects plaza curb"
        assert y==13.4, "Pedestal base must rest on the lawn datum"
for family in ("hub","plot","island","background","hero"):
    for suffix in ("","_front"):
        assert (ASSETS/f"previews/_sheet_env_{family}{suffix}.png").stat().st_size>1000
for name in ("_env_assembled","_env_spawn","_env_plot"):
    assert (ASSETS/f"previews/{name}.png").stat().st_size>1000
summary={"assets":44,"individual_previews":88,"contact_sheets":10,"assembly_views":3,
         "unique_triangles":sum(a["tris"] for a in entries),
         "maximum_asset_triangles":max(a["tris"] for a in entries),
         "maximum_dimension_studs":max(max(a["size_studs"]) for a in entries),
         "assembly_mesh_instances":layout["mesh_instances"],
         "assembly_placed_triangles":layout["placed_triangles"],
         "status":"passed","boundary":"Local artifact and Blender round-trip audit; Studio acceptance remains required"}
(ASSETS/"validation-env-delivery.json").write_text(json.dumps(summary,indent=2)+"\n")
print("ENV_DELIVERY_OK",json.dumps(summary),flush=True)
