#!/usr/bin/env python3
"""
Génère les JSON Lottie pour SAYIBI AI (Bodymovin / Lottie 5.7.x).
Exécuter depuis la racine du package Flutter :
  python tool/generate_lottie_assets.py
"""

from __future__ import annotations

import json
import math
import os
from typing import Any, List, Tuple

# Couleurs SAYIBI (RGBA 0–1)
PURPLE = [0.424, 0.388, 1.0, 1.0]
PURPLE_DARK = [0.29, 0.26, 0.78, 1.0]
TEAL = [0.0, 0.831, 0.667, 1.0]
WHITE = [1.0, 1.0, 1.0, 1.0]
MUTED = [0.72, 0.74, 0.78, 1.0]
RED = [0.937, 0.267, 0.267, 1.0]
GREEN = [0.063, 0.725, 0.506, 1.0]
BLUE = [0.231, 0.51, 0.965, 1.0]
ORANGE = [0.96, 0.62, 0.04, 1.0]
PINK = [0.925, 0.282, 0.6, 1.0]
GRAY = [0.45, 0.48, 0.55, 1.0]


def _kf_opacity_loop(period: int, low: float = 35.0, high: float = 100.0) -> dict:
    half = max(1, period // 2)
    return {
        "a": 1,
        "k": [
            {"t": 0, "s": [low], "h": 1},
            {"t": half, "s": [high], "h": 1},
            {"t": period, "s": [low], "h": 1},
        ],
    }


def _kf_scale_pulse(period: int, lo: float = 92.0, hi: float = 108.0) -> dict:
    half = max(1, period // 2)
    return {
        "a": 1,
        "k": [
            {"t": 0, "s": [lo, lo, 100], "h": 1},
            {"t": half, "s": [hi, hi, 100], "h": 1},
            {"t": period, "s": [lo, lo, 100], "h": 1},
        ],
    }


def _kf_bar_height(frames: int, base_h: float, amp: float, phase: int) -> dict:
    """Rectangle height oscillation (value in size y)."""
    pts: List[dict] = []
    step = max(1, frames // 4)
    for i in range(0, frames + 1, step):
        ang = (i + phase) / float(max(1, frames)) * 2 * math.pi
        h = base_h + amp * (0.5 + 0.5 * math.sin(ang))
        pts.append({"t": i, "s": [24, h], "h": 1})
    return {"a": 1, "k": pts}


def _tr_static() -> dict:
    return {
        "ty": "tr",
        "p": {"a": 0, "k": [0, 0]},
        "a": {"a": 0, "k": [0, 0]},
        "s": {"a": 0, "k": [100, 100]},
        "r": {"a": 0, "k": 0},
        "o": {"a": 0, "k": 100},
        "sk": {"a": 0, "k": 0},
        "sa": {"a": 0, "k": 0},
        "nm": "Transform",
    }


def ellipse_fill(cx: float, cy: float, w: float, h: float, color: List[float], nm: str = "e") -> dict:
    return {
        "ty": "gr",
        "it": [
            {
                "ty": "el",
                "d": 1,
                "p": {"a": 0, "k": [cx, cy]},
                "s": {"a": 0, "k": [w, h]},
                "nm": f"{nm} Path",
                "mn": "ADBE Vector Shape - Ellipse",
                "hd": False,
            },
            {
                "ty": "fl",
                "c": {"a": 0, "k": color},
                "o": {"a": 0, "k": 100},
                "r": 1,
                "nm": "Fill",
                "mn": "ADBE Vector Graphic - Fill",
                "hd": False,
            },
            _tr_static(),
        ],
        "nm": nm,
        "np": 3,
        "cix": 2,
        "bm": 0,
        "ix": 1,
        "mn": "ADBE Vector Group",
        "hd": False,
    }


def rect_fill(
    x: float,
    y: float,
    w: float,
    h: float,
    color: List[float],
    corner: float = 0.0,
    nm: str = "r",
) -> dict:
    return {
        "ty": "gr",
        "it": [
            {
                "ty": "rc",
                "d": 1,
                "p": {"a": 0, "k": [x, y]},
                "s": {"a": 0, "k": [w, h]},
                "r": {"a": 0, "k": corner},
                "nm": f"{nm} Path",
                "mn": "ADBE Vector Shape - Rect",
                "hd": False,
            },
            {
                "ty": "fl",
                "c": {"a": 0, "k": color},
                "o": {"a": 0, "k": 100},
                "r": 1,
                "nm": "Fill",
                "mn": "ADBE Vector Graphic - Fill",
                "hd": False,
            },
            _tr_static(),
        ],
        "nm": nm,
        "np": 3,
        "cix": 2,
        "bm": 0,
        "ix": 1,
        "mn": "ADBE Vector Group",
        "hd": False,
    }


def rect_fill_animated_size(
    x: float,
    y: float,
    w: float,
    h_kf: dict,
    color: List[float],
    corner: float = 0.0,
    nm: str = "r",
) -> dict:
    return {
        "ty": "gr",
        "it": [
            {
                "ty": "rc",
                "d": 1,
                "p": {"a": 0, "k": [x, y]},
                "s": h_kf,
                "r": {"a": 0, "k": corner},
                "nm": f"{nm} Path",
                "mn": "ADBE Vector Shape - Rect",
                "hd": False,
            },
            {
                "ty": "fl",
                "c": {"a": 0, "k": color},
                "o": {"a": 0, "k": 100},
                "r": 1,
                "nm": "Fill",
                "mn": "ADBE Vector Graphic - Fill",
                "hd": False,
            },
            _tr_static(),
        ],
        "nm": nm,
        "np": 3,
        "cix": 2,
        "bm": 0,
        "ix": 1,
        "mn": "ADBE Vector Group",
        "hd": False,
    }


def shape_layer(
    ind: int,
    name: str,
    op: int,
    position: Tuple[float, float, float],
    shapes: List[dict],
    opacity_kf: dict | None = None,
    scale_kf: dict | None = None,
    st: float = 0.0,
) -> dict:
    ks: dict[str, Any] = {
        "o": opacity_kf if opacity_kf else {"a": 0, "k": 100},
        "r": {"a": 0, "k": 0},
        "p": {"a": 0, "k": list(position)},
        "a": {"a": 0, "k": [0, 0, 0]},
        "s": scale_kf if scale_kf else {"a": 0, "k": [100, 100, 100]},
    }
    return {
        "ddd": 0,
        "ind": ind,
        "ty": 4,
        "nm": name,
        "sr": 1,
        "st": st,
        "op": op,
        "ip": 0,
        "bm": 0,
        "hasMask": False,
        "ao": 0,
        "ks": ks,
        "shapes": shapes,
        "ct": 1,
    }


def composition(
    name: str,
    w: int,
    h: int,
    fr: int,
    op: int,
    layers: List[dict],
) -> dict:
    return {
        "v": "5.7.4",
        "fr": fr,
        "ip": 0,
        "op": op,
        "w": w,
        "h": h,
        "nm": name,
        "ddd": 0,
        "assets": [],
        "layers": layers,
        "markers": [],
    }


# ——— Animations spécifiques ———


def build_splash() -> dict:
    op = 90
    layers = [
        shape_layer(
            1,
            "Pulse",
            op,
            (256, 256, 0),
            [ellipse_fill(0, 0, 220, 220, PURPLE, "ring")],
            scale_kf=_kf_scale_pulse(90, 88, 112),
        ),
        shape_layer(
            2,
            "Core",
            op,
            (256, 256, 0),
            [ellipse_fill(0, 0, 120, 120, TEAL, "core")],
            opacity_kf=_kf_opacity_loop(45, 70, 100),
        ),
    ]
    return composition("SayibiSplash", 512, 512, 30, op, list(reversed(layers)))


def build_ai_thinking() -> dict:
    op = 120
    layers = [
        shape_layer(
            1,
            "Aura",
            op,
            (256, 256, 0),
            [ellipse_fill(0, 0, 280, 280, PURPLE_DARK, "aura")],
            opacity_kf=_kf_opacity_loop(60, 25, 55),
            scale_kf=_kf_scale_pulse(120, 95, 105),
        ),
        shape_layer(
            2,
            "Brain",
            op,
            (256, 256, 0),
            [ellipse_fill(0, 0, 140, 160, PURPLE, "brain")],
        ),
        shape_layer(
            3,
            "Spark",
            op,
            (256, 180, 0),
            [ellipse_fill(0, 0, 40, 40, TEAL, "spark")],
            opacity_kf=_kf_opacity_loop(40, 30, 100),
        ),
    ]
    return composition("AiThinking", 512, 512, 30, op, list(reversed(layers)))


def build_loading_typing(fr: int, op: int, name: str, dot_color: List[float], spacing: float = 52) -> dict:
    layers = []
    for i in range(3):
        x = 256 + (i - 1) * spacing
        layers.append(
            shape_layer(
                i + 1,
                f"Dot{i+1}",
                op,
                (x, 280, 0),
                [ellipse_fill(0, 0, 28, 28, dot_color, "dot")],
                opacity_kf=_kf_opacity_loop(op, 38, 100),
                st=float(i * (op // 6)),
            )
        )
    return composition(name, 512, 512, fr, op, list(reversed(layers)))


def build_loading() -> dict:
    return build_loading_typing(30, 90, "Loading", PURPLE)


def build_typing() -> dict:
    return build_loading_typing(30, 60, "Typing", TEAL)


def build_error() -> dict:
    op = 75
    layers = [
        shape_layer(
            1,
            "Circle",
            op,
            (256, 256, 0),
            [ellipse_fill(0, 0, 200, 200, [0.93, 0.27, 0.27, 0.25], "bg")],
        ),
        shape_layer(
            2,
            "CrossV",
            op,
            (256, 256, 0),
            [rect_fill(0, -80, 20, 160, RED, 6, "v")],
        ),
        shape_layer(
            3,
            "CrossH",
            op,
            (256, 256, 0),
            [rect_fill(-80, 0, 160, 20, RED, 6, "h")],
            opacity_kf=_kf_opacity_loop(75, 85, 100),
        ),
    ]
    return composition("Error", 512, 512, 30, op, list(reversed(layers)))


def build_success() -> dict:
    op = 72
    # Checkmark simplifié : deux rectangles en L
    layers = [
        shape_layer(
            1,
            "Circle",
            op,
            (256, 256, 0),
            [ellipse_fill(0, 0, 200, 200, [GREEN[0], GREEN[1], GREEN[2], 0.2], "bg")],
        ),
        shape_layer(
            2,
            "Leg1",
            op,
            (236, 270, 0),
            [rect_fill(0, 0, 14, 56, WHITE, 4, "l1")],
            scale_kf=_kf_scale_pulse(72, 90, 105),
        ),
        shape_layer(
            3,
            "Leg2",
            op,
            (268, 292, 0),
            [rect_fill(0, 0, 70, 14, WHITE, 4, "l2")],
        ),
    ]
    return composition("Success", 512, 512, 30, op, list(reversed(layers)))


def build_voice_wave() -> dict:
    op = 90
    fr = 30
    bars = []
    for i in range(5):
        x = 196 + i * 32
        phase = i * 8
        hkf = _kf_bar_height(op, 48.0, 36.0, phase)
        bars.append(
            shape_layer(
                i + 1,
                f"Bar{i}",
                op,
                (x, 280, 0),
                [
                    rect_fill_animated_size(-12, -48, 24, hkf, PURPLE, 6, f"b{i}"),
                ],
            )
        )
    return composition("VoiceWave", 512, 512, fr, op, list(reversed(bars)))


def build_file_generating() -> dict:
    op = 96
    layers = [
        shape_layer(
            1,
            "Paper",
            op,
            (256, 280, 0),
            [rect_fill(-90, -110, 180, 220, [0.14, 0.17, 0.28, 1.0], 12, "paper")],
        ),
        shape_layer(
            2,
            "Fold",
            op,
            (256, 170, 0),
            [rect_fill(-40, 0, 80, 24, TEAL, 4, "fold")],
            opacity_kf=_kf_opacity_loop(48, 60, 100),
        ),
        shape_layer(
            3,
            "Line1",
            op,
            (256, 230, 0),
            [rect_fill(-70, 0, 140, 10, MUTED, 3, "ln1")],
        ),
        shape_layer(
            4,
            "Line2",
            op,
            (256, 255, 0),
            [rect_fill(-70, 0, 100, 10, MUTED, 3, "ln2")],
        ),
        shape_layer(
            5,
            "Line3",
            op,
            (256, 280, 0),
            [rect_fill(-70, 0, 120, 10, MUTED, 3, "ln3")],
            opacity_kf=_kf_opacity_loop(64, 40, 90),
        ),
    ]
    return composition("FileGen", 512, 512, 30, op, list(reversed(layers)))


def build_empty_chat() -> dict:
    op = 120
    layers = [
        shape_layer(
            1,
            "Head",
            op,
            (256, 220, 0),
            [ellipse_fill(0, 0, 160, 160, PURPLE, "head")],
            scale_kf=_kf_scale_pulse(120, 96, 104),
        ),
        shape_layer(
            2,
            "EyeL",
            op,
            (220, 210, 0),
            [ellipse_fill(0, 0, 22, 28, WHITE, "eyeL")],
        ),
        shape_layer(
            3,
            "EyeR",
            op,
            (292, 210, 0),
            [ellipse_fill(0, 0, 22, 28, WHITE, "eyeR")],
        ),
        shape_layer(
            4,
            "Smile",
            op,
            (256, 255, 0),
            [rect_fill(-36, 0, 72, 12, TEAL, 6, "smile")],
        ),
    ]
    return composition("EmptyChat", 512, 512, 30, op, list(reversed(layers)))


def build_upload() -> dict:
    op = 90
    layers = [
        shape_layer(
            1,
            "Cloud",
            op,
            (256, 300, 0),
            [ellipse_fill(-50, 0, 200, 70, [0.25, 0.29, 0.45, 1.0], "cloud")],
        ),
        shape_layer(
            2,
            "Arrow",
            op,
            (256, 230, 0),
            [rect_fill(-14, -50, 28, 70, TEAL, 4, "shaft")],
            scale_kf=_kf_scale_pulse(90, 92, 108),
        ),
        shape_layer(
            3,
            "ArrowHead",
            op,
            (256, 175, 0),
            [rect_fill(-28, 0, 56, 24, TEAL, 4, "head")],
        ),
    ]
    return composition("Upload", 512, 512, 30, op, list(reversed(layers)))


def build_onboarding(idx: int, accent: List[float]) -> dict:
    op = 100
    layers = [
        shape_layer(
            1,
            "Panel",
            op,
            (256, 256, 0),
            [rect_fill(-140, -160, 280, 320, [0.08, 0.1, 0.18, 1.0], 24, "panel")],
        ),
        shape_layer(
            2,
            "Icon",
            op,
            (256, 240, 0),
            [ellipse_fill(0, 0, 120, 120, accent, "ico")],
            scale_kf=_kf_scale_pulse(100, 94, 106),
        ),
        shape_layer(
            3,
            "Dot",
            op,
            (256, 360, 0),
            [ellipse_fill(0, 0, 16, 16, TEAL if idx != 2 else PINK, "dot")],
            opacity_kf=_kf_opacity_loop(50, 40, 100),
        ),
    ]
    return composition(f"Onboarding{idx}", 512, 512, 30, op, list(reversed(layers)))


def build_search_web() -> dict:
    op = 90
    layers = [
        shape_layer(
            1,
            "Lens",
            op,
            (240, 240, 0),
            [ellipse_fill(0, 0, 100, 100, [0.2, 0.35, 0.95, 0.35], "lens")],
        ),
        shape_layer(
            2,
            "Ring",
            op,
            (240, 240, 0),
            [ellipse_fill(0, 0, 120, 120, [0.2, 0.35, 0.95, 0.9], "ring")],
            opacity_kf=_kf_opacity_loop(90, 70, 100),
        ),
        shape_layer(
            3,
            "Handle",
            op,
            (310, 310, 0),
            [rect_fill(0, 0, 24, 80, BLUE, 5, "handle")],
        ),
    ]
    return composition("SearchWeb", 512, 512, 30, op, list(reversed(layers)))


def build_no_internet() -> dict:
    op = 90
    layers = [
        shape_layer(
            1,
            "Arc1",
            op,
            (256, 260, 0),
            [rect_fill(-100, 0, 200, 14, GRAY, 7, "a1")],
        ),
        shape_layer(
            2,
            "Arc2",
            op,
            (256, 230, 0),
            [rect_fill(-80, 0, 160, 12, GRAY, 6, "a2")],
            opacity_kf=_kf_opacity_loop(45, 45, 85),
        ),
        shape_layer(
            3,
            "Slash",
            op,
            (256, 256, 0),
            [rect_fill(-90, -8, 180, 16, RED, 4, "slash")],
            opacity_kf=_kf_opacity_loop(90, 55, 100),
        ),
    ]
    return composition("NoInternet", 512, 512, 30, op, list(reversed(layers)))


def build_empty_docs() -> dict:
    op = 100
    layers = [
        shape_layer(
            1,
            "Folder",
            op,
            (256, 280, 0),
            [rect_fill(-100, -40, 200, 140, [0.35, 0.4, 0.55, 1.0], 8, "body")],
        ),
        shape_layer(
            2,
            "Tab",
            op,
            (200, 210, 0),
            [rect_fill(0, 0, 80, 28, ORANGE, 6, "tab")],
        ),
        shape_layer(
            3,
            "Paper",
            op,
            (256, 290, 0),
            [rect_fill(-70, -50, 140, 90, [0.92, 0.93, 0.96, 1.0], 4, "paper")],
            opacity_kf=_kf_opacity_loop(100, 55, 95),
        ),
    ]
    return composition("EmptyDocs", 512, 512, 30, op, list(reversed(layers)))


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(root, "assets", "lottie")
    os.makedirs(out_dir, exist_ok=True)

    catalog: List[Tuple[str, Any]] = [
        ("splash.json", build_splash),
        ("ai_thinking.json", build_ai_thinking),
        ("loading.json", build_loading),
        ("typing.json", build_typing),
        ("error.json", build_error),
        ("success.json", build_success),
        ("voice_wave.json", build_voice_wave),
        ("file_generating.json", build_file_generating),
        ("empty_chat.json", build_empty_chat),
        ("upload.json", build_upload),
        ("onboarding_1.json", lambda: build_onboarding(1, PURPLE)),
        ("onboarding_2.json", lambda: build_onboarding(2, BLUE)),
        ("onboarding_3.json", lambda: build_onboarding(3, PINK)),
        ("search_web.json", build_search_web),
        ("no_internet.json", build_no_internet),
        ("empty_docs.json", build_empty_docs),
    ]

    for filename, builder in catalog:
        path = os.path.join(out_dir, filename)
        data = builder()
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
