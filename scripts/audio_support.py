"""NumPy-only audio I/O, metering and PNG diagnostics. No external audio samples."""
from __future__ import annotations

import ctypes as ct
import ctypes.util
import hashlib
import os
from pathlib import Path
import struct
import sys
import zlib

import numpy as np

SR = 32000


class SFInfo(ct.Structure):
    _fields_ = [("frames", ct.c_int64), ("samplerate", ct.c_int),
                ("channels", ct.c_int), ("format", ct.c_int),
                ("sections", ct.c_int), ("seekable", ct.c_int)]


class Codec:
    """Use an existing libsndfile; Blender bundles it on this Windows machine."""
    def __init__(self, library=None):
        candidates = [library, os.environ.get("SNDFILE_LIBRARY")]
        candidates += [str(p / "blender.shared" / "sndfile.dll")
                       for p in Path(sys.executable).resolve().parents]
        candidates += [ct.util.find_library("sndfile")]
        self.lib = None
        for name in filter(None, candidates):
            try:
                self.lib = ct.CDLL(name)
                break
            except OSError:
                pass
        if self.lib is None:
            raise RuntimeError("Install/use libsndfile or pass --sndfile PATH to its library")
        lib = self.lib
        lib.sf_open.argtypes = [ct.c_char_p, ct.c_int, ct.POINTER(SFInfo)]
        lib.sf_open.restype = ct.c_void_p
        lib.sf_close.argtypes = [ct.c_void_p]
        lib.sf_close.restype = ct.c_int
        lib.sf_strerror.argtypes = [ct.c_void_p]
        lib.sf_strerror.restype = ct.c_char_p
        lib.sf_version_string.restype = ct.c_char_p
        lib.sf_command.argtypes = [ct.c_void_p, ct.c_int, ct.c_void_p, ct.c_int]
        for name in ("sf_readf_float", "sf_writef_float"):
            fn = getattr(lib, name)
            fn.argtypes = [ct.c_void_p, ct.c_void_p, ct.c_int64]
            fn.restype = ct.c_int64
        self.version = lib.sf_version_string().decode()

    def _open(self, path, mode, info):
        handle = self.lib.sf_open(os.fsencode(path), mode, ct.byref(info))
        if not handle:
            raise RuntimeError(self.lib.sf_strerror(None).decode())
        return handle

    def write(self, path, samples, quality=0.5, sample_rate=SR):
        data = np.ascontiguousarray(samples, dtype=np.float32)
        if data.ndim == 1:
            data = data[:, None]
        info = SFInfo(0, sample_rate, data.shape[1], 0x200000 | 0x0060, 0, 0)
        handle = self._open(path, 0x20, info)
        try:
            q = ct.c_double(quality)
            if not self.lib.sf_command(handle, 0x1300, ct.byref(q), ct.sizeof(q)):
                raise RuntimeError("Vorbis quality setting failed")
            # The bundled Vorbis writer uses stack scratch space proportional to
            # each request; bounded writes also work with long tracks on Windows.
            for start in range(0, len(data), 16384):
                block = data[start:start+16384]
                count = self.lib.sf_writef_float(handle, block.ctypes.data, len(block))
                if count != len(block):
                    raise RuntimeError("Incomplete audio write")
        finally:
            if self.lib.sf_close(handle):
                raise RuntimeError("Audio encoder close failed")
        canonical_ogg(path)

    def read(self, path):
        info = SFInfo()
        handle = self._open(path, 0x10, info)
        try:
            out = np.empty((info.frames, info.channels), dtype=np.float32)
            for start in range(0, info.frames, 16384):
                block = out[start:start+16384]
                count = self.lib.sf_readf_float(handle, block.ctypes.data, len(block))
                if count != len(block):
                    raise RuntimeError(f"Incomplete audio read at frame {start}")
        finally:
            self.lib.sf_close(handle)
        return out, info


