"""Assemble this generator's PNG diagnostics without external imaging packages."""
import json
from pathlib import Path
import struct
import sys
import zlib

sys.dont_write_bytecode = True
import numpy as np
from audio_support import png

ROOT=Path(__file__).resolve().parents[1]/'assets/audio'


def read_preview(path):
    # Deliberately limited to audio_support.png's RGB8, filter-zero format.
    data=path.read_bytes()
    assert data[:8]==b'\x89PNG\r\n\x1a\n'
    pos=8
    compressed=[]
    width=height=None
    while pos<len(data):
        size=struct.unpack_from('>I',data,pos)[0]
        kind=data[pos+4:pos+8]
        payload=data[pos+8:pos+8+size]
        if kind==b'IHDR':
            width,height,depth,color,compression,filter_method,interlace=struct.unpack('>IIBBBBB',payload)
            assert (depth,color,compression,filter_method,interlace)==(8,2,0,0,0)
        elif kind==b'IDAT':
            compressed.append(payload)
        pos+=size+12
    rows=np.frombuffer(zlib.decompress(b''.join(compressed)),np.uint8).reshape(height,width*3+1)
    assert np.all(rows[:,0]==0)
    return rows[:,1:].reshape(height,width,3)


def main():
    entries=json.loads((ROOT/'manifest.json').read_text())['assets']
    groups=[entries[start:start+8] for start in (21,29,37,45)]
    references={'Click','CoinCollect','Flush','Epic','Legendary','Mythic','PurchaseSuccess','ServerEvent'}
    groups.append([e for e in entries if e['key'] in references])
    for index,group in enumerate(groups,1):
        canvas=np.full((1540,1200,3),(15,24,40),np.uint8)
        for tile,entry in enumerate(group):
            source=read_preview(ROOT/'previews'/f"{entry['key']}.png")
            # Box averaging retains narrow spectral features at half size.
            small=np.rint(source.reshape(385,2,600,2,3).mean(axis=(1,3))).astype(np.uint8)
            y,x=(tile//2)*385,(tile%2)*600
            canvas[y:y+385,x:x+600]=small
        png(ROOT/'previews'/f'contact-{index}.png',canvas)
    print('Generated four new-cue contact sheets and one original-palette sheet')


if __name__=='__main__':
    main()
