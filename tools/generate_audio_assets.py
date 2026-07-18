#!/usr/bin/env python3
"""Generate Echo Kickoff's original imported WAV sound set deterministically.

The generator uses only Python's standard library, fixed mathematical waveforms,
and a fixed integer-noise sequence. It reads no external audio, font, image,
network resource, or random system state.

Outputs are mono 16-bit PCM WAV at 24 kHz. The ambience loop is six seconds;
all Effects cues are deliberately short for the Web release.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import math
import struct
import wave
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Sequence, Tuple


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = Path("assets/audio")
MANIFEST_PATH = Path("assets/audio/generated-audio.json")
SAMPLE_RATE = 24_000
GENERATOR_VERSION = 2
TAU = math.tau

Samples = List[float]
Builder = Callable[[], Samples]


def sine(frequency: float, time: float, phase: float = 0.0) -> float:
    return math.sin(TAU * frequency * time + phase)


def smoothstep(value: float) -> float:
    value = min(max(value, 0.0), 1.0)
    return value * value * (3.0 - 2.0 * value)


def envelope(time: float, duration: float, attack: float, release: float) -> float:
    attack_gain = smoothstep(time / max(attack, 1e-6))
    release_gain = smoothstep((duration - time) / max(release, 1e-6))
    return min(attack_gain, release_gain)


def decay(time: float, rate: float) -> float:
    return math.exp(-rate * max(time, 0.0))


def deterministic_noise(index: int, salt: int = 0) -> float:
    value = (index + 1) * 1_103_515_245 + 12_345 + salt * 2_654_435_761
    value = (value ^ (value >> 13)) * 1_274_126_177
    value = (value ^ (value >> 16)) & 0xFFFFFFFF
    return value / 2_147_483_647.5 - 1.0


def low_pass_noise(count: int, coefficient: float, salt: int) -> Samples:
    result: Samples = []
    state = 0.0
    for index in range(count):
        state += coefficient * (deterministic_noise(index, salt) - state)
        result.append(state)
    return result


def normalize(samples: Samples, peak_dbfs: float) -> Samples:
    maximum = max((abs(sample) for sample in samples), default=1.0)
    target = 10.0 ** (peak_dbfs / 20.0)
    scale = target / maximum if maximum > 0.0 else 0.0
    return [min(max(sample * scale, -1.0), 1.0) for sample in samples]


def build_echo_pulse() -> Samples:
    duration = 0.86
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.42, 11)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        click = noise[index] * decay(time, 78.0) * 0.85
        sweep_phase = TAU * (980.0 * time - 410.0 * time * time)
        tone = math.sin(sweep_phase) * decay(time, 4.4) * 0.58
        echo = 0.0
        if time >= 0.18:
            echo += sine(510.0, time - 0.18) * decay(time - 0.18, 7.5) * 0.28
        if time >= 0.37:
            echo += sine(360.0, time - 0.37) * decay(time - 0.37, 8.5) * 0.17
        samples.append((click + tone + echo) * envelope(time, duration, 0.002, 0.08))
    return normalize(samples, -7.0)


def build_footstep() -> Samples:
    duration = 0.14
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.17, 23)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        thud = sine(118.0 - 34.0 * time, time) * decay(time, 32.0)
        grit = noise[index] * decay(time, 42.0) * 0.55
        samples.append((thud + grit) * envelope(time, duration, 0.003, 0.035))
    return normalize(samples, -18.0)


def build_listener_movement() -> Samples:
    duration = 0.25
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.28, 37)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        scrape = noise[index] * (0.45 + 0.55 * sine(21.0, time))
        joint = sine(176.0, time) * decay(time, 8.0) * 0.45
        samples.append((scrape * 0.72 + joint) * envelope(time, duration, 0.012, 0.065))
    return normalize(samples, -14.0)


def build_listener_alert() -> Samples:
    duration = 0.72
    count = round(duration * SAMPLE_RATE)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        frequency = 330.0 + 760.0 * smoothstep(time / duration)
        phase = TAU * (330.0 * time + 0.5 * (760.0 / duration) * time * time)
        carrier = math.sin(phase) + 0.42 * sine(frequency * 1.5, time)
        warning_gate = 0.62 + 0.38 * max(sine(7.0, time), -0.35)
        samples.append(carrier * warning_gate * envelope(time, duration, 0.018, 0.16))
    return normalize(samples, -7.0)


def build_decoy_impact() -> Samples:
    duration = 0.38
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.68, 41)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        hit = noise[index] * decay(time, 48.0) * 0.8
        metal = sine(1_480.0, time) * decay(time, 13.0) * 0.55
        body = sine(286.0, time) * decay(time, 18.0) * 0.48
        second = sine(1_130.0, time - 0.09) * decay(time - 0.09, 21.0) * 0.22 if time >= 0.09 else 0.0
        samples.append((hit + metal + body + second) * envelope(time, duration, 0.002, 0.07))
    return normalize(samples, -8.0)


def build_relay_activation() -> Samples:
    duration = 1.42
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.51, 53)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        progress = time / duration
        rise_phase = TAU * (86.0 * time + 72.0 * time * time)
        motor = math.sin(rise_phase) * (0.35 + 0.65 * progress)
        harmonic = sine(220.0, time) * smoothstep(progress) * 0.48
        electric = noise[index] * (0.16 + 0.22 * max(sine(34.0, time), 0.0))
        lock = sine(520.0, time - 1.04) * decay(time - 1.04, 8.0) * 0.6 if time >= 1.04 else 0.0
        samples.append((motor + harmonic + electric + lock) * envelope(time, duration, 0.025, 0.22))
    return normalize(samples, -6.0)


def build_door_open() -> Samples:
    duration = 0.68
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.12, 67)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        slide = noise[index] * (0.7 + 0.3 * sine(9.0, time))
        motor = sine(92.0, time) * 0.55 + sine(184.0, time) * 0.2
        latch = sine(740.0, time) * decay(time, 35.0) * 0.34
        samples.append((slide * 0.65 + motor + latch) * envelope(time, duration, 0.008, 0.12))
    return normalize(samples, -10.0)


def build_power_surge() -> Samples:
    duration = 0.92
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.46, 71)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        progress = time / duration
        phase = TAU * (72.0 * time + 460.0 * time * time)
        charge = math.sin(phase) * (0.25 + 0.75 * smoothstep(progress))
        grid = sine(240.0, time) * decay(time, 1.9) * 0.35
        spark = noise[index] * decay(time, 3.8) * 0.22
        samples.append((charge + grid + spark) * envelope(time, duration, 0.012, 0.17))
    return normalize(samples, -8.0)


def build_gate_unlock() -> Samples:
    duration = 1.08
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.10, 73)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        latch = sine(920.0, time) * decay(time, 23.0) * 0.42
        motor = sine(64.0, time) * 0.48 + sine(128.0, time) * 0.18
        slide = noise[index] * (0.42 + 0.28 * smoothstep(time / duration))
        confirm = sine(660.0, time - 0.72) * decay(time - 0.72, 9.0) * 0.4 if time >= 0.72 else 0.0
        samples.append((latch + motor + slide + confirm) * envelope(time, duration, 0.006, 0.16))
    return normalize(samples, -9.0)


def build_warden_alert() -> Samples:
    duration = 0.84
    count = round(duration * SAMPLE_RATE)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        pulse = 0.55 + 0.45 * max(sine(6.0, time), -0.25)
        violet = sine(196.0, time) + 0.44 * sine(294.0, time)
        rise_phase = TAU * (410.0 * time + 120.0 * time * time)
        samples.append((violet * pulse + 0.3 * math.sin(rise_phase)) * envelope(time, duration, 0.014, 0.19))
    return normalize(samples, -8.0)


def build_level_complete() -> Samples:
    duration = 2.18
    count = round(duration * SAMPLE_RATE)
    notes = (174.61, 220.0, 261.63, 349.23, 440.0)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        total = 0.0
        for note_index, frequency in enumerate(notes):
            start = note_index * 0.2
            if time >= start:
                local = time - start
                total += sine(frequency, local) * decay(local, 0.72 + note_index * 0.08) * 0.26
        shimmer = sine(880.0, time) * smoothstep(time / duration) * 0.08
        samples.append((total + shimmer) * envelope(time, duration, 0.025, 0.38))
    return normalize(samples, -8.0)


def build_player_caught() -> Samples:
    duration = 0.50
    count = round(duration * SAMPLE_RATE)
    noise = low_pass_noise(count, 0.55, 79)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        impact = (sine(74.0, time) + noise[index] * 0.52) * decay(time, 14.0)
        cut = sine(620.0 - 430.0 * time, time) * decay(time, 5.0) * 0.44
        samples.append((impact + cut) * envelope(time, duration, 0.003, 0.14))
    return normalize(samples, -7.0)


def build_victory_extraction() -> Samples:
    duration = 1.82
    count = round(duration * SAMPLE_RATE)
    notes = (220.0, 277.18, 329.63, 440.0)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        progress = time / duration
        total = 0.0
        for note_index, frequency in enumerate(notes):
            note_start = note_index * 0.18
            if time >= note_start:
                note_time = time - note_start
                total += sine(frequency, note_time) * decay(note_time, 1.0 + note_index * 0.12) * 0.34
        beacon = sine(55.0, time) * smoothstep(progress) * 0.12
        samples.append((total + beacon) * envelope(time, duration, 0.035, 0.34))
    return normalize(samples, -8.0)


def build_industrial_ambience() -> Samples:
    duration = 6.0
    count = round(duration * SAMPLE_RATE)
    samples: Samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        # Every oscillator completes an integer number of cycles over six seconds,
        # keeping the imported loop seam deterministic and effectively silent.
        modulation = 0.76 + 0.14 * sine(0.5, time) + 0.10 * sine(1.0 / 3.0, time)
        hum = sine(48.0, time) * 0.55 + sine(72.0, time) * 0.24 + sine(120.0, time) * 0.12
        air = sine(312.0, time) * sine(2.0, time) * 0.035
        tick = 0.0
        for tick_time in (1.25, 3.75, 4.80):
            if tick_time <= time < tick_time + 0.09:
                local = time - tick_time
                tick += sine(960.0, local) * decay(local, 48.0) * 0.12
        samples.append((hum * modulation + air + tick) * 0.72)
    return normalize(samples, -20.0)


ASSETS: Dict[str, Tuple[str, str, float, Builder]] = {
    "echo_pulse.wav": ("Effects", "broad click + descending tonal echo", -7.0, build_echo_pulse),
    "footstep.wav": ("Effects", "quiet low thud + grit", -18.0, build_footstep),
    "listener_movement.wav": ("Effects", "dry scrape + low joint tone", -14.0, build_listener_movement),
    "listener_alert.wav": ("Effects", "rising gated warning interval", -7.0, build_listener_alert),
    "decoy_impact.wav": ("Effects", "bright metallic impact + short body", -8.0, build_decoy_impact),
    "relay_activation.wav": ("Effects", "long electrical motor rise + lock", -6.0, build_relay_activation),
    "door_open.wav": ("Effects", "mechanical slide + latch", -10.0, build_door_open),
    "power_surge.wav": ("Effects", "ascending electrical charge + grid settle", -8.0, build_power_surge),
    "gate_unlock.wav": ("Effects", "dual-panel motor + latch confirmation", -9.0, build_gate_unlock),
    "warden_alert.wav": ("Effects", "gated violet warning dyad + rising intercept", -8.0, build_warden_alert),
    "level_complete.wav": ("Effects", "five-note campaign resolution + shimmer", -8.0, build_level_complete),
    "player_caught.wav": ("Effects", "restrained low interception impact", -7.0, build_player_caught),
    "victory_extraction.wav": ("Effects", "ascending stable harmonic beacon", -8.0, build_victory_extraction),
    "industrial_ambience.wav": ("Ambience", "quiet seamless low industrial hum", -20.0, build_industrial_ambience),
}


def encode_wav(samples: Sequence[float]) -> bytes:
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for sample in samples:
            frames.extend(struct.pack("<h", round(min(max(sample, -1.0), 1.0) * 32767.0)))
        target.writeframes(bytes(frames))
    return buffer.getvalue()


def level_dbfs(samples: Sequence[float], peak: bool) -> float:
    if not samples:
        return -120.0
    value = max(abs(sample) for sample in samples) if peak else math.sqrt(sum(sample * sample for sample in samples) / len(samples))
    return round(20.0 * math.log10(max(value, 1e-6)), 2)


def build_payloads() -> Tuple[Dict[Path, bytes], dict]:
    payloads: Dict[Path, bytes] = {}
    records = []
    for filename, (bus, signature, target_peak, builder) in ASSETS.items():
        samples = builder()
        payload = encode_wav(samples)
        relative_path = OUTPUT_DIR / filename
        payloads[relative_path] = payload
        records.append({
            "path": str(relative_path),
            "bus": bus,
            "channels": 1,
            "sample_rate_hz": SAMPLE_RATE,
            "sample_width_bits": 16,
            "frames": len(samples),
            "duration_seconds": round(len(samples) / SAMPLE_RATE, 3),
            "peak_dbfs": level_dbfs(samples, True),
            "rms_dbfs": level_dbfs(samples, False),
            "target_peak_dbfs": target_peak,
            "frequency_signature": signature,
            "loop": filename == "industrial_ambience.wav",
            "sha256": hashlib.sha256(payload).hexdigest(),
        })
    manifest = {
        "generator": "tools/generate_audio_assets.py",
        "generator_version": GENERATOR_VERSION,
        "authorship": "Original Echo Kickoff jam work; fixed mathematical synthesis only; no external source audio.",
        "license_basis": "Original project asset; no third-party license or attribution dependency.",
        "format": "mono PCM16 WAV",
        "sample_rate_hz": SAMPLE_RATE,
        "assets": records,
    }
    return payloads, manifest


def manifest_bytes(manifest: dict) -> bytes:
    return (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8")


def write_assets(payloads: Dict[Path, bytes], manifest: dict) -> None:
    for relative_path, payload in payloads.items():
        destination = ROOT / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(payload)
    destination = ROOT / MANIFEST_PATH
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(manifest_bytes(manifest))


def check_assets(payloads: Dict[Path, bytes], manifest: dict) -> bool:
    expected = dict(payloads)
    expected[MANIFEST_PATH] = manifest_bytes(manifest)
    mismatches = []
    for relative_path, payload in expected.items():
        destination = ROOT / relative_path
        if not destination.is_file() or destination.read_bytes() != payload:
            mismatches.append(str(relative_path))
    if mismatches:
        print("AUDIO_ASSET_CHECK_FAILED")
        for mismatch in mismatches:
            print(mismatch)
        return False
    print("AUDIO_ASSET_CHECK_OK")
    for record in manifest["assets"]:
        print(
            f"{record['path']} {record['duration_seconds']:.3f}s "
            f"peak={record['peak_dbfs']:.2f}dBFS rms={record['rms_dbfs']:.2f}dBFS"
        )
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify exact committed WAV bytes and manifest.")
    args = parser.parse_args()
    payloads, manifest = build_payloads()
    if args.check:
        return 0 if check_assets(payloads, manifest) else 1
    write_assets(payloads, manifest)
    return 0 if check_assets(payloads, manifest) else 1


if __name__ == "__main__":
    raise SystemExit(main())
