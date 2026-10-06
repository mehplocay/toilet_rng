"""The 32 additional cues, using the original generator's unmodified palette.

Compose at the palette's 32 kHz, then band-limited interpolate to 48 kHz.
No resampling of the original delivered files, no samples or external services.
"""
from __future__ import annotations

import hashlib
import re

import numpy as np

from audio_support import SR, db, loudness, measure, spectrum_filter

RATE = 48000
TAU = 2 * np.pi
# Render length, permitted bounds, K-weighted level, creative description.
SLOTS = {
    'FlushStart': (.145, .12, .16, -25, 'Ceramic handle and one water bead'),
    'Common': (.16, .12, .18, -26, 'Rounded low discovery plop'),
    'Uncommon': (.26, .20, .30, -24, 'Two rising bubble notes'),
    'Rare': (.44, .35, .50, -21, 'Three glass and bubble notes'),
    'DropLanding': (.17, .12, .20, -27, 'Rubbery settle and tiny water bead'),
    'Sell': (.31, .25, .35, -20, 'Coin exchange ping and register tap'),
    'SellAll': (.56, .45, .60, -20, 'Small coin cascade into the Sell ping'),
    'CoinPopup': (.11, .08, .14, -33, 'Understated coin glint'),
    'DisplayPlace': (.31, .25, .35, -24, 'Pedestal clack and glass sparkle'),
    'DisplayReturn': (.235, .18, .28, -27, 'Suction pop with falling note'),
    'DisplayLocked': (.195, .15, .22, -29, 'Muted hollow wooden double knock'),
    'ToiletUpgrade': (1.48, 1.20, 1.60, -15, 'Water lift into golden warm chord'),
    'UpgradeBuy': (.48, .35, .55, -20, 'Compact ascending progress triad'),
    'UpgradeMax': (.98, .80, 1.10, -17, 'Progress triad and crown sparkle'),
    'RebirthHold': (1., 1., 1., -30, 'Stable magical water pulse; no climax'),
    'RebirthSuccess': (2.62, 2.20, 2.80, -14, 'Ascending crown fanfare and cosmic resolution'),
    'IndexClaim': (.65, .50, .75, -20, 'Stamp and crystalline reward arpeggio'),
    'DailyClaim': (.60, .45, .70, -21, 'Gift pop and warm bell pair'),
    'DailyStreak': (1.44, 1.20, 1.60, -17, 'Seven warm chimes into luck shimmer'),
    'TutorialStep': (.34, .25, .40, -27, 'Small encouraging two-note success'),
    'TabSwitch': (.10, .08, .12, -28, 'Papery sideways bubble tick'),
    'PurchaseStart': (.26, .20, .30, -27, 'Unresolved opening bell and air'),
    'PurchaseFail': (.26, .20, .30, -29, 'Gentle falling pluck pair'),
    'AutoFlushToggle': (.17, .12, .20, -27, 'Two neutral rounded switch notes'),
    'Teleport': (.58, .45, .65, -23, 'Air and water travel with gentle arrival'),
    'PortalLocked': (.26, .20, .30, -28, 'Soft comic rubber bonk and wobble'),
    'ChatAnnouncement': (.39, .30, .45, -28, 'Tiny warm notification pair'),
    'LuckStart': (.61, .45, .70, -24, 'Rising airy magical shimmer'),
    'LuckEnd': (.46, .35, .50, -27, 'Descending gently settling shimmer'),
    'LeaderboardUpdate': (.07, .05, .08, -36, 'Barely audible rounded glass tick'),
    'SpawnArrival': (.72, .55, .80, -25, 'Welcoming air bloom and warm chime'),
    'Ambience': (36., 30., 45., -33, 'Distant ocean wash, coastal wind and sparse birds'),
}
LOOPS = {'RebirthHold', 'Ambience'}


def interpolate(x, frames):
    """Fourier interpolation of an even, band-limited circular signal.

    One-shots have zero, smooth endpoints before this call. Explicitly split
    the old Nyquist bin as required when increasing an even-length transform.
    """
    n = len(x)
    if n % 2 or frames <= n:
        raise ValueError('Expected even input length and upsampling')
    bins = np.fft.rfft(x, axis=0)
    bins[-1] *= .5
    return (np.fft.irfft(bins, n=frames, axis=0) * frames / n).astype(np.float32)


