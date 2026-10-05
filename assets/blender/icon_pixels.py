"""Deterministic PNG compositing. NumPy ships with Blender; no pip dependencies.

All resizing and layering uses premultiplied alpha. Delivered PNGs use straight
alpha, with zero RGB in fully transparent pixels (no white matte).
"""
import struct
import zlib
from pathlib import Path
import numpy as np


def read_png(path):
    data = Path(path).read_bytes()
    offset, packed = 8, bytearray()
    while offset < len(data):
        size = struct.unpack('>I', data[offset:offset+4])[0]
        kind, chunk = data[offset+4:offset+8], data[offset+8:offset+8+size]
        if kind == b'IHDR':
            width, height, depth, color, _, _, interlace = struct.unpack('>IIBBBBB', chunk)
        elif kind == b'IDAT':
            packed.extend(chunk)
        offset += size + 12
    assert depth == 8 and color in (2, 6) and interlace == 0
    channels = 4 if color == 6 else 3
    rows = np.frombuffer(zlib.decompress(packed), dtype=np.uint8).reshape(height, width*channels+1)
    out = np.zeros((height, width*channels), dtype=np.uint8)
    for y in range(height):
        f = rows[y, 0]
        row = rows[y, 1:].astype(np.int32)
        up = out[y-1].astype(np.int32) if y else np.zeros_like(row)
        if f == 0:
            pass
        elif f == 2:
            row += up
        elif f == 1:
            row = np.cumsum(row.reshape(width, channels), axis=0).reshape(-1)
        else:
            row, up = row.tolist(), up.tolist()
            for x in range(len(row)):
                a = row[x-channels] % 256 if x >= channels else 0
                b = up[x]
                c = up[x-channels] if x >= channels else 0
                if f == 3:
                    row[x] += (a+b)//2
                elif f == 4:
                    p = a+b-c
                    pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
                    row[x] += a if pa <= pb and pa <= pc else b if pb <= pc else c
                else:
                    raise ValueError(f'Unsupported PNG filter {f}')
                row[x] %= 256
            row = np.asarray(row, dtype=np.int32)
        out[y] = row % 256
    rgba = out.reshape(height, width, channels).astype(np.float32)/255
    if channels == 3:
        rgba = np.concatenate((rgba, np.ones((height, width, 1), np.float32)), axis=2)
    return rgba


def write_png(path, rgba):
    pixels = np.round(np.clip(rgba, 0, 1)*255).astype(np.uint8)
    pixels[pixels[:, :, 3] == 0, :3] = 0
    opaque = np.all(pixels[:, :, 3] == 255)
    if opaque:
        pixels = pixels[:, :, :3]
    h, w, channels = pixels.shape
    # Sub filter is lossless and keeps the large campaign images below 3 MB.
    delta = pixels.copy()
    delta[:, 1:] -= pixels[:, :-1]
    raw = b''.join(b'\x01'+row.tobytes() for row in delta)
    def chunk(kind, payload):
        return struct.pack('>I', len(payload))+kind+payload+struct.pack('>I', zlib.crc32(kind+payload)&0xffffffff)
    result = b'\x89PNG\r\n\x1a\n'
    result += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2 if opaque else 6, 0, 0, 0))
    result += chunk(b'sRGB', b'\x00')
    result += chunk(b'IDAT', zlib.compress(raw, 9))+chunk(b'IEND', b'')
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(result)


def over(top, bottom):
    a, b = top[:, :, 3:4], bottom[:, :, 3:4]
    alpha = a+b*(1-a)
    rgb = (top[:, :, :3]*a+bottom[:, :, :3]*b*(1-a))/np.maximum(alpha, 1e-8)
    return np.concatenate((rgb, alpha), axis=2)


def downsample(rgba, factor):
    h, w = rgba.shape[:2]
    premul = rgba.copy()
    premul[:, :, :3] *= premul[:, :, 3:4]
    out = premul.reshape(h//factor, factor, w//factor, factor, 4).mean(axis=(1, 3))
    out[:, :, :3] /= np.maximum(out[:, :, 3:4], 1e-8)
    return out


def shift(a, dx, dy):
    out = np.zeros_like(a)
    h, w = a.shape
    out[max(0,dy):min(h,h+dy), max(0,dx):min(w,w+dx)] = a[max(0,-dy):min(h,h-dy), max(0,-dx):min(w,w-dx)]
    return out


def blur(a, sigma):
    radius = int(sigma*3)
    weights = np.exp(-np.arange(-radius, radius+1, dtype=np.float32)**2/(2*sigma*sigma))
    weights /= weights.sum()
    a = sum(shift(a, i-radius, 0)*v for i,v in enumerate(weights))
    return sum(shift(a, 0, i-radius)*v for i,v in enumerate(weights))


def sticker(rgba, radius=7, shadow=True):
    alpha = rgba[:, :, 3]
    dilated = alpha.copy()
    for y in range(-radius, radius+1):
        for x in range(-radius, radius+1):
            if x*x+y*y <= radius*radius:
                np.maximum(dilated, shift(alpha, x, y), out=dilated)
    ink = np.zeros_like(rgba)
    ink[:, :, :3] = (0.035, 0.045, 0.09)
    ink[:, :, 3] = dilated
    result = over(rgba, ink)
    if shadow:
        shade = np.zeros_like(rgba)
        shade[:, :, :3] = (0.025, 0.035, 0.065)
        shade[:, :, 3] = blur(shift(dilated, 4, 12), 7)*.26
        result = over(result, shade)
    return result


def backdrop(width, height, theme='blue'):
    y, x = np.mgrid[0:height, 0:width].astype(np.float32)
    x = (x/width-.50)*width/height
    y = y/height-.47
    r = np.sqrt(x*x+y*y)
    themes = {'blue': ((.03,.18,.68),(.16,.83,1.0)),
              'gold': ((.20,.015,.40),(1.0,.66,.09)),
              'purple': ((.055,.025,.27),(.51,.24,.91))}
    outer, inner = map(np.array, themes[theme])
    mix = np.clip(1-r*1.12, 0, 1)**1.7
    rgb = outer[None,None,:]*(1-mix[:,:,None])+inner[None,None,:]*mix[:,:,None]
    ray = (np.cos(np.arctan2(y,x)*18)>.72).astype(np.float32)*.065*np.clip(r,0,.8)
    rgb += ray[:,:,None]
    return np.concatenate((np.clip(rgb,0,1), np.ones((height,width,1))), axis=2).astype(np.float32)
