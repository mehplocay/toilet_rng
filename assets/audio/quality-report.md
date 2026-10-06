# Audio quality report

Encoder: libsndfile-1.2.2; NumPy 1.26.4; rate: 32000 Hz.
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

*Short-clip proxy, not integrated LUFS. Seam delta is an acceptance check only for music; one-shots are checked against silence at both endpoints.

Checks: finite samples; exact frames; one Vorbis stream; slot duration; Roblox duration/size/rate; zero clipped samples; estimated 4x true peak < -1 dBTP; DC < 0.0005 FS; non-silence; energy above 10 kHz < 0.2%; music seam < 0.003 FS; no music silence >= 120 ms; music peak -7.2..-5.2 dBFS; music estimated loudness -26..-15; stingers -16..-12 LUFS estimate; one-shot endpoint < 0.003 FS and silence < 160 ms.

The spectral high-band check detects excess ultrasonic/near-Nyquist content, not every possible alias or an unpleasant timbre. The peak interpolation and loudness meter are engineering estimates. PNG spectrograms sample overlapping windows across the file and may miss very short events between plotted columns.

## Upload batches

- Batch 1: Click, Hover, Open, Close, CoinCollect, Flush, FlushRumble, Epic, Legendary, Mythic, Godly, Secret, ServerEvent, PurchaseSuccess, Error, AutoFlushTick, Music1, Music2, Music3, Music4, Music5; 5,785,365 bytes (5.785 MB), below 9,000,000 bytes.
