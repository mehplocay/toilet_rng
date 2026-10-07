"""Decode the shipped OGGs and report source and steady-state runtime loudness.

Uses the repository's NumPy K-weighted, gated LUFS estimate and libsndfile.
This is not a certified BS.1770 meter. Short clips use an ungated proxy.
No assets are changed; runtime levels exclude EQ, fades and device volume.
"""
import argparse
import json
import math
from pathlib import Path
import re

import numpy as np
from audio_support import Codec, db, loudness

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sndfile")
    parser.add_argument("--output", type=Path, default=ROOT / "docs/research/music-levels.json")
    args = parser.parse_args()
    config = (ROOT / "src/shared/Config/Audio.luau").read_text()
    music_volume = float(re.search(r"MusicVolume = ([\d.]+)", config)[1])
    sfx_volume = float(re.search(r"SFXVolume = ([\d.]+)", config)[1])
    duck = float(re.search(r"\n\s*DuckGain = ([\d.]+)", config)[1])
    class_gains = {key: float(value) for key, value in re.findall(
        r"(\w+) = ([\d.]+)", re.search(r"ClassGains = \{([^}]+)\}", config)[1])}
    gain_block = re.search(r"MusicTrackGains = \{([^}]+)\}", config)
    track_gains = [float(value) for value in re.findall(r"[\d.]+", gain_block[1])] if gain_block else [1] * 5
    cues = {key: (kind, float(gain)) for key, kind, gain in re.findall(
        r"(\w+) = \{\s*Bus = \"\w+\",\s*Class = \"(\w+)\",\s*Gain = ([\d.]+)", config)}
    codec = Codec(args.sndfile)
    rows = []
    for path in sorted((ROOT / "assets/audio/final").glob("*.ogg")):
        samples, info = codec.read(path)
        integrated, proxy = loudness(samples, info.samplerate)
        peak = db(np.max(np.abs(samples)))
        music = path.stem.startswith("Music")
        gain = track_gains[int(path.stem[5:]) - 1] if music else cues[path.stem][1] * class_gains[cues[path.stem][0]]
        old_gain = 0.25 if music else gain * sfx_volume
        new_gain = gain * (music_volume if music else sfx_volume)
        level = integrated if integrated is not None else proxy
        rows.append({
            "file": path.name, "class": "music" if music else cues[path.stem][0],
            "seconds": round(len(samples) / info.samplerate, 3),
            "source_lufs_estimate": None if integrated is None else round(integrated, 3),
            "short_k_weighted_proxy_db": None if integrated is not None else round(proxy, 3),
            "source_sample_peak_dbfs": round(peak, 3), "track_or_cue_gain": gain,
            "old_runtime_level_estimate": round(level + 20 * math.log10(old_gain), 3),
            "new_runtime_level_estimate": round(level + 20 * math.log10(new_gain), 3),
            "new_runtime_sample_peak_dbfs": round(peak + 20 * math.log10(new_gain), 3),
            "old_ducked_level_estimate": round(level + 20 * math.log10(old_gain * 0.4), 3) if music else None,
            "new_ducked_level_estimate": round(level + 20 * math.log10(new_gain * duck), 3) if music else None,
        })
        print(f"{path.stem:20} source {level:7.2f}{' proxy' if integrated is None else ' LUFS~'} peak {peak:7.2f} | old {rows[-1]['old_runtime_level_estimate']:7.2f} new {rows[-1]['new_runtime_level_estimate']:7.2f}")
    args.output.write_text(json.dumps({
        "method": "Decoded OGG; audio_support.loudness gated K-weighted LUFS estimate; sample peak; gain offsets in dB. Short clips (<400 ms) use ungated proxy. Not certified; not captured Roblox output.",
        "codec": codec.version, "music_volume": music_volume, "sfx_volume": sfx_volume,
        "duck_gain": duck, "assets": rows,
    }, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
