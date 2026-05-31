#!/usr/bin/env bash
# =============================================================================
# Claude Code status line  —  "Unicode glyphs" theme
# -----------------------------------------------------------------------------
# A single, self-contained status line script. Claude Code pipes session JSON
# on stdin; this prints one formatted line to stdout. See:
#   https://code.claude.com/docs/en/statusline
#
# It renders (left -> right), each segment auto-hiding when not applicable:
#
#   🦊  [my_feature]  Opus 4.8 1M·xhigh  ctx ▓░░░░░ 15% · 150k/1M  ↑12 ↓3  ◷ May 30 2:54p  5h 23% → 7:54p · 7d 41%  · small diffs win
#   │   │             │                  │                          │       │               │                       │
#   │   │             │                  │                          │       │               │                       └ rotating quip (cosmetic, free)
#   │   │             │                  │                          │       │               └ billing: 5h+7d windows …
#   │   │             │                  │                          │       │                 …OR  "◆ api  $1.23"  on API billing
#   │   │             │                  │                          │       └ session start date+time (cached)
#   │   │             │                  │                          └ lines added / removed this session
#   │   │             │                  └ context fuel gauge + % + absolute token headroom
#   │   │             └ model + reasoning effort (effort colored by level)
#   │   └ session name (snake_cased, shortened) — only if you've named the session
#   └ per-session "mascot" emoji, stable for the session's lifetime
#
# -----------------------------------------------------------------------------
# DEPENDENCIES:  bash 4+, jq, coreutils `date`/`stat` (GNU or BSD/macOS), and a
#                terminal with 256-color support (almost all modern ones).
#
# INSTALL (also in statusline-README.md):
#   1. Save this file to ~/.claude/statusline.sh
#   2. chmod +x ~/.claude/statusline.sh
#   3. Add to ~/.claude/settings.json:
#        "statusLine": {
#          "type": "command",
#          "command": "~/.claude/statusline.sh",
#          "refreshInterval": 60
#        }
#      (refreshInterval keeps the clock/quip fresh while idle.)
#
# OPTIONAL PERSONAL EXTRAS (auto-disabled if absent — safe to ignore):
#   • Stale-429 hint: only shown if a `claude-limit` CLI is on PATH.
#   • Shadow session names: read from ~/.claude/.session-shadow-names/<id> when
#     the JSON `session_name` is empty (used by some `claude-rename` helpers).
#
# Tweak everything in the CONFIG / PALETTE blocks below — no need to read logic.
# =============================================================================

# ----------------------------- CONFIG ----------------------------------------
TZ_OVERRIDE=""          # "" = system local time. Set a TZ name ("Region/City") to pin.
GAUGE_WIDTH=6           # cells in the context fuel gauge
NAME_MAX=22             # max displayed session-name length (then truncated with …)
STRIP_NAME_DATE=1       # 1 = drop a trailing date token from names (the bar shows the date)
SHOW_MASCOT=1           # 1 = leading per-session emoji
SHOW_QUIP=1             # 1 = trailing rotating quip
SHOW_STALE_HINT=1       # 1 = show "⚠ stale 429" hint (also requires `claude-limit` on PATH)
SHOW_CTX_LABEL=1        # 1 = print "ctx" before the gauge
SHOW_CTX_TOKENS=1       # 1 = print absolute token headroom, e.g. "· 310k/1M"
SHOW_SEVEN_DAY=1        # 1 = show the 7-day rate-limit window next to the 5h one
SHOW_DIR=1              # 1 = show current directory, or owner/name inside a git repo
SHOW_DECO=1             # 1 = decorative white→blue "───" framing each end of the bar
SEP="    "              # spacing between segments (4 spaces)