def canonical_ogg(path):
    """Fix the random container serial, then recompute standard Ogg page CRCs."""
    table = []
    for i in range(256):
        value = i << 24
        for _ in range(8):
            value = ((value << 1) ^ (0x04C11DB7 if value & 0x80000000 else 0)) & 0xffffffff
        table.append(value)
    data = bytearray(Path(path).read_bytes())
    serial = zlib.crc32(Path(path).stem.encode("ascii"))
    pos = 0
    while pos < len(data):
        assert data[pos:pos + 4] == b"OggS"
        segments = data[pos + 26]
        end = pos + 27 + segments + sum(data[pos + 27:pos + 27 + segments])
        struct.pack_into("<I", data, pos + 14, serial)
        data[pos + 22:pos + 26] = bytes(4)
        crc = 0
        for value in data[pos:end]:
            crc = ((crc << 8) ^ table[((crc >> 24) ^ value) & 255]) & 0xffffffff
        struct.pack_into("<I", data, pos + 22, crc)
        pos = end
    Path(path).write_bytes(data)


def db(value):
    return float(20 * np.log10(max(float(value), 1e-12)))


def spectrum_filter(x, low=20, high=7000, periodic=False):
    """Smooth zero-phase spectral filters, with padding for one-shots."""
    x = np.asarray(x)
    n = len(x) if periodic else 1 << (len(x) + 2047).bit_length()
    f = np.fft.rfftfreq(n, 1 / SR)
    gain = (1 - np.exp(-(f / low) ** 4)) / np.sqrt(1 + (f / high) ** 12)
    if x.ndim == 2:
        gain = gain[:, None]
    return np.fft.irfft(np.fft.rfft(x, n=n, axis=0) * gain, n=n, axis=0)[:len(x)].astype(np.float32)


def k_weighted(x, sample_rate=SR):
    """RBJ shelf + high-pass estimate; not a certified BS.1770 meter."""
    SR = sample_rate
    # Evaluate causal biquad transfer functions on a zero-padded FFT grid.
    n = 1 << (len(x) + SR).bit_length()
    z = np.exp(-2j * np.pi * np.fft.rfftfreq(n))
    w = 2 * np.pi * 1500 / SR
    a = 10 ** (4 / 40)
    alpha = np.sin(w) / np.sqrt(2)
    c = np.cos(w)
    v = 2 * np.sqrt(a) * alpha
    b = [a * (a + 1 + (a - 1) * c + v), -2*a*(a - 1 + (a + 1)*c), a*(a + 1 + (a - 1)*c - v)]
    den = [a + 1 - (a - 1)*c + v, 2*(a - 1 - (a + 1)*c), a + 1 - (a - 1)*c - v]
    h = (b[0] + b[1]*z + b[2]*z*z) / (den[0] + den[1]*z + den[2]*z*z)
    w = 2*np.pi*38/SR
    c, alpha = np.cos(w), np.sin(w)
    h *= ((1+c)/2 * (1-2*z+z*z)) / (1+alpha-2*c*z+(1-alpha)*z*z)
    return np.fft.irfft(np.fft.rfft(x, n=n, axis=0) * h[:, None], n=n, axis=0)[:len(x)]


def loudness(x, sample_rate=SR):
    SR = sample_rate
    x = x[:, None] if x.ndim == 1 else x
    weighted = k_weighted(x, sample_rate)
    energy = np.sum(weighted * weighted, axis=1)
    if len(x) < int(.4 * SR):
        return None, float(-.691 + 10*np.log10(max(np.mean(energy), 1e-15)))
    size, step = int(.4*SR), int(.1*SR)
    cumulative = np.concatenate(([0.], np.cumsum(energy)))
    starts = np.arange(0, len(x)-size+1, step)
    powers = (cumulative[starts+size] - cumulative[starts])/size
    powers = powers[powers > 10**((-70+.691)/10)]
    if not len(powers):
        return -120., -120.
    powers = powers[powers >= np.mean(powers)*.1]
    result = float(-.691 + 10*np.log10(np.mean(powers)))
    return result, result


