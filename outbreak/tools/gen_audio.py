#!/usr/bin/env python3
"""
tools/gen_audio.py - synthesizes every sound the pack ships, from nothing. No sample packs, no
licensing question, no download. Pure Python `wave`: 22050 Hz, mono, 16-bit.

  outbreak_radio/html/sfx/
    click_on.wav     squelch click on key-up (short noise burst, sharp envelope)
    click_off.wav    release click + 220 ms static tail
    hiss.wav         1.6 s loop, quiet band-limited hiss while a transmission is open
    static_weak.wav  1.6 s loop, rougher static for the edge of range
  outbreak_ambience/html/sfx/
    wind.wav         6 s loop, low-passed noise with slow swell
    groan_1.wav / groan_2.wav   distant moans: low tone + vibrato + breathy noise, 1.4 s, decayed

Re-run any time; deterministic (seeded).
"""
import wave, struct, math, random, os

SR = 22050
random.seed(1409)

def write(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))
    print('wrote', path, f'{len(samples)/SR:.2f}s')

def noise(n): return [random.uniform(-1, 1) for _ in range(n)]
def lowpass(x, k):        # one-pole; k in (0,1): smaller = darker
    y, acc = [], 0.0
    for s in x: acc += k * (s - acc); y.append(acc)
    return y
def highpass(x, k):
    return [a - b for a, b in zip(x, lowpass(x, k))]
def env(n, a, d, sustain=1.0, r=0):   # attack/decay/release in samples
    out = []
    for i in range(n):
        if i < a: out.append(i / max(1, a))
        elif i < a + d: out.append(1.0 - (1.0 - sustain) * (i - a) / max(1, d))
        elif i >= n - r: out.append(sustain * (n - i) / max(1, r))
        else: out.append(sustain)
    return out
def mul(x, e, g=1.0): return [s * v * g for s, v in zip(x, e)]
def add(*xs):
    n = max(len(x) for x in xs)
    return [sum(x[i] if i < len(x) else 0.0 for x in xs) for i in range(n)]
def fade_loop(x, ms=40):   # crossfade the tail into the head so it loops clean
    f = int(SR * ms / 1000); n = len(x); y = list(x)
    for i in range(f):
        t = i / f
        y[n - f + i] = x[n - f + i] * (1 - t) + x[i] * t
    return y

# ── radio ──
n = int(SR * 0.07)
click = mul(highpass(noise(n), 0.35), env(n, 20, n - 40, 0.15, 20), 0.9)
write('resources/[outbreak]/outbreak_radio/html/sfx/click_on.wav', click)

n1, n2 = int(SR * 0.05), int(SR * 0.22)
release = mul(highpass(noise(n1), 0.4), env(n1, 10, n1 - 20, 0.2, 10), 0.8)
tail = mul(lowpass(noise(n2), 0.55), env(n2, 30, n2 - 60, 0.0, 30), 0.45)
write('resources/[outbreak]/outbreak_radio/html/sfx/click_off.wav', release + tail)

n = int(SR * 1.6)
hiss = fade_loop(mul(lowpass(highpass(noise(n), 0.02), 0.6), [1.0] * n, 0.22))
write('resources/[outbreak]/outbreak_radio/html/sfx/hiss.wav', hiss)

crackle = []
for i in range(n):
    crackle.append(random.uniform(-1, 1) if random.random() < 0.012 else 0.0)
weak = fade_loop(add(mul(lowpass(noise(n), 0.5), [1.0] * n, 0.35), mul(crackle, [1.0] * n, 0.9)))
write('resources/[outbreak]/outbreak_radio/html/sfx/static_weak.wav', weak)

# ── ambience ──
n = int(SR * 6.0)
swell = [0.55 + 0.45 * math.sin(2 * math.pi * 0.23 * i / SR + 1.1) * math.sin(2 * math.pi * 0.071 * i / SR) for i in range(n)]
wind = fade_loop(mul(lowpass(lowpass(noise(n), 0.08), 0.5), swell, 0.5), 200)
write('resources/[outbreak]/outbreak_ambience/html/sfx/wind.wav', wind)

def groan(f0, seed):
    random.seed(seed)
    n = int(SR * 1.4)
    out = []
    for i in range(n):
        t = i / SR
        f = f0 * (1.0 + 0.06 * math.sin(2 * math.pi * 5.5 * t)) * (1.0 - 0.12 * t)   # vibrato + downward slide
        ph = 2 * math.pi * f * t
        tone = 0.6 * math.sin(ph) + 0.25 * math.sin(2 * ph) + 0.12 * math.sin(3 * ph) + 0.08 * math.sin(0.5 * ph)
        out.append(tone)
    breath = mul(lowpass(noise(n), 0.12), [1.0] * n, 0.35)
    g = mul(add(out, breath), env(n, int(SR * 0.18), int(SR * 0.5), 0.55, int(SR * 0.45)), 0.6)
    return lowpass(g, 0.35)
write('resources/[outbreak]/outbreak_ambience/html/sfx/groan_1.wav', groan(82.0, 7))
write('resources/[outbreak]/outbreak_ambience/html/sfx/groan_2.wav', groan(64.0, 11))
