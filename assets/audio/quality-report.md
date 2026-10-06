# Audio quality report

Encoder: libsndfile-1.2.2; NumPy 1.26.4; original rate: 32000 Hz; new SFX: 48000 Hz mono.
Measurements are from decoded final OGGs. LUFS values are estimates; short UI clips use the documented ungated K-weighted proxy. No human listening or Roblox import approval is claimed.

| Key | Seconds | Peak dBFS | Est. LUFS / short proxy | DC | Seam delta | kB | QA |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Click | 0.120 | -13.31 | -25.04* | 0.0000114 | 0.000327 | 4.2 | PASS |
| Hover | 0.085 | -22.67 | -33.23* | 0.0000018 | 0.000668 | 4.5 | PASS |
| Open | 0.290 | -14.66 | -25.04* | 0.0000176 | 0.000008 | 5.6 | PASS |
| Close | 0.240 | -16.56 | -27.08* | 0.0000021 | 0.000023 | 5.4 | PASS |
| CoinCollect | 0.360 | -12.03 | -19.99* | 0.0000002 | 0.000089 | 5.5 | PASS |
| Flush | 0.880 | -6.60 | -18.14 | 0.0000057 | 0.000006 | 12.7 | PASS |
| FlushRumble | 0.760 | -15.50 | -26.96 | 0.0000406 | 0.000003 | 4.9 | PASS |
| Epic | 0.900 | -3.74 | -14.47 | 0.0000015 | 0.000009 | 10.5 | PASS |
| Legendary | 1.380 | -4.37 | -13.97 | 0.0000087 | 0.000004 | 14.0 | PASS |
| Mythic | 1.680 | -4.44 | -13.96 | 0.0000086 | 0.000009 | 15.8 | PASS |
| Godly | 1.900 | -2.90 | -13.96 | 0.0000122 | 0.000001 | 18.4 | PASS |
| Secret | 2.300 | -4.04 | -14.01 | 0.0000139 | 0.000005 | 24.9 | PASS |
| ServerEvent | 2.800 | -3.52 | -13.96 | 0.0000230 | 0.000208 | 29.5 | PASS |
| PurchaseSuccess | 0.720 | -9.91 | -19.99 | 0.0000013 | 0.000004 | 7.0 | PASS |
| Error | 0.270 | -22.74 | -28.96* | 0.0000018 | 0.000010 | 4.6 | PASS |
| AutoFlushTick | 0.075 | -20.51 | -32.00* | 0.0000258 | 0.000109 | 4.2 | PASS |
| Music1 | 120.000 | -6.20 | -21.38 | 0.0000028 | 0.001679 | 1147.4 | PASS |
| Music2 | 100.000 | -6.22 | -19.33 | 0.0000058 | 0.000958 | 1056.4 | PASS |
| Music3 | 133.333 | -6.13 | -18.21 | 0.0000043 | 0.000640 | 1354.9 | PASS |
| Music4 | 111.628 | -6.11 | -19.69 | 0.0000036 | 0.002120 | 1067.8 | PASS |
| Music5 | 96.000 | -6.10 | -20.30 | 0.0000029 | 0.001249 | 987.3 | PASS |
| FlushStart | 0.145 | -8.74 | -25.01* | 0.0000093 | 0.000280 | 4.5 | PASS |
| Common | 0.160 | -14.10 | -25.93* | 0.0000183 | 0.000361 | 4.7 | PASS |
| Uncommon | 0.260 | -11.78 | -23.96* | 0.0000292 | 0.000526 | 4.9 | PASS |
| Rare | 0.440 | -10.19 | -20.93 | 0.0000109 | 0.000632 | 5.8 | PASS |
| DropLanding | 0.170 | -14.55 | -26.93* | 0.0000257 | 0.000323 | 4.4 | PASS |
| Sell | 0.310 | -11.83 | -19.97* | 0.0000014 | 0.000033 | 5.4 | PASS |
| SellAll | 0.560 | -10.19 | -19.99 | 0.0000007 | 0.000475 | 7.0 | PASS |
| CoinPopup | 0.110 | -29.01 | -32.94* | 0.0000002 | 0.000149 | 4.6 | PASS |
| DisplayPlace | 0.310 | -10.71 | -23.97* | 0.0000102 | 0.000020 | 5.6 | PASS |
| DisplayReturn | 0.235 | -14.89 | -26.98* | 0.0000219 | 0.000015 | 4.6 | PASS |
| DisplayLocked | 0.195 | -11.62 | -28.96* | 0.0000076 | 0.000002 | 4.9 | PASS |
| ToiletUpgrade | 1.480 | -3.83 | -16.13 | 0.0000035 | 0.000016 | 12.6 | PASS |
| UpgradeBuy | 0.480 | -9.34 | -19.94 | 0.0000013 | 0.000135 | 6.4 | PASS |
| UpgradeMax | 0.980 | -6.02 | -16.96 | 0.0000014 | 0.000278 | 9.6 | PASS |
| RebirthHold | 1.000 | -19.08 | -29.99 | 0.0000162 | 0.000891 | 8.9 | PASS |
| RebirthSuccess | 2.620 | -3.66 | -14.98 | 0.0000364 | 0.000335 | 20.1 | PASS |
| IndexClaim | 0.650 | -9.84 | -19.97 | 0.0000056 | 0.000199 | 7.0 | PASS |
| DailyClaim | 0.600 | -10.88 | -20.95 | 0.0000141 | 0.000329 | 7.0 | PASS |
| DailyStreak | 1.440 | -6.06 | -16.96 | 0.0000050 | 0.000164 | 12.3 | PASS |
| TutorialStep | 0.340 | -16.91 | -26.94* | 0.0000012 | 0.000109 | 5.3 | PASS |
| TabSwitch | 0.100 | -17.40 | -28.20* | 0.0000048 | 0.000793 | 4.8 | PASS |
| PurchaseStart | 0.260 | -19.82 | -26.93* | 0.0000003 | 0.000023 | 5.5 | PASS |
| PurchaseFail | 0.260 | -19.12 | -28.94* | 0.0000023 | 0.000063 | 4.7 | PASS |
| AutoFlushToggle | 0.170 | -11.01 | -27.00* | 0.0000812 | 0.000044 | 4.8 | PASS |
| Teleport | 0.580 | -10.06 | -23.30 | 0.0000029 | 0.000066 | 7.5 | PASS |
| PortalLocked | 0.260 | -15.70 | -27.92* | 0.0000116 | 0.000037 | 4.5 | PASS |
| ChatAnnouncement | 0.390 | -18.39 | -27.94* | 0.0000012 | 0.000083 | 5.6 | PASS |
| LuckStart | 0.610 | -12.74 | -23.98 | 0.0000005 | 0.000172 | 8.0 | PASS |
| LuckEnd | 0.460 | -17.54 | -26.95 | 0.0000013 | 0.000530 | 6.9 | PASS |
| LeaderboardUpdate | 0.070 | -31.15 | -36.12* | 0.0000001 | 0.000357 | 4.5 | PASS |
| SpawnArrival | 0.720 | -14.79 | -25.00 | 0.0000007 | 0.000017 | 8.2 | PASS |
| Ambience | 36.000 | -18.66 | -33.27 | 0.0000013 | 0.000580 | 189.2 | PASS |