# ---- Fun animation (DISPOSABLE easter egg) -----------------------------------
# A brief critter scurries across the bar now and then. Just for fun.
# To remove entirely: set ANIM_ENABLED=0 (or delete this block, the _animation
# helper, and the 2-line call after `input=$(cat)`), and put refreshInterval
# back to 60 in settings.json.
ANIM_ENABLED=1          # 1 = occasional in-bar cameo; 0 = off
ANIM_EVERY=20           # period in seconds (a cameo plays once per window)
ANIM_FRAMES=10          # steps per cameo. The bar repaints ~1×/sec, so this ≈ seconds
                        # of cameo. More = smoother (more in-between frames); fewer = snappier.
# Which animations rotate through the bar (one per window, cycling). Easiest way
# to change this: the `bfc` command (bfc off | only … | exclude … | every N).
# Or edit by hand — names must exist in statusline-animations.sh. Full set:
#   rainbow nyan mouse ufo comet caterpillar fish train wave sparkle fireworks
#   race fight chase party dance converge marquee abduct duel rocket
#   pacman snake meteor llama bananapeel trex selfdestruct computa
#   warp decrypt radar helix boot  seth credits
# ('credits' is the customizable signature — set SIG_NAME/SIG_GH; 'seth' is the author's.)
ANIM_STYLES=(rainbow nyan mouse ufo comet caterpillar fish train wave sparkle fireworks race fight chase party dance converge marquee abduct duel rocket pacman snake meteor llama bananapeel trex selfdestruct computa warp decrypt radar helix boot seth credits)
ANIM_LIB="$HOME/.claude/statusline-animations.sh"   # shared animation library
ANIM_MAXW=200           # cap animation width (≈ your normal bar width); raise/lower to taste
# NOTE: the in-bar cameo needs "refreshInterval": 1 so frames advance ~1×/sec,
# and even then it's a choppy ~1fps hop (status lines can't truly glide). For the
# smooth show, run `test-animations` in a terminal.
# ------------------------------------------------------------------------------

# Per-session mascot pool. Single-codepoint emoji only (no ZWJ / skin tones) for
# the widest terminal support. Add/remove freely.
EMOJI=(🦊 🦉 🐙 🦀 🐢 🦎 🐝 🦋 🐳 🦭 🦦 🦔 🐲 🦄 🐧 🦥 🐬 🦈 🐡 🦞 🦐 🦑 🐌 🐞 🦗 🕷 🦂 🐜 🐺 🐗 🦬 🦌 🐘 🦣 🦏 🐪 🦒 🦓 🦍 🦧 🐅 🐆 🦇 🦅 🦤 🦢 🦩 🐉 🦕 🦖 🐋 🐦 🐊 🦘)

# Rotating quips (indexed by current minute). Keep them short (≤ ~22 chars).
QUIPS=("small diffs win" "rubber duck it" "name things well" "read the error" "measure twice" "commit early" "touch grass" "hydrate 💧" "YAGNI" "tests green?" "ship it" "breathe")
# ------------------------------------------------------------------------------

