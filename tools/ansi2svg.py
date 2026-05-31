#!/usr/bin/env python3
"""ansi2svg — render one line of ANSI (256-color) text to a static SVG snapshot.

Used to make the README's assets/*.svg (GitHub can't show ANSI color in a code
block). Reads ANSI on stdin, writes SVG on stdout.

Example (regenerate the energy-clash signature image):
  . ./statusline-animations.sh
  ANIM_SEED=2 anim_frame seth 420 98 | python3 tools/ansi2svg.py > assets/seth.svg
"""
import sys, re, unicodedata

CW = 9.7          # monospace cell advance (px) at font-size 17
X0 = 10.0         # left padding
PADR = 10.0       # right padding
FS = 17
H = 37
Y = 25.0
BG = "#0d1117"
DEFAULT_FG = "#d0d0d0"

_LOW = [0x000000,0x800000,0x008000,0x808000,0x000080,0x800080,0x008080,0xc0c0c0,
        0x808080,0xff0000,0x00ff00,0xffff00,0x0000ff,0xff00ff,0x00ffff,0xffffff]
_STEPS = [0,95,135,175,215,255]

def hexcolor(n):
    if n < 16:
        v = _LOW[n]
    elif n < 232:
        n -= 16
        r, g, b = _STEPS[n // 36], _STEPS[(n // 6) % 6], _STEPS[n % 6]
        v = (r << 16) | (g << 8) | b
    else:
        g = 8 + 10 * (n - 232)
        v = (g << 16) | (g << 8) | g
    return "#%06x" % v

def cellwidth(ch):
    o = ord(ch)
    if unicodedata.combining(ch) or 0xFE00 <= o <= 0xFE0F:
        return 0
    if (unicodedata.east_asian_width(ch) in ("W", "F")
            or 0x1F000 <= o <= 0x1FAFF or 0x2600 <= o <= 0x27BF or 0x1F300 <= o <= 0x1F9FF):
        return 2
    return 1

def esc(ch):
    return {"&": "&amp;", "<": "&lt;", ">": "&gt;"}.get(ch, ch)

def main():
    data = sys.stdin.read().rstrip("\n")
    fg, bold = DEFAULT_FG, False
    x = X0
    spans = []
    parts = re.split(r"\x1b\[([0-9;]*)m", data)   # text, code, text, code, ...
    for i, part in enumerate(parts):
        if i % 2 == 1:                            # an SGR code
            codes = [c for c in part.split(";") if c != ""] or ["0"]
            j = 0
            while j < len(codes):
                c = codes[j]
                if c == "0":
                    fg, bold = DEFAULT_FG, False
                elif c == "1":
                    bold = True
                elif c == "2":
                    pass                          # dim: keep color (rare in these frames)
                elif c == "38" and j + 2 < len(codes) and codes[j + 1] == "5":
                    fg = hexcolor(int(codes[j + 2])); j += 2
                elif c == "39":
                    fg = DEFAULT_FG
                j += 1
            continue
        for ch in part:                           # literal text
            w = cellwidth(ch)
            if ch != " ":
                spans.append('<tspan x="%.1f" font-weight="%d" fill="%s">%s</tspan>'
                             % (x, 700 if bold else 400, fg, esc(ch)))
            x += w * CW
    width = int(x + PADR)
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" '
           'font-family="ui-monospace,Menlo,Consolas,monospace" font-size="%d">' % (width, H, width, H, FS),
           '<rect width="100%%" height="100%%" rx="8" fill="%s"/>' % BG,
           '<text y="%.1f" xml:space="preserve">%s</text>' % (Y, "".join(spans)),
           '</svg>']
    sys.stdout.write("\n".join(out) + "\n")

if __name__ == "__main__":
    main()
