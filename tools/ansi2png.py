#!/usr/bin/env python3
"""ansi2png — render one line of ANSI (256-color) text to a PNG (with color emoji).

Used to build animated-GIF previews of the status-bar animations. Reads ANSI on
stdin, writes a PNG to the path given as argv[1]. Pair with ImageMagick to make a
GIF (see tools/make-gif.sh).
"""
import sys, re, unicodedata
from PIL import Image, ImageDraw, ImageFont

FS = 28
CW = 17          # mono cell advance (px)
PADX, PADY = 12, 10
BG = (13, 17, 23)
DEFAULT_FG = (208, 208, 208)
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
MONO_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
EMOJI = "/usr/share/fonts/windows/seguiemj.ttf"   # scalable COLR color font

_LOW = [(0,0,0),(128,0,0),(0,128,0),(128,128,0),(0,0,128),(128,0,128),(0,128,128),(192,192,192),
        (128,128,128),(255,0,0),(0,255,0),(255,255,0),(0,0,255),(255,0,255),(0,255,255),(255,255,255)]
_STEPS = [0,95,135,175,215,255]

def rgb256(n):
    if n < 16: return _LOW[n]
    if n < 232:
        n -= 16
        return (_STEPS[n//36], _STEPS[(n//6)%6], _STEPS[n%6])
    g = 8 + 10*(n-232); return (g,g,g)

def cw(ch):
    o = ord(ch)
    if unicodedata.combining(ch) or 0xFE00 <= o <= 0xFE0F: return 0
    if (unicodedata.east_asian_width(ch) in ("W","F")
            or 0x1F000<=o<=0x1FAFF or 0x2600<=o<=0x27BF or 0x1F300<=o<=0x1F9FF): return 2
    return 1

def is_emoji(ch):
    o = ord(ch)
    return 0x1F000<=o<=0x1FAFF or 0x2600<=o<=0x27BF or 0x1F300<=o<=0x1F9FF or 0x2B00<=o<=0x2BFF

def main():
    out_path = sys.argv[1]
    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 80
    data = sys.stdin.read().rstrip("\n")
    mono = ImageFont.truetype(MONO, FS)
    monob = ImageFont.truetype(MONO_B, FS)
    emoji = ImageFont.truetype(EMOJI, 28)   # COLR scalable; 28px ~ fits two cells
    W = cols*CW + 2*PADX
    Hh = FS + 2*PADY + 6
    img = Image.new("RGB", (W, Hh), BG)
    d = ImageDraw.Draw(img)
    fg, bold = DEFAULT_FG, False
    x = PADX; y = PADY
    for i, part in enumerate(re.split(r"\x1b\[([0-9;]*)m", data)):
        if i % 2 == 1:
            codes = [c for c in part.split(";") if c != ""] or ["0"]
            j = 0
            while j < len(codes):
                c = codes[j]
                if c == "0": fg, bold = DEFAULT_FG, False
                elif c == "1": bold = True
                elif c == "38" and j+2 < len(codes) and codes[j+1] == "5":
                    fg = rgb256(int(codes[j+2])); j += 2
                elif c == "39": fg = DEFAULT_FG
                j += 1
            continue
        for ch in part:
            w = cw(ch)
            if ch != " ":
                if is_emoji(ch):
                    d.text((x, y-2), ch, font=emoji, embedded_color=True)
                else:
                    d.text((x, y), ch, font=(monob if bold else mono), fill=fg)
            x += w*CW
    img.save(out_path)

if __name__ == "__main__":
    main()