# ----------------------------- PALETTE ----------------------------------------
# 256-color theme, organized by ROLE so the bar reads as a coherent whole:
#   • chrome  = quiet grey family for identity/metadata (cohesive, low-stim)
#   • accent  = ONE refined hue, only on the session name + api tag
#   • meter   = the only saturated colors; a single muted ramp shared by every
#               "fills-up" value (context gauge, 5h, 7d, lines, cost)
# To restyle, change these — the segment logic only references these names.
R=$'\e[0m'; DIM=$'\e[2m'
# BRIGHTENED variant (tuned for a black background).
# To revert to the previous, softer palette:  cp ~/.claude/statusline.sh.prebright ~/.claude/statusline.sh
# -- chrome (greys): bright -> faint --
C_TEXT=$'\e[38;5;255m'   # near-white  — model (the static anchor)
C_MUTE=$'\e[38;5;250m'   # light grey  — dir, effort, start, tokens
C_FAINT=$'\e[38;5;245m'  # mid grey    — labels, separators, reset, quip
# -- accent: the session-name identity color --
C_ACCENT=$'\e[38;5;183m' # lavender    — session name + api tag
C_QUIP_C=$'\e[38;5;223m' # peach       — quip (a warm, fun pop at the end)
# -- effort "thinking intensity" gradient: low -> max (violet -> bright pink) --
E_LOW=$'\e[38;5;104m'; E_MED=$'\e[38;5;134m'; E_HIGH=$'\e[38;5;177m'
E_XHIGH=$'\e[38;5;207m'; E_MAX=$'\e[1;38;5;213m'
# -- meter ramp: low -> critical --
G=$'\e[38;5;114m'        # green  — low / healthy
W=$'\e[38;5;150m'        # lime   — moderate
Y=$'\e[38;5;221m'        # gold   — high
RED=$'\e[38;5;210m'      # coral  — critical
BRED=$'\e[1;38;5;203m'   # bold red — stale-429 alert (rare; meant to grab you)
# -- aliases so the segment code below stays readable --
MAG=$C_ACCENT; CY=$'\e[1;38;5;183m'
C_MODEL=$C_TEXT; C_LBL=$C_FAINT; C_TOK=$C_MUTE
C_START=$C_MUTE; C_QUIP=$C_QUIP_C; C_RESET=$C_FAINT; C_DIR=$C_MUTE
# Decorative end-caps: white→blue "───" on the left, mirrored blue→white on the right.
DECO=$'\e[38;5;75m─\e[38;5;123m─\e[38;5;231m─\e[0m'    # left:  blue → sky → white  (white points inward)
DECO_R=$'\e[38;5;231m─\e[38;5;123m─\e[38;5;75m─\e[0m'  # right: white → sky → blue  (white points inward)
# ------------------------------------------------------------------------------

# ----------------------------- HELPERS ----------------------------------------
# Format an epoch with a strftime string, honoring TZ_OVERRIDE; GNU then BSD.
_fmt_time() {  # <epoch> <fmt>
    local e="$1" f="$2"
    if [ -n "$TZ_OVERRIDE" ]; then
        TZ="$TZ_OVERRIDE" date -d "@$e" +"$f" 2>/dev/null && return 0
        TZ="$TZ_OVERRIDE" date -r "$e"   +"$f" 2>/dev/null && return 0
    else
        date -d "@$e" +"$f" 2>/dev/null && return 0
        date -r "$e"   +"$f" 2>/dev/null && return 0
    fi
}

# "May 30 2:54p"  (zero-pad strftime, then strip leading zeros + shorten am/pm)
_clock() { _fmt_time "$1" '%b %d %I:%M%p' | sed -E 's/ 0([0-9])/ \1/g; s/AM/a/; s/PM/p/'; }
# "7:54p"
_clock_short() { _fmt_time "$1" '%I:%M%p' | sed -E 's/^0//; s/AM/a/; s/PM/p/'; }

# File birth (creation) time as epoch, or 0 if unavailable. GNU then BSD.
_birthtime() {  # <file>
    local f="$1" b
    b=$(stat -c %W "$f" 2>/dev/null) || b=$(stat -f %B "$f" 2>/dev/null) || b=0
    case "$b" in ''|0|-) echo 0 ;; *) echo "$b" ;; esac
}

# ISO-8601 -> epoch. GNU `date -d`, else BSD `date -j -f`.
_epoch_from_iso() {  # <iso8601>
    local iso="$1" e clean
    e=$(date -d "$iso" +%s 2>/dev/null) && { echo "$e"; return 0; }
    clean="${iso%.*}"; clean="${clean%Z}"
    e=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null) && { echo "$e"; return 0; }
    echo 0
}

