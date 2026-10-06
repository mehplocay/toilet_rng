"""Build 53 Toilet RNG audio assets, preserving the original 21 final files.

Run with Blender's bundled python.exe, or any Python with NumPy; --sndfile can
point to Blender's blender.shared/sndfile.dll. Nothing is downloaded at runtime.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
from pathlib import Path
import sys

# Keep generated import caches out of the scripts handoff.
sys.dont_write_bytecode = True

import numpy as np

from audio_support import Codec, SR, db, loudness, measure, preview, spectrum_filter
import audio_new

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio"
TAU = 2*np.pi
SEED = 20261006

# Durations honor the exact sourcing contract. Mono for all UI and utility cues.
SFX = {
    "Click": (.12, .08, .15, -25, 1),
    "Hover": (.085, .05, .1, -33, 1),
    "Open": (.29, .2, .35, -25, 1),
    "Close": (.24, .15, .3, -27, 1),
    "CoinCollect": (.36, .2, .45, -20, 1),
    "Flush": (.88, .6, 1, -18, 2),
    "FlushRumble": (.76, .5, .9, -27, 1),
    "Epic": (.9, .6, 1, -14.5, 2),
    "Legendary": (1.38, 1, 1.5, -14, 2),
    "Mythic": (1.68, 1.2, 1.8, -14, 2),
    "Godly": (1.9, 1.5, 2, -14, 2),
    "Secret": (2.3, 1.8, 2.4, -14, 2),
    "ServerEvent": (2.8, 2, 3, -14, 2),
    "PurchaseSuccess": (.72, .4, .8, -20, 1),
    "Error": (.27, .15, .3, -29, 1),
    "AutoFlushTick": (.075, .04, .1, -32, 1),
}

SONGS = [
    dict(key="Music1", title="Porcelain Sunrise", bpm=80, tonic="C major", lead="keys", swing=.075,
         style="Warm lo-fi electric keys, soft swung beat and rounded bass",
         chords=[(48,[60,64,67,71,74]),(45,[60,64,67,71]),(50,[60,65,69,72]),(43,[59,64,65,69]),
                 (41,[57,60,64,67]),(40,[55,59,62,67]),(50,[57,60,64,65]),(43,[59,62,65,69])],
         motif=[0,2,3,1,2,0], rhythm=[0,.75,1.5,2.25,2.75,3.5]),
    dict(key="Music2", title="Palm Bubble Bay", bpm=96, tonic="D major", lead="pluck", swing=.018,
         style="Relaxed tropical plucks, syncopated congas and delicate shakers",
         chords=[(50,[62,66,69,73]),(47,[62,66,69,73]),(43,[59,62,66,69]),(45,[61,64,67,71]),
                 (42,[57,61,64,69]),(47,[59,62,66,69]),(43,[59,62,66,69]),(45,[61,64,67,71])],
         motif=[2,1,0,2,3,1], rhythm=[.5,1.25,1.75,2.5,3,3.5]),
    dict(key="Music3", title="Cloud Pool", bpm=72, tonic="A major", lead="flute", swing=.025,
         style="Dreamy warm synth pads, breathy sine lead and a gentle half-time groove",
         chords=[(45,[61,64,68,71]),(42,[61,64,68,69]),(50,[61,64,66,69]),(40,[59,62,66,68]),
                 (47,[57,61,64,66]),(49,[59,61,64,68]),(50,[57,61,64,66]),(40,[56,59,62,66])],
         motif=[1,3,2,0], rhythm=[0,1.5,2.5,3.25]),
    dict(key="Music4", title="Velvet Coin Cafe", bpm=86, tonic="F major", lead="vibes", swing=.105,
         style="Cozy jazz-hop extended chords, muted kit, upright-like bass and vibraphone",
         chords=[(41,[57,60,64,67]),(38,[53,57,60,64]),(43,[58,62,65,69]),(48,[58,62,64,69]),
                 (45,[55,60,64,67]),(38,[54,60,64,69]),(43,[58,62,65,69]),(48,[58,62,64,67])],
         motif=[2,3,1,0,2], rhythm=[.5,1.25,2,2.75,3.5]),
    dict(key="Music5", title="Marimba Float Parade", bpm=100, tonic="G major", lead="marimba", swing=.035,
         style="Playful chill marimba, soft pads, wooden percussion and a smiling bassline",
         chords=[(43,[59,62,66,69]),(40,[59,62,66,67]),(48,[55,59,62,64]),(50,[57,60,64,66]),
                 (45,[55,59,60,64]),(47,[57,59,62,66]),(48,[55,59,62,64]),(50,[57,60,64,66])],
         motif=[0,2,1,3,2,0,1], rhythm=[0,.5,1.25,1.75,2.5,3,3.5]),
]


def smooth_edge(x, attack=.006, release=.03):
    y = x.copy()
    for seconds, start in ((attack, True),(release, False)):
        count = min(len(y)//2, max(2, round(seconds*SR)))
        ramp = np.sin(np.linspace(0,np.pi/2,count))**2
        if y.ndim == 2:
            ramp = ramp[:,None]
        if start:
            y[:count] *= ramp
        else:
            y[-count:] *= ramp[::-1]
    return y


def midi(note):
    return 440*2**((note-69)/12)


def voice(note, duration, kind="keys", velocity=1.):
    t = np.arange(round(duration*SR))/SR
    f = midi(note)
    phase = TAU*f*t
    x = np.zeros(len(t))
    if kind in ("keys", "vibes", "pluck", "marimba", "chime"):
        partials = {
            "keys": [(1,1,1.5),(2,.25,.48),(3,.08,.23),(4,.035,.12)],
            "vibes": [(1,1,1.6),(2,.16,.5),(3.98,.075,.24)],
            "pluck": [(1,1,.62),(2,.32,.27),(3,.12,.12),(4,.05,.07)],
            "marimba": [(1,1,.55),(3.99,.17,.1),(10.01,.025,.025)],
            "chime": [(1,1,.72),(2,.25,.34),(3,.07,.18),(4.02,.025,.09)],
        }[kind]
        for ratio, amplitude, decay in partials:
            if f*ratio < 8500:
                x += amplitude*np.sin(phase*ratio)*np.exp(-t/(decay*max(.5,duration)))
        if kind == "keys":
            # Gentle index-limited FM tine. Carrier and all significant sidebands
            # remain far below Nyquist at the authored pitches.
            x += .1*np.sin(phase + .5*np.exp(-t/.09)*np.sin(2*phase))*np.exp(-t/.5)
        if kind == "vibes":
            x *= .94 + .06*np.sin(TAU*4.7*t)
        attack = .007 if kind == "keys" else .004
    elif kind == "bass":
        x = (np.sin(phase)+.24*np.sin(2*phase)+.07*np.sin(3*phase))*np.exp(-t/max(.15,duration*.6))
        attack = .012
    elif kind == "pad":
        for ratio, gain in ((1,.75),(2,.16),(3,.045)):
            x += gain*(np.sin(phase*ratio*.999)+np.sin(phase*ratio*1.001))/2
        x *= .9+.1*np.sin(TAU*.4*t)
        attack = min(.35,duration*.18)
    elif kind == "brass":
        for h in range(1,7):
            x += (.7/h**1.6)*np.sin(h*phase + .008*h*np.sin(TAU*5*t))
        x *= .72+.28*np.exp(-t/.12)
        attack = .035
    elif kind == "flute":
        p = phase+.025*np.sin(TAU*4.3*t)*(1-np.exp(-t/.2))
        x = np.sin(p)+.085*np.sin(p*2)+.025*np.sin(p*3)
        attack = .07
    else:
        raise ValueError(kind)
    return smooth_edge(x,attack,min(duration*.22,.18)).astype(np.float32)*velocity


def noise(rng, duration, low=100, high=3000):
    x = spectrum_filter(rng.normal(size=round(duration*SR)),low,high)
    return x / max(np.sqrt(np.mean(x*x)),1e-9)


def bubble(duration, start, end):
    t = np.arange(round(duration*SR))/SR
    f = end + (start-end)*np.exp(-t/(duration*.2))
    x = np.sin(TAU*np.cumsum(f)/SR)*np.exp(-t/(duration*.3))
    return smooth_edge(x,.003,duration*.18).astype(np.float32)


def drum(kind, rng):
    duration = dict(kick=.32,snare=.18,hat=.085,shaker=.075,rim=.075,conga=.19)[kind]
    t = np.arange(round(duration*SR))/SR
    if kind == "kick":
        f = 48+58*np.exp(-t/.018)
        x = np.sin(TAU*np.cumsum(f)/SR)*np.exp(-t/.07)
        x += .025*noise(rng,duration,300,1400)*np.exp(-t/.008)
    elif kind == "snare":
        x = .55*noise(rng,duration,650,3600)*np.exp(-t/.034)
        x += .28*np.sin(TAU*185*t)*np.exp(-t/.035)
    elif kind in ("hat","shaker"):
        x = noise(rng,duration,2500,6500)*np.exp(-t/(.016 if kind == 'hat' else .025))*.4
    elif kind == "rim":
        x = (np.sin(TAU*820*t)+.4*np.sin(TAU*1250*t))*np.exp(-t/.012)*.5
    else:
        x = (np.sin(TAU*185*t)+.32*np.sin(TAU*290*t))*np.exp(-t/.046)
        x += .05*noise(rng,duration,400,2000)*np.exp(-t/.01)
    return smooth_edge(x,.002,.02).astype(np.float32)


def add(bus, signal, seconds, amplitude=1, pan=0):
    start = round(seconds*SR)
    if start < 0:
        signal = signal[-start:]
        start = 0
    count = min(len(signal),len(bus)-start)
    if count <= 0:
        return
    if bus.shape[1] == 1:
        bus[start:start+count,0] += signal[:count]*amplitude
    else:
        angle = (pan+1)*np.pi/4
        bus[start:start+count] += signal[:count,None]*np.array([np.cos(angle),np.sin(angle)])*amplitude


def room(bus, rng, duration=.7, wet=.12):
    """Finite diffuse impulse: render all tails, never trim at a loop boundary."""
    count = round(duration*SR)
    t = np.arange(count)/SR
    output = np.zeros((len(bus)+count-1,bus.shape[1]),np.float32)
    output[:len(bus)] = bus
    nfft = 1 << (len(output)-1).bit_length()
    for ch in range(bus.shape[1]):
        impulse = noise(rng,duration,180,4300)*np.exp(-t/(duration/7))
        impulse[:round(.022*SR)] = 0
        impulse = smooth_edge(impulse,.03,.06)
        impulse *= wet/max(np.sqrt(np.sum(impulse**2)),1e-12)
        for delay, amplitude in ((.039,.12),(.067,.07),(.113,.04)):
            impulse[round((delay+ch*.006)*SR)] += wet*amplitude
        reflected = np.fft.irfft(np.fft.rfft(bus[:,ch],nfft)*np.fft.rfft(impulse,nfft),nfft)
        output[:,ch] += reflected[:len(output)].astype(np.float32)
    return output


def wrap_tail(x, frames):
    out = x[:frames].copy()
    for pos in range(frames,len(x),frames):
        tail = x[pos:pos+frames]
        out[:len(tail)] += tail
    return out


def make_sfx(key, index):
    duration, _, _, target, channels = SFX[key]
    rng = np.random.Generator(np.random.PCG64(SEED+index))
    bus = np.zeros((round(duration*SR),channels),np.float32)
    if key in ("Click","Hover","AutoFlushTick"):
        values = {"Click":(620,240),"Hover":(920,1100),"AutoFlushTick":(510,300)}
        add(bus,bubble(duration,*values[key]),0)
        if key == "Hover":
            add(bus,smooth_edge(noise(rng,duration,700,2500),.018,.04),0,.06)
    elif key in ("Open","Close"):
        up = key == 'Open'
        add(bus,bubble(duration,350 if up else 760,850 if up else 260),0,.7)
        t=np.arange(len(bus))/SR
        add(bus,noise(rng,duration,350,2500)*np.sin(np.pi*t/duration)**2,0,.14)
        add(bus,bubble(duration*.55,500 if up else 640,1050 if up else 220),duration*.22,.28)
    elif key == "CoinCollect":
        add(bus,voice(88,.32,"chime"),.004,.7)
        add(bus,voice(95,.25,"chime"),.065,.32)
        add(bus,bubble(.08,1000,700),0,.12)
    elif key == "Flush":
        t=np.arange(len(bus))/SR
        sweep = noise(rng,duration,130,1800)*np.sin(np.pi*t/duration)**1.6
        sweep *= .68+.25*np.sin(TAU*5.5*t+.6*np.sin(TAU*2*t))
        add(bus,sweep,0,.45,-.18)
        add(bus,noise(rng,duration,700,3400)*np.sin(np.pi*t/duration)**2,0,.075,.25)
        for i in range(9):
            when=.035+i*.074+rng.uniform(-.007,.007)
            add(bus,bubble(.12,600-i*35,200-i*12),when,.18,rng.uniform(-.35,.35))
    elif key == "FlushRumble":
        t=np.arange(len(bus))/SR
        add(bus,(np.sin(TAU*63*t)+.25*np.sin(TAU*95*t))*np.sin(np.pi*t/duration)**2,0,.7)
        add(bus,noise(rng,duration,35,160)*np.sin(np.pi*t/duration)**2,0,.12)
    elif key == "Error":
        for when,note in ((0,53),(.115,50)):
            add(bus,voice(note,.15,"brass"),when,.8)
    elif key == "PurchaseSuccess":
        for when,note in zip((.01,.15,.3),(72,76,79)):
            add(bus,voice(note,.4,"keys"),when,.65)
            add(bus,voice(note+12,.28,"chime"),when,.12)
    elif key == "ServerEvent":
        # A rhythmic call-and-response fanfare, distinct from rising rarity arps.
        for when,note,length in [(0,67,.22),(.25,67,.18),(.5,72,.4),(.95,76,.3),(1.3,79,.7)]:
            add(bus,voice(note,length,"brass"),when,.52,-.15)
            add(bus,voice(note-12,length,"brass"),when,.25,.2)
        for note in (60,64,67,72):
            add(bus,voice(note,1.05,"brass"),1.55,.23,(note-66)/26)
        for i,note in enumerate((84,88,91,96)):
            add(bus,voice(note,.55,"chime"),1.6+i*.13,.17,(i-1.5)*.2)
        for when in (0,.25,.5,1.3,1.55):
            add(bus,drum("snare",rng),when,.11,.1)
            add(bus,drum("kick",rng),when,.16)
    else:
        # Escalate orchestration and harmonic color, not just source volume.
        settings = {
            "Epic":([72,76,79,83],.075,"chime",.3),
            "Legendary":([67,71,74,79,83,86],.105,"keys",.5),
            "Mythic":([69,73,76,80,85,88],.13,"vibes",.65),
            "Godly":([60,67,72,76,79,84],.12,"brass",.75),
            "Secret":([73,80,85,87,88,92,95],.13,"chime",1.05),
        }
        notes,spacing,kind,resolution = settings[key]
        for i,note in enumerate(notes):
            length=min(.72,duration-i*spacing-.05)
            if key == 'Secret':
                length=min(length,max(.12,resolution-i*spacing-.07))
            add(bus,voice(note,length,kind),.008+i*spacing,.48,(i/(len(notes)-1)-.5)*.9)
        resolved = {'Epic':[60,64,67], 'Legendary':[55,59,62],
                    'Mythic':[57,61,64,68], 'Godly':[60,64,67,72],
                    'Secret':[61,65,68]}[key]
        for i,note in enumerate(resolved):
            add(bus,voice(note,duration-resolution-.04,"pad" if key in ('Secret','Mythic') else "keys"),resolution,.26,(i-1)*.3)
        if key in ('Godly','Secret'):
            add(bus,drum("kick",rng),resolution,.24)
        if key == 'Secret':
            add(bus,voice(61,.95,"pad"),0,.22,-.3)
            add(bus,voice(68,1.05,"pad"),0,.18,.3)
            for i,note in enumerate((80,85,89,92,97)):
                add(bus,voice(note,.48,"chime"),1.06+i*.12,.27,(i-2)*.2)
    if key in ('Epic','Legendary','Mythic','Godly','Secret','ServerEvent','PurchaseSuccess','CoinCollect'):
        bus=room(bus,rng,.33,.12)[:len(bus)]
    bus=spectrum_filter(bus,30,6500)
    attack=.008 if key == 'ServerEvent' else .003
    bus=smooth_edge(bus,attack,min(.13,duration*.24))
    # Remove residual DC under the same envelope without disturbing zero edges.
    taper=smooth_edge(np.ones(len(bus)),attack,min(.13,duration*.24))[:,None]
    bus-=taper*(np.sum(bus,axis=0)/np.sum(taper))
    _, level=loudness(bus)
    gain=min(10**((target-level)/20),10**(-2.5/20)/max(np.max(np.abs(bus)),1e-9))
    return (bus*gain).astype(np.float32)


def make_music(song, index):
    rng=np.random.Generator(np.random.PCG64(SEED+100+index))
    beat=60/song['bpm']
    frames=round(40*4*beat*SR)
    bus=np.zeros((frames+4*SR,2),np.float32)
    kit={kind:drum(kind,rng) for kind in ('kick','snare','hat','rim','shaker','conga')}
    chords=song['chords']
    lead=song['lead']
    for bar in range(40):
        section=bar//8
        root,tones=chords[bar%8]
        next_root=chords[(bar+1)%8][0]
        start=bar*4*beat
        # Five eight-bar phrases: A, A variation, B, spacious interlude, A return.
        sparse=section==3
        energy=[.86,1.,.96,.72,.92][section]
        def event(signal,position,amplitude,pan=0,human=True):
            timing=rng.uniform(-.007,.007) if human else 0
            when=max(.008,start+position*beat+timing)
            add(bus,signal,when,amplitude*rng.uniform(.92,1.06)*energy,pan)
        chord_positions=[0,2.5] if index in (0,3) else [.5,2,3.25] if index==1 else [0]
        for pos in chord_positions:
            length=beat*(1.8 if index in (0,3) else 1.1 if index==1 else 3.8)
            instrument='keys' if index in (0,3) else 'pluck' if index==1 else 'pad'
            for j,note in enumerate(tones):
                event(voice(note,length,instrument),pos+j*.012,.105 if instrument!='pad' else .078,(j-2)*.17)
        if index in (0,1,3):
            for j,note in enumerate(tones[:3]):
                event(voice(note,4.3*beat,'pad'),0,.025,(j-1)*.4)
        # Anticipations and fifths make a bassline; the next root connects bars.
        bassline=[(0,root,1.35),(1.75,root+7,.65),(2.5,root,1.),(3.5,next_root,.45)]
        if index==2:
            bassline=[(0,root,2.4),(2.75,root+7,.95)]
        for pos,note,length in bassline:
            event(voice(note,beat*length,'bass'),pos,.21)
        # The motif leaves breathing room; B reverses contour, the return answers it.
        if not sparse or bar%2==0:
            pattern=song['motif'] if section!=2 else list(reversed(song['motif']))
            for j,pos in enumerate(song['rhythm']):
                if bar%4==3 and j>=len(pattern)-2:
                    continue
                if sparse and j%2:
                    continue
                degree=pattern[(j+(bar%2))%len(pattern)]%len(tones)
                pitch=tones[degree]+12
                if section==4 and j==len(pattern)-1:
                    pitch=tones[0]+12
                length=(.85 if lead=='flute' else .5)*beat
                if j==len(pattern)-1:
                    length*=1.4
                swing=song['swing'] if int(pos*2)%2 else 0
                event(voice(pitch,length,lead),pos+swing,.105 if lead!='flute' else .082,.16)
        if section in (1,2,4) and bar%2==1:
            # Quiet answer in the opposite side of the image.
            for j,pos in enumerate((2.25,3.25)):
                event(voice(tones[(j+2)%len(tones)]+12,.45*beat,'chime'),pos,.035,-.38)
        # Distinct grooves. Hats are intentionally low, band-limited and soft.
        kicks=[0,2.5] if index!=2 else [0]
        if index==1: kicks=[0,1.75,2.5]
        for pos in kicks:
            event(kit['kick'],pos,.23 if index!=2 else .16)
        for pos in ([2] if index==2 else [1,3]):
            event(kit['rim'] if index in (1,4) else kit['snare'],pos+.022,.09 if not sparse else .06,.08)
        for step in range(8):
            if sparse and step%2: continue
            pos=step*.5+(song['swing'] if step%2 else 0)
            event(kit['shaker'] if index in (1,4) else kit['hat'],pos,.027 if step%2 else .019,.32 if step%2 else -.25)
        if index in (1,4):
            for j,pos in enumerate((.75,2.25,3.5)):
                event(kit['conga'],pos,.062 if index==1 else .039,(-1 if j%2 else 1)*.4)
        if bar%8==7 and section!=3:
            for j,pos in enumerate((3.25,3.5,3.75)):
                event(kit['rim'],pos,.035+j*.008,(j-1)*.2)
    # Wrap every note release and the complete finite reverb tail into the start.
    bus=wrap_tail(room(bus,rng,1.65,.1 if index!=2 else .18),frames)
    bus=spectrum_filter(bus,28,5200 if index in (0,3) else 6200,periodic=True)
    # Gentle cubic tape-style warmth, at low drive. Periodic filtering after it.
    bus/=max(np.max(np.abs(bus)),1e-9)
    bus=bus-.065*bus**3
    bus=spectrum_filter(bus,24,6400,periodic=True)
    bus-=np.mean(bus,axis=0)
    # Put the file boundary at a naturally quiet, low-derivative point within the
    # first 8 ms; no bar/time is removed and no fade-to-silence interrupts the loop.
    candidates=np.arange(1,round(.008*SR))
    score=np.max(np.abs(bus[candidates]-bus[candidates-1]),axis=1)
    score+=.02*np.max(np.abs(bus[candidates]),axis=1)
    shift=int(candidates[np.argmin(score)])
    bus=np.roll(bus,-shift,axis=0)
    bus*=10**(-6.2/20)/np.max(np.abs(bus))
    return bus.astype(np.float32),shift


def inspect(codec, path, entry):
    samples,info=codec.read(path)
    rate=info.samplerate
    stats=measure(samples,rate)
    entry.update(stats)
    entry.update(duration=round(len(samples)/rate,6),frames=len(samples),sample_rate=info.samplerate,
                 channels=info.channels,bytes=path.stat().st_size,
                 sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    failures=[]
    def require(condition,message):
        if not condition: failures.append(message)
    require(np.all(np.isfinite(samples)),"non-finite samples")
    require(len(samples)==entry['expected_frames'],"sample count mismatch")
    require(info.format==0x200060,"not OGG Vorbis")
    require(info.sections==1,"multiple logical streams")
    is_new=entry['key'] in audio_new.SLOTS
    if is_new:
        duration,lo,hi,level,_=audio_new.SLOTS[entry['key']]
        require((entry['min_duration'],entry['max_duration'],entry['target_k_level'])==(lo,hi,level),"manifest differs from slot contract")
        require(entry['expected_frames']==round(duration*audio_new.RATE),"manifest frame count differs from generator")
        require(entry['loop']==(entry['key'] in audio_new.LOOPS),"manifest loop flag differs from slot")
    require(info.samplerate==(audio_new.RATE if is_new else SR),"unexpected sample rate")
    require(info.channels==(1 if is_new else (2 if entry['key'].startswith('Music') else SFX[entry['key']][4])),"unexpected channel count")
    require(entry['min_duration']<=len(samples)/rate<=entry['max_duration'],"slot duration")
    require(path.stat().st_size<20_000_000 and len(samples)/rate<420,"Roblox import limits")
    require(stats['clipped_samples']==0 and stats['true_peak_estimate_dbtp']<-1,"clipping/headroom")
    require(stats['dc_offset']<.0005,"DC offset")
    require(stats['rms_dbfs']>-55,"silent or nearly silent asset")
    require(stats['high_band_energy_fraction_10khz']<.002,"excess high-frequency energy")
    if entry['loop']:
        require(stats['seam_delta']<.003,"loop seam exceeds 0.003 FS")
        require(stats['longest_silence_seconds']<.12,"music has silent gap")
        if not is_new:
            require(-7.2<stats['peak_dbfs']<-5.2,"music peak outside target")
            require(-26<stats['lufs_estimate']<-15,"music loudness outside quiet mix range")
    else:
        require(stats['edge_peak']<.003,"one-shot endpoint click risk")
        require(stats['longest_silence_seconds']<.16,"excess one-shot silence")
        if entry['key'] in ('Epic','Legendary','Mythic','Godly','Secret','ServerEvent'):
            require(abs(stats['lufs_estimate']+14)<2,"stinger loudness outside target")
    if is_new:
        audio_new.inspect_extra(samples,rate,entry,require)
    entry['checks_passed']=not failures
    entry['failures']=failures
    preview(OUT/'previews'/f"{entry['key']}.png",entry['key'],samples,stats,entry['loop'],rate)
    return samples


def player_page(entries):
    cards=[]
    for e in entries:
        key=e['key']
        cards.append(f'''<article><h2>{key} <small>{html.escape(e.get('title',e.get('style','')))}</small></h2>
<p>{e['duration']:.3f}s / {e['peak_dbfs']:.1f} dBFS / {e['bytes']/1000:.0f} kB / {'loop' if e['loop'] else 'one-shot'}</p>
<audio controls preload="none" {'loop' if e['loop'] else ''} src="final/{key}.ogg"></audio>
{'<label> Sale speed <select onchange="this.parentElement.previousElementSibling.playbackRate=Number(this.value);this.parentElement.previousElementSibling.preservesPitch=false"><option>1.00</option><option>1.12</option><option>1.24</option></select></label>' if key in ('Sell','SellAll') else ''}
<details><summary>Waveform and spectrogram</summary><img loading="lazy" alt="{key} diagnostics" src="previews/{key}.png"></details></article>''')
    (OUT/'review.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Toilet RNG - original audio review</title><style>body{background:#0f1828;color:#dce9f3;font:16px system-ui;max-width:1000px;margin:40px auto;padding:0 20px}h1{color:#71e5c6}article{border-top:1px solid #395067;padding:20px 0}small{font-size:16px;font-weight:400;color:#aabed0}audio{width:min(100%,600px)}img{max-width:100%}summary{cursor:pointer;padding:14px 0}p{line-height:1.6}</style>
<h1>Toilet RNG / original audio</h1><p>48 synthesized effects and 5 original instrumental loops. Original 21 files remain unchanged; 32 new effects are 48 kHz mono. Play at comfortable volume. Loop controls repeat the complete file. For sample-accurate transition audition in a DAW, repeat the decoded OGG without gaps; browser controls do not prove Roblox timing. RebirthHold and Ambience need a 20 ms runtime release for click-free arbitrary stops; browser pause is abrupt. Automated QA is not human listening approval.</p>'''+''.join(cards)+'</html>',encoding='utf-8')


def report(entries, codec, write_manifest=True):
    batches=[]
    for e in entries:
        if not batches or (e['key'] in audio_new.SLOTS)!=(batches[-1][0]['key'] in audio_new.SLOTS) or sum(v['bytes'] for v in batches[-1])+e['bytes']>=8_500_000:
            batches.append([])
        batches[-1].append(e)
    batch_records=[dict(batch=i+1,keys=[e['key'] for e in group],bytes=sum(e['bytes'] for e in group)) for i,group in enumerate(batches)]
    if any(b['bytes']>=9_000_000 for b in batch_records):
        raise RuntimeError('Upload batch must remain below 9 MB')
    data=dict(schema_version=2,seed=SEED,sample_rates=[SR,audio_new.RATE],codec='Ogg Vorbis',encoder=codec.version,
              numpy=np.__version__,source='100% original numerical synthesis; no recordings, sample packs, MIDI imports or third-party melodies',
              meter='Estimated K-weighted gated loudness, 400 ms / 75% overlap. Under 400 ms: LUFS null, short_k_weighted_db is an ungated proxy. Not a certified BS.1770 meter.',
              loop_seam_threshold=.003,batch_limit_bytes=9_000_000,upload_batches=batch_records,assets=entries)
    if write_manifest:
        (OUT/'manifest.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    lines=['# Audio quality report','',f'Encoder: {codec.version}; NumPy {np.__version__}; original rate: {SR} Hz; new SFX: {audio_new.RATE} Hz mono.',
           'Measurements are from decoded final OGGs. LUFS values are estimates; short UI clips use the documented ungated K-weighted proxy. No human listening or Roblox import approval is claimed.','',
           '| Key | Seconds | Peak dBFS | Est. LUFS / short proxy | DC | Seam delta | kB | QA |',
           '| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |']
    for e in entries:
        level=e['lufs_estimate'] if e['lufs_estimate'] is not None else e['short_k_weighted_db']
        lines.append(f"| {e['key']} | {e['duration']:.3f} | {e['peak_dbfs']:.2f} | {level:.2f}{'*' if e['lufs_estimate'] is None else ''} | {e['dc_offset']:.7f} | {e['seam_delta']:.6f} | {e['bytes']/1000:.1f} | {'PASS' if e['checks_passed'] else ', '.join(e['failures'])} |")
    lines+=['','*Short-clip proxy, not integrated LUFS. Seam delta is an acceptance check for all loops; one-shots are checked against silence at both endpoints.','',
            'Checks: finite samples; exact frames; one Vorbis stream; slot duration; Roblox duration/size/rate; zero clipped samples; estimated 4x true peak < -1 dBTP; DC < 0.0005 FS; non-silence; energy above 10 kHz < 0.2%; music seam < 0.003 FS; no music silence >= 120 ms; music peak -7.2..-5.2 dBFS; music estimated loudness -26..-15; stingers -16..-12 LUFS estimate; one-shot endpoint < 0.003 FS and silence < 160 ms.','',
            'New SFX additionally require 48 kHz mono, estimated true peak <= -3 dBTP, level within 1.5 dB of authored class target, onset within 10 ms, one-shot edge <= 0.001 FS, exact spec/runtime key and duration/loop agreement. Loops: seam <= 0.001 FS, slope mismatch <= 0.001 FS/sample, boundary energy within 3 dB of nearby windows; 64 arbitrary stop phases tested with a 20 ms cosine release. Sell/SellAll: decoded playback-speed probes at 1.00, 1.06, 1.12, 1.18 and 1.24x. See per-file manifest fields. Original files are also verified against original-21-hashes.json.','',
            'A nonzero loop cannot guarantee click-free abrupt stops at every phase. The source code currently destroys stopped voices without a release; the 20 ms runtime fade is a handoff requirement, not an implemented src change. No live playback or human audition approval is claimed.','',
            'The spectral high-band check detects excess ultrasonic/near-Nyquist content, not every possible alias or an unpleasant timbre. The peak interpolation and loudness meter are engineering estimates. PNG spectrograms sample overlapping windows across the file and may miss very short events between plotted columns.','', '## Upload batches','']
    for b in batch_records:
        lines.append(f"- Batch {b['batch']}: {', '.join(b['keys'])}; {b['bytes']:,} bytes ({b['bytes']/1e6:.3f} MB), below 9,000,000 bytes.")
    (OUT/'quality-report.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    player_page(entries)
    return all(e['checks_passed'] for e in entries)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sndfile',help='Path to existing libsndfile library')
    parser.add_argument('--check',action='store_true',help='Decode, measure and verify existing deliverables without rendering')
    parser.add_argument('--only',nargs='+',help='Render selected keys; preserve other manifest entries')
    parser.add_argument('--new',action='store_true',help='Render/check only the 32 new cues; retain original files')
    args=parser.parse_args()
    codec=Codec(args.sndfile)
    (OUT/'final').mkdir(parents=True,exist_ok=True)
    (OUT/'previews').mkdir(parents=True,exist_ok=True)
    previous={}
    if (OUT/'manifest.json').exists():
        previous_entries=json.loads((OUT/'manifest.json').read_text())['assets']
        previous={e['key']:e for e in previous_entries}
        if len(previous)!=len(previous_entries):
            raise RuntimeError('Duplicate manifest keys')
    entries=[]
    keys=list(SFX)+[s['key'] for s in SONGS]+list(audio_new.SLOTS)
    if set(previous)-set(keys) or (args.check and set(previous)!=set(keys)):
        raise RuntimeError('Manifest key set differs from configured slots')
    runtime=audio_new.contracts(ROOT,SFX)
    frozen=json.loads((OUT/'original-21-hashes.json').read_text(encoding='utf-8-sig'))
    audio_new.verify_originals(OUT,frozen)
    if args.new:
        if args.only: parser.error('--new and --only are mutually exclusive')
        args.only=list(audio_new.SLOTS)
    if args.only and set(args.only)-set(keys):
        parser.error('Unknown keys: '+', '.join(set(args.only)-set(keys)))
    for index,key in enumerate(keys):
        path=OUT/'final'/f'{key}.ogg'
        if args.only and key not in args.only:
            if key in previous: entries.append(previous[key])
            continue
        print(f'{"Checking" if args.check else "Rendering"} {key}',flush=True)
        if args.check:
            if key not in previous: raise RuntimeError(f'{key}: missing manifest entry')
            entry=previous[key].copy()
            expected_hash=entry['sha256']
        else:
            # Never rewrite the finished original batch in a normal full build.
            if key not in audio_new.SLOTS and path.exists() and not args.only:
                if key not in previous: raise RuntimeError(f'{key}: missing original metadata')
                entries.append(previous[key])
                continue
            entry=dict(key=key,file=f'final/{key}.ogg',loop=key.startswith('Music') or key in audio_new.LOOPS,
                       intended_assets_luau_path=f'src/shared/Config/Assets.luau:Music[{key[-1]}]' if key.startswith('Music') else f'src/shared/Config/Assets.luau:Sounds.{key}')
            if key in audio_new.SLOTS:
                samples=audio_new.make(key,sys.modules[__name__])
                _,lo,hi,target,style=audio_new.SLOTS[key]
                entry.update(min_duration=lo,max_duration=hi,target_k_level=target,style=style,
                             runtime_class=runtime[key]['class'],runtime_gain=runtime[key]['gain'],
                             stop_release_seconds=.020 if key in audio_new.LOOPS else None)
            elif key.startswith('Music'):
                song=SONGS[int(key[-1])-1]
                samples,shift=make_music(song,int(key[-1])-1)
                entry.update(title=song['title'],style=song['style'],tempo_bpm=song['bpm'],musical_key=song['tonic'],bars=40,
                             arrangement='8 bars A / 8 A variation / 8 B / 8 interlude / 8 A return',
                             boundary_rotation_samples=shift,min_duration=90,max_duration=150)
            else:
                samples=make_sfx(key,index)
                entry.update(min_duration=SFX[key][1],max_duration=SFX[key][2],target_k_level=SFX[key][3])
            entry['expected_frames']=len(samples)
            if key in audio_new.LOOPS:
                samples,shift=audio_new.encode_loop(codec,path,samples)
                entry['codec_boundary_rotation_samples']=shift
            else:
                codec.write(path,samples,.5,audio_new.RATE if key in audio_new.SLOTS else SR)
            entry['synthesis_pcm_sha256']=hashlib.sha256(samples.astype('<f4').tobytes()).hexdigest()
        inspect(codec,path,entry)
        if args.check and entry['sha256']!=expected_hash:
            entry['failures'].append('file hash differs from manifest')
            entry['checks_passed']=False
        entries.append(entry)
        print(f"  {entry['duration']:.3f}s  peak {entry['peak_dbfs']:.2f}  LUFS {entry['lufs_estimate']}  seam {entry['seam_delta']:.6f}  {entry['failures'] or 'PASS'}",flush=True)
    audio_new.verify_originals(OUT,frozen)
    audio_new.verify_inventory(OUT,entries,keys)
    passed=report(entries,codec,write_manifest=not args.check)
    print(f'{len(entries)} assets; {sum(e["bytes"] for e in entries)/1e6:.3f} MB; QA {"PASS" if passed else "FAIL"}',flush=True)
    return 0 if passed else 1


if __name__=='__main__':
    sys.exit(main())
