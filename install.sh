#!/usr/bin/env bash
# =============================================================================
# beautiful_fun_claude — installer
# Copies the status line + animation library into ~/.claude and the preview CLIs
# into ~/.local/bin, makes them executable, and wires up ~/.claude/settings.json.
# Safe to re-run. Backs up settings.json before touching it.
# =============================================================================
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

CLAUDE="$HOME/.claude"
BIN="$HOME/.local/bin"
mkdir -p "$CLAUDE" "$BIN"

echo "→ installing status line + animation library to $CLAUDE"
cp "$here/statusline.sh"            "$CLAUDE/statusline.sh"
cp "$here/statusline-animations.sh" "$CLAUDE/statusline-animations.sh"
chmod +x "$CLAUDE/statusline.sh" "$CLAUDE/statusline-animations.sh"

echo "→ installing preview tools to $BIN"
cp "$here/test-animations"      "$BIN/test-animations"
cp "$here/test-animations-fast" "$BIN/test-animations-fast"
chmod +x "$BIN/test-animations" "$BIN/test-animations-fast"

SETTINGS="$CLAUDE/settings.json"
if command -v jq >/dev/null 2>&1; then
    echo "→ wiring up $SETTINGS (statusLine + refreshInterval)"
    [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    tmp=$(mktemp)
    jq '.statusLine = {type:"command", command:"~/.claude/statusline.sh", refreshInterval:1}' "$SETTINGS" > "$tmp" \
        && mv "$tmp" "$SETTINGS" \
        && echo "  ✓ patched (backup saved alongside)"
else
    cat <<'EOF'
  ⚠ jq not found — add this to ~/.claude/settings.json yourself (merge, don't overwrite):
      "statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "refreshInterval": 1 }
EOF
fi

echo
echo "✅ Installed. Open a terminal and run:  test-animations"
echo "   (Your status bar updates on the next interaction with Claude Code.)"
echo "   Dependencies: bash 4+, jq, coreutils date/stat, a 256-color terminal."
echo "   Note: refreshInterval=1 lets the periodic animation cameos move; set it"
echo "   to 60 in settings.json if you'd rather the bar repaint less often"
echo "   (the cameos won't animate then). Disable cameos entirely with ANIM_ENABLED=0"
echo "   near the top of ~/.claude/statusline.sh."