# Humanize a token count: 1000000->1M, 310000->310k, 5000->5k, 800->800.
_humantok() {  # <int>
    local n="$1"
    if [ "$n" -ge 1000000 ]; then
        awk -v n="$n" 'BEGIN{v=n/1000000; if (v==int(v)) printf "%dM", v; else printf "%.1fM", v}'
    elif [ "$n" -ge 1000 ]; then
        awk -v n="$n" 'BEGIN{printf "%dk", (n+500)/1000}'
    else
        printf '%s' "$n"
    fi
}

# Snake-case + shorten a session name for display.
_fmt_name() {  # <raw name>
    local n; n=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
    if [ "$STRIP_NAME_DATE" = 1 ]; then
        n=$(printf '%s' "$n" | sed -E 's/[-_ ]+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)([-_]?[0-9]{1,2})?$//')
        n=$(printf '%s' "$n" | sed -E 's/[-_ ]+[0-9]{1,2}[-_][0-9]{1,2}$//')
    fi
    n=$(printf '%s' "$n" | tr -cs 'a-z0-9' '_' | sed 's/^_*//; s/_*$//')
    [ "${#n}" -gt "$NAME_MAX" ] && n="${n:0:$((NAME_MAX-1))}…"
    printf '%s' "$n"
}

# ---- Fun animation (DISPOSABLE) ----------------------------------------------
# Echoes one animation frame if we're mid-run, else nothing. Optional arg = a
# specific phase (for testing); otherwise derived from the wall clock.
_animation() {
    [ "$ANIM_ENABLED" = 1 ] || return 0
    [ -f "$ANIM_LIB" ] || return 0
    [[ "$ANIM_FRAMES" =~ ^[0-9]+$ ]] && [ "$ANIM_FRAMES" -ge 1 ] || return 0
    [ "${#ANIM_STYLES[@]}" -ge 1 ] || return 0
    local now phase win style pm frames
    now=$(date +%s)
    win=$(( now / ANIM_EVERY ))
    style="${ANIM_STYLES[$(( win % ${#ANIM_STYLES[@]} ))]}"
    frames=$ANIM_FRAMES; [ "$style" = seth ] && frames=18   # the author's signature reel runs longer (18s); credits uses the default
    phase=$(( now % ANIM_EVERY ))
    [ "$phase" -lt "$frames" ] || return 0
    declare -F anim_frame >/dev/null 2>&1 || . "$ANIM_LIB" 2>/dev/null
    declare -F anim_frame >/dev/null 2>&1 || return 0
    if [ "$frames" -gt 1 ]; then pm=$(( phase * 1000 / (frames - 1) )); else pm=0; fi
    local ANIM_SEED=$win   # varies outcome/colors per occurrence (dynamic scope → anim_frame sees it)
    anim_frame "$style" "$pm" "${COLUMNS:-80}"
}
# ------------------------------------------------------------------------------

# ----------------------------- INPUT ------------------------------------------
input=$(cat)

# Fun animation (DISPOSABLE): if mid-run, paint a frame and skip the normal bar.
_anim_frame=$(_animation)
[ -n "$_anim_frame" ] && { printf '%s' "$_anim_frame"; exit 0; }

