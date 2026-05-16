#!/usr/bin/env python3
"""
Generate a 1024x1024 SVG meter background for ESPHome LVGL meters.

Geometry:
  Center:           (CX, CY)
  Arc radius:       R
  Scale arc:        START deg to START+SWEEP deg (clockwise)
  Tick outer edge:  CX + R  (ticks meet the arc centerline)
  Major tick inner: CX + R - MAJOR_LEN
  Minor tick inner: CX + R - MINOR_LEN
  All ticks lie at y=CY before rotation about (CX, CY)

Usage:
    python meter_bg.py --units psi
    python meter_bg.py --units bar
"""

import argparse
import math

CX, CY = 512, 512
R = 400
START = 135.0
SWEEP = 270.0

MAJOR_LEN = 80
MINOR_LEN = 48

UNIT_DEFS = {
    "psi": dict(vmin=0, vmax=100, major_step=20, minor_div=4, label="PSI"),
    "bar": dict(vmin=0, vmax=7, major_step=1, minor_div=5, label="BAR"),
    "f": dict(vmin=0, vmax=120, major_step=20, minor_div=4, label="°F"),
    "c": dict(vmin=-20, vmax=50, major_step=10, minor_div=5, label="°C"),
}

COLOR = "#ffffff"
LABEL_R = 240
FONT_SIZE = 85


def val_to_deg(v, vmin, vmax):
    return START + (v - vmin) / (vmax - vmin) * SWEEP


def label_pos(v, vmin, vmax):
    a = math.radians(val_to_deg(v, vmin, vmax))
    return CX + LABEL_R * math.cos(a), CY + LABEL_R * math.sin(a)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--units", choices=["psi", "bar", "f", "c"], required=True)
    args = parser.parse_args()

    cfg = UNIT_DEFS[args.units]
    vmin = cfg["vmin"]
    vmax = cfg["vmax"]
    major = cfg["major_step"]
    ndiv = cfg["minor_div"]
    lbl = cfg["label"]

    # arc endpoints
    def pt(deg):
        a = math.radians(deg)
        return CX + R * math.cos(a), CY + R * math.sin(a)

    x0, y0 = pt(START)
    xm, ym = pt(START + SWEEP / 2)
    x1, y1 = pt(START + SWEEP)

    # major tick values
    majors = []
    v = vmin
    while v <= vmax + 1e-9:
        majors.append(round(v, 9))
        v += major

    w, h = CX * 2, CY * 2
    print('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
    print(f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}"')
    print('     version="1.1" xmlns="http://www.w3.org/2000/svg">')

    # arc
    print(
        f'  <path style="fill:none;stroke:{COLOR};stroke-width:16;stroke-linecap:round"'
    )
    print(
        f'        d="M {x0:.6f},{y0:.6f} A {R},{R} 0 0 1 {xm:.6f},{ym:.6f} A {R},{R} 0 0 1 {x1:.6f},{y1:.6f}" />'
    )

    # derived tick coordinates
    outer = CX + R
    major_inner = outer - MAJOR_LEN
    minor_inner = outer - MINOR_LEN

    # major ticks
    for v in majors:
        a = val_to_deg(v, vmin, vmax)
        print(
            f'  <path style="fill:none;stroke:{COLOR};stroke-width:16;stroke-linecap:round"'
        )
        print(
            f'        d="M {major_inner} {CY} H {outer}" transform="rotate({a:.4f},{CX},{CY})" />'
        )

    # minor ticks
    for i in range(len(majors) - 1):
        for k in range(1, ndiv):
            vm = majors[i] + (majors[i + 1] - majors[i]) * k / ndiv
            a = val_to_deg(vm, vmin, vmax)
            print(
                f'  <path style="fill:none;stroke:{COLOR};stroke-width:8;stroke-linecap:round"'
            )
            print(
                f'        d="M {minor_inner} {CY} H {outer}" transform="rotate({a:.4f},{CX},{CY})" />'
            )

    # labels
    for v in majors:
        lx, ly = label_pos(v, vmin, vmax)
        display = int(round(v)) if v == int(v) else v
        print(f'  <text x="{lx:.2f}" y="{ly:.2f}"')
        print(f'        text-anchor="middle" dominant-baseline="central"')
        print(
            f'        font-family="sans-serif" font-size="{FONT_SIZE}" font-weight="bold"'
        )
        print(f'        fill="{COLOR}">{display}</text>')

    # unit label
    print(f'  <text x="{CX}" y="{CY + LABEL_R}"')
    print(f'        text-anchor="middle" dominant-baseline="central"')
    print(
        f'        font-family="sans-serif" font-size="{FONT_SIZE}" font-weight="bold"'
    )
    print(f'        fill="{COLOR}">{lbl}</text>')

    print("</svg>")


if __name__ == "__main__":
    main()
