"""Isolated campaign previews, for iteration while the main icon batch runs."""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import render_icons as r

r.OUT=r.OUT/'.scratch/art-review'
r.SCRATCH=r.OUT/'beauty'
r.lib.PALETTE['red']='F42B48'
r.lib.PALETTE['basketSlot']='841530'
r.install_render_geometry()
names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['Logo','GameIcon','HubScene','RareDrop','ToiletLineup']
for name in names:
    print('ART_REVIEW '+name,flush=True)
    r.render_art(name,32)
