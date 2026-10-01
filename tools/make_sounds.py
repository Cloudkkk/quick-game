"""Original cartoon SFX: offline synthesis, no sampled/third-party audio."""
from pathlib import Path
import math, wave, struct, json

RATE = 44100
ROOT = Path(__file__).resolve().parents[1] / "assets" / "sounds"
ROOT.mkdir(parents=True, exist_ok=True)

def tone(buf, start, length, f0, f1=None, gain=1.0, decay=7.0, bright=0.15):
    phase = 0.0
    for i in range(int(length * RATE)):
        t = i / RATE
        u = t / length
        f = f0 + ((f1 if f1 is not None else f0) - f0) * u
        phase += 2 * math.pi * f / RATE
        attack = min(1.0, t / 0.006)
        release = min(1.0, (length - t) / 0.012)
        env = attack * release * math.exp(-decay * u)
        sample = (math.sin(phase) + bright * math.sin(2 * phase)) * env * gain
        index = int(start * RATE) + i
        if index < len(buf): buf[index] += sample

def render(name, seconds, notes):
    buf = [0.0] * int(seconds * RATE)
    for args in notes: tone(buf, *args)
    peak = max(map(abs, buf)) or 1
    buf = [v * 0.32 / peak for v in buf]
    pcm = b"".join(struct.pack('<h', round(v * 32767)) for v in buf)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(pcm)
    return {'seconds': seconds, 'sample_rate': RATE, 'peak_dbfs': round(20 * math.log10(max(map(abs, buf))), 2)}

specs = {
    'buy': (0.18, [(0, .15, 480, 880, 1, 4, .12), (.065, .105, 620, 360, .35, 6, .05)]),
    'profit': (0.34, [(0, .16, 1046.5, None, .85, 6, .12), (.07, .18, 1318.5, None, .8, 6, .1), (.145, .18, 1568, None, .7, 6, .08)]),
    'loss': (0.25, [(0, .13, 440, 370, .75, 3, .08), (.10, .14, 330, 240, 1, 4, .08)]),
    'boop': (0.21, [(0, .11, 280, 240, 1, 5, .04), (.09, .10, 250, 205, .7, 5, .04)]),
    'click': (0.075, [(0, .065, 720, 580, 1, 7, .08)]),
    'win': (0.78, [(0, .17, 523.25, None, .8, 5, .1), (.11, .17, 659.25, None, .8, 5, .1), (.22, .17, 783.99, None, .8, 5, .1), (.34, .40, 1046.5, None, .75, 4, .1), (.36, .36, 659.25, None, .22, 5, .07), (.36, .36, 783.99, None, .22, 5, .07)]),
}
report = {name: render(name, *spec) for name, spec in specs.items()}
(ROOT / 'SYNTHESIS.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