*Short-clip proxy, not integrated LUFS. Seam delta is an acceptance check for all loops; one-shots are checked against silence at both endpoints.

Checks: finite samples; exact frames; one Vorbis stream; slot duration; Roblox duration/size/rate; zero clipped samples; estimated 4x true peak < -1 dBTP; DC < 0.0005 FS; non-silence; energy above 10 kHz < 0.2%; music seam < 0.003 FS; no music silence >= 120 ms; music peak -7.2..-5.2 dBFS; music estimated loudness -26..-15; stingers -16..-12 LUFS estimate; one-shot endpoint < 0.003 FS and silence < 160 ms.

New SFX additionally require 48 kHz mono, estimated true peak <= -3 dBTP, level within 1.5 dB of authored class target, onset within 10 ms, one-shot edge <= 0.001 FS, exact spec/runtime key and duration/loop agreement. Loops: seam <= 0.001 FS, slope mismatch <= 0.001 FS/sample, boundary energy within 3 dB of nearby windows; 64 arbitrary stop phases tested with a 20 ms cosine release. Sell/SellAll: decoded playback-speed probes at 1.00, 1.06, 1.12, 1.18 and 1.24x. See per-file manifest fields. Original files are also verified against original-21-hashes.json.

A nonzero loop cannot guarantee click-free abrupt stops at every phase. The source code currently destroys stopped voices without a release; the 20 ms runtime fade is a handoff requirement, not an implemented src change. No live playback or human audition approval is claimed.

The spectral high-band check detects excess ultrasonic/near-Nyquist content, not every possible alias or an unpleasant timbre. The peak interpolation and loudness meter are engineering estimates. PNG spectrograms sample overlapping windows across the file and may miss very short events between plotted columns.

## Upload batches

- Batch 1: Click, Hover, Open, Close, CoinCollect, Flush, FlushRumble, Epic, Legendary, Mythic, Godly, Secret, ServerEvent, PurchaseSuccess, Error, AutoFlushTick, Music1, Music2, Music3, Music4, Music5; 5,785,365 bytes (5.785 MB), below 9,000,000 bytes.
- Batch 2: FlushStart, Common, Uncommon, Rare, DropLanding, Sell, SellAll, CoinPopup, DisplayPlace, DisplayReturn, DisplayLocked, ToiletUpgrade, UpgradeBuy, UpgradeMax, RebirthHold, RebirthSuccess, IndexClaim, DailyClaim, DailyStreak, TutorialStep, TabSwitch, PurchaseStart, PurchaseFail, AutoFlushToggle, Teleport, PortalLocked, ChatAnnouncement, LuckStart, LuckEnd, LeaderboardUpdate, SpawnArrival, Ambience; 399,746 bytes (0.400 MB), below 9,000,000 bytes.
