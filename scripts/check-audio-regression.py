"""Re-render into a temporary directory and verify all 53 encoded/PCM hashes.

Also exercise the sample-rate-aware meter and interpolation with analytic tones.
Does not replace any final asset or manifest. Requires the build tool's Python.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile

sys.dont_write_bytecode = True
import numpy as np
from audio_support import Codec, loudness
import audio_new

spec=importlib.util.spec_from_file_location('audio_build',Path(__file__).with_name('build-audio.py'))
build=importlib.util.module_from_spec(spec)
sys.modules[spec.name]=build
spec.loader.exec_module(build)


def pcm_hash(x):
    return hashlib.sha256(x.astype('<f4').tobytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sndfile')
    parser.add_argument('--only',nargs='+',help='Limit re-render comparison to these keys')
    args=parser.parse_args()
    codec=Codec(args.sndfile)
    manifest=json.loads((build.OUT/'manifest.json').read_text())
    frozen=json.loads((build.OUT/'original-21-hashes.json').read_text(encoding='utf-8-sig'))
    entries={e['key']:e for e in manifest['assets']}
    if args.only and set(args.only)-set(entries):
        parser.error('Unknown regression keys')
    audio_new.contracts(build.ROOT,build.SFX)
    audio_new.verify_originals(build.OUT,frozen)
    for rate in (32000,48000):
        t=np.arange(rate)/rate
        tone=(.1*np.sin(2*np.pi*1000*t))[:,None]
        mono=loudness(tone,rate)[0]
        stereo=loudness(np.repeat(tone,2,axis=1),rate)[0]
        assert abs(mono+23.05)<.12,(rate,mono)
        assert abs(stereo-mono-3.0103)<.001
        assert loudness(tone[:int(.1*rate)],rate)[0] is None
    original=(.1*np.sin(2*np.pi*1000*np.arange(32000)/32000))[:,None]
    expected=(.1*np.sin(2*np.pi*1000*np.arange(48000)/48000))[:,None]
    assert np.max(np.abs(audio_new.interpolate(original,48000)-expected))<1e-7
    with tempfile.TemporaryDirectory(prefix='audio-regression-',dir=build.OUT) as folder:
        for index,entry in enumerate(manifest['assets']):
            key=entry['key']
            if args.only and key not in args.only:
                continue
            path=Path(folder)/f'{key}.ogg'
            if key in audio_new.SLOTS:
                samples=audio_new.make(key,build)
                if key in audio_new.LOOPS:
                    samples,shift=audio_new.encode_loop(codec,path,samples)
                    assert shift==entry['codec_boundary_rotation_samples'],key
                else:
                    codec.write(path,samples,.5,audio_new.RATE)
            elif key in build.SFX:
                samples=build.make_sfx(key,index)
                codec.write(path,samples)
            else:
                song_index=int(key[-1])-1
                samples,_=build.make_music(build.SONGS[song_index],song_index)
                codec.write(path,samples)
            expected_hashes=next((e for e in frozen if e['key']==key),entry)
            assert pcm_hash(samples)==expected_hashes['synthesis_pcm_sha256'],f'{key}: source PCM changed'
            assert hashlib.sha256(path.read_bytes()).hexdigest()==expected_hashes['sha256'],f'{key}: OGG changed'
            decoded,_=codec.read(path)
            assert pcm_hash(decoded)==expected_hashes['pcm_sha256'],f'{key}: decode changed'
            print(f'{key}: source PCM, OGG bytes and decoded PCM identical',flush=True)
    print(f'PASS: {len(args.only) if args.only else len(entries)} regenerated files and rate-aware meter/interpolation fixtures')


if __name__=='__main__':
    main()