def make(key, palette):
    duration, _, _, target, _ = SLOTS[key]
    # A stable key-derived seed cannot change when the slot table is reordered.
    seed = palette.SEED + int.from_bytes(hashlib.sha256(key.encode()).digest()[:4], 'little')
    rng = np.random.Generator(np.random.PCG64(seed))
    bus = np.zeros((round(duration * SR), 1), np.float32)
    t = np.arange(len(bus)) / SR
    add, voice, bubble, edge, noise = (palette.add, palette.voice, palette.bubble,
                                      palette.smooth_edge, palette.noise)

    def note(pitch, when, length, gain=.5, kind='keys'):
        add(bus, voice(pitch, length, kind), when, gain)

    def plop(when, length, start, end, gain=1):
        add(bus, bubble(length, start, end), when, gain)

    def tap(when=0, length=.07, pitch=510, gain=.5, wooden=False):
        tt = np.arange(round(length * SR)) / SR
        x = (np.sin(TAU*pitch*tt) + .28*np.sin(TAU*pitch*1.63*tt)) * np.exp(-tt/.014)
        x += noise(rng, length, 400, 2200) * np.exp(-tt/.006) * (.18 if wooden else .07)
        add(bus, edge(x, .002, .018), when, gain)

    def water(length, when=0, gain=.3, lift=True):
        tt = np.arange(round(length*SR))/SR
        env = np.sin(np.pi*tt/length)**1.6
        # Same filtered, softly modulated noise bands as Flush; no deep impact.
        x = noise(rng,length,130,1800) * (.68+.25*np.sin(TAU*5.5*tt+.6*np.sin(TAU*2*tt)))
        x += noise(rng,length,700,3400) * (.17 + (.35*tt/length if lift else 0))
        add(bus,edge(x*env,.003,.04),when,gain)

    def ping(when=0, gain=.6):
        # Exactly the same final ping recipe for Sell and SellAll.
        note(88,when,.28,gain,'chime')
        note(95,when+.018,.21,gain*.19,'chime')

    def triad(spacing, length, when=0, gain=.55):
        for i,pitch in enumerate((72,76,79)):
            note(pitch,when+i*spacing,length,gain)
            note(pitch+12,when+i*spacing,length*.75,gain*.18,'chime')

    if key == 'FlushStart':
        tap(pitch=430,gain=.85)
        plop(.035,.105,670,330,.28)
    elif key == 'Common':
        plop(0,duration,420,230)
        water(.09,.015,.035,False)
    elif key == 'Uncommon':
        for when,pitch in ((0,72),(.105,76)):
            plop(when,.145,palette.midi(pitch)*.78,palette.midi(pitch),.65)
            note(pitch,when,.145,.16,'chime')
    elif key == 'Rare':
        for i,pitch in enumerate((72,76,79)):
            note(pitch,i*.10,.23,.52,'chime')
            plop(i*.10,.12,palette.midi(pitch)*.8,palette.midi(pitch),.23)
    elif key == 'DropLanding':
        plop(0,.15,350,165,.8)
        plop(.035,.11,950,610,.14)
    elif key in ('Sell','SellAll'):
        if key == 'SellAll':
            for i,(when,pitch) in enumerate(((0,83),(.065,88),(.12,91),(.18,86))):
                note(pitch,when,.14,.22+i*.035,'chime')
                tap(when,.045,650+i*75,.08)
            ping(.25)
            tap(.245,.06,520,.14)
        else:
            ping()
            tap(.012,.06,520,.14)
    elif key in ('CoinPopup','LeaderboardUpdate'):
        note(95 if key=='CoinPopup' else 88,0,duration,.7,'chime')
        plop(0,duration,850,610,.1)
    elif key == 'DisplayPlace':
        tap(pitch=570,gain=.8)
        note(84,.065,.23,.26,'chime')
        note(91,.09,.20,.10,'chime')
    elif key == 'DisplayReturn':
        plop(0,.15,390,790,.6)
        plop(.035,.19,710,240,.65)
    elif key == 'DisplayLocked':
        tap(0,.09,280,.7,True)
        tap(.082,.10,280,.52,True)
    elif key == 'ToiletUpgrade':
        water(.69,0,.5)
        plop(0,.18,380,560,.06)
        for i,pitch in enumerate((67,71,74,79,83)):
            note(pitch,.20+i*.075,.38,.19)
        for pitch in (55,59,62,67):
            note(pitch,.53,.91,.24)
            note(pitch,.53,.91,.14,'pad')
        for i,pitch in enumerate((86,91,95)):
            note(pitch,.61+i*.1,.60,.10,'chime')
    elif key in ('UpgradeBuy','UpgradeMax'):
        triad(.09 if key=='UpgradeBuy' else .13,.27 if key=='UpgradeBuy' else .4)
        if key=='UpgradeMax':
            for i,pitch in enumerate((84,88,91,96)):
                note(pitch,.38+i*.085,.32,.20,'chime')
            note(60,.36,.55,.14,'pad')
    elif key == 'RebirthSuccess':
        # New rhythm/contour, the ServerEvent brass family and Secret glass.
        for when,pitch,length in ((0,60,.40),(.29,64,.42),(.62,67,.55),(1.08,74,.40),(1.36,72,.85)):
            note(pitch,when,length,.48,'brass')
            note(pitch+12,when,length,.18,'brass')
        for i,pitch in enumerate((48,60,64,67,72)):
            note(pitch,1.49+i*.012,1.03-i*.012,.09,'keys')
            note(pitch,1.44+i*.012,1.11-i*.012,.16,'pad')
        for i,pitch in enumerate((84,91,88,96,100)):
            note(pitch,1.55+i*.135,.46,.15,'chime')
        for when in (0,.62,1.36):
            add(bus,palette.drum('snare',rng),when,.075)
            add(bus,palette.drum('kick',rng),when,.09)
    elif key == 'IndexClaim':
        tap(0,.08,390,.55,True)
        for i,pitch in enumerate((72,76,79,84)):
            note(pitch,.055+i*.10,.27,.43,'chime')
    elif key == 'DailyClaim':
        plop(0,.12,580,260,.7)
        for when,pitch in ((.065,76),(.245,79)):
            note(pitch,when,.32,.52,'keys')
            note(pitch+12,when,.25,.12,'chime')
    elif key == 'DailyStreak':
        for i,pitch in enumerate((67,71,74,76,79,83,86)):
            note(pitch,i*.125,.39,.45,'keys')
            note(pitch+12,i*.125,.33,.11,'chime')
        for pitch in (67,71,74):
            note(pitch,.80,.59,.14,'pad')
        water(.52,.83,.035)
    elif key == 'TutorialStep':
        note(72,0,.19,.5)
        note(76,.125,.21,.5)
    elif key == 'TabSwitch':
        plop(0,.095,650,710,.6)
        add(bus,edge(noise(rng,.09,850,2800),.005,.045),.003,.18)
    elif key == 'PurchaseStart':
        # Single suspended bell, deliberately no resolved major triad.
        note(74,0,.25,.5)
        water(.24,0,.11)
    elif key == 'PurchaseFail':
        note(64,0,.14,.5,'pluck')
        note(60,.105,.15,.44,'pluck')
    elif key == 'AutoFlushToggle':
        tap(0,.072,510,.65)
        tap(.077,.085,540,.58)
        plop(.077,.085,480,300,.15)
    elif key == 'Teleport':
        water(.56,0,.45)
        plop(0,.30,270,820,.13)
        plop(.32,.24,880,580,.11)
    elif key == 'PortalLocked':
        wobble=220+145*np.exp(-t/.04)+23*np.sin(TAU*14*t)*np.exp(-t/.10)
        x=np.sin(TAU*np.cumsum(wobble)/SR)*np.exp(-t/.085)
        add(bus,edge(x,.003,.07),0,.75)
        tap(0,.06,330,.12)
    elif key == 'ChatAnnouncement':
        note(76,0,.22,.5)
        note(79,.145,.235,.36)
    elif key in ('LuckStart','LuckEnd'):
        notes=(81,85,88) if key=='LuckStart' else (88,85,81)
        for i,pitch in enumerate(notes):
            note(pitch,i*.09,.33 if key=='LuckStart' else .25,.33,'vibes')
            note(pitch+12,i*.09,.23,.065,'chime')
        note(69,0,duration-.02,.2,'pad')
        water(duration-.01,0,.045)
    elif key == 'SpawnArrival':
        water(.66,0,.15)
        note(76,0,.25,.035,'keys')
        note(72,0,.68,.25,'pad')
        note(76,.10,.54,.45)
        note(79,.23,.45,.20,'chime')
    elif key == 'RebirthHold':
        # Integer-Hz oscillators and modulation are periodic over exactly 1 s.
        pulse=.83+.17*np.cos(TAU*2*t)
        for freq,gain in ((110,.2),(220,.3),(277,.17),(330,.13),(440,.025)):
            bus[:,0] += gain*np.sin(TAU*freq*t)*pulse
        texture=spectrum_filter(rng.normal(size=len(t)),130,1800,periodic=True)
        texture/=np.sqrt(np.mean(texture*texture))
        bus[:,0] += texture*.055*(.85+.15*np.cos(TAU*2*t+.3))
    elif key == 'Ambience':
        # Slow, irregular circular modulation: no repeating close-wave crash.
        def bed(low,high):
            x=spectrum_filter(rng.normal(size=len(t)),low,high,periodic=True)
            return x/np.sqrt(np.mean(x*x))
        phase=TAU*t/duration
        wash=.64+.15*np.sin(phase*3+.7)+.11*np.sin(phase*5+2.2)+.07*np.cos(phase*7)
        wind=.67+.14*np.sin(phase*2+1.4)+.10*np.sin(phase*9)
        bus[:,0]=bed(100,1450)*wash*.45+bed(450,2900)*wind*.12+bed(70,340)*.055
        # Three very distant, soft bird gestures, without gull-like shrieks.
        for when,length,center in ((5.3,.46,1450),(17.8,.61,1720),(29.1,.38,1330)):
            tt=np.arange(round(length*SR))/SR
            f=center+130*np.sin(np.pi*tt/length)+35*np.sin(TAU*4.6*tt)
            bird=np.sin(TAU*np.cumsum(f)/SR)*np.sin(np.pi*tt/length)**3
            add(bus,edge(bird,.05,.09),when,.070)
    else:
        raise ValueError(key)

    loop=key in LOOPS
    if not loop:
        if key in ('Rare','ToiletUpgrade','UpgradeMax','RebirthSuccess','IndexClaim',
                   'DailyClaim','DailyStreak','LuckStart','LuckEnd','SpawnArrival'):
            bus=palette.room(bus,rng,.22,.075)[:len(bus)]
        bus=spectrum_filter(bus,40,5900)
        attack=.007 if key in ('Sell','DisplayPlace','AutoFlushToggle') else .003
        bus=edge(bus,attack,min(.13,duration*.23))
        taper=edge(np.ones(len(bus)),attack,min(.13,duration*.23))[:,None]
        bus-=taper*np.sum(bus,axis=0)/np.sum(taper)
    else:
        bus=spectrum_filter(bus,45,4000,periodic=True)
        bus-=np.mean(bus,axis=0)
        # Select a low-amplitude, low-slope join. No loop fade or silent notch.
        candidates=np.arange(2,min(len(bus)-2,round(.025*SR)))
        score=np.abs(bus[candidates,0])+.8*np.abs(bus[candidates,0]-bus[candidates-1,0])
        bus=np.roll(bus,-int(candidates[np.argmin(score)]),axis=0)
    bus=interpolate(bus,round(duration*RATE))
    _,level=loudness(bus,RATE)
    # Linear gain only. Reserve extra codec/true-peak margin, never limit.
    gain=min(10**((target-level)/20),10**(-3.7/20)/max(np.max(np.abs(bus)),1e-9))
    return (bus*gain).astype(np.float32)