def measure(x, sample_rate=SR):
    SR = sample_rate
    lufs, short = loudness(x, sample_rate)
    block = max(1, int(.01 * SR))
    levels = np.sqrt(np.mean(x[:len(x)//block*block].reshape(-1, block, x.shape[1])**2, axis=(1, 2)))
    silent = levels < 10**(-60/20)
    run = longest = 0
    for value in silent:
        run = run + 1 if value else 0
        longest = max(longest, run)
    # Welch-style spectrum, all channels; avoid cancellation in stereo.
    window = np.hanning(2048)
    padded = np.pad(x, ((0, max(0, 2048-len(x))), (0, 0)))
    frames = np.lib.stride_tricks.sliding_window_view(padded, 2048, axis=0)[::1024]
    energy = np.sum(np.abs(np.fft.rfft(frames * window, axis=-1))**2, axis=(0, 1))
    f = np.fft.rfftfreq(2048, 1/SR)
    high = float(np.sum(energy[f >= 10000]) / max(np.sum(energy), 1e-30))
    # Four-times sinc interpolation in bounded chunks, retaining overlap.
    true_peak = float(np.max(np.abs(x)))
    offsets = np.arange(-24, 25)
    for fraction in (.25, .5, .75):
        kernel = np.sinc(offsets-fraction) * np.kaiser(49, 8.6)
        kernel /= kernel.sum()
        for ch in range(x.shape[1]):
            true_peak = max(true_peak, float(np.max(np.abs(np.convolve(x[:, ch], kernel, mode="same")))))
    return {
        "peak_dbfs": round(db(np.max(np.abs(x))), 3),
        "true_peak_estimate_dbtp": round(db(true_peak), 3),
        "lufs_estimate": None if lufs is None else round(lufs, 3),
        "short_k_weighted_db": round(short, 3),
        "rms_dbfs": round(db(np.sqrt(np.mean(x*x))), 3),
        "dc_offset": float(np.max(np.abs(np.mean(x, axis=0, dtype=np.float64)))),
        "clipped_samples": int(np.sum(np.abs(x) >= .999)),
        "silent_fraction_10ms": float(np.mean(silent)),
        "longest_silence_seconds": longest * .01,
        "high_band_energy_fraction_10khz": high,
        "seam_delta": float(np.max(np.abs(x[0]-x[-1]))),
        "edge_peak": float(np.max(np.abs(x[[0, -1]]))),
        "pcm_sha256": hashlib.sha256(x.astype('<f4').tobytes()).hexdigest(),
    }


# Small original bitmap typeface keeps diagnostics portable without Pillow.
_FONT = {
    'A':'01110 10001 10001 11111 10001 10001 10001','B':'11110 10001 10001 11110 10001 10001 11110',
    'C':'01111 10000 10000 10000 10000 10000 01111','D':'11110 10001 10001 10001 10001 10001 11110',
    'E':'11111 10000 10000 11110 10000 10000 11111','F':'11111 10000 10000 11110 10000 10000 10000',
    'G':'01111 10000 10000 10111 10001 10001 01111','H':'10001 10001 10001 11111 10001 10001 10001',
    'I':'11111 00100 00100 00100 00100 00100 11111','J':'00111 00010 00010 00010 10010 10010 01100',
    'K':'10001 10010 10100 11000 10100 10010 10001','L':'10000 10000 10000 10000 10000 10000 11111',
    'M':'10001 11011 10101 10101 10001 10001 10001','N':'10001 11001 10101 10011 10001 10001 10001',
    'O':'01110 10001 10001 10001 10001 10001 01110','P':'11110 10001 10001 11110 10000 10000 10000',
    'Q':'01110 10001 10001 10001 10101 10010 01101','R':'11110 10001 10001 11110 10100 10010 10001',
    'S':'01111 10000 10000 01110 00001 00001 11110','T':'11111 00100 00100 00100 00100 00100 00100',
    'U':'10001 10001 10001 10001 10001 10001 01110','V':'10001 10001 10001 10001 10001 01010 00100',
    'W':'10001 10001 10001 10101 10101 11011 10001','X':'10001 10001 01010 00100 01010 10001 10001',
    'Y':'10001 10001 01010 00100 00100 00100 00100','Z':'11111 00001 00010 00100 01000 10000 11111',
    '0':'01110 10001 10011 10101 11001 10001 01110','1':'00100 01100 00100 00100 00100 00100 01110',
    '2':'01110 10001 00001 00010 00100 01000 11111','3':'11110 00001 00001 01110 00001 00001 11110',
    '4':'00010 00110 01010 10010 11111 00010 00010','5':'11111 10000 10000 11110 00001 00001 11110',
    '6':'01110 10000 10000 11110 10001 10001 01110','7':'11111 00001 00010 00100 01000 01000 01000',
    '8':'01110 10001 10001 01110 10001 10001 01110','9':'01110 10001 10001 01111 00001 00001 01110',
    '.':'00000 00000 00000 00000 00000 00110 00110','-':'00000 00000 00000 11111 00000 00000 00000',
    '/':'00001 00001 00010 00100 01000 10000 10000',':':'00000 00110 00110 00000 00110 00110 00000',
}


def label(canvas, x, y, text, color=(210, 225, 239), scale=2):
    for char in text.upper():
        for row, pattern in enumerate(_FONT.get(char, '').split()):
            for col, value in enumerate(pattern):
                if value == '1':
                    canvas[y+row*scale:y+(row+1)*scale, x+col*scale:x+(col+1)*scale] = color
        x += 6*scale


def png(path, canvas):
    h, w = canvas.shape[:2]
    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind+payload))
    rows = b''.join(b'\x00' + row.tobytes() for row in canvas)
    Path(path).write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w,h,8,2,0,0,0)) + chunk(b'IDAT',zlib.compress(rows,8)) + chunk(b'IEND',b''))


