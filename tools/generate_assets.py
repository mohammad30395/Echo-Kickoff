#!/usr/bin/env python3
"""Generate Echo Kickoff's exact-size raster assets deterministically.

Outputs:
  assets/branding/game-icon.png        512 x 512 RGBA, transparent surround
  marketing/itch-cover-draft.png       630 x 500 RGBA, intentionally opaque
  assets/generated-assets.json         dimensions, alpha policy, and SHA-256

The artwork uses only Pillow drawing primitives and original geometric forms.
No external image, font, logo, symbol, network resource, or random input is used.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Optional, Sequence, Tuple

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SUPERSAMPLE = 4
GENERATOR_VERSION = 1

RGBA = Tuple[int, int, int, int]
Point = Tuple[float, float]

INK: RGBA = (217, 250, 255, 255)
ECHO: RGBA = (91, 231, 242, 255)
WARNING: RGBA = (255, 107, 53, 255)
DECOY: RGBA = (247, 200, 75, 255)
VOID: RGBA = (2, 6, 12, 255)
PANEL: RGBA = (5, 17, 28, 250)


def _scaled_point(point: Point) -> Tuple[int, int]:
    return (round(point[0] * SUPERSAMPLE), round(point[1] * SUPERSAMPLE))


def _scaled_points(points: Iterable[Point]) -> List[Tuple[int, int]]:
    return [_scaled_point(point) for point in points]


def _rgba(color: RGBA, alpha: Optional[int] = None) -> RGBA:
    return color if alpha is None else (color[0], color[1], color[2], alpha)


def _line(
    draw: ImageDraw.ImageDraw,
    points: Sequence[Point],
    color: RGBA,
    width: float,
    joint: str = "curve",
) -> None:
    draw.line(
        _scaled_points(points),
        fill=color,
        width=max(1, round(width * SUPERSAMPLE)),
        joint=joint,
    )


def _polygon(
    draw: ImageDraw.ImageDraw,
    points: Sequence[Point],
    fill: RGBA,
) -> None:
    draw.polygon(_scaled_points(points), fill=fill)


def _regular_polygon(center: Point, radius: float, sides: int, rotation: float = -0.5) -> List[Point]:
    import math

    return [
        (
            center[0] + math.cos(rotation * math.pi + index * 2.0 * math.pi / sides) * radius,
            center[1] + math.sin(rotation * math.pi + index * 2.0 * math.pi / sides) * radius,
        )
        for index in range(sides)
    ]


def _arc(
    draw: ImageDraw.ImageDraw,
    box: Tuple[float, float, float, float],
    start: float,
    end: float,
    color: RGBA,
    width: float,
) -> None:
    draw.arc(
        tuple(round(value * SUPERSAMPLE) for value in box),
        start=start,
        end=end,
        fill=color,
        width=max(1, round(width * SUPERSAMPLE)),
    )


def _new_canvas(size: Tuple[int, int], color: RGBA) -> Image.Image:
    return Image.new("RGBA", (size[0] * SUPERSAMPLE, size[1] * SUPERSAMPLE), color)


def _downsample(image: Image.Image, size: Tuple[int, int]) -> Image.Image:
    return image.resize(size, Image.Resampling.LANCZOS)


def _draw_echo_mark(
    draw: ImageDraw.ImageDraw,
    center: Point,
    radius: float,
    line_width: float,
) -> None:
    cx, cy = center
    for scale, alpha in ((1.0, 110), (0.7, 205), (0.4, 255)):
        current = radius * scale
        box = (cx - current, cy - current, cx + current, cy + current)
        _arc(draw, box, 42, 160, _rgba(ECHO if scale > 0.4 else INK, alpha), line_width)
        _arc(draw, box, 200, 318, _rgba(ECHO if scale > 0.4 else INK, alpha), line_width)
    diamond_radius = radius * 0.18
    _polygon(
        draw,
        [
            (cx, cy - diamond_radius),
            (cx + diamond_radius, cy),
            (cx, cy + diamond_radius),
            (cx - diamond_radius, cy),
        ],
        INK,
    )
    _line(
        draw,
        [(cx + radius * 0.62, cy - radius * 0.28), (cx + radius * 1.02, cy - radius * 0.42), (cx + radius * 0.88, cy - radius * 0.08)],
        WARNING,
        line_width,
    )
    _line(
        draw,
        [(cx + radius * 0.62, cy + radius * 0.28), (cx + radius * 1.02, cy + radius * 0.42), (cx + radius * 0.88, cy + radius * 0.08)],
        WARNING,
        line_width,
    )


GLYPHS: Dict[str, Sequence[Sequence[Point]]] = {
    "E": (((1, 0), (0, 0), (0, 1), (1, 1)), ((0, 0.5), (0.78, 0.5))),
    "C": (((1, 0), (0, 0), (0, 1), (1, 1)),),
    "H": (((0, 0), (0, 1)), ((1, 0), (1, 1)), ((0, 0.5), (1, 0.5))),
    "O": (((0, 0), (1, 0), (1, 1), (0, 1), (0, 0)),),
    "K": (((0, 0), (0, 1)), ((1, 0), (0, 0.5), (1, 1))),
    "I": (((0, 0), (1, 0)), ((0.5, 0), (0.5, 1)), ((0, 1), (1, 1))),
    "F": (((0, 1), (0, 0), (1, 0)), ((0, 0.5), (0.8, 0.5))),
}


def _draw_wordmark(
    draw: ImageDraw.ImageDraw,
    text: str,
    origin: Point,
    height: float,
    color: RGBA,
) -> float:
    glyph_width = height * 0.5
    advance = glyph_width + height * 0.22
    x = origin[0]
    for character in text:
        if character == " ":
            x += advance * 0.7
            continue
        for segment in GLYPHS[character]:
            _line(
                draw,
                [(x + px * glyph_width, origin[1] + py * height) for px, py in segment],
                color,
                height * 0.095,
                "curve",
            )
        x += advance
    return x


def build_game_icon() -> Image.Image:
    size = (512, 512)
    image = _new_canvas(size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    center = (256.0, 256.0)
    hexagon = _regular_polygon(center, 222.0, 6)
    _polygon(draw, hexagon, PANEL)
    _line(draw, hexagon + [hexagon[0]], _rgba(ECHO, 150), 8.0)
    inner_hexagon = _regular_polygon(center, 188.0, 6)
    _line(draw, inner_hexagon + [inner_hexagon[0]], _rgba(ECHO, 34), 4.0)
    _draw_echo_mark(draw, center, 142.0, 12.0)
    for offset in (-66.0, 0.0, 66.0):
        _line(draw, [(188.0 + offset, 420.0), (228.0 + offset, 420.0)], _rgba(ECHO, 72), 5.0)
    return _downsample(image, size)


def build_itch_cover() -> Image.Image:
    size = (630, 500)
    image = _new_canvas(size, VOID)
    draw = ImageDraw.Draw(image, "RGBA")

    # Deterministic near-black vertical falloff, not a photograph or generated texture.
    for y in range(size[1] * SUPERSAMPLE):
        normalized = y / max(1, size[1] * SUPERSAMPLE - 1)
        color = (2 + round(3 * normalized), 6 + round(7 * normalized), 12 + round(11 * normalized), 255)
        draw.line([(0, y), (size[0] * SUPERSAMPLE, y)], fill=color, width=1)

    for x in range(0, size[0] + 1, 70):
        _line(draw, [(x, 0), (x, size[1])], _rgba(ECHO, 18), 1.0)
    for y in range(0, size[1] + 1, 70):
        _line(draw, [(0, y), (size[0], y)], _rgba(ECHO, 18), 1.0)

    for radius, alpha in ((228.0, 22), (172.0, 30), (116.0, 42)):
        _arc(draw, (505 - radius, 250 - radius, 505 + radius, 250 + radius), 35, 150, _rgba(ECHO, alpha), 3.0)
        _arc(draw, (505 - radius, 250 - radius, 505 + radius, 250 + radius), 205, 320, _rgba(ECHO, alpha), 3.0)

    _draw_echo_mark(draw, (106.0, 104.0), 55.0, 5.0)
    _draw_wordmark(draw, "ECHO", (55.0, 188.0), 62.0, INK)
    _draw_wordmark(draw, "KICKOFF", (55.0, 282.0), 62.0, ECHO)
    _line(draw, [(56.0, 375.0), (342.0, 375.0)], _rgba(ECHO, 130), 4.0)
    _line(draw, [(360.0, 375.0), (430.0, 375.0)], WARNING, 4.0)

    # Small original relay/decoy glyphs reinforce the game's geometric language.
    relay_center = (500.0, 360.0)
    relay = _regular_polygon(relay_center, 48.0, 6)
    _line(draw, relay + [relay[0]], _rgba(ECHO, 210), 4.0)
    for offset in (-14.0, 0.0, 14.0):
        _line(draw, [(470.0, relay_center[1] + offset), (530.0, relay_center[1] + offset)], _rgba(INK, 220), 4.0)
    diamond = [(500.0, 346.0), (514.0, 360.0), (500.0, 374.0), (486.0, 360.0)]
    _polygon(draw, diamond, WARNING)

    cover = _downsample(image, size)
    cover.putalpha(255)
    return cover


ASSETS: Dict[Path, Tuple[Tuple[int, int], bool, Callable[[], Image.Image]]] = {
    Path("assets/branding/game-icon.png"): ((512, 512), True, build_game_icon),
    Path("marketing/itch-cover-draft.png"): ((630, 500), False, build_itch_cover),
}
MANIFEST_PATH = Path("assets/generated-assets.json")


def _encode_png(image: Image.Image) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", compress_level=9, optimize=False)
    return buffer.getvalue()


def _generate_payloads() -> Tuple[Dict[Path, bytes], dict]:
    payloads: Dict[Path, bytes] = {}
    records = []
    for relative_path, (dimensions, transparent_background, builder) in sorted(ASSETS.items()):
        image = builder()
        if image.size != dimensions or image.mode != "RGBA":
            raise RuntimeError(f"{relative_path}: expected RGBA {dimensions}, got {image.mode} {image.size}")
        alpha = image.getchannel("A")
        alpha_min, alpha_max = alpha.getextrema()
        if transparent_background and alpha_min != 0:
            raise RuntimeError(f"{relative_path}: transparent background is required")
        if not transparent_background and (alpha_min, alpha_max) != (255, 255):
            raise RuntimeError(f"{relative_path}: cover must be fully opaque")
        data = _encode_png(image)
        payloads[relative_path] = data
        records.append(
            {
                "path": relative_path.as_posix(),
                "width": dimensions[0],
                "height": dimensions[1],
                "mode": image.mode,
                "transparent_background": transparent_background,
                "sha256": hashlib.sha256(data).hexdigest(),
            }
        )
    manifest = {
        "generator": "tools/generate_assets.py",
        "generator_version": GENERATOR_VERSION,
        "supersample": SUPERSAMPLE,
        "assets": records,
    }
    return payloads, manifest


def _manifest_bytes(manifest: dict) -> bytes:
    return (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8")


def write_assets() -> None:
    payloads, manifest = _generate_payloads()
    for relative_path, data in payloads.items():
        destination = ROOT / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        print(f"GENERATED {relative_path.as_posix()} {ASSETS[relative_path][0][0]}x{ASSETS[relative_path][0][1]}")
    destination = ROOT / MANIFEST_PATH
    destination.write_bytes(_manifest_bytes(manifest))
    print(f"RECORDED {MANIFEST_PATH.as_posix()}")


def check_assets() -> None:
    payloads, manifest = _generate_payloads()
    failures: List[str] = []
    for relative_path, expected in payloads.items():
        destination = ROOT / relative_path
        if not destination.is_file():
            failures.append(f"missing {relative_path.as_posix()}")
        elif destination.read_bytes() != expected:
            failures.append(f"non-deterministic or stale {relative_path.as_posix()}")
    manifest_path = ROOT / MANIFEST_PATH
    expected_manifest = _manifest_bytes(manifest)
    if not manifest_path.is_file():
        failures.append(f"missing {MANIFEST_PATH.as_posix()}")
    elif manifest_path.read_bytes() != expected_manifest:
        failures.append(f"stale {MANIFEST_PATH.as_posix()}")
    if failures:
        raise SystemExit("ASSET_CHECK_FAIL\n" + "\n".join(failures))
    print("ASSET_CHECK_OK")
    for relative_path, (dimensions, transparent_background, _builder) in sorted(ASSETS.items()):
        alpha_label = "transparent" if transparent_background else "opaque"
        print(f"{relative_path.as_posix()} {dimensions[0]}x{dimensions[1]} RGBA {alpha_label}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify committed outputs without writing")
    arguments = parser.parse_args()
    if arguments.check:
        check_assets()
    else:
        write_assets()


if __name__ == "__main__":
    main()