def contracts(root, original_keys):
    """Read the actual Luau tables and Markdown spec; fail closed on drift."""
    assets=(root/'src/shared/Config/Assets.luau').read_text(encoding='utf-8')
    audio=(root/'src/shared/Config/Audio.luau').read_text(encoding='utf-8')
    sound_table=assets.split('\tSounds = {',1)[1].split('\n\t},',1)[0]
    sounds=re.findall(r'^\t\t(\w+) = ',sound_table,re.M)
    cue_table=audio.split('\tCues = {',1)[1]
    cue_pairs=re.findall(r'^\t\t(\w+) = \{(.*?)^\t\t\},',cue_table,re.M|re.S)
    cues=dict(cue_pairs)
    expected=set(original_keys)|set(SLOTS)
    if len(sounds)!=len(set(sounds)) or len(cues)!=len(cue_pairs) or set(sounds)!=expected or set(cues)!=expected:
        raise RuntimeError('Generator, Audio.Cues and Assets.Sounds keys must match exactly')
    spec=(root/'docs/audio-new-slots.md').read_text(encoding='utf-8')
    rows=re.findall(r'^\| (\w+) \| [^\n]+',spec,re.M)
    rows=[k for k in rows if k!='Key']
    if set(rows)!=set(SLOTS) or len(rows)!=32:
        raise RuntimeError('New generator keys must equal all 32 brief keys')
    for key,(_,lo,hi,_,_) in SLOTS.items():
        row=next(line for line in spec.splitlines() if line.startswith(f'| {key} |'))
        cells=[c.strip() for c in row.split('|')]
        bounds=[float(v) for v in re.split('[–-]',cells[3])]
        if (bounds[0],bounds[-1])!=(lo,hi):
            raise RuntimeError(f'{key}: brief duration drift')
        runtime_max=float(re.search(r'Length = ([\d.]+)',cues[key]).group(1))
        if hi>runtime_max or ('Looped = true' in cues[key])!=(key in LOOPS):
            raise RuntimeError(f'{key}: runtime duration/loop mismatch')
        if (cells[5]=='Seamless loop')!=(key in LOOPS):
            raise RuntimeError(f'{key}: brief loop mismatch')
    return {key: {'class':re.search(r'Class = "(\w+)"',body).group(1),
                  'gain':float(re.search(r'Gain = ([\d.]+)',body).group(1))}
            for key,body in cues.items()}


