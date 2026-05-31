#!/usr/bin/env bash
# =============================================================================
# Fun status-line animations — shared library + standalone player  (v5: cinematic)
#
#   ONE anim_frame(style, pm, width); TWO drivers: the terminal player loops it
#   smoothly; ~/.claude/statusline.sh calls it ~1×/sec (sampled at pm 0/250/500/
#   750/1000 — beats are choreographed to land on that grid).
#
#   Preview:  test-animations [style]   (real terminal = smooth; piped = storyboard)
#
#   Per-run randomness via ANIM_SEED: palette VARIANT, rosters, and OUTCOMES
#   (who wins the race/fight/duel, escape-vs-catch in the chase, orbit-vs-kaboom).
#   Beats land at pm 0/250/500/750/1000 with the climax at 1000. Left-facing
#   emoji travel right-to-left; positions drawn with visible chars (bar trims space).
# =============================================================================

ALL_STYLES=(rainbow nyan mouse ufo comet caterpillar fish train wave sparkle \
            fireworks race fight chase party dance converge marquee abduct duel rocket \
            pacman snake meteor llama bananapeel trex selfdestruct computa \
            warp decrypt radar helix boot \
            lightsaber deathstar yoda titrate flametest ribosome benzene \
            r2d2 ironman dgoggins volcano dragon \
            seth credits)