def preview(path, key, x, stats, loop, sample_rate=SR):
    SR = sample_rate
    canvas = np.full((770, 1200, 3), (15, 24, 40), dtype=np.uint8)
    label(canvas, 36, 24, f'{key} / DECODED OGG', scale=3)
    level = stats['lufs_estimate'] if stats['lufs_estimate'] is not None else stats['short_k_weighted_db']
    label(canvas, 36, 62, f'{len(x)/SR:.3f} S   PEAK {stats["peak_dbfs"]:.1f} DBFS   K-LEVEL {level:.1f} DB')
    label(canvas, 36, 98, 'WAVEFORM / FULL SCALE / CHANNEL ENVELOPE')
    left, width = 86, 1070
    bounds = np.linspace(0,len(x),width+1).astype(int)
    for col in range(width):
        part = x[bounds[col]:max(bounds[col]+1,bounds[col+1])]
        hi, lo = np.max(part), np.min(part)
        y1,y2 = int(213-hi*88), int(213-lo*88)
        canvas[max(124,y1):min(302,y2+1),left+col] = (91, 218, 186)
    canvas[213,left:left+width] = (60,83,101)
    label(canvas, 24, 130, '1.0',scale=1)
    label(canvas, 24, 282, '-1.0',scale=1)
    label(canvas, 36, 318, 'SPECTROGRAM / LOG HZ / -90 TO -10 DBFS')
    size = 1024
    mono = np.mean(x, axis=1)
    padded = np.pad(mono,(size//2,size//2))
    starts = np.linspace(0,len(mono)-1,width).astype(int)
    frame = padded[starts[:,None]+np.arange(size)] * np.hanning(size)
    power = 20*np.log10(np.maximum(np.abs(np.fft.rfft(frame,axis=1))/(size/4),1e-8))
    frequency = np.geomspace(15000,40,290)
    bins = np.clip(np.round(frequency*size/SR).astype(int),0,size//2)
    intensity = np.clip((power[:,bins].T+90)/80,0,1)
    stops = np.array([[12,20,39],[45,47,94],[48,115,145],[69,191,173],[245,216,109]])
    coords = intensity*4
    base = np.minimum(coords.astype(int),3)
    colors = stops[base]*(1-(coords-base)[...,None])+stops[base+1]*(coords-base)[...,None]
    canvas[350:640,left:left+width] = colors.astype(np.uint8)
    for freq in (100,500,1000,5000,15000):
        yy = 350+int(np.log(15000/freq)/np.log(15000/40)*289)
        label(canvas,12,yy,str(freq),scale=1)
    for part in range(5):
        xx = left+int(part*(width-40)/4)
        label(canvas,xx,653,f'{len(x)/SR*part/4:.2f} S',scale=1)
    label(canvas,36,689,f'DC {stats["dc_offset"]:.6f}   CLIPS {stats["clipped_samples"]}   SEAM {stats["seam_delta"]:.6f}')
    loop_text='LOOP: PERIODIC SOURCE / EXACT FRAME COUNT' if key in ('RebirthHold','Ambience') else 'LOOP: WRAPPED TAIL / EXACT FRAME COUNT'
    label(canvas,36,726,loop_text if loop else 'ONE-SHOT: SMOOTH ATTACK AND RELEASE')
    png(path,canvas)