def verify_originals(out, frozen):
    if len(frozen)!=21:
        raise RuntimeError('Expected 21 frozen original fingerprints')
    for entry in frozen:
        path=out/'final'/f"{entry['key']}.ogg"
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest()!=entry['sha256']:
            raise RuntimeError(f"Original asset changed or missing: {entry['key']}")


def encode_loop(codec, path, samples):
    """Choose a circular cut using the *decoded* codec boundary, not PCM alone.

    Standalone Vorbis edge reconstruction differs slightly from the circular
    source. Rotate at most 24 ms, without removing frames or adding a fade.
    """
    best=None
    for shift in range(0,24*(RATE//1000),RATE//1000):
        candidate=np.roll(samples,-shift,axis=0)
        codec.write(path,candidate,.5,RATE)
        x,_=codec.read(path)
        bridge=x[0]-x[-1]
        seam=float(np.max(np.abs(bridge)))
        slope=float(max(np.max(np.abs(bridge-(x[-1]-x[-2]))),
                        np.max(np.abs((x[1]-x[0])-bridge))))
        score=max(seam,slope)
        if best is None or score<best[0]:
            best=(score,shift,path.read_bytes())
        if score<.00025:
            break
    _,shift,data=best
    path.write_bytes(data)
    return np.roll(samples,-shift,axis=0),shift


def verify_inventory(out, entries, keys):
    listed=[e['key'] for e in entries]
    files={p.name for p in (out/'final').iterdir() if p.is_file()}
    if len(listed)!=len(set(listed)) or set(listed)!=set(keys):
        raise RuntimeError('Manifest must contain exactly 53 unique configured keys')
    if files!={f'{key}.ogg' for key in keys}:
        raise RuntimeError('Final filenames must exactly equal configured audio keys')
    for entry in entries:
        if entry['file']!=f"final/{entry['key']}.ogg":
            raise RuntimeError('Manifest filename/key mismatch')
        path=out/entry['file']
        if hashlib.sha256(path.read_bytes()).hexdigest()!=entry['sha256']:
            raise RuntimeError(f"Inventory hash mismatch: {entry['key']}")


def inspect_extra(x, rate, entry, require):
    require(entry['true_peak_estimate_dbtp']<=-3,'new cue true-peak headroom < 3 dB')
    level=entry['short_k_weighted_db']
    require(abs(level-entry['target_k_level'])<=1.5,'new cue outside loudness class target')
    # 1 ms RMS windows distinguish a smooth attack from actual leading silence.
    block=rate//1000
    energy=np.sqrt(np.mean(x[:len(x)//block*block].reshape(-1,block)**2,axis=1))
    active=np.flatnonzero(energy>10**(-60/20))
    onset=float(active[0]/1000) if len(active) else float(len(x)/rate)
    entry['onset_seconds']=onset
    require(onset<=.010,'leading silence exceeds 10 ms attack allowance')
    if not entry['loop']:
        require(entry['edge_peak']<=.001,'new one-shot edge exceeds 0.001 FS')
        return_speed=entry['key'] in ('Sell','SellAll')
        if return_speed:
            probes=[]
            for speed in (1.,1.06,1.12,1.18,1.24):
                # Oversampled linear interpolation: a conservative offline
                # playback-speed probe, not a model of Roblox's resampler.
                fine=interpolate(x,4*len(x))
                positions=np.arange(0,len(x)-1,speed)*4
                y=np.interp(positions,np.arange(len(fine)),fine[:,0])[:,None].astype(np.float32)
                stats=measure(y,rate)
                probes.append(dict(speed=speed,peak_dbtp=stats['true_peak_estimate_dbtp'],
                                   high_band=stats['high_band_energy_fraction_10khz'],
                                   edge_peak=stats['edge_peak']))
                require(stats['true_peak_estimate_dbtp']<=-3 and stats['edge_peak']<.001
                        and stats['high_band_energy_fraction_10khz']<.002,'sale speed probe')
            entry['speed_probes']=probes
        return
    bridge=x[0]-x[-1]
    slope=float(max(np.max(np.abs(bridge-(x[-1]-x[-2]))),
                    np.max(np.abs((x[1]-x[0])-bridge))))
    entry['seam_slope_error']=slope
    require(entry['seam_delta']<=.001,'new loop seam exceeds 0.001 FS')
    require(slope<=.001,'new loop slope mismatch')
    window=round(.025*rate)
    middle=np.concatenate((x[-window:],x[:window]))
    adjacent=np.concatenate((x[-3*window:-window],x[window:3*window]))
    ratio=db(np.sqrt(np.mean(middle*middle))/np.sqrt(np.mean(adjacent*adjacent)))
    entry['seam_energy_difference_db']=round(ratio,4)
    require(abs(ratio)<3,'loop seam has a local loudness dip or bump')
    # Stop at arbitrary phases, releasing from the actual sample level instead
    # of forcing a fade at the file boundary on each repetition.
    count=round(.020*rate)
    ramp=np.cos(np.linspace(0,np.pi/2,count))**2
    worst=0.
    for phase in np.linspace(0,len(x)-1,64).astype(int):
        segment=x[(phase+np.arange(count))%len(x),0]*ramp
        worst=max(worst,abs(float(segment[-1])),abs(float(segment[-1]-segment[-2])))
    entry['stop_probe_phases']=64
    entry['faded_stop_worst_edge']=worst
    entry['abrupt_stop_worst_edge']=float(np.max(np.abs(x)))
    entry['clean_stop_requires_runtime_release']=True
    require(worst<.00001,'20 ms arbitrary-phase stop release failed')
