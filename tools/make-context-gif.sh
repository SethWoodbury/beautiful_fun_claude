#!/usr/bin/env bash
# make-context-gif.sh — a GIF showing the REAL status bar, a cameo playing, then
# back to the bar (assets/computa-in-context.gif). Uses a representative mock
# session + a slightly trimmed bar (so it's narrow enough to read on GitHub).
# Needs: python3 + Pillow + a color-emoji font + ImageMagick `convert`.
set -euo pipefail
cd "$(dirname "$0")/.."
. ./statusline-animations.sh
SEED="${1:-111}"
MOCK='{"session_id":"bfc-demo-ctx","session_name":"bfc","model":{"display_name":"Opus 4.8 (1M context)"},"effort":{"level":"xhigh"},"context_window":{"used_percentage":15,"context_window_size":1000000},"cost":{"total_cost_usd":0,"total_lines_added":0,"total_lines_removed":0,"total_duration_ms":5400000},"rate_limits":{"five_hour":{"used_percentage":23,"resets_at":1780256700},"seven_day":{"used_percentage":41}},"transcript_path":"","workspace":{}}'

# a cameo-disabled, lightly-trimmed copy so we capture a clean, narrow normal bar
bar_sh=$(mktemp)
sed -e 's/^ANIM_ENABLED=1/ANIM_ENABLED=0/' -e 's/^SHOW_DIR=1/SHOW_DIR=0/' \
    -e 's/^SHOW_CTX_TOKENS=1/SHOW_CTX_TOKENS=0/' -e 's/^SHOW_SEVEN_DAY=1/SHOW_SEVEN_DAY=0/' \
    -e 's/^SEP="    "/SEP="  "/' statusline.sh > "$bar_sh"
BAR="$(printf '%s' "$MOCK" | bash "$bar_sh")"
rm -f "$bar_sh"; rm -rf "$HOME/.claude/.session-start/bfc-demo-ctx" 2>/dev/null || true

COLS=$(printf '%s' "$BAR" | sed 's/\x1b\[[0-9;]*m//g' | python3 -c "import sys,unicodedata
s=sys.stdin.read().rstrip('\n');w=0
for ch in s:
 o=ord(ch)
 if unicodedata.east_asian_width(ch) in ('W','F') or 0x1F000<=o<=0x1FAFF or 0x2600<=o<=0x27BF or 0x1F300<=o<=0x1F9FF: w+=2
 elif unicodedata.combining(ch) or 0xFE00<=o<=0xFE0F: w+=0
 else: w+=1
print(w)")
echo "normal bar: $COLS cols"

tmp=$(mktemp -d); n=0
addpng() { printf '%s' "$1" | python3 tools/ansi2png.py "$(printf '%s/f%04d.png' "$tmp" "$n")" "$COLS"; n=$((n+1)); }
for _ in $(seq 1 16); do addpng "$BAR"; done                                   # the normal bar (hold ~1.6s)
for pm in $(seq 0 20 1000); do addpng "$(ANIM_SEED=$SEED anim_frame computa "$pm" $((COLS+8)))"; done   # cameo takes over
for _ in 1 2 3 4 5 6; do addpng "$(ANIM_SEED=$SEED anim_frame computa 1000 $((COLS+8)))"; done          # finale lingers
for _ in $(seq 1 16); do addpng "$BAR"; done                                   # ...and back to the bar
convert -loop 0 -delay 10 "$tmp"/f*.png -layers Optimize assets/computa-in-context.gif
rm -rf "$tmp"
echo "wrote assets/computa-in-context.gif ($(du -h assets/computa-in-context.gif | cut -f1), $n frames)"