readarray -t F < <(printf '%s' "$input" | jq -r '
    .session_id // "",
    .session_name // "",
    (.model.display_name // .model.id // ""),
    (.effort.level // ""),
    (.context_window.used_percentage // -1),
    (.context_window.context_window_size // 0),
    (.cost.total_cost_usd // 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.cost.total_duration_ms // 0),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.five_hour.resets_at // 0),
    (if .rate_limits.five_hour then 1 else 0 end),
    (.rate_limits.seven_day.used_percentage // -1),
    (if .rate_limits.seven_day then 1 else 0 end),
    (.transcript_path // ""),
    (.workspace.current_dir // .cwd // ""),
    (.workspace.repo.owner // ""),
    (.workspace.repo.name // "")
' 2>/dev/null)

session_id="${F[0]:-}"
session_name="${F[1]:-}"
model="${F[2]:-}"
effort="${F[3]:-}"
ctx="${F[4]:--1}"
ctx_size="${F[5]:-0}"
cost="${F[6]:-0}"
lines_add="${F[7]:-0}"
lines_rem="${F[8]:-0}"
duration_ms="${F[9]:-0}"
rl5_pct="${F[10]:--1}"
rl5_resets="${F[11]:-0}"
rl5_present="${F[12]:-0}"
rl7_pct="${F[13]:--1}"
rl7_present="${F[14]:-0}"
transcript_path="${F[15]:-}"
current_dir="${F[16]:-}"
repo_owner="${F[17]:-}"
repo_name="${F[18]:-}"

# Shadow-name fallback (no-op if the dir/file doesn't exist).
if [ -z "$session_name" ] && [ -n "$session_id" ]; then
    shadow="$HOME/.claude/.session-shadow-names/$session_id"
    [ -f "$shadow" ] && session_name=$(cat "$shadow" 2>/dev/null)
fi

# ----------------------------- BILLING MODE -----------------------------------
# api_mode=1 means pay-as-you-go API billing; 0 means Claude.ai subscription.
api_mode=0
settings_file="$HOME/.claude/settings.json"
cost_cents=$(awk -v c="$cost" 'BEGIN{printf "%.0f", c*100}' 2>/dev/null); cost_cents=${cost_cents:-0}
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    api_mode=1
elif [ -f "$settings_file" ] && grep -q '"apiKeyHelper"' "$settings_file" 2>/dev/null; then
    api_mode=1
elif [ "$rl5_present" = 1 ]; then
    api_mode=0
elif [ "$cost_cents" -gt 0 ] 2>/dev/null; then
    api_mode=1
fi

# ----------------------------- START TIME (cached) ----------------------------
start_epoch=0
if [ -n "$session_id" ]; then
    START_DIR="$HOME/.claude/.session-start"
    mkdir -p "$START_DIR" 2>/dev/null
    sf="$START_DIR/$session_id"
    if [ -f "$sf" ]; then
        start_epoch=$(cat "$sf" 2>/dev/null)
    else
        if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
            first_ts=$(grep -m1 -o '"timestamp":"[^"]*"' "$transcript_path" 2>/dev/null \
                | head -1 | sed 's/.*"timestamp":"//; s/"$//')
            [ -n "$first_ts" ] && start_epoch=$(_epoch_from_iso "$first_ts")
            { [ -z "$start_epoch" ] || [ "$start_epoch" = 0 ]; } && start_epoch=$(_birthtime "$transcript_path")
        fi
        if { [ -z "$start_epoch" ] || [ "$start_epoch" = 0 ]; } \
           && [[ "$duration_ms" =~ ^[0-9]+$ ]] && [ "$duration_ms" -gt 0 ]; then
            start_epoch=$(( $(date +%s) - duration_ms / 1000 ))
        fi
        [[ "$start_epoch" =~ ^[0-9]+$ ]] && [ "$start_epoch" -gt 0 ] \
            && printf '%s\n' "$start_epoch" > "$sf" 2>/dev/null
    fi
fi
[[ "$start_epoch" =~ ^[0-9]+$ ]] || start_epoch=0

# ----------------------------- STALE-429 HINT ---------------------------------
# Detect a session whose transcript ends in a synthetic 429 (client-side cooldown
# wedged). Recovery is `claude-limit retry`. Only meaningful if that CLI exists.
stale_hint=""
if [ "$SHOW_STALE_HINT" = 1 ] && command -v claude-limit >/dev/null 2>&1 \
   && [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    last_asst=$(tail -n 50 "$transcript_path" 2>/dev/null \
        | jq -rR 'fromjson? | select(.type=="assistant")
            | "\(.isApiErrorMessage // false)|\(.message.model // "")|\(.apiErrorStatus // 0)|\(.error // "")"' 2>/dev/null \
        | tail -1)
    if [ -n "$last_asst" ]; then
        IFS='|' read -r _is_err _emodel _api_st _err <<< "$last_asst"
        if [ "$_is_err" = "true" ] && [[ "$_emodel" == "<"* ]] \
           && { [ "$_api_st" = "429" ] || [ "$_api_st" = "529" ] || [ "$_err" = "rate_limit" ]; }; then
            stale_hint="${BRED}⚠ stale 429${R}${DIM} → claude-limit retry${R}"
        fi
    fi
fi

# ----------------------------- BUILD SEGMENTS ---------------------------------
segs=()

# Session name
if [ -n "$session_name" ]; then
    dn=$(_fmt_name "$session_name")
    [ -n "$dn" ] && segs+=("${MAG}[${dn}]${R}")
fi

# Directory / repo
if [ "$SHOW_DIR" = 1 ]; then
    if [ -n "$repo_name" ]; then
        if [ -n "$repo_owner" ]; then dlabel="$repo_owner/$repo_name"; else dlabel="$repo_name"; fi
        segs+=("${C_DIR}📁 ${dlabel}${R}")
    elif [ -n "$current_dir" ]; then
        segs+=("${C_DIR}📁 ${current_dir##*/}${R}")
    fi
fi

# Model · effort
model_short="${model/ (1M context)/ 1M}"
model_seg="${C_MODEL}${model_short}${R}"
if [ -n "$effort" ]; then
    case "$effort" in
        low)    ec=$E_LOW ;;
        medium) ec=$E_MED ;;
        high)   ec=$E_HIGH ;;
        xhigh)  ec=$E_XHIGH ;;
        max)    ec=$E_MAX ;;
        *)      ec=$C_MUTE ;;
    esac
    model_seg="${model_seg}${C_FAINT}·${R}${ec}${effort}${R}"
fi
segs+=("$model_seg")

# Context fuel gauge ( + label + absolute token headroom )
ctx_int=${ctx%.*}
if [[ "$ctx_int" =~ ^[0-9]+$ ]] && [ "$ctx_int" -ge 0 ]; then
    filled=$(( (ctx_int * GAUGE_WIDTH + 50) / 100 ))
    [ "$filled" -gt "$GAUGE_WIDTH" ] && filled=$GAUGE_WIDTH
    [ "$filled" -lt 0 ] && filled=0
    empty=$(( GAUGE_WIDTH - filled ))
    if   [ "$ctx_int" -ge 95 ]; then fc=$RED
    elif [ "$ctx_int" -ge 80 ]; then fc=$Y
    elif [ "$ctx_int" -ge 50 ]; then fc=$W
    else                             fc=$G
    fi
    bar=""
    for ((i=0; i<filled; i++)); do bar+="▓"; done
    for ((i=0; i<empty;  i++)); do bar+="░"; done

    ctx_seg=""
    [ "$SHOW_CTX_LABEL" = 1 ] && ctx_seg="${C_LBL}ctx ${R}"
    ctx_seg="${ctx_seg}${fc}${bar} ${ctx_int}%${R}"
    if [ "$SHOW_CTX_TOKENS" = 1 ] && [[ "$ctx_size" =~ ^[0-9]+$ ]] && [ "$ctx_size" -gt 0 ]; then
        used=$(awk -v p="$ctx_int" -v s="$ctx_size" 'BEGIN{printf "%.0f", p/100*s}')
        ctx_seg="${ctx_seg}${C_LBL} · ${R}${C_TOK}$(_humantok "$used")/$(_humantok "$ctx_size")${R}"
    fi
    segs+=("$ctx_seg")
fi

# Lines changed
if [ "$lines_add" != "0" ] || [ "$lines_rem" != "0" ]; then
    segs+=("${G}↑${lines_add}${R} ${RED}↓${lines_rem}${R}")
fi

# Session start
if [ "$start_epoch" -gt 0 ]; then
    ds=$(_clock "$start_epoch")
    [ -n "$ds" ] && segs+=("${C_START}◷ ${ds}${R}")
fi

# Billing (adaptive)
if [ "$api_mode" = 1 ]; then
    if [ "$cost_cents" -gt 0 ]; then
        if   [ "$cost_cents" -ge 2000 ]; then cc=$RED
        elif [ "$cost_cents" -ge 500 ];  then cc=$Y
        elif [ "$cost_cents" -ge 100 ];  then cc=$W
        else                                  cc=$C_FAINT
        fi
        cs=$(awk -v c="$cost" 'BEGIN{printf "$%.2f", c}')
        segs+=("${CY}◆ api${R} ${cc}${cs}${R}")
    else
        segs+=("${CY}◆ api${R}")
    fi
else
    lim=""
    rl5_int=${rl5_pct%.*}
    if [[ "$rl5_int" =~ ^[0-9]+$ ]] && [ "$rl5_int" -ge 0 ]; then
        if   [ "$rl5_int" -ge 95 ]; then rc=$RED
        elif [ "$rl5_int" -ge 80 ]; then rc=$Y
        elif [ "$rl5_int" -ge 50 ]; then rc=$W
        else                             rc=$G
        fi
        lim="${rc}5h ${rl5_int}%${R}"
        if [[ "$rl5_resets" =~ ^[0-9]+$ ]] && [ "$rl5_resets" -gt 0 ]; then
            rs=$(_clock_short "$rl5_resets")
            [ -n "$rs" ] && lim="${lim} ${C_RESET}→ ${rs}${R}"
        fi
    fi
    if [ "$SHOW_SEVEN_DAY" = 1 ] && [ "$rl7_present" = 1 ]; then
        rl7_int=${rl7_pct%.*}
        if [[ "$rl7_int" =~ ^[0-9]+$ ]] && [ "$rl7_int" -ge 0 ]; then
            if   [ "$rl7_int" -ge 95 ]; then wc=$RED
            elif [ "$rl7_int" -ge 80 ]; then wc=$Y
            elif [ "$rl7_int" -ge 50 ]; then wc=$W
            else                             wc=$G
            fi
            [ -n "$lim" ] && lim="${lim}${C_LBL} · ${R}"
            lim="${lim}${wc}7d ${rl7_int}%${R}"
        fi
    fi
    [ -n "$lim" ] && segs+=("$lim")
fi

# Rotating quip (last; truncates first under right-side notifications)
if [ "$SHOW_QUIP" = 1 ] && [ "${#QUIPS[@]}" -gt 0 ]; then
    min=$(date +%M); min=$((10#$min))
    segs+=("${C_QUIP}· ${QUIPS[$(( min % ${#QUIPS[@]} ))]}${R}")
fi

# Stale-429 hint sits at the front (after mascot).
[ -n "$stale_hint" ] && segs=("$stale_hint" "${segs[@]}")

# ----------------------------- JOIN & EMIT ------------------------------------
sep="$SEP"
out=""
for s in "${segs[@]}"; do
    if [ -z "$out" ]; then out="$s"; else out="${out}${sep}${s}"; fi
done

# Right end-cap "───" (mirrored: blue→white)
[ "$SHOW_DECO" = 1 ] && out="${out} ${DECO_R}"

# Leading mascot + left end-cap "───"
if [ "$SHOW_MASCOT" = 1 ] && [ -n "$session_id" ] && [ "${#EMOJI[@]}" -gt 0 ]; then
    n=$(printf '%s' "$session_id" | cksum | cut -d' ' -f1)
    mascot="${EMOJI[$(( n % ${#EMOJI[@]} ))]}"
    if [ "$SHOW_DECO" = 1 ]; then out="${mascot} ${DECO} ${out}"; else out="${mascot}  ${out}"; fi
elif [ "$SHOW_DECO" = 1 ]; then
    out="${DECO} ${out}"
fi

printf '%s' "$out"
