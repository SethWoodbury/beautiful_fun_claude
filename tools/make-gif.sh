#!/usr/bin/env bash
# make-gif.sh — render an animation to an animated GIF for the README.
#   tools/make-gif.sh [style] [seed] [width]
# Needs: python3 + Pillow, a color-emoji font (Segoe UI Emoji / Noto Color Emoji),
#        ImageMagick `convert`. Frames -> PNG (tools/ansi2png.py) -> optimized GIF.
# NB: no `set -e` — the animation lib uses the idiomatic `((i++))` slot-skip, which
# returns exit status 1 when i==0 (post-increment yields 0) and would abort under -e.
set -uo pipefail
cd "$(dirname "$0")/.."
. ./statusline-animations.sh
STYLE="${1:-computa}"; SEED="${2:-111}"; W="${3:-80}"
tmp=$(mktemp -d); n=0
frame() { ANIM_SEED="$SEED" anim_frame "$STYLE" "$1" "$W" | python3 tools/ansi2png.py "$(printf '%s/f%04d.png' "$tmp" "$n")" "$W"; n=$((n+1)); }
for pm in $(seq 0 20 1000); do frame "$pm"; done
for _ in 1 2 3 4 5 6 7 8; do frame 1000; done          # let the wholesome finale linger
convert -loop 0 -delay 10 "$tmp"/f*.png -layers Optimize "assets/$STYLE.gif"
rm -rf "$tmp"
echo "wrote assets/$STYLE.gif ($(du -h "assets/$STYLE.gif" | cut -f1), $n frames)"