R=$'\e[0m'
# --- palettes (256-color, bright head -> dark tail; head-safe on black) ------
RING=(196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51 45 39 33 27 63 99 135 171 207 206 205 204)
ICE_GLACIER=(231 195 159 123 87 81 75 69); ICE_FROSTFIRE=(231 159 123 117 111 153 147 105)
OCEAN_SURF=(51 45 39 33 27 26 25 24 23); OCEAN_TEAL=(50 44 43 37 31 30 36 29 23); OCEAN_DUSK=(207 171 135 99 63 62 61 60)
TOX_NEON=(190 154 118 82 46 40 34 28); FOREST_DEEP=(120 84 78 42 36 35 29 28)
FIRE_CLASSIC=(231 226 220 214 208 202 196 160 124); FIRE_EMBER=(229 222 215 208 202 166 130 94); FIRE_VIOLET=(231 219 213 207 171 135 99 93)
DISCO_NEON=(207 201 165 51 226 46); DISCO_CANDY=(218 213 207 219 159 117); DISCO_VAPOR=(207 171 141 117 153 219)
RACE_STEEL=(252 250 248 246 244 242 240 248); RACE_GOLD=(229 226 220 214 208 178 172 136)
SMOKE=(253 251 249 246 243 240 238 236)
ELECTRIC=(231 230 226 190 154 87 51 45 39 33)        # white→yellow→cyan→blue (lightning)
FLASH=(196 202 226 46 51 21 93 201 213 231)          # vivid strobe (intense flashing)
SETHPALS=(RING DISCO_NEON DISCO_CANDY DISCO_VAPOR FIRE_VIOLET ICE_GLACIER OCEAN_SURF FIRE_CLASSIC)
# --- extra palettes for the newer animations -------------------------------
MOUSE_DUST=(223 222 180 144 138 102 101 240)         # warm dust kicked up by the mouse
PAC_MAZE=(226 220 214 190 184 178)                   # pellet gold
SNAKE_GRN=(46 40 34 28 22 22)                         # bright head -> dark tail
SPIT=(231 230 194 154 120 84 70)                      # llama goo: white -> sickly green
BANANA=(231 229 226 220 214 178)                      # banana yellow
HUD_CYAN=(231 159 123 87 51 45 39 38 37 31)           # white -> ice -> cyan HUD glow
MATRIX=(231 194 157 120 83 46 40 34 28 22)            # white head -> deep matrix green
PLASMA=(231 219 213 207 171 135 99 63 57 93)          # white -> magenta -> indigo
RADAR_GRN=(231 195 157 119 83 46 40 34 28 22)         # sweep: bright edge -> fading trail
WARP_BLU=(231 195 159 153 117 111 75 69 63 27)        # white-hot -> blue-shift streaks
SABER_BLU=(231 195 159 153 117 111 75 69 33 27)       # lightsaber: white-hot core -> blue
SABER_RED=(231 224 217 210 203 196 160 124 88 52)     # lightsaber: white-hot core -> Sith red
LASER_GRN=(231 194 157 120 83 46 40 34 28 22)         # Death Star superlaser green
PH_PINK=(231 230 224 225 218 219 213 207 206 205)     # titration: clear -> SHOCKING phenolphthalein pink
FLAME_TEST=(196 208 226 46 51 201 129)                # flame test: Li/Ca/Na/Ba/Cu/K element colors
GFP_GLOW=(231 195 159 156 154 118 82 46 40 34)        # fluorescent GFP green glow (folded protein)
PH_DEEP=(218 219 213 207 206 205 199 198 197 163 127 91)   # titration overshoot: pink -> magenta -> violet
# --- flame test: ONE ramp per element (bright core -> the element's real flame colour -> dark tail) ---
FLAME_LI=(231 224 217 210 203 196 160 124 88)         # Li  crimson red
FLAME_NA=(231 230 229 228 227 226 220 214 178)        # Na  intense sodium yellow
FLAME_K=(231 225 219 183 177 141 135 99 57)           # K   lilac / violet
FLAME_CU=(231 195 159 123 87 50 44 37 30)             # Cu  blue-green / emerald
FLAME_CA=(231 230 223 216 209 202 166 130 94)         # Ca  orange-red
FLAME_BA=(231 194 157 156 120 113 78 71 65)           # Ba  pale apple-green
FLAME_SR=(231 224 218 211 204 197 161 125 89)         # Sr  scarlet red
FLAME_B=(231 195 158 121 84 47 41 35 29)              # B   bright green
FLAME_SYM=(Li Na K Cu Ca Ba Sr B)
FLAME_RAMP=(FLAME_LI FLAME_NA FLAME_K FLAME_CU FLAME_CA FLAME_BA FLAME_SR FLAME_B)
# --- character & emoji-audit palettes ---------------------------------------
R2_BLUE=(231 195 159 117 75 39 33 27 26 25)           # astromech: white dome -> R2 blue
HOTROD_RED=(231 224 217 210 203 196 160 124 88 52)    # Iron Man hot-rod crimson
IRON_GOLD=(231 230 229 228 227 226 220 214 178 136)   # Iron Man faceplate gold
ARC_CYAN=(231 195 159 123 87 51 45 39 38 31)          # arc-reactor cyan core glow
REPULSOR=(231 231 230 195 159 123 87 51 45 39)        # repulsor blast: white-hot -> cyan
LAVA_CORE=(231 229 228 226 220 214 208 202 196 160 124 88)   # magma: white-hot -> deep red
LAVA_ASH=(255 250 245 242 240 238 236 235)            # ash / smoke
DRAGON_FIRE=(231 230 226 220 214 208 202 196 160 124 88)     # dragon breath: white-hot -> crimson
DRAGON_GOLD=(231 229 226 220 214 178 172 136)         # dragon hoard gold
# --- customize the `credits` animation with YOUR name/handle (env-overridable) ---
# Default is a placeholder so you SEE it asking to be replaced. ('David Baker' is the
# Baker Lab director — our stand-in name; swap the WHOLE string for your own.)
SIG_NAME="${SIG_NAME:-David Baker <insert_your_name>}"; SIG_GH="${SIG_GH:-your-handle}"
NR=${#RING[@]}

_pick()  { local s="${1:-0}"; shift; local a=("$@"); printf '%s' "${a[$(( s % ${#a[@]} ))]}"; }
_solid() { local n="$1" t; [ "$n" -le 0 ] && return 0; printf -v t '%*s' "$n" ''; printf '\e[38;5;%dm%s%s' "$3" "${t// /$2}" "$R"; }
_dots()  { local n="$1" t; [ "$n" -le 0 ] && return 0; printf -v t '%*s' "$n" ''; printf '\e[38;5;236m%s%s' "${t// /·}" "$R"; }
_cycle() { local n="$1" c="$2" off="${3:-0}"; local -n P="$4"; local m=${#P[@]} out='' i; [ "$n" -lt 0 ] && n=0
           for ((i=0;i<n;i++)); do out+=$'\e[38;5;'"${P[$(( (i+off)%m ))]}"m"$c"; done; printf '%s%s' "$out" "$R"; }
_fade()  { local n="$1" c="$2"; local -n P="$3"; local be="$4" m=${#P[@]} out='' i d idx denom; [ "$n" -lt 0 ] && n=0; denom=$(( n>1 ? n-1 : 1 ))
           for ((i=0;i<n;i++)); do if [ "$be" = R ]; then d=$(( n-1-i )); else d=$i; fi
               idx=$(( d*(m-1)/denom )); [ "$idx" -ge "$m" ] && idx=$(( m-1 )); out+=$'\e[38;5;'"${P[$idx]}"m"$c"; done; printf '%s%s' "$out" "$R"; }
_text()  { local msg="$1" off="${2:-0}"; local -n P="${3:-RING}"; local m=${#P[@]} out='' i
           for ((i=0;i<${#msg};i++)); do out+=$'\e[1;38;5;'"${P[$(( (i+off)%m ))]}"m"${msg:i:1}"; done; printf '%s%s' "$out" "$R"; }
_runner() {
    local hc="$1" hw="$2" w="$3" head="$4" dir="$5" off="${6:-0}" tc="${7:-━}" pal="${8:-SMOKE}" mode="${9:-fade}"
    [ "$hc" -lt 0 ] && hc=0
    if [ "$dir" = rtl ]; then local tn=$(( w-hc-hw )) tr
        if [ "$mode" = cycle ]; then tr="$(_cycle "$tn" "$tc" "$off" "$pal")"; else tr="$(_fade "$tn" "$tc" "$pal" L)"; fi
        printf '%s%s%s' "$(_dots "$hc")" "$head" "$tr"
    else local tr
        if [ "$mode" = cycle ]; then tr="$(_cycle "$hc" "$tc" "$off" "$pal")"; else tr="$(_fade "$hc" "$tc" "$pal" R)"; fi
        printf '%s%s%s' "$tr" "$head" "$(_dots $(( w-hc-hw )))"
    fi
}

# _signature NAME GH CREDIT  — an 18s wizard-battle signature reel. Reads pm/span/off/seed
# from the caller (dynamic scope). Used by both `seth` (the author) and `credits` (customizable).
_signature() {
    local NAME="$1" GH="$2" CREDIT="${3:-}" L=${#1} c=$(( span/2 )) fin=$(( seed%3 ))
    local band tl quip created
    band=$(_pick "$seed" "${SETHPALS[@]}")
    tl=$(_pick "$seed" 'ships code' 'made this' 'builds proteins' 'fueled by happy hour' 'was here' 'commits at 2am' 'folds proteins @ IPD' 'high on life' 'designs diffusion-limited enzymes' 'relies on claude' 'vibe codes')
    quip=$(_pick "$(( seed+1 ))" 'EN GARDE!' 'BEHOLD!' 'WITNESS ME!' 'KABOOM!' 'TA-DA!' 'ZAP! ZAP!')
    created="created by $NAME"; [ -n "$GH" ] && created="$created (github: $GH)"
    [ "$L" -gt "$span" ] && { NAME="${NAME:0:$(( span>1?span-1:1 ))}…"; L=${#NAME}; }   # narrow-bar guard
    if   [ "$pm" -lt 100 ]; then local q=" ⚡ $quip ⚡ " qw sh; qw=$(( ${#q}+2 )); sh=$(( (span-qw-4)/2 )); [ "$sh" -lt 0 ] && sh=0       # ⚔ wizards square up
        printf '🧙%s%s%s🧙' "$(_dots "$sh")" "$(_text "$q" "$off" "$band")" "$(_dots $(( span-qw-4-sh<0?0:span-qw-4-sh )))"
    elif [ "$pm" -lt 220 ]; then local cl sh; cl=$(( 1+(pm-100)/40 )); sh=$(( (span-15-4*cl)/2 )); [ "$sh" -lt 0 ] && sh=0             # ⚡ charging staffs
        printf '🧙%s%s%s%s%s🧙' "$(_cycle "$cl" '✦' "$off" ELECTRIC)" "$(_dots "$sh")" "$(_text ' CHARGING… ' "$off" "$band")" "$(_dots "$sh")" "$(_cycle "$cl" '✦' $((off+3)) ELECTRIC)"
    elif [ "$pm" -lt 390 ]; then local bl g; bl=$(( (pm-220)*(c-4)/170 )); [ "$bl" -lt 0 ] && bl=0; g=$(( span-2*bl-4 )); [ "$g" -lt 0 ] && g=0   # bolts converge
        printf '🧙%s%s%s🧙' "$(_cycle "$bl" '═' "$off" ELECTRIC)" "$(_dots "$g")" "$(_cycle "$bl" '═' $((off+4)) ELECTRIC)"
    elif [ "$pm" -lt 450 ]; then local bl; bl=$(( c-6 )); [ "$bl" -lt 0 ] && bl=0; local CLS=(231 226 51 201) sc=${CLS[$(( (pm/30)%4 ))]}   # 💥 COLLISION
        printf '🧙%s\e[1;38;5;%dm💥💥💥%s%s🧙' "$(_cycle "$bl" '═' "$off" ELECTRIC)" "$sc" "$R" "$(_cycle "$bl" '═' $((off+4)) ELECTRIC)"
    elif [ "$pm" -lt 560 ]; then local lp; lp=$(( (span-L)/2 )); [ "$lp" -lt 0 ] && lp=0                                              # ✦ NAME bursts out
        printf '%s%s%s' "$(_cycle "$lp" '═' "$off" "$band")" "$(_text "$NAME" "$off" "$band")" "$(_cycle $(( span-lp-L )) '═' "$off" "$band")"
    elif [ "$pm" -lt 740 ]; then local mw sh fo; mw=${#created}; [ "$mw" -gt $(( span-4 )) ] && { created="${created:0:$(( span>5?span-5:1 ))}…"; mw=${#created}; }; fo=$(( off*3 + pm/4 )); sh=$(( (span-mw-4)/2 )); [ "$sh" -lt 0 ] && sh=0   # 🧙 held + multi-color flashing
        printf '🧙%s%s%s🧙' "$(_cycle "$sh" '═' "$fo" RING)" "$(_text "$created" "$fo" RING)" "$(_cycle $(( span-mw-4-sh<0?0:span-mw-4-sh )) '═' "$fo" RING)"
    elif [ "$pm" -lt 920 ]; then local sig="$NAME $tl" sl lp; [ "${#sig}" -gt "$span" ] && sig="${sig:0:$(( span>1?span-1:1 ))}…"; sl=${#sig}; lp=$(( (span-sl)/2 )); [ "$lp" -lt 0 ] && lp=0   # name + funny tagline (holds ~3s)
        printf '%s%s%s' "$(_cycle "$lp" '─' "$off" "$band")" "$(_text "$sig" "$off" "$band")" "$(_cycle $(( span-lp-sl )) '─' "$off" "$band")"
    elif [ "$pm" -lt 970 ]; then case "$fin" in                                                                                      # 🎆 FINALE (random)
            0) printf '%s' "$(_cycle $(( span-2 )) '▰' "$off" "$band")" ;;
            1) local s='' i; for ((i=0;i<span-2;i++)); do if [ $(( (i+off)%6 )) -eq 0 ]; then s+=$'\e[1m''🎉'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'▀'; fi; done; printf '%s%s' "$s" "$R" ;;
            *) local s='' i; for ((i=0;i<span-2;i++)); do if [ $(( (i*7+off)%9 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''✦'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'·'; fi; done; printf '%s%s' "$s" "$R" ;;
        esac
    else local sig; if [ -n "$CREDIT" ]; then sig="🎉 $NAME — $tl · $CREDIT 🎉"; else sig="🎉 $NAME — $tl 🎉"; fi   # 🏆 signature card
        [ "${#sig}" -gt "$span" ] && sig="${sig:0:$(( span>2?span-2:1 ))}…"
        local sl lp; sl=$(( ${#sig}+2 )); lp=$(( (span-sl)/2 )); [ "$lp" -lt 0 ] && lp=0
        printf '%s%s%s' "$(_cycle "$lp" '─' "$off" "$band")" "$(_text "$sig" "$off" RING)" "$(_cycle $(( span-lp-sl )) '─' "$off" "$band")"; fi
}

# _credits NAME GH — the customizable `credits` reel (default 10s). A silly+epic
# SHOWBIZ HYPE REEL (mic check → drumroll → big reveal → goofy title → crowd →
# card). Deliberately NOTHING like `seth` (the author's wizard battle, his alone).
# Reads pm/span/off/seed from the caller. NAME is shown verbatim (set SIG_NAME).
_credits() {
    local NAME="$1" GH="${2:-}" L=${#1}
    local band title
    band=$(_pick "$seed" DISCO_NEON DISCO_CANDY DISCO_VAPOR RING RACE_GOLD FIRE_VIOLET)
    title=$(_pick "$(( seed+2 ))" 'CERTIFIED LEGEND' 'THE G.O.A.T.' '10x DEVELOPER' 'BUG SLAYER' 'CODE ROYALTY' 'ABSOLUTE UNIT' 'KEYBOARD WARRIOR' 'SHIP-IT CHAMPION' 'RUBBER-DUCK WHISPERER' 'STACK OVERFLOWER' 'CAFFEINE-POWERED HERO' 'TOUCHED GRASS ONCE')
    if   [ "$pm" -lt 150 ]; then local t=' ...mic check... ' tl lp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0      # 🎤 tap tap
        printf '%s🎤%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" SMOKE)" "$(_dots $(( span-lp-tl-2<0?0:span-lp-tl-2 )))"
    elif [ "$pm" -lt 300 ]; then local t=' ...drumroll... ' tl lp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0       # 🥁 build-up
        printf '%s🥁%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" FIRE_EMBER)" "$(_dots $(( span-lp-tl-2<0?0:span-lp-tl-2 )))"
    elif [ "$pm" -lt 380 ]; then local t=' INTRODUCING... ' tl lp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0       # 🔦 spotlights
        printf '%s🔦%s🔦%s' "$(_dots "$lp")" "$(_text "$t" "$off" "$band")" "$(_dots $(( span-lp-tl-4<0?0:span-lp-tl-4 )))"
    elif [ "$pm" -lt 520 ]; then local nm="$NAME" nl=$L fo lp rp                                                                  # 🌟 THE BIG REVEAL, name flashing
        [ $(( nl+6 )) -gt "$span" ] && { nm="${NAME:0:$(( span>7?span-7:1 ))}…"; nl=${#nm}; }
        fo=$(( off*3+pm/4 )); lp=$(( (span-nl-6)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-lp-nl-6 )); [ "$rp" -lt 0 ] && rp=0
        printf '%s🌟 %s 🌟%s' "$(_dots "$lp")" "$(_text "$nm" "$fo" "$band")" "$(_dots "$rp")"
    elif [ "$pm" -lt 840 ]; then local tt=" $title " tl lp fo                                                                     # 👑 a gloriously silly title (HELD ~4s, flashing)
        tl=${#tt}; [ $(( tl+4 )) -gt "$span" ] && { tt="${tt:0:$(( span>5?span-5:1 ))}…"; tl=${#tt}; }
        fo=$(( off*2+pm/5 )); lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0
        printf '%s👑%s👑%s' "$(_dots "$lp")" "$(_text "$tt" "$fo" RACE_GOLD)" "$(_dots $(( span-lp-tl-4<0?0:span-lp-tl-4 )))"
    elif [ "$pm" -lt 900 ]; then local s='' n=$span i; local -n BP="$band"; local bm=${#BP[@]} CR=(🎉 🙌 🤘 🎊 🥳)               # 🎉 the crowd goes WILD
        for ((i=0;i<n;i++)); do if [ $(( (i+off)%5 )) -eq 0 ]; then s+=$'\e[1m'"${CR[$(( (i/5+off)%5 ))]}"$'\e[0m'; ((i++)); else s+=$'\e[38;5;'"${BP[$(( (i+off)%bm ))]}"m'▀'; fi; done
        printf '%s%s' "$s" "$R"
    else local ct="$NAME · $title · beautiful_fun_claude" cl lp rp                                                                # 🎉 finale card: name + title + framework (held ~2s)
        cl=${#ct}; [ $(( cl+6 )) -gt "$span" ] && { ct="${ct:0:$(( span>7?span-7:1 ))}…"; cl=${#ct}; }
        lp=$(( (span-cl-6)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-lp-cl-6 )); [ "$rp" -lt 0 ] && rp=0
        printf '%s🎉 %s 🎉%s' "$(_dots "$lp")" "$(_text "$ct" "$off" "$band")" "$(_dots "$rp")"; fi
}

anim_frame() {
    local style="$1" pm="${2:-0}" w="${3:-80}"
    [[ "$pm" =~ ^[0-9]+$ ]] || pm=0; [ "$pm" -gt 1000 ] && pm=1000
    [[ "$w"  =~ ^[0-9]+$ ]] || w=80; [ "$w" -lt 30 ] && w=30
    local cap=${ANIM_MAXW:-180}; [ "$w" -gt "$cap" ] && w=$cap
    local seed=${ANIM_SEED:-0} off=$(( pm/9 + ${ANIM_SEED:-0} ))
    local span=$(( w-8 )); [ "$span" -lt 6 ] && span=6
    local pos=$(( pm*span/1000 )) i

    case "$style" in
        rainbow)     local n=$(( w-2 ))                                              # rainbow + a bright shimmer glint -> 🌈 payoff
                     if   [ "$pm" -lt 920 ]; then local s='' sweep; sweep=$(( pm*(n-1)/920 ))
                         for ((i=0;i<n;i++)); do local dd=$(( i-sweep )); [ "$dd" -lt 0 ] && dd=$(( -dd ))
                             if [ "$dd" -eq 0 ]; then s+=$'\e[1;38;5;231m''█'; elif [ "$dd" -le 2 ]; then s+=$'\e[1;38;5;195m''█'; else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'█'; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ $(( seed%2 )) -eq 0 ]; then local s='' i; for ((i=0;i<n;i++)); do if [ $(( (i+off)%6 )) -eq 0 ]; then s+=$'\e[1m''🌈'; ((i++)); else s+=$'\e[1;38;5;'"${RING[$(( (i+off)%NR ))]}"m'█'; fi; done; printf '%s%s' "$s" "$R"
                     else local s='' i; for ((i=0;i<n;i++)); do if [ $(( (i*7+off)%9 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''✨'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'█'; fi; done; printf '%s%s' "$s" "$R"; fi ;;
        nyan)        if   [ "$pm" -lt 900 ]; then local s='' tn; tn=$(( pm*(span-2)/900 )); [ "$tn" -gt $(( span-2 )) ] && tn=$(( span-2 )); [ "$tn" -lt 0 ] && tn=0   # 🐱 + rainbow stripe trail + ⭐
                         for ((i=0;i<tn;i++)); do if [ "$i" -lt $(( tn-1 )) ] && [ $(( (i+off)%7 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''⭐'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'▬'; fi; done
                         printf '%s%s🐱%s' "$s" "$R" "$(_dots $(( span-tn-2<0?0:span-tn-2 )))"
                     elif [ $(( seed%3 )) -eq 0 ]; then printf '%s🚀🐱' "$(_cycle $(( span-4<0?0:span-4 )) '▬' "$off" RING)"   # blast off to space
                     elif [ $(( seed%3 )) -eq 1 ]; then local s='' i; for ((i=0;i<span;i++)); do if [ $(( (i+off)%5 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''✨'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'▀'; fi; done; printf '%s%s' "$s" "$R"   # RAINBOW BOOM
                     else local t=' nyan~nyan~ ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🐱%s%s%s' "$(_cycle "$lp" '▬' "$off" RING)" "$(_text "$t" "$off" RING)" "$(_cycle "$rp" '▬' "$off" RING)"; fi ;;
        mouse)       local out=$(( seed%3 )) ms=$pos cz=$(( span-3 ))                 # 🐭 sprints after 🧀 — heist (catch / cat-steal / escape)
                     [ "$ms" -gt $(( cz-2 )) ] && ms=$(( cz-2 )); [ "$ms" -lt 0 ] && ms=0
                     if   [ "$pm" -lt 888 ]; then
                         printf '%s🐭%s🧀%s' "$(_fade "$ms" '∘' MOUSE_DUST R)" "$(_dots $(( cz-ms-2<0?0:cz-ms-2 )))" "$(_dots $(( span-cz-2<0?0:span-cz-2 )))"
                     elif [ "$pm" -lt 1000 ]; then
                         case "$out" in
                           1) printf '%s🐭💢🐱🧀%s' "$(_dots $(( cz-6<0?0:cz-6 )))" "$(_dots $(( span-cz-2<0?0:span-cz-2 )))" ;;
                           *) printf '%s🐭🧀%s' "$(_fade $(( cz-2<0?0:cz-2 )) '∘' MOUSE_DUST R)" "$(_dots $(( span-cz-2<0?0:span-cz-2 )))" ;;
                         esac
                     else case "$out" in
                           0) printf '%s🐭🧀😋%s' "$(_dots $(( cz-2<0?0:cz-2 )))" "$(_dots $(( span-cz-4<0?0:span-cz-4 )))" ;;
                           1) printf '💨🐭%s🐱😼🧀%s' "$(_dots $(( cz-6<0?0:cz-6 )))" "$(_dots $(( span-cz-6<0?0:span-cz-6 )))" ;;
                           *) printf '💨🐭%s🐱💢🧀%s' "$(_dots $(( cz-6<0?0:cz-6 )))" "$(_dots $(( span-cz-6<0?0:span-cz-6 )))" ;;
                         esac; fi ;;
        ufo)         if [ "$pm" -lt 820 ]; then _runner "$pos" 2 "$w" '🛸' ltr "$off" '=' TOX_NEON cycle   # 🛸 cruises, then ZAPS something
                     elif [ "$pm" -lt 920 ]; then local t=' bzzzt… ' tl lp; tl=${#t}; lp=$(( (w-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🛸%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" TOX_NEON)" "$(_dots $(( w-lp-tl-2<0?0:w-lp-tl-2 )))"
                     else local t; case "$(( seed%3 ))" in 0) t=' ⚡ZAP!⚡ 🐄→🛸 ' ;; 1) t=' 💨 NOPE, abort! 🛸 ' ;; *) t=' 🛸 we come in peace 🖖 ' ;; esac
                         local mw=${#t}; mw=$(( mw+4 )); local lp=$(( (w-mw)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( w-lp-mw )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" FLASH)" "$(_dots "$rp")"; fi ;;
        comet)       if   [ "$pm" -lt 850 ]; then _runner $(( span-pos )) 2 "$w" '☄' rtl "$off" '─' "$(_pick "$seed" ICE_GLACIER ICE_FROSTFIRE)" fade   # ☄ streaks in...
                     elif [ "$pm" -lt 950 ]; then printf '💥%s' "$(_cycle $(( w-2<0?0:w-2 )) '█' "$off" FIRE_CLASSIC)"               # IMPACT flash
                     else local t; case "$(( seed%3 ))" in 0) t=' 💥 KABOOM! ' ;; 1) t=' 🌠 make a wish ' ;; *) t=' 🦕 …oh. ' ;; esac
                         local dw=$(( ${#t}+2 )) lp rp; lp=$(( (span-dw)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-dw-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" FIRE_CLASSIC)" "$(_dots "$rp")"; fi ;;
        caterpillar) if [ "$pm" -lt 820 ]; then _runner $(( span-pos )) 2 "$w" '🐛' rtl "$off" '●' "$(_pick "$seed" FOREST_DEEP TOX_NEON)" cycle   # 🐛 crawls -> 🦋 metamorphosis
                     elif [ "$pm" -lt 920 ]; then printf '🐛💤%s' "$(_dots $(( w-4<0?0:w-4 )))"
                     else local t=' 🦋 TA-DA! ✨ '; local mw=${#t}; mw=$(( mw+4 )); local lp=$(( (w-mw)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( w-lp-mw )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" DISCO_CANDY)" "$(_dots "$rp")"; fi ;;
        fish)        if   [ "$pm" -lt 850 ]; then _runner $(( span-pos )) 2 "$w" '🐟' rtl "$off" '~' "$(_pick "$seed" OCEAN_SURF OCEAN_TEAL OCEAN_DUSK)" cycle   # 🐟 swims home...
                     elif [ "$pm" -lt 950 ]; then local t=" 🐟❓ what's this? " dw lp rp; dw=$(( ${#t}+4 )); lp=$(( (span-dw)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-dw-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" OCEAN_SURF)" "$(_dots "$rp")"
                     else local t; case "$(( seed%3 ))" in 0) t=' 🐟😋 yum! ' ;; 1) t=' 🐟🪝 …a BOOT?! ' ;; *) t=' 🐟💎 TREASURE! ' ;; esac
                         local dw=$(( ${#t}+4 )) lp rp; lp=$(( (span-dw)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-dw-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" OCEAN_SURF)" "$(_dots "$rp")"; fi ;;
        train)       if [ "$pm" -lt 820 ]; then _runner $(( span-pos )) 6 "$w" '🚂🚃🚃' rtl "$off" '°' SMOKE fade   # 🚂 chugs -> whistle -> tunnel
                     elif [ "$pm" -lt 920 ]; then local t=' CHOO CHOO! ' tl; tl=${#t}; printf '🚂%s%s' "$(_text "$t" "$off" SMOKE)" "$(_dots $(( w-tl-2<0?0:w-tl-2 )))"
                     else local t; case "$(( seed%3 ))" in 0) t='🚇💨 …gone! ' ;; *) t='🚂💨 ALL ABOARD! ' ;; esac
                         local mw=${#t}; mw=$(( mw+4 )); printf '%s%s' "$(_text "$t" "$off" RACE_STEEL)" "$(_dots $(( w-mw<0?0:w-mw )))"; fi ;;
        wave)        local n=$(( w-2 )) sp; sp="$(_pick "$seed" OCEAN_SURF OCEAN_TEAL OCEAN_DUSK)"; local -n SP="$sp"; local sm=${#SP[@]}   # surf's up: a roaming actor + silly climax
                     local act=$(( seed%4 )) glyph; case "$act" in 0) glyph='🏄' ;; 1) glyph='🦈' ;; 2) glyph='🐬' ;; *) glyph='🐙' ;; esac
                     if [ "$pm" -lt 820 ]; then local s='' apos=$(( pm*(n-2)/1000 )); [ "$apos" -lt 0 ] && apos=0
                         for ((i=0;i<n;i++)); do local col=${SP[$(( (i+off)%sm ))]}
                             if   [ "$i" -eq "$apos" ]; then s+=$'\e[1m'"$glyph"$'\e[0m'; ((i++))
                             elif [ $(( (i+off)%15 )) -eq 0 ]; then s+=$'\e[38;5;'"$col"m'🌊'; ((i++))
                             elif [ $(( (i*3+off)%41 )) -eq 0 ]; then s+=$'\e[38;5;81m''🐟'; ((i++))
                             elif [ $(( (i*5+off)%59 )) -eq 0 ]; then s+=$'\e[38;5;195m''🫧'; ((i++))
                             else s+=$'\e[38;5;'"$col"m'~'; fi; done
                         printf '%s%s' "$s" "$R"
                     else local t pal; case "$act" in 0) t=' 💥 WIPEOUT! ' pal=OCEAN_SURF ;; 1) t=' 🦈 dun-dun… SHARK! ' pal=FLASH ;; 2) t=' 🐬 SPLASH! ' pal=OCEAN_SURF ;; *) t=' 🐙 the KRAKEN! ' pal=FLASH ;; esac
                         local mw=${#t}; mw=$(( mw+2 )); local lp=$(( (n-mw)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( n-lp-mw )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" "$pal")" "$(_dots "$rp")"; fi ;;
        sparkle)     local hot=$(( pm/40+seed )) br; br=$(_pick "$seed" 226 231 201 51 213); local n=$(( w-2 ))   # twinkle field + a shooting star + a wish
                     if [ "$pm" -ge 880 ]; then local t; case "$(( seed%2 ))" in 0) t=' ✦ make a wish ✦ ' ;; *) t=' ⭐ you are a star ⭐ ' ;; esac
                         local mw=${#t}; mw=$(( mw+4 )); local lp=$(( (n-mw)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( n-lp-mw )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" FLASH)" "$(_dots "$rp")"
                     else local s='' star=$(( pm*(n-2)/1000 )); [ "$star" -lt 0 ] && star=0
                         for ((i=0;i<n;i++)); do
                             if   [ "$i" -eq "$star" ]; then s+=$'\e[1;38;5;231m''🌠'; ((i++))
                             elif [ $(( (i*7+hot)%13 )) -eq 0 ]; then s+=$'\e[1;38;5;'"$br"m'✦'; ((i++))
                             elif [ $(( (i*5+hot)%19 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''✨'; ((i++))
                             elif [ $(( (i*3+hot)%23 )) -eq 0 ]; then s+=$'\e[38;5;'"$br"m'·'
                             else s+=$'\e[38;5;236m''·'; fi; done
                         printf '%s%s' "$s" "$R"; fi ;;
        fireworks)   local c=$(( (w-2)/2 )); local fp; fp="$(_pick "$seed" FIRE_CLASSIC FIRE_EMBER FIRE_VIOLET)"
                     if [ "$pm" -lt 120 ]; then local fpos; fpos=$(( pm*c/120 )); [ "$fpos" -gt $(( c-1 )) ] && fpos=$(( c-1 )); [ "$fpos" -lt 0 ] && fpos=0   # the fuse visibly CLIMBS
                         printf '%s\e[1;38;5;226m!%s%s' "$(_fade "$fpos" '·' FIRE_EMBER R)" "$R" "$(_dots $(( w-fpos-1<0?0:w-fpos-1 )))"
                     elif [ "$pm" -lt 900 ]; then local s='' n=$(( w-2 )) j; local -n FP="$fp"; local fm=${#FP[@]}   # three staggered bursts + glowing debris
                         local cen=( $(( n/5 )) $(( n/2 )) $(( 4*n/5 )) ) ign=( 120 360 600 )
                         for ((i=0;i<n;i++)); do local ch='' boom=0
                             for j in 0 1 2; do [ "$pm" -lt "${ign[$j]}" ] && continue
                                 local r=$(( (pm-${ign[$j]})*(n/5)/430 )); [ "$r" -lt 0 ] && r=0
                                 local ctr=${cen[$j]} dd; dd=$(( i-ctr )); [ "$dd" -lt 0 ] && dd=$(( -dd ))
                                 if   [ "$dd" -eq 0 ]; then ch=$'\e[1;38;5;231m''💥'; boom=1; break
                                 elif [ "$dd" -le "$r" ]; then ch=$'\e[38;5;'"${FP[$(( (dd+off)%fm ))]}"m'─'; fi; done
                             if [ -n "$ch" ]; then s+="$ch"; [ "$boom" -eq 1 ] && ((i++)); else s+=$'\e[38;5;236m''·'; fi; done
                         printf '%s%s' "$s" "$R"
                     else printf '%s' "$(_cycle $(( w-2 )) '█' "$off" "$fp")"; fi ;;   # full-width fire-blast finale

        race)        local V=(🏎️ 🚗 🚙 🛻 🏍️ 🚜 🚓 🚕) ga gb; ga=${V[$(( seed%8 ))]}; gb=${V[$(( (seed/5+3)%8 ))]}; [ "$gb" = "$ga" ] && gb=${V[$(( (seed/5+4)%8 ))]}
                     local win=$(( seed%2 )) passes=$(( (seed*13+5)%7 ))      # lead changes: 0..6, random
                     local crash=0 crashpm=0 crasher=0
                     if [ $(( seed%4 )) -eq 0 ]; then crash=1; crashpm=$(( 400+(seed*7)%300 )); crasher=$(( (seed/3)%2 )); win=$(( crasher==0?1:0 )); fi
                     local tag='' extra=0
                     [ "$pm" -lt 130 ] && { tag="$(_text ' 3·2·1·GO! ' "$off" FIRE_CLASSIC)"; extra=13; }
                     [ "$pm" -ge 950 ] && { tag="$(_text ' 🏆WIN! ' "$off" RACE_GOLD)"; extra=9; }
                     local trk=$(( span-extra )); [ "$trk" -lt 6 ] && trk=6
                     local amp=$(( trk/6>3?trk/6:3 )) adv=$(( pm*trk/1000 )) wA=0
                     if [ "$pm" -lt 900 ]; then
                         if [ "$passes" -le 0 ]; then wA=$(( win==0 ? amp/3 : -(amp/3) ))   # wire-to-wire: winner leads throughout
                         else local per=$(( 1800/passes )); [ "$per" -lt 2 ] && per=2
                              local x=$(( pm%per )) h=$(( per/2 )); [ "$h" -lt 1 ] && h=1
                              wA=$(( x<h ? (2*amp*x)/h-amp : amp-(2*amp*(x-h))/h )); fi
                     fi
                     local posA=$(( adv+wA )) posB=$(( adv-wA ))
                     if [ "$crash" -eq 1 ] && [ "$pm" -ge "$crashpm" ]; then              # 💥 wipeout: freeze the crasher, swap its glyph
                         local cc=$(( crashpm*trk/1000 )) st=$(( pm-crashpm )) cg
                         if [ "$st" -lt 200 ]; then cg='💥'; elif [ "$st" -lt 430 ]; then cg='🌀'; else cg='🔥'; fi
                         if [ "$crasher" -eq 0 ]; then posA=$cc; ga="$cg"; else posB=$cc; gb="$cg"; fi
                     fi
                     if [ "$pm" -ge 900 ]; then
                         if [ "$crash" -eq 1 ]; then if [ "$crasher" -eq 0 ]; then posB=$trk; else posA=$trk; fi   # survivor takes the win
                         else local lead=$(( 2+(seed/2)%2 ))                              # photo finish: win by 2..3 cols
                             if [ "$win" -eq 0 ]; then posA=$trk; posB=$(( trk-lead )); else posB=$trk; posA=$(( trk-lead )); fi; fi
                     fi
                     posA=$(( posA<0?0:(posA>trk?trk:posA) )); posB=$(( posB<0?0:(posB>trk?trk:posB) ))
                     local cA=$(( trk-posA )) cB=$(( trk-posB )) lo hi glo ghi
                     if [ "$cA" -le "$cB" ]; then lo=$cA; glo=$ga; hi=$cB; ghi=$gb; else lo=$cB; glo=$gb; hi=$cA; ghi=$ga; fi
                     local mid=$(( hi-lo-1 )); [ "$mid" -lt 0 ] && mid=0; local post=$(( trk-hi )); [ "$post" -lt 0 ] && post=0; local winner=''; [ "$pm" -ge 950 ] && winner='💨'
                     printf '🏁%s%s%s%s%s%s%s' "$tag" "$(_dots "$lo")" "$glo" "$(_cycle "$mid" '━' "$off" RACE_STEEL)" "$ghi" "$winner" "$(_cycle "$post" '━' "$off" RACE_STEEL)" ;;

        fight)       local F=(🥊 🤺 🥷 🏹 🤖 👹 👺 🐉 🦖 🦂 🦅 🐅 🦁 🐺 🦍 🐻 🦈 🐲 👽 🦏) a b; a=${F[$(( seed%20 ))]}; b=${F[$(( (seed*7+5)%20 ))]}; [ "$b" = "$a" ] && b=${F[$(( (seed*7+6)%20 ))]}
                     local c=$(( span/2 )) win=$(( (seed/3)%2 ))
                     if   [ "$pm" -lt 200 ]; then local L=$(( pm*(c-3)/200 ))
                         printf '%s%s%s%s%s' "$(_dots "$L")" "$a" "$(_dots $(( span-2*L-4 )))" "$b" "$(_dots "$L")"
                     elif [ "$pm" -lt 340 ]; then printf '%s%s%s%s%s' "$(_dots $(( c-5 )))" "$a" "$(_text ' ⚔VS⚔ ' "$off" FIRE_CLASSIC)" "$b" "$(_dots $(( c-5 )))"
                     elif [ "$pm" -lt 470 ]; then printf '%s%s💥%s%s' "$(_dots $(( c-2 )))" "$a" "$b" "$(_dots $(( c-3 )))"
                     elif [ "$pm" -lt 620 ]; then local CL=(231 196 51) sc=${CL[$(( (pm/40)%3 ))]}
                         printf '%s%s\e[1;38;5;%dm💥💥💥%s%s%s' "$(_dots $(( c-5 )))" "$a" "$sc" "$R" "$b" "$(_dots $(( c-5 )))"
                     elif [ "$pm" -lt 800 ]; then local k=$(( 4+span/6 )) bn=$(( (pm-620)/45+1 ))
                         printf '%s%s%s💥%s%s%s' "$(_dots $(( c-k<0?0:c-k )))" "$a" "$(_cycle "$bn" '»' "$off" FIRE_CLASSIC)" "$(_cycle "$bn" '«' "$off" FIRE_CLASSIC)" "$b" "$(_dots $(( c-k<0?0:c-k )))"
                     else local w1 l1; if [ "$win" -eq 0 ]; then w1=$a; l1=$b; else w1=$b; l1=$a; fi
                         case "$(( seed%5 ))" in
                             0) printf '💥%s🏆 %s%s' "$w1" "$l1" "$(_dots $(( span-9 )))" ;;                                    # both blasted left
                             1) printf '%s%s 🏆%s💥' "$(_dots $(( span-9 )))" "$l1" "$w1" ;;                                   # both blasted right
                             2) printf '%s🏆%s💥💫💥%s💀%s' "$w1" "$(_dots $(( (span-14)/2 )))" "$(_dots $(( (span-14)/2 )))" "$l1" ;;  # blown apart
                             3) printf '%s%s🏆💨%s' "$(_dots $(( c-3 )))" "$w1" "$(_dots $(( span-c-5 )))" ;;                  # loser launched off-screen
                             *) printf '%s%s🏆%s%s💫💀' "$(_dots $(( c-3 )))" "$w1" "$(_text ' K.O.! ' "$off" FIRE_CLASSIC)" "$(_dots $(( c-12<0?0:c-12 )))" ;;
                         esac; fi ;;

        chase)       local PREY=(🐁 🐟 🐛 🐇 🐹 🦌 🐠 🦟 🐭 🦓 🐧 🐡) PRED=(🐈 🦈 🐦 🦊 🦉 🐺 🐙 🦎 🐍 🦁 🦭 🐬) ix=$(( seed%12 ))
                     local pr=${PREY[$ix]} pd=${PRED[$ix]} out=$(( seed%2 ))
                     local catch=$(( seed%4 )) cf                                   # catch timing: early/mid/late/escape
                     case "$catch" in 0) cf=670 ;; 1) cf=780 ;; 2) cf=890 ;; *) cf=1001 ;; esac
                     local tgt=$(( catch==3 ? 750 : cf )); [ "$tgt" -lt 1 ] && tgt=1
                     local march=$(( pm*span/1000 )) wide=$(( span/2>6?span/2:6 ))
                     local gap=$(( wide-(wide-1)*pm/tgt )); [ "$gap" -lt 1 ] && gap=1
                     local predcol=$(( span-march )); [ "$predcol" -gt "$span" ] && predcol=$span; [ "$predcol" -lt 0 ] && predcol=0
                     local preycol=$(( predcol-gap-2 )); [ "$preycol" -lt 0 ] && preycol=0
                     if [ "$catch" -ne 3 ] && [ "$pm" -ge "$cf" ]; then                  # CAUGHT — animate the munch (💥 GOTCHA → 😋 NOM → *burp*)
                         local cc st face cap cl; cc=$(( span - cf*span/1000 )); [ "$cc" -lt 0 ] && cc=0; [ "$cc" -gt $(( span-4 )) ] && cc=$(( span-4 )); st=$(( pm-cf ))
                         if [ "$st" -lt 130 ]; then face='💥' cap=' GOTCHA! '; elif [ "$st" -lt 260 ]; then face='😋' cap=' NOM NOM '; else face='😋' cap=' *burp* '; fi
                         cl=${#cap}; printf '%s%s%s%s%s' "$(_dots "$cc")" "$pd" "$face" "$(_text "$cap" "$off" FIRE_CLASSIC)" "$(_dots $(( span-cc-4-cl<0?0:span-cc-4-cl )))"
                     elif [ "$catch" -eq 3 ] && [ "$pm" -ge 900 ]; then                  # ESCAPE
                         local np=$(( preycol-(3+span/6) )); [ "$np" -lt 0 ] && np=0; local pdc=$(( predcol+2 )); [ "$pdc" -gt "$span" ] && pdc=$span
                         printf '💨%s%s%s%s💢%s' "$(_dots "$np")" "$pr" "$(_dots $(( pdc-np-2 )))" "$pd" "$(_dots $(( span-pdc )))"
                     else local lung=''; [ "$gap" -le 2 ] && lung='💨'; local aft=$(( span-preycol-gap-4 )); [ "$aft" -lt 0 ] && aft=0
                         printf '%s%s%s%s%s%s' "$(_dots "$preycol")" "$pr" "$(_cycle "$gap" '·' "$off" SMOKE)" "$pd" "$lung" "$(_dots "$aft")"; fi ;;

        party)       local n=$(( w-2 )) cp PR out=$(( seed%4 ))                       # themed confetti BUILDS -> 🎉 DROP
                     case "$out" in 0) PR=(🥳 🎉 🎈 🎁 🎂) ;; 1) PR=(🪩 🕺 💃 🎶 ✨) ;; 2) PR=(🤡 🎪 🐘 🎠 🎟) ;; *) PR=(🎆 🥂 ✨ 🎇 🍾) ;; esac
                     cp="$(_pick "$seed" DISCO_NEON DISCO_CANDY DISCO_VAPOR RING)"; local -n CP="$cp"; local cm=${#CP[@]}
                     if   [ "$pm" -lt 850 ]; then local out2='' i gap; gap=$(( 7-pm/170 )); [ "$gap" -lt 3 ] && gap=3
                         for ((i=0;i<n;i++)); do if [ $(( (i+off)%gap )) -eq 0 ]; then out2+=$'\e[1m'"${PR[$(( (i/gap+off)%${#PR[@]} ))]}"$'\e[0m'; ((i++)); else out2+=$'\e[38;5;'"${CP[$(( (i+off)%cm ))]}"m'▀'; fi; done
                         printf '%s' "$out2"
                     else local t=' 🎉 PARTY! 🎉 ' dw lp rp; dw=$(( ${#t}+4 )); lp=$(( (n-dw)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( n-dw-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_cycle "$lp" '▀' "$off" FLASH)" "$(_text "$t" "$off" FLASH)" "$(_cycle "$rp" '▀' "$off" FLASH)"; fi ;;
        dance)       local n=$(( w-2 )) cp DA out=$(( seed%3 )) cen=$(( (w-9)/2 ))     # dancers + ♪DANCE♪ BUILD -> 🪩 DROP
                     case "$out" in 0) DA=(🕺 💃 👯 🪩) ;; 1) DA=(🤖 🦾 ⚙ 🪩) ;; *) DA=(🦄 🌈 🦓 🪩) ;; esac
                     cp="$(_pick "$seed" DISCO_NEON DISCO_VAPOR RING)"; local -n CD="$cp"; local cm=${#CD[@]}
                     if   [ "$pm" -lt 850 ]; then local out2='' i txt; txt="$(_text '♪DANCE♪' "$off" RING)"
                         for ((i=0;i<n;i++)); do if [ "$i" -eq "$cen" ]; then out2+="$txt"; i=$(( i+8 )); continue; fi
                             if [ $(( (i+off)%4 )) -eq 0 ]; then out2+=$'\e[1m'"${DA[$(( (i/4+off)%${#DA[@]} ))]}"$'\e[0m'; ((i++)); else out2+=$'\e[38;5;'"${CD[$(( (i+off)%cm ))]}"m'▀'; fi; done
                         printf '%s%s' "$out2" "$R"
                     else local t=' 🪩 DROP THE BEAT 🪩 ' dw lp rp; dw=$(( ${#t}+4 )); [ "$dw" -gt "$n" ] && { t=' 🪩 DISCO! 🪩 '; dw=$(( ${#t}+4 )); }; lp=$(( (n-dw)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( n-dw-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_cycle "$lp" '▀' "$off" FLASH)" "$(_text "$t" "$off" FLASH)" "$(_cycle "$rp" '▀' "$off" FLASH)"; fi ;;

        converge)    local half=$(( (w-2)/2 )) fn cp out; fn=$(( pm*half/700 )); [ "$fn" -gt "$half" ] && fn=$half; cp="$(_pick "$seed" RING FIRE_CLASSIC ICE_GLACIER DISCO_NEON)"; out=$(( seed%4 ))
                     if [ "$pm" -lt 730 ]; then local mid=$(( (w-2)-2*fn )); [ "$mid" -lt 0 ] && mid=0
                         printf '%s%s%s' "$(_cycle "$fn" '█' "$off" "$cp")" "$(_dots "$mid")" "$(_cycle "$fn" '█' $((off+7)) "$cp")"
                     else local t pal dw; case "$out" in 0) t=' ✦BOOM✦ ' pal=FIRE_CLASSIC dw=10 ;; 1) t=' KABOOM! ' pal=FLASH dw=8 ;; 2) t=' FUSION! ' pal=ELECTRIC dw=8 ;; *) t=' ✦SMASH✦ ' pal=FIRE_VIOLET dw=10 ;; esac
                         local sw=$(( ((w-2)-dw)/2 )); [ "$sw" -lt 0 ] && sw=0; local rw=$(( (w-2)-dw-sw )); [ "$rw" -lt 0 ] && rw=0
                         printf '%s%s%s' "$(_cycle "$sw" '█' "$off" "$cp")" "$(_text "$t" "$off" "$pal")" "$(_cycle "$rw" '█' $((off+7)) "$cp")"; fi ;;
        marquee)     local MSGS=('>> CLAUDE CODE << keep shipping >> ' '++ stay caffeinated ++ touch grass ++ ' '~~ vibe coding ~~ small diffs win ~~ ' '== 0 bugs == 100% vibes == ' '<< commit << push << repeat << ' '** be unreasonably good ** ') band; band=$(_pick "$(( seed+2 ))" RING DISCO_NEON DISCO_VAPOR RACE_GOLD)
                     if   [ "$pm" -lt 900 ]; then local msg="${MSGS[$(( seed%6 ))]}" ml winw=$(( w-2 )) full='' start k; ml=${#msg}; [ "$ml" -lt 1 ] && ml=1
                         for ((k=0; k*ml < winw+ml; k++)); do full+="$msg"; done
                         start=$(( pm*(ml-1)/900 )); _text "${full:start:winw}" "$off" "$band"
                     else local t; case "$(( seed%3 ))" in 0) t=' 🚀 SHIP IT 🚀 ' ;; 1) t=' ✨ LGTM ✨ ' ;; *) t=' ☕ REFILL ☕ ' ;; esac
                         local dw=$(( ${#t}+4 )) lp rp; lp=$(( ((w-2)-dw)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( (w-2)-dw-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_cycle "$lp" '▰' "$off" FLASH)" "$(_text "$t" "$off" FLASH)" "$(_cycle "$rp" '▰' "$off" FLASH)"; fi ;;

        abduct)      local VIC=(🐄 🚜 🧍 🐑) v; v=${VIC[$(( seed%4 ))]}; local vc=$(( span/3 )) okk=$(( seed%3 ))
                     local beam; beam="$(_cycle 3 '┊' "$off" TOX_NEON)"
                     if   [ "$pm" -lt 180 ]; then local uc=$(( span - pm*(span-vc-8)/180 ))
                         printf '%s%s%s🛸%s' "$(_dots "$vc")" "$v" "$(_dots $(( uc-vc-2<0?0:uc-vc-2 )))" "$(_dots $(( span-uc<0?0:span-uc )))"
                     elif [ "$pm" -lt 400 ]; then local bl=$(( 1+(pm-180)/70 ))
                         printf '%s%s%s🛸%s' "$(_dots "$vc")" "$v" "$(_cycle "$bl" '┊' "$off" TOX_NEON)" "$(_dots $(( span-vc-4-bl<0?0:span-vc-4-bl )))"
                     elif [ "$pm" -lt 620 ]; then printf '%s%s%s🛸%s' "$(_dots "$vc")" "$(_cycle 1 '✦' "$off" TOX_NEON)" "$beam" "$(_dots $(( span-vc-6 )))"
                     elif [ "$pm" -lt 875 ]; then printf '%s%s%s🛸%s' "$(_dots "$vc")" "$(_cycle 2 '✦' "$off" TOX_NEON)" "$beam" "$(_dots $(( span-vc-8 )))"
                     elif [ "$okk" -gt 0 ]; then printf '%s%s🛸💨%s%s' "$(_dots "$vc")" "$(_cycle 2 '✦' "$off" TOX_NEON)" "$(_dots $(( span-vc-19<0?0:span-vc-19 )))" "$(_text ' ✦ABDUCTED✦ ' "$off" TOX_NEON)"
                     else printf '%s%s💢%s%s🛸' "$(_dots "$vc")" "$v" "$(_text ' ✦ESCAPED!✦ ' "$off" TOX_NEON)" "$(_dots $(( span-vc-16<0?0:span-vc-16 )))"; fi ;;

        duel)        local Lg='🤠' Rg='🥷' win=$(( seed%2 )) half=$(( span/2-2 )); [ "$half" -lt 1 ] && half=1
                     if   [ "$pm" -lt 110 ]; then printf '%s%s%s%s%s' "$Lg" "$(_dots "$half")" "$(_text ' 3 ' "$off" FIRE_CLASSIC)" "$(_dots "$half")" "$Rg"
                     elif [ "$pm" -lt 220 ]; then printf '%s%s%s%s%s' "$Lg" "$(_dots "$half")" "$(_text ' 2 ' "$off" FIRE_CLASSIC)" "$(_dots "$half")" "$Rg"
                     elif [ "$pm" -lt 330 ]; then printf '%s%s%s%s%s' "$Lg" "$(_dots "$half")" "$(_text ' 1 ' "$off" FIRE_CLASSIC)" "$(_dots "$half")" "$Rg"
                     elif [ "$pm" -lt 700 ]; then printf '%s💥%s%s%s💥%s' "$Lg" "$(_cycle $(( half-2 )) '─' "$off" FIRE_CLASSIC)" "$(_text ' FIRE! ' "$off" RACE_GOLD)" "$(_cycle $(( half-2 )) '─' "$off" FIRE_CLASSIC)" "$Rg"
                     else local rr=$(( seed%10 )) sh
                         if   [ "$rr" -eq 0 ]; then sh=$(( (span-18)/2 )); [ "$sh" -lt 0 ] && sh=0; printf '💀%s%s%s💀' "$(_dots "$sh")" "$(_text ' DOUBLE K.O.! ' "$off" FIRE_CLASSIC)" "$(_dots "$sh")"
                         elif [ "$win" -eq 0 ]; then sh=$(( (span-13)/2 )); [ "$sh" -lt 0 ] && sh=0; printf '🤠🎉%s%s%s💀' "$(_dots "$sh")" "$(_text ' BANG! ' "$off" FIRE_CLASSIC)" "$(_dots "$sh")"
                         else sh=$(( (span-13)/2 )); [ "$sh" -lt 0 ] && sh=0; printf '💀%s%s%s🎉🥷' "$(_dots "$sh")" "$(_text ' BANG! ' "$off" FIRE_CLASSIC)" "$(_dots "$sh")"; fi; fi ;;

        rocket)      local res=$(( seed%10 ))
                     if   [ "$pm" -lt 110 ]; then printf '🗼🚀%s%s' "$(_text ' T-3 ' "$off" FIRE_CLASSIC)" "$(_dots $(( span-7 )))"
                     elif [ "$pm" -lt 222 ]; then printf '🗼🚀%s%s' "$(_text ' T-2 ' "$off" FIRE_CLASSIC)" "$(_dots $(( span-7 )))"
                     elif [ "$pm" -lt 333 ]; then printf '🗼🚀%s🔥%s' "$(_text ' T-1 ' "$off" FIRE_EMBER)" "$(_dots $(( span-9 )))"
                     elif [ "$pm" -lt 444 ]; then printf '🗼🚀%s%s%s' "$(_text ' LIFTOFF! ' "$off" FIRE_EMBER)" "$(_cycle 2 '╿' "$off" FIRE_EMBER)" "$(_dots $(( span-13 )))"
                     elif [ "$pm" -lt 889 ]; then local rc=$(( (pm-444)*(span-4)/445 )); [ "$rc" -lt 0 ] && rc=0
                         printf '%s🚀%s' "$(_cycle "$rc" '╿' "$off" FIRE_EMBER)" "$(_dots $(( span-rc-2<0?0:span-rc-2 )))"
                     elif [ "$res" -lt 5 ]; then local fl; fl=$(_pick "$seed" '✨' '🌟')                       # ~50% clean orbit
                         printf '%s🚀%s%s' "$(_cycle $(( span-8 )) '╿' "$off" FIRE_EMBER)" "$fl" "$(_text ' ORBIT! ' "$off" ICE_GLACIER)"
                     elif [ "$res" -lt 8 ]; then local CL=(231 196 51) sc=${CL[$(( (pm/40)%3 ))]}            # ~30% rapid unscheduled disassembly
                         printf '%s\e[1;38;5;%dm💥💥💥%s%s%s' "$(_dots $(( span/2-6 )))" "$sc" "$R" "$(_cycle 3 '✺' "$off" FIRE_CLASSIC)" "$(_text ' RUD! ' "$off" FIRE_CLASSIC)"
                     else local ab; ab=$(_pick "$seed" '💨' '🧯')
                         printf '🗼🚀%s%s%s' "$(_text ' ABORT ' "$off" RACE_STEEL)" "$ab" "$(_dots $(( span-9 )))"; fi ;;

        pacman)      local out=$(( seed%3 )) pc=$pos fr=$(( span-2 )) gh gap mouth      # 😮 chomps pellets; 👻 closes in -> eats cherry / power-up / caught
                     [ "$pc" -gt $(( fr-2 )) ] && pc=$(( fr-2 )); [ "$pc" -lt 2 ] && pc=2
                     gh=$(( pc-4-pm/250 )); [ "$gh" -lt 0 ] && gh=0; gap=$(( pc-gh-2 )); [ "$gap" -lt 0 ] && gap=0
                     mouth=$( [ $(( (pm/111)%2 )) -eq 0 ] && printf '😮' || printf '😯' )
                     if   [ "$pm" -lt 1000 ]; then local pel=$(( span-gh-gap-6 )); [ "$pel" -lt 0 ] && pel=0
                         printf '%s👻%s%s%s🍒' "$(_dots "$gh")" "$(_dots "$gap")" "$mouth" "$(_cycle "$pel" '•' "$off" PAC_MAZE)"
                     elif [ "$out" -eq 0 ]; then printf '%s😋✨' "$(_dots $(( span-4<0?0:span-4 )))"                                 # gobbled the lot
                     elif [ "$out" -eq 1 ]; then printf '😨💨%s😋🍒' "$(_dots $(( span-8<0?0:span-8 )))"                            # POWER PELLET! ghost flees
                     else printf '👻💥😵%s' "$(_dots $(( span-6<0?0:span-6 )))"; fi ;;                                              # ghost got pac
        snake)       local g=$(( seed%4 )) len=$(( 2+pm/150 )) hd=$pos ap=$(( span-2 ))   # 🟢 snake grows, chases 🍎; eats it or hits the wall
                     [ "$hd" -gt $(( ap-2 )) ] && hd=$(( ap-2 )); [ "$hd" -lt 0 ] && hd=0; [ "$len" -gt "$hd" ] && len=$hd
                     if   [ "$pm" -lt 1000 ]; then
                         printf '%s%s🟢%s🍎%s' "$(_dots $(( hd-len<0?0:hd-len )))" "$(_fade "$len" 'o' SNAKE_GRN L)" "$(_dots $(( ap-hd-2<0?0:ap-hd-2 )))" "$(_dots $(( span-ap-2<0?0:span-ap-2 )))"
                     elif [ "$g" -ne 0 ]; then printf '%s🟢🍎😋%s' "$(_fade $(( ap-2<0?0:ap-2 )) 'o' SNAKE_GRN L)" "$(_dots $(( span-ap-4<0?0:span-ap-4 )))"
                     else printf '%s🟢💥%s' "$(_fade $(( ap-2<0?0:ap-2 )) 'o' SNAKE_GRN L)" "$(_dots $(( span-ap-2<0?0:span-ap-2 )))"; fi ;;
        meteor)      local save=$(( seed%3 )) c=$(( span/2 ))                              # ☄ incoming + 🚀 intercept that visibly MEET at centre -> SAVED / 💥 impact
                     if   [ "$pm" -lt 450 ]; then local mc; mc=$(( span-2 - pm*(span-6)/450 )); [ "$mc" -lt 4 ] && mc=4   # ☄ races in from the right
                         printf '🌍%s☄%s' "$(_dots $(( mc-2<0?0:mc-2 )))" "$(_fade $(( span-mc-2<0?0:span-mc-2 )) '─' ICE_FROSTFIRE L)"
                     elif [ "$pm" -lt 780 ]; then local rc mc; rc=$(( 2 + (pm-450)*(c-4)/330 )); [ "$rc" -gt $(( c-2 )) ] && rc=$(( c-2 )); mc=$(( span-2 - (pm-450)*(span-4-c)/330 )); [ "$mc" -lt $(( c+2 )) ] && mc=$(( c+2 ))   # 🚀 launches, both close on centre
                         printf '🌍%s🚀%s☄%s' "$(_dots $(( rc-2<0?0:rc-2 )))" "$(_dots $(( mc-rc-2<0?0:mc-rc-2 )))" "$(_dots $(( span-mc-2<0?0:span-mc-2 )))"
                     elif [ "$pm" -lt 900 ]; then local lp=$(( c-2 )); [ "$lp" -lt 0 ] && lp=0   # COLLISION at centre
                         printf '🌍%s\e[1;38;5;231m💥💥%s%s' "$(_dots "$lp")" "$R" "$(_dots $(( span-lp-6<0?0:span-lp-6 )))"
                     elif [ "$save" -lt 2 ]; then local t=' SAVED! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-6)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-6-lp )); [ "$rp" -lt 0 ] && rp=0   # 🚀 deflects it
                         printf '🌍%s🚀%s%s✨' "$(_dots "$lp")" "$(_text "$t" "$off" ICE_GLACIER)" "$(_dots "$rp")"
                     else printf '💥🌍🔥%s' "$(_cycle $(( span-6<0?0:span-6 )) '▒' "$off" FIRE_EMBER)"; fi ;;
        llama)       local out=$(( seed%3 )) vic; vic=$(_pick "$seed" '🧍' '🐑' '🤠' '🌵')   # 🦙 (right) spits a VISIBLE glob ● leftward; victim braces 😨 then SPLAT / MISS
                     local sp; sp=$(( (span-4) - pm*(span-7)/1000 )); [ "$sp" -lt 3 ] && sp=3; [ "$sp" -gt $(( span-4 )) ] && sp=$(( span-4 ))
                     local face="$vic"; [ "$pm" -ge 800 ] && [ "$out" -lt 2 ] && face='😨'
                     if   [ "$pm" -lt 1000 ]; then printf '%s%s\e[1;38;5;120m●%s%s🦙' "$face" "$(_dots $(( sp-3<0?0:sp-3 )))" "$(_fade 2 '~' SPIT R)" "$(_dots $(( span-sp-4<0?0:span-sp-4 )))"
                     elif [ "$out" -lt 2 ]; then printf '😵💦%s🦙' "$(_dots $(( span-6<0?0:span-6 )))"      # SPLAT — victim hit
                     else printf '😏%s🤮' "$(_dots $(( span-4<0?0:span-4 )))"; fi ;;                       # MISS — boomerangs into its own face
        bananapeel)  local fate=$(( seed%4 )) pose; pose=$(_pick "$seed" '🤕' '😵' '💫')      # 🚶 + 🍌 -> glorious wipeout (or rare dodge)
                     local bx=$(( span*2/3 )) wp; wp=$(( pm*(bx-2)/555 )); [ "$wp" -gt $(( bx-2 )) ] && wp=$(( bx-2 )); [ "$wp" -lt 0 ] && wp=0
                     if   [ "$pm" -lt 555 ]; then printf '%s🚶%s🍌%s' "$(_dots "$wp")" "$(_dots $(( bx-wp-2<0?0:bx-wp-2 )))" "$(_dots $(( span-bx-2<0?0:span-bx-2 )))"
                     elif [ "$pm" -lt 888 ]; then local fly; fly=$( [ "$pm" -lt 720 ] && printf '🤸' || printf '💫' )
                         printf '%s💥%s%s' "$(_dots $(( bx-2<0?0:bx-2 )))" "$fly" "$(_dots $(( span-bx-2<0?0:span-bx-2 )))"
                     elif [ "$fate" -lt 3 ]; then local lp=$(( (span-13)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s%s%s%s' "$pose" "$(_dots "$lp")" "$(_text ' WHOOPSIE! ' "$off" FIRE_CLASSIC)" "$(_dots $(( span-lp-13<0?0:span-lp-13 )))"
                     else local lp=$(( (span-11)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '🦘%s%s%s😎' "$(_dots "$lp")" "$(_text ' PHEW! ' "$off" BANANA)" "$(_dots $(( span-lp-11<0?0:span-lp-11 )))"; fi ;;
        trex)        local hlp=$(( seed%3 )) food; food=$(_pick "$seed" '🍪' '🍩' '🥨' '🍖')    # 🦖 (right, faces left) — tiny arms can't reach the snack on the left
                     local arm=$(( 1 + (pm/100)%5 ))   # arms PULSE: reach… retract… reach… (no longer frozen)
                     if   [ "$pm" -lt 850 ]; then printf '%s▔▔%s%s%s🦖' "$(_dots $(( span-12<0?0:span-12 )))" "$food" "$(_dots $(( 6-arm )))" "$(_cycle "$arm" '«' "$off" FIRE_EMBER)"
                     elif [ "$hlp" -lt 2 ]; then local lp rp; lp=$(( (span-19)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-19-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '▔▔%s%s%s%s😤🦖' "$food" "$(_dots "$lp")" "$(_text ' SO CLOSE! ' "$off" FIRE_CLASSIC)" "$(_dots "$rp")"
                     else local lp rp; lp=$(( (span-17)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-17-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🦅%s%s%s%s🦖' "$(_dots "$lp")" "$(_text ' TEAMWORK! ' "$off" RACE_GOLD)" "$(_dots "$rp")" "$food"; fi ;;
        selfdestruct) local forreal=$(( seed%6 ))                                          # 🚨 5..0 countdown that just says "...jk" (rarely: KABOOM)
                     if   [ "$pm" -lt 600 ]; then local num=$(( 5 - pm/110 )); [ "$num" -lt 0 ] && num=0
                         local na=$(( 1 + pm/220 )); [ "$na" -gt 3 ] && na=3; local body=" $num " bl; bl=${#body}
                         local lp=$(( (span-4*na-bl)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( span-4*na-bl-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s%s%s' "$(_solid "$na" '🚨' 196)" "$(_dots "$lp")" "$(_text "$body" "$off" FLASH)" "$(_dots "$rp")" "$(_solid "$na" '🚨' 196)"
                     elif [ "$pm" -lt 730 ]; then local lp=$(( (span-6)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s\e[2m . . .\e[0m%s' "$(_dots "$lp")" "$(_dots $(( span-lp-6<0?0:span-lp-6 )))"
                     elif [ "$forreal" -ne 0 ]; then local jk; jk=$(_pick "$seed" 'jk 😜' 'nvm 🙃' 'psych! 😏'); local txt="...$jk" dw; dw=$(( ${#txt}+1 ))
                         local lp=$(( (span-dw)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$txt" "$off" RING)" "$(_dots $(( span-lp-dw<0?0:span-lp-dw )))"
                     else printf '💥💥%s💥💥' "$(_cycle $(( span-8<0?0:span-8 )) '▰' "$off" FIRE_CLASSIC)"; fi ;;
        warp)        local lvl=$(( pm/170 )); [ "$lvl" -gt 5 ] && lvl=5                    # hyperdrive: star-streaks accelerate -> JUMP
                     local glyphs=(· ‧ - ─ ━ ═) mwm=${#WARP_BLU[@]} s='' g; g="${glyphs[$lvl]}"
                     if   [ "$pm" -lt 850 ]; then local thr=$(( 11 - pm/110 )); [ "$thr" -lt 2 ] && thr=2
                         for ((i=0;i<span;i++)); do if [ $(( (i*7+off)%thr )) -eq 0 ]; then s+=$'\e[1;38;5;'"${WARP_BLU[$(( (i+off)%mwm ))]}"m"$g"; else s+=$'\e[38;5;236m''·'; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ "$pm" -lt 940 ]; then printf '%s' "$(_solid "$span" '█' 231)"
                     else local rail=$(( (span-10)/2 )); [ "$rail" -lt 0 ] && rail=0
                         printf '%s%s%s' "$(_cycle "$rail" '═' "$off" WARP_BLU)" "$(_text ' ◈ JUMP ◈ ' "$off" WARP_BLU)" "$(_cycle $(( span-rail-10<0?0:span-rail-10 )) '═' $((off+4)) WARP_BLU)"; fi ;;
        decrypt)     local MSGS=('ACCESS GRANTED' 'LINK ESTABLISHED' 'KEY ACCEPTED' 'SYS ONLINE')   # matrix scramble resolves L->R into text
                     local msg="${MSGS[$(( seed%4 ))]}" pool='#%&@$01<>/=+*?:;~' pl; pl=${#pool}
                     local n=$span s='' mm=${#MATRIX[@]} lock ml; lock=$(( pm*n/1000 )); ml=${#msg}; [ "$ml" -gt "$n" ] && { msg="${msg:0:$n}"; ml=$n; }
                     local lpad=$(( (n-ml)/2 ))
                     for ((i=0;i<n;i++)); do
                         if   [ "$i" -lt "$lock" ]; then local rel=$(( i-lpad ))
                             if [ "$rel" -ge 0 ] && [ "$rel" -lt "$ml" ]; then s+=$'\e[1;38;5;46m'"${msg:rel:1}"; else s+=$'\e[38;5;28m''·'; fi
                         elif [ "$i" -eq "$lock" ]; then s+=$'\e[1;38;5;231m'"${pool:$(( (i+off)%pl )):1}"
                         else s+=$'\e[38;5;'"${MATRIX[$(( (i*5+off+seed)%mm ))]}"m"${pool:$(( (i*3+off)%pl )):1}"; fi; done
                     printf '%s%s' "$s" "$R" ;;
        radar)       local n=$span head; head=$(( pm*(n-1)/1000 )); [ "$head" -ge "$n" ] && head=$(( n-1 ))   # sonar sweep -> a ridiculous CONTACT
                     if   [ "$pm" -lt 760 ]; then local nb=$(( 2+seed%3 )) s='' j; local -a blip=(); for ((j=0;j<nb;j++)); do blip+=( $(( (seed*7+j*53+11)%n )) ); done
                         for ((i=0;i<n;i++)); do local d=$(( head-i )) isb=0
                             for ((j=0;j<nb;j++)); do [ "${blip[$j]}" -eq "$i" ] && isb=1; done
                             if   [ "$i" -eq "$head" ]; then s+=$'\e[1;38;5;231m''┃'
                             elif [ "$d" -ge 1 ] && [ "$d" -le 6 ]; then local ti=$(( (d-1)*9/6 )); s+=$'\e[38;5;'"${RADAR_GRN[$ti]}"m'╎'
                             elif [ "$isb" -eq 1 ]; then if [ "$d" -ge -1 ] && [ "$d" -le 2 ]; then s+=$'\e[1;38;5;231m''●'; else s+=$'\e[38;5;28m''◦'; fi
                             else s+=$'\e[38;5;22m''·'; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ "$pm" -lt 850 ]; then local t=' *ping!* ' tl lp; tl=${#t}; lp=$(( (n-tl)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" RADAR_GRN)" "$(_dots $(( n-lp-tl<0?0:n-lp-tl )))"
                     elif [ "$pm" -lt 940 ]; then local t=' ◈ CONTACT! ◈ ' tl lp; tl=${#t}; lp=$(( (n-tl)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" FLASH)" "$(_dots $(( n-lp-tl<0?0:n-lp-tl )))"
                     else local rv; case "$(( seed%5 ))" in 0) rv=' …a 🦆?! ' ;; 1) rv=' 🛸 THEY ARE HERE ' ;; 2) rv=' 🐙 KRAKEN!! ' ;; 3) rv=' 🍕 …pizza? ' ;; *) rv=' …nothing 🥱 ' ;; esac
                         local mw=${#rv}; mw=$(( mw+2 )); local lp=$(( (n-mw)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( n-lp-mw )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s' "$(_dots "$lp")" "$(_text "$rv" "$off" RING)" "$(_dots "$rp")"; fi ;;
        helix)       local n=$span s='' mc=${#HUD_CYAN[@]} mp=${#PLASMA[@]} per half out=$(( seed%5 ))   # DNA helix scroll -> SEQUENCED! / …MUTATION?!
                     per=$(( 6+seed%3 )); half=$(( per/2 )); local up=(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈)
                     if   [ "$pm" -lt 900 ]; then
                         for ((i=0;i<n;i++)); do local ph=$(( (i+off)%per )) a b; a=$(( ph*8/per )); b=$(( ((ph+half)%per)*8/per )); [ "$a" -gt 7 ] && a=7; [ "$b" -gt 7 ] && b=7
                             if   [ "$ph" -eq 0 ] || [ "$ph" -eq "$half" ]; then s+=$'\e[1;38;5;231m''═'
                             elif [ "$ph" -lt "$half" ]; then s+=$'\e[38;5;'"${HUD_CYAN[$(( (i+off)%mc ))]}"m"${up[$a]}"
                             else s+=$'\e[38;5;'"${PLASMA[$(( (i+off)%mp ))]}"m"${up[$b]}"; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ "$out" -lt 4 ]; then local t=' SEQUENCED! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🧬%s%s%s' "$(_cycle "$lp" '═' "$off" HUD_CYAN)" "$(_text "$t" "$off" HUD_CYAN)" "$(_cycle "$rp" '═' "$off" HUD_CYAN)"
                     else local t=' …MUTATION?! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🧬%s%s%s🔬' "$(_dots "$lp")" "$(_text "$t" "$off" FIRE_CLASSIC)" "$(_dots "$rp")"; fi ;;
        boot)        local n=$span                                                          # holographic boot: subsystems report -> SYSTEM ONLINE
                     if [ "$pm" -ge 920 ]; then local BAN=(' SYSTEM ONLINE ' ' ALL SYSTEMS GO ' ' READY ') b bl rail
                         b="${BAN[$(( seed%3 ))]}"; bl=${#b}; rail=$(( (n-bl)/2 )); [ "$rail" -lt 0 ] && rail=0
                         printf '%s%s%s' "$(_cycle "$rail" '─' "$off" HUD_CYAN)" "$(_text "$b" "$off" HUD_CYAN)" "$(_cycle $(( n-rail-bl<0?0:n-rail-bl )) '─' $((off+3)) HUD_CYAN)"
                     else local SUB=(CORE MEM NET GPU AI) si=$(( pm*5/1000 )); [ "$si" -gt 4 ] && si=4
                         local pct=$(( pm/10 )) lab="${SUB[$si]}" okf=$(( (pm/111)%2 )) tag
                         if [ "$okf" -eq 0 ]; then tag=" ${pct}% ${lab} [OK]"; else tag=" ${pct}% ${lab}"; fi
                         local tl=${#tag} barw bf; barw=$(( n-tl )); [ "$barw" -lt 4 ] && barw=4; bf=$(( pm*barw/1000 )); [ "$bf" -gt "$barw" ] && bf=$barw
                         printf '%s%s\e[1;38;5;46m%s%s' "$(_fade "$bf" '▰' HUD_CYAN R)" "$(_solid $(( barw-bf )) '▱' 23)" "$tag" "$R"; fi ;;
        computa)     local pre='COMPUTA, MAKE THESE claude bfc USERS SUPA ' mid=' AND ' kw rw msg   # a robot dutifully runs a wholesome command
                     kw=$(_pick "$seed" kind sweet warm nice good calm gentle caring cheery friendly humble lovely happy jolly chill wholesome)
                     rw=$(_pick "$(( seed*7+3 ))" respectful thoughtful gracious generous patient courteous wonderful delightful mindful polite pleasant helpful supportive civil decent)
                     msg="$pre$kw$mid$rw"
                     if   [ "$pm" -lt 140 ]; then local t=' *beep boop* ' tl lp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🤖%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" ELECTRIC)" "$(_dots $(( span-lp-tl-2<0?0:span-lp-tl-2 )))"
                     elif [ "$pm" -lt 300 ]; then local t=' NEW COMMAND! ' tl lp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🤖%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" FLASH)" "$(_dots $(( span-lp-tl-2<0?0:span-lp-tl-2 )))"
                     elif [ "$pm" -lt 450 ]; then local t=' COMPUTING... ' tl lp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🤖%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" ELECTRIC)" "$(_dots $(( span-lp-tl-2<0?0:span-lp-tl-2 )))"
                     elif [ "$pm" -lt 860 ]; then local ml=${#msg} gy=$'\e[38;5;250m' cp                       # the command (held ~3s); wholesome words flash
                         cp="$gy$pre$(_text "$kw" "$off" FLASH)$gy$mid$(_text "$rw" "$((off+4))" DISCO_NEON)$R"
                         if   [ $(( ml+6 )) -le "$span" ]; then local tot=$(( ml+6 )) lp rp; lp=$(( (span-tot)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-lp-tot )); [ "$rp" -lt 0 ] && rp=0
                             printf '%s🤖 %s 🤖%s' "$(_dots "$lp")" "$cp" "$(_dots "$rp")"
                         elif [ $(( ml+3 )) -le "$span" ]; then local lp; lp=$(( (span-ml-3)/2 )); [ "$lp" -lt 0 ] && lp=0   # keep ONE 🤖 when the full framing won't fit
                             printf '%s🤖 %s%s' "$(_dots "$lp")" "$cp" "$(_dots $(( span-lp-ml-3<0?0:span-lp-ml-3 )))"
                         elif [ "$ml" -le "$span" ]; then local lp; lp=$(( (span-ml)/2 )); [ "$lp" -lt 0 ] && lp=0
                             printf '%s%s%s' "$(_dots "$lp")" "$cp" "$(_dots $(( span-lp-ml<0?0:span-lp-ml )))"
                         else printf '%s' "$(_text "${msg:0:$(( span>1?span-1:1 ))}…" "$off" FLASH)"; fi
                     elif [ "$pm" -lt 950 ]; then local t=' EXECUTED! ' tl lp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🤖👍%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" TOX_NEON)" "$(_dots $(( span-lp-tl-4<0?0:span-lp-tl-4 )))"
                     else local fin=" be $kw & $rw! " fl lp; fl=${#fin}; [ $(( fl+8 )) -gt "$span" ] && { fin=" $kw! "; fl=${#fin}; }   # wholesome finale 💛
                         lp=$(( (span-fl-8)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🤖💛%s💛🤖%s' "$(_dots "$lp")" "$(_text "$fin" "$off" DISCO_CANDY)" "$(_dots $(( span-lp-fl-8<0?0:span-lp-fl-8 )))"; fi ;;
        lightsaber)  local c=$(( span/2 )) win=$(( seed%2 )) twist=$(( seed%6 ))                        # ⚔ blades clash, random winner, "NOOO!"
                     if   [ "$pm" -lt 330 ]; then local bl gap; bl=$(( 1 + pm*(c-3)/330 )); [ "$bl" -lt 1 ] && bl=1; [ "$bl" -gt $(( c-2 )) ] && bl=$(( c-2 )); gap=$(( span-2-2*bl )); [ "$gap" -lt 0 ] && gap=0
                         printf '▮%s%s%s▮' "$(_fade "$bl" '━' SABER_BLU R)" "$(_dots "$gap")" "$(_fade "$bl" '━' SABER_RED L)"
                     elif [ "$pm" -lt 780 ]; then local bl rb CL=(231 226 196 51) sc; bl=$(( (span-4)/2 )); [ "$bl" -lt 0 ] && bl=0; rb=$(( span-4-bl )); [ "$rb" -lt 0 ] && rb=0; sc=${CL[$(( (pm/40)%4 ))]}
                         printf '▮%s\e[1;38;5;%dm💥%s%s%s▮' "$(_cycle "$bl" '━' "$off" SABER_BLU)" "$sc" "$R" "$(_cycle "$rb" '━' "$off" SABER_RED)"
                     elif [ "$twist" -eq 0 ]; then local t=' DISARMED?! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🤺%s%s%s🤺' "$(_dots "$lp")" "$(_text "$t" "$off" RACE_GOLD)" "$(_dots "$rp")"
                     else local t=' NOOO! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0   # winner's blade fills the bar
                         if [ "$win" -eq 0 ]; then printf '🎉%s%s%s💀' "$(_cycle "$lp" '━' "$off" SABER_BLU)" "$(_text "$t" "$off" SABER_BLU)" "$(_cycle "$rp" '━' "$off" SABER_BLU)"
                         else printf '💀%s%s%s🎉' "$(_cycle "$lp" '━' "$off" SABER_RED)" "$(_text "$t" "$off" SABER_RED)" "$(_cycle "$rp" '━' "$off" SABER_RED)"; fi; fi ;;
        deathstar)   local fate=$(( seed%6 ))                                                            # 🌑 superlaser charges -> FIRE -> BOOM / "that's no moon"
                     if   [ "$pm" -lt 450 ]; then local ch; ch=$(( 2 + pm/45 )); [ "$ch" -gt $(( span-4 )) ] && ch=$(( span-4 ))
                         printf '🌑%s%s🌍' "$(_cycle "$ch" '·' "$off" LASER_GRN)" "$(_dots $(( span-ch-4<0?0:span-ch-4 )))"
                     elif [ "$pm" -lt 840 ]; then local bh; bh=$(( (pm-450)*(span-4)/390 )); [ "$bh" -lt 0 ] && bh=0; [ "$bh" -gt $(( span-4 )) ] && bh=$(( span-4 ))
                         printf '🌑%s%s🌍' "$(_cycle "$bh" '━' "$off" LASER_GRN)" "$(_dots $(( span-bh-4<0?0:span-bh-4 )))"
                     elif [ "$fate" -lt 4 ]; then local t=' ☄ BOOM ☄ ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0   # beam connects -> planet becomes debris
                         printf '🌑%s%s%s💥' "$(_cycle "$lp" '━' "$off" LASER_GRN)" "$(_text "$t" "$off" FLASH)" "$(_cycle "$rp" '▰' "$off" FIRE_CLASSIC)"
                     elif [ "$fate" -eq 4 ]; then printf '🌑%s💨😎' "$(_cycle $(( span-6<0?0:span-6 )) '━' "$off" LASER_GRN)"
                     else local t=" THAT'S NO MOON " tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s🌝%s' "$(_dots "$lp")" "$(_text "$t" "$off" ICE_GLACIER)" "$(_dots "$rp")"; fi ;;
        yoda)        local res=$(( seed%5 ))                                                             # 🧎 Yoda (right, faces left) raises a big X-wing <==[X]==} from the swamp
                     if   [ "$pm" -lt 200 ]; then                                                        # establishing shot: 🌳 swamp, sunk X-wing [X], Luke 🧍, Yoda 🧎
                         printf '🌳%s[X]%s🧍 🧎' "$(_cycle 3 '≈' "$off" OCEAN_TEAL)" "$(_cycle $(( span-13<0?0:span-13 )) '≈' "$off" OCEAN_TEAL)"
                     elif [ "$pm" -lt 380 ]; then local t=' do or do not ' tl lp rp; tl=${#t}; [ $(( tl+7 )) -gt "$span" ] && { t="${t:0:$(( span-8>1?span-8:1 ))}…"; tl=${#t}; }; lp=$(( (span-tl-7)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-7-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🌳%s%s%s🧍 🧎' "$(_dots "$lp")" "$(_text "$t" "$off" ICE_GLACIER)" "$(_dots "$rp")"
                     elif [ "$pm" -lt 620 ]; then local sh; sh=$(( 2 + (pm-380)*(span-18)/240 )); [ "$sh" -lt 2 ] && sh=2; [ "$sh" -gt $(( span-16 )) ] && sh=$(( span-16 )); [ "$sh" -lt 0 ] && sh=0   # lift the big X-wing on a Force shimmer
                         printf '🌳%s<==[X]==}%s🧍 🧎' "$(_cycle "$sh" '‧' "$off" ICE_GLACIER)" "$(_dots $(( span-sh-16<0?0:span-sh-16 )))"
                     elif [ "$pm" -lt 800 ]; then local t=' there is no try ' tl lp rp; tl=${#t}; [ $(( tl+7 )) -gt "$span" ] && { t="${t:0:$(( span-8>1?span-8:1 ))}…"; tl=${#t}; }; lp=$(( (span-tl-7)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-7-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '✨%s%s%s🧍 🧎' "$(_dots "$lp")" "$(_text "$t" "$off" RACE_GOLD)" "$(_dots "$rp")"
                     elif [ "$res" -lt 4 ]; then local t=' WIZARD! ' tl lp rp; tl=${#t}; [ $(( tl+12 )) -gt "$span" ] && { t="${t:0:$(( span-13>1?span-13:1 ))}…"; tl=${#t}; }; lp=$(( (span-tl-12)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-12-lp )); [ "$rp" -lt 0 ] && rp=0   # blastoff! Luke 🧍 + R2D2 🤖 aboard
                         printf '<=[🧍🤖]=}%s%s%s🧎' "$(_dots "$lp")" "$(_text "$t" "$off" RACE_GOLD)" "$(_dots "$rp")"
                     else local t=' …cannot be done ' tl lp rp; tl=${#t}; [ $(( tl+10 )) -gt "$span" ] && { t="${t:0:$(( span-11>1?span-11:1 ))}…"; tl=${#t}; }; lp=$(( (span-tl-10)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-10-lp )); [ "$rp" -lt 0 ] && rp=0   # flop: sinks back 💦
                         printf '💦[X]%s%s%s🧍 🧎' "$(_dots "$lp")" "$(_text "$t" "$off" OCEAN_DUSK)" "$(_dots "$rp")"; fi ;;
        titrate)     local roll=$(( seed%8 )) out pn dmax                                                # 🧪 drip titrant -> pink deepens -> undershoot / just-right / over / WAY over
                     if   [ "$roll" -lt 2 ]; then out=0; pn=PH_PINK; dmax=2          # UNDERSHOOT — too little, stays pale
                     elif [ "$roll" -lt 5 ]; then out=1; pn=PH_PINK; dmax=5          # JUST RIGHT — faint permanent pink
                     elif [ "$roll" -lt 7 ]; then out=2; pn=PH_PINK; dmax=9          # SLIGHT OVER — a touch too much
                     else out=3; pn=PH_DEEP; dmax=11; fi                             # WAY OVER — deep magenta/violet
                     local -n PALN="$pn"; local mlen=${#PALN[@]}; [ "$dmax" -ge "$mlen" ] && dmax=$(( mlen-1 ))
                     local sw; sw=$( [ $(( (pm/111)%2 )) -eq 0 ] && printf '◐' || printf '◑' )
                     if   [ "$pm" -lt 860 ]; then local body=$(( span-3 )) di col lvl; di=$(( pm*dmax/860 )); [ "$di" -gt "$dmax" ] && di=$dmax; [ "$di" -lt 0 ] && di=0; col=${PALN[$di]}
                         lvl=$(( pm*body/860 )); [ "$lvl" -gt "$body" ] && lvl=$body; [ "$lvl" -lt 0 ] && lvl=0   # the pink visibly RISES toward the endpoint
                         printf '🧪\e[1;38;5;87m%s\e[1;38;5;231m°%s%s%s' "$sw" "$(_solid "$lvl" '▒' "$col")" "$(_dots $(( body-lvl-1<0?0:body-lvl-1 )))" "$R"
                     else local t gl bk1 bk2 ec col; col=${PALN[$dmax]}
                         case "$out" in 0) t=' …add more ' gl='▒' bk1='😕' bk2='' ;; 1) t=' ENDPOINT! ' gl='▒' bk1='🎯' bk2='' ;; 2) t=' …a touch over ' gl='▓' bk1='😬' bk2='' ;; *) t=' WAY OVERSHOT!! ' gl='█' bk1='🍷' bk2='💀' ;; esac
                         local tl=${#t}; ec=2; [ -n "$bk2" ] && ec=4; [ $(( tl+ec )) -gt "$span" ] && { t=' OVERSHOT!! '; tl=${#t}; }
                         local lp=$(( (span-tl-ec)/2 )); [ "$lp" -lt 0 ] && lp=0; local rp=$(( span-tl-ec-lp )); [ "$rp" -lt 0 ] && rp=0
                         if [ -n "$bk2" ]; then printf '%s%s%s%s%s' "$bk1" "$(_solid "$lp" "$gl" "$col")" "$(_text "$t" "$off" "$pn")" "$(_solid "$rp" "$gl" "$col")" "$bk2"
                         else printf '%s%s%s%s' "$bk1" "$(_solid "$lp" "$gl" "$col")" "$(_text "$t" "$off" "$pn")" "$(_solid "$rp" "$gl" "$col")"; fi; fi ;;
        flametest)   local e=$(( seed%8 )) gag ramp sym; gag=$(( seed%5==0 ? 1 : 0 ))   # 🔥 flame burns the element's REAL colour (radiating from the wire) -> surprise reveal
                     sym="${FLAME_SYM[$e]}"; ramp="${FLAME_RAMP[$e]}"; [ "$gag" -eq 1 ] && { ramp=FLAME_NA; sym=Na; }
                     local -n RP="$ramp"; local m=${#RP[@]}
                     if   [ "$pm" -lt 110 ]; then local t=' dip the loop… ' tl lp; tl=${#t}; [ $(( tl+2 )) -gt "$span" ] && { t=' dip… '; tl=${#t}; }; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '🔥%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" SMOKE)" "$(_dots $(( span-lp-tl-2<0?0:span-lp-tl-2 )))"
                     elif [ "$pm" -lt 360 ]; then local n=$(( span-2 )) c r s='' i; c=$(( n/2 )); r=$(( pm*c/360 )); [ "$r" -lt 1 ] && r=1   # plume radiates outward from the centre wire
                         for ((i=0;i<n;i++)); do local d=$(( i-c )); [ "$d" -lt 0 ] && d=$(( -d ))
                             if [ "$d" -le "$r" ]; then local idx gl; idx=$(( d*(m-1)/(r>0?r:1) )); [ "$idx" -ge "$m" ] && idx=$(( m-1 ))
                                 if [ $(( d*3 )) -le "$r" ]; then gl='█'; elif [ $(( d*2 )) -le "$r" ]; then gl='▓'; elif [ $(( d*3 )) -le $(( 2*r )) ]; then gl='▒'; else gl='░'; fi
                                 s+=$'\e[38;5;'"${RP[$idx]}"m"$gl"
                             else s+=$'\e[38;5;236m''·'; fi; done
                         printf '🔥%s%s' "$s" "$R"
                     elif [ "$pm" -lt 650 ]; then local g; g=$(_pick "$(( seed+pm/110 ))" 'Cu?' 'Ba?' 'Sr?' 'K??' 'Li?' 'Ca?' 'B??'); local t=" $g what colour?? " tl lp; tl=${#t}; [ $(( tl+2 )) -gt "$span" ] && { t=" $g …?? "; tl=${#t}; }; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '🔥%s%s%s' "$(_cycle "$lp" '▀' "$off" "$ramp")" "$(_text "$t" "$off" "$ramp")" "$(_cycle $(( span-lp-tl-2<0?0:span-lp-tl-2 )) '▀' $((off+3)) "$ramp")"
                     elif [ "$pm" -lt 900 ]; then local n=$(( span-2 )) c s='' i; c=$(( n/2 ))   # full bloom, FLICKERING like real flame
                         for ((i=0;i<n;i++)); do local d=$(( i-c )); [ "$d" -lt 0 ] && d=$(( -d )); local idx gl; idx=$(( d*(m-1)/(c>0?c:1) )); [ "$idx" -ge "$m" ] && idx=$(( m-1 ))
                             case $(( (i*3+off)%4 )) in 1) gl='▓' ;; 3) gl='▒' ;; *) gl='█' ;; esac; s+=$'\e[38;5;'"${RP[$idx]}"m"$gl"; done
                         printf '🔥%s%s' "$s" "$R"
                     elif [ "$gag" -eq 1 ]; then local t=' …just SODIUM ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🔥%s%s%s🧂' "$(_solid "$lp" '█' 226)" "$(_text "$t" "$off" FLAME_NA)" "$(_solid "$rp" '█' 226)"
                     else local t=" IT'S $sym! " tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🔥%s%s%s' "$(_cycle "$lp" '█' "$off" "$ramp")" "$(_text "$t" "$off" "$ramp")" "$(_cycle "$rp" '█' "$off" "$ramp")"; fi ;;
        ribosome)    local out=$(( seed%5 ))                                                             # 🧬 ribosome builds a rainbow protein -> FOLDED! / STOP CODON
                     if   [ "$pm" -lt 820 ]; then local s='' rc=$pos j; [ "$rc" -gt $(( span-1 )) ] && rc=$(( span-1 ))
                         s="$(_cycle "$rc" '●' "$off" RING)"$'\e[1;38;5;231m''⊙'
                         local m=$(( span-rc-1 )); for ((j=0;j<m;j++)); do if [ $(( j%4 )) -eq 3 ]; then s+=$'\e[38;5;238m''·'; else s+=$'\e[38;5;240m''─'; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ "$pm" -lt 920 ]; then printf '%s' "$(_cycle "$span" '●' "$off" GFP_GLOW)"
                     elif [ "$out" -ne 4 ]; then local t=' PROTEIN! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🧬%s%s%s' "$(_cycle "$lp" '●' "$off" GFP_GLOW)" "$(_text "$t" "$off" GFP_GLOW)" "$(_cycle "$rp" '●' "$off" GFP_GLOW)"
                     else local t=' STOP CODON?! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🛑%s%s%s😅' "$(_dots "$lp")" "$(_text "$t" "$off" FIRE_CLASSIC)" "$(_dots "$rp")"; fi ;;
        benzene)     local out=$(( seed%3 )) cp ring; cp=$(_pick "$seed" DISCO_NEON DISCO_VAPOR DISCO_CANDY)   # ⏣ benzene ring SPINS across -> AROMATIC / RESONANCE / DELOCALIZED
                     ring=$( [ $(( (pm/55)%2 )) -eq 0 ] && printf '⏣' || printf '⌬' )
                     if   [ "$pm" -lt 670 ]; then local rc=$pos; [ "$rc" -gt $(( span-1 )) ] && rc=$(( span-1 ))
                         printf '%s\e[1;38;5;201m%s%s%s' "$(_cycle "$rc" '◦' "$off" "$cp")" "$ring" "$R" "$(_dots $(( span-rc-1<0?0:span-rc-1 )))"
                     elif [ "$out" -eq 0 ]; then local t=' AROMATIC! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s💅' "$(_cycle "$lp" '◦' "$off" "$cp")" "$(_text "$t" "$off" DISCO_CANDY)" "$(_cycle "$rp" '◦' "$off" "$cp")"
                     elif [ "$out" -eq 1 ]; then local t=' RESONANCE!! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s💫' "$(_cycle "$lp" '⌬' "$off" "$cp")" "$(_text "$t" "$off" DISCO_VAPOR)" "$(_cycle "$rp" '⏣' "$off" "$cp")"
                     else local t=' DELOCALIZED~ ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '%s%s%s✨' "$(_cycle "$lp" '◦' "$off" "$cp")" "$(_text "$t" "$off" RING)" "$(_cycle "$rp" '◦' "$off" "$cp")"; fi ;;
        r2d2)        local out=$(( seed%6 )) dz=$(( span-2 ))                                            # ╒◉╕ astromech rolls in, holograms, zaps the blast-door
                     if   [ "$pm" -lt 220 ]; then local t=' *boop-beep* ' tl lp; tl=${#t}; [ $(( tl+5 )) -gt "$span" ] && { t=' beep! '; tl=${#t}; }; lp=$(( (span-tl-5)/2 )); [ "$lp" -lt 0 ] && lp=0
                         printf '╒◉╕%s%s%s║▒' "$(_dots "$lp")" "$(_text "$t" "$off" ELECTRIC)" "$(_dots $(( span-tl-lp-5<0?0:span-tl-lp-5 )))"
                     elif [ "$pm" -lt 560 ]; then local rc; rc=$(( pm*(dz-5)/560 )); [ "$rc" -lt 0 ] && rc=0; [ "$rc" -gt $(( dz-5 )) ] && rc=$(( dz-5 ))
                         printf '%s╒◉╕%s║▒' "$(_fade "$rc" '∿' R2_BLUE R)" "$(_dots $(( span-rc-5<0?0:span-rc-5 )))"
                     elif [ "$pm" -lt 720 ]; then local t=' help me… ' tl lp; tl=${#t}; [ $(( tl+7 )) -gt "$span" ] && { t=' help! '; tl=${#t}; }; lp=$(( span-tl-7 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s🧍%s╒◉╕║▒' "$(_dots "$lp")" "$(_text "$t" "$off" HUD_CYAN)"
                     elif [ "$pm" -lt 900 ]; then local ac; ac=$(( 2+(pm-720)*6/180 )); [ "$ac" -gt 8 ] && ac=8; local lp=$(( span-ac-7 )); [ "$lp" -lt 0 ] && lp=0
                         printf '%s╒◉╕⚡%s║▒' "$(_dots "$lp")" "$(_cycle "$ac" '═' "$off" ELECTRIC)"
                     elif [ "$out" -lt 3 ]; then local t=' DOOR OPEN! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-8)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-8-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '╒◉╕💨%s%s%s║ ║' "$(_dots "$lp")" "$(_text "$t" "$off" RACE_GOLD)" "$(_dots "$rp")"
                     elif [ "$out" -lt 5 ]; then local t=' …does not compute ' tl lp rp; tl=${#t}; [ $(( tl+5 )) -gt "$span" ] && { t=' …error '; tl=${#t}; }; lp=$(( (span-tl-5)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-5-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '╒◉╕%s%s%s🤖' "$(_dots "$lp")" "$(_text "$t" "$off" SMOKE)" "$(_dots "$rp")"
                     else local t=' WHEE-BOOP! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-7)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-7-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '╒◉╕🎉%s%s%s✨' "$(_dots "$lp")" "$(_text "$t" "$off" FLASH)" "$(_dots "$rp")"; fi ;;
        ironman)     local res=$(( seed%5 )) liv; liv=$(_pick "$seed" HOTROD_RED IRON_GOLD); local c=$(( span/2 )) m=${#ARC_CYAN[@]}   # arc reactor -> suit up -> repulsor -> "I AM IRON MAN"
                     if   [ "$pm" -lt 330 ]; then local s='' i r; r=$(( pm*c/330 )); [ "$r" -lt 1 ] && r=1
                         for ((i=0;i<span;i++)); do local d=$(( i-c )); [ "$d" -lt 0 ] && d=$(( -d ))
                             if [ "$d" -le "$r" ]; then local idx gl; idx=$(( d*(m-1)/(r>0?r:1) )); [ "$idx" -ge "$m" ] && idx=$(( m-1 ))
                                 if [ $(( d*3 )) -le "$r" ]; then gl='█'; elif [ $(( d*2 )) -le "$r" ]; then gl='▓'; elif [ $(( d*3 )) -le $(( 2*r )) ]; then gl='▒'; else gl='░'; fi
                                 s+=$'\e[38;5;'"${ARC_CYAN[$idx]}"m"$gl"
                             else s+=$'\e[38;5;236m''·'; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ "$pm" -lt 480 ]; then local asm gap; asm=$(( (pm-330)*c/150 )); [ "$asm" -gt "$c" ] && asm=$c; gap=$(( span-2*asm-1 )); [ "$gap" -lt 1 ] && gap=1
                         printf '%s%s\e[1;38;5;231m◉%s%s%s' "$(_fade "$asm" '▰' "$liv" R)" "$(_dots $(( (gap-1)/2 )))" "$R" "$(_dots $(( gap-1-(gap-1)/2 )))" "$(_fade "$asm" '▰' "$liv" L)"
                     elif [ "$pm" -lt 720 ]; then local bl; bl=$(( (pm-480)*(span-2)/240 )); [ "$bl" -lt 0 ] && bl=0; [ "$bl" -gt $(( span-2 )) ] && bl=$(( span-2 ))
                         printf '%s\e[1;38;5;231m💥%s%s' "$(_fade "$bl" '━' REPULSOR R)" "$R" "$(_dots $(( span-bl-2<0?0:span-bl-2 )))"
                     elif [ "$pm" -lt 900 ]; then local t=' I AM IRON MAN ' tl lp rp fo; tl=${#t}; fo=$(( off*2+pm/5 )); [ $(( tl+2 )) -gt "$span" ] && { t=' IRON MAN '; tl=${#t}; }; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '◈%s%s%s◈' "$(_cycle "$lp" '═' "$fo" HOTROD_RED)" "$(_text "$t" "$fo" IRON_GOLD)" "$(_cycle "$rp" '═' "$fo" HOTROD_RED)"
                     else case "$res" in
                           0) local t=' TARGET DESTROYED ' tl lp rp; tl=${#t}; [ $(( tl+4 )) -gt "$span" ] && { t=' DESTROYED '; tl=${#t}; }; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                              printf '💥%s%s%s💥' "$(_solid "$lp" '█' 214)" "$(_text "$t" "$off" IRON_GOLD)" "$(_solid "$rp" '█' 214)" ;;
                           1) local t=' …power at 5% ' tl lp rp; tl=${#t}; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                              printf '🔋%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" ARC_CYAN)" "$(_dots "$rp")" ;;
                           2) local t=' JARVIS, you there? ' tl lp rp; tl=${#t}; [ $(( tl+2 )) -gt "$span" ] && { t=' JARVIS? '; tl=${#t}; }; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                              printf '🤖%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" HUD_CYAN)" "$(_dots "$rp")" ;;
                           3) local t=' FLAWLESS ' tl lp rp; tl=${#t}; lp=$(( (span-tl)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-lp )); [ "$rp" -lt 0 ] && rp=0
                              printf '%s%s%s' "$(_cycle "$lp" '▰' "$off" IRON_GOLD)" "$(_text "$t" "$off" IRON_GOLD)" "$(_cycle "$rp" '▰' "$off" IRON_GOLD)" ;;
                           *) local t=' …and a cheeseburger ' tl lp rp; tl=${#t}; [ $(( tl+2 )) -gt "$span" ] && { t=' burger! '; tl=${#t}; }; lp=$(( (span-tl-2)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-2-lp )); [ "$rp" -lt 0 ] && rp=0
                              printf '%s%s%s🍔' "$(_dots "$lp")" "$(_text "$t" "$off" RING)" "$(_dots "$rp")" ;;
                         esac; fi ;;
        dgoggins)    local clip=$(( seed%3 )) reps=$(( 40 + (seed*17+3)%61 )) chant; chant=$(_pick "$seed" 'STAY HARD!' 'CARRY THE LOGS!' 'TAKING SOULS' 'GET AFTER IT!' "YOU DON'T KNOW ME SON!" 'THE GOVERNOR IS OFF' "WHO'S GONNA CARRY THE BOATS?!")   # 🏃 grind -> CHANT -> 🚣 -> 💀
                     if   [ "$pm" -lt 110 ]; then local t=' 0430 — GET UP ' tl; tl=${#t}; [ $(( tl+2 )) -gt "$span" ] && { t=' GET UP! '; tl=${#t}; }; printf '%s%s🏃' "$(_text "$t" "$off" SMOKE)" "$(_dots $(( span-tl-2<0?0:span-tl-2 )))"
                     elif [ "$pm" -lt 330 ]; then _runner $(( span-pos )) 2 "$w" '🏃' rtl "$off" '°' SMOKE fade
                     elif [ "$pm" -lt 440 ]; then local t=" REP $reps " tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '💪%s%s%s💦' "$(_dots "$lp")" "$(_text "$t" "$off" FLASH)" "$(_dots "$rp")"
                     elif [ "$pm" -lt 620 ]; then local cc="$chant" cl lp rp; [ $(( ${#cc}+4 )) -gt "$span" ] && cc="${cc:0:$(( span>5?span-5:1 ))}…"; cl=${#cc}; lp=$(( (span-cl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-cl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🔥%s%s%s🔥' "$(_dots "$lp")" "$(_text "$cc" "$(( off*2+pm/4 ))" FLASH)" "$(_dots "$rp")"
                     elif [ "$pm" -lt 830 ]; then local t=' HEAVY! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🚣%s%s%s💪' "$(_dots "$lp")" "$(_text "$t" "$off" FIRE_EMBER)" "$(_dots "$rp")"
                     elif [ "$pm" -lt 945 ]; then local s='' n=$span i fm=${#FLASH[@]}; for ((i=0;i<n;i++)); do if [ $(( (i+off)%9 )) -eq 0 ]; then s+=$'\e[1m''💀'; ((i++)); else s+=$'\e[1;38;5;'"${FLASH[$(( (i+off)%fm ))]}"m'▀'; fi; done; printf '%s%s' "$s" "$R"
                     else local t=" $chant " tl lp rp; [ $(( ${#t}+4 )) -gt "$span" ] && t="${t:0:$(( span>5?span-5:1 ))}…"; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0   # climax shows the run's chant
                         printf '💀%s%s%s💀' "$(_dots "$lp")" "$(_text "$t" "$(( off*2+pm/4 ))" FLASH)" "$(_dots "$rp")"; fi ;;
        volcano)     local fate=$(( seed%5 )) c=$(( span/2 )) m=${#LAVA_CORE[@]}                        # 🌋 erupts, lava radiates from the cone -> KABOOM / lava / just smoke
                     if   [ "$pm" -lt 780 ]; then local s='' i r; r=$(( pm*c/780 )); [ "$r" -lt 1 ] && r=1
                         for ((i=0;i<span;i++)); do
                             if [ "$i" -eq "$c" ]; then s+=$'\e[0m''🌋'; ((i++)); continue; fi
                             local d=$(( i-c )); [ "$d" -lt 0 ] && d=$(( -d ))
                             if [ "$d" -le "$r" ]; then local idx gl; idx=$(( d*(m-1)/(r>0?r:1) )); [ "$idx" -ge "$m" ] && idx=$(( m-1 ))
                                 if [ $(( d*3 )) -le "$r" ]; then gl='█'; elif [ $(( d*2 )) -le "$r" ]; then gl='▓'; elif [ $(( d*3 )) -le $(( 2*r )) ]; then gl='▒'; else gl='░'; fi
                                 s+=$'\e[38;5;'"${LAVA_CORE[$idx]}"m"$gl"
                             elif [ $(( (i*7+off)%17 )) -eq 0 ]; then s+=$'\e[38;5;208m''◦'
                             else s+=$'\e[38;5;236m''·'; fi; done
                         printf '%s%s' "$s" "$R"
                     elif [ "$fate" -lt 3 ]; then local t=' KABOOM! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🌋%s%s%s💥' "$(_cycle "$lp" '█' "$off" LAVA_CORE)" "$(_text "$t" "$off" FLASH)" "$(_cycle "$rp" '█' "$off" LAVA_CORE)"
                     elif [ "$fate" -eq 3 ]; then printf '🌋%s' "$(_fade $(( span-2 )) '▒' LAVA_CORE R)"
                     else local t=' …just smoke ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🌬%s%s%s🌋' "$(_cycle "$lp" '░' "$off" LAVA_ASH)" "$(_text "$t" "$off" LAVA_ASH)" "$(_dots "$rp")"; fi ;;
        dragon)      local fate=$(( seed%4 )) m=${#DRAGON_FIRE[@]}                                       # 🐉 inhales, breathes a gradient fire-breath -> TOASTY / HOARD / burp
                     if   [ "$pm" -lt 330 ]; then local gl; gl=$(( pm/82 )); printf '🐉%s\e[1;38;5;231m‹%s%s' "$(_fade $(( 2+gl )) '◦' DRAGON_FIRE L)" "$R" "$(_dots $(( span-5-gl<0?0:span-5-gl )))"   # inhale: glow gathers + ‹ air intake
                     elif [ "$pm" -lt 900 ]; then local bl s='' i; bl=$(( (pm-330)*(span-2)/570 )); [ "$bl" -lt 1 ] && bl=1; [ "$bl" -gt $(( span-2 )) ] && bl=$(( span-2 ))
                         for ((i=0;i<bl;i++)); do local idx gl; idx=$(( i*(m-1)/(bl>1?bl-1:1) )); [ "$idx" -ge "$m" ] && idx=$(( m-1 )); if [ $(( i*3 )) -lt "$bl" ]; then gl='█'; elif [ $(( i*2 )) -lt "$bl" ]; then gl='▓'; else gl='▒'; fi; s+=$'\e[38;5;'"${DRAGON_FIRE[$idx]}"m"$gl"; done
                         printf '🐉%s%s%s' "$s" "$R" "$(_dots $(( span-bl-2<0?0:span-bl-2 )))"
                     elif [ "$fate" -lt 2 ]; then local t=' TOASTY! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🐉%s%s%s🔥' "$(_cycle "$lp" '█' "$off" DRAGON_FIRE)" "$(_text "$t" "$off" DRAGON_FIRE)" "$(_cycle "$rp" '█' "$off" DRAGON_FIRE)"
                     elif [ "$fate" -eq 2 ]; then local t=' HOARD! ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🐉%s%s%s💎' "$(_cycle "$lp" '▓' "$off" DRAGON_GOLD)" "$(_text "$t" "$off" DRAGON_GOLD)" "$(_cycle "$rp" '▓' "$off" DRAGON_GOLD)"
                     else local t=' …just a burp ' tl lp rp; tl=${#t}; lp=$(( (span-tl-4)/2 )); [ "$lp" -lt 0 ] && lp=0; rp=$(( span-tl-4-lp )); [ "$rp" -lt 0 ] && rp=0
                         printf '🐉💨%s%s%s' "$(_dots "$lp")" "$(_text "$t" "$off" SMOKE)" "$(_dots "$rp")"; fi ;;
        seth)        _signature 'SETH M. WOODBURY' 'SethWoodbury' '' ;;                                                         # the author's signature
        credits)     _credits "$SIG_NAME" "$SIG_GH" ;;                                                                          # customizable hype reel (set SIG_NAME/SIG_GH)
        *)           _runner "$pos" 2 "$w" '🐭' ltr "$off" '°' SMOKE fade ;;
    esac
}

# ---- standalone player (runs only when executed, not when sourced) -----------
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
    case "${1:-}" in
        -h|--help|help)
            cat <<EOF
test-animations-fast — smooth, full-fps preview of the Claude status-bar animations.
  test-animations-fast [style|all]   play one (or all) smoothly
  test-animations-fast loop          play random animations forever (Ctrl-C to stop)
  test-animations-fast --list        list available animations
  test-animations-fast --help        this help
Bar-accurate (choppy, exactly as the bar shows it) instead: test-animations
Available: ${ALL_STYLES[*]}
EOF
            exit 0 ;;
        -l|--list) printf '%s\n' "${ALL_STYLES[@]}"; exit 0 ;;
    esac
    # `test-animations-fast loop` -> smooth, forever (great in a tmux split below Claude)
    mode=oneshot; case "${1:-}" in loop|--loop) mode=loop; set --;; esac
    styles=("${ALL_STYLES[@]}"); [ -n "${1:-}" ] && styles=("$1")
    width=${COLUMNS:-0}; [ "$width" -le 0 ] && width=$(tput cols 2>/dev/null || echo 100)
    cap=${ANIM_MAXW:-180}; [ "$width" -gt "$cap" ] && width=$cap
    if [ -t 1 ] && [ "$mode" = loop ]; then
        printf '\e[?25l'; trap 'printf "\e[?25h\e[0m\n"' EXIT; trap 'exit 130' INT TERM
        while :; do
            s=${ALL_STYLES[$(( RANDOM % ${#ALL_STYLES[@]} ))]}; ANIM_SEED=$(( RANDOM ))
            for ((p=0;p<=1000;p+=8)); do printf '\r\e[K%s' "$(anim_frame "$s" "$p" "$width")"; sleep 0.011; done
            printf '\r\e[K'; sleep 0.35
        done
    elif [ -t 1 ]; then
        printf '\e[?25l'; trap 'printf "\e[?25h\e[0m\n"' EXIT; trap 'exit 130' INT TERM
        printf '\n  \e[1m✨ test-animations-fast\e[0m — %d animation(s) @ %d cols, Ctrl-C to stop\n' "${#styles[@]}" "$width"
        for s in "${styles[@]}"; do ANIM_SEED=$(( RANDOM ))
            printf '\n  \e[1m%-12s\e[0m\n' "$s"
            for ((p=0;p<=1000;p+=8)); do printf '\r\e[K%s' "$(anim_frame "$s" "$p" "$width")"; sleep 0.011; done
            printf '\r\e[K'; done
        printf '\e[?25h\e[0m  done.\n'
    else
        for s in "${styles[@]}"; do ANIM_SEED=7; printf '\n== %s ==\n' "$s"
            for p in 0 250 500 750 1000; do printf '%s\n' "$(anim_frame "$s" "$p" "${width:-72}")"; done; done
    fi
fi
