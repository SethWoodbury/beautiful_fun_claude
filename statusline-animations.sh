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
            fireworks race fight chase party dance converge marquee abduct duel rocket seth)

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

anim_frame() {
    local style="$1" pm="${2:-0}" w="${3:-80}"
    [[ "$pm" =~ ^[0-9]+$ ]] || pm=0; [ "$pm" -gt 1000 ] && pm=1000
    [[ "$w"  =~ ^[0-9]+$ ]] || w=80; [ "$w" -lt 30 ] && w=30
    local cap=${ANIM_MAXW:-180}; [ "$w" -gt "$cap" ] && w=$cap
    local seed=${ANIM_SEED:-0} off=$(( pm/9 + ${ANIM_SEED:-0} ))
    local span=$(( w-8 )); [ "$span" -lt 6 ] && span=6
    local pos=$(( pm*span/1000 )) i

    case "$style" in
        rainbow)     _cycle $(( w-2 )) '█' "$off" RING ;;
        nyan)        _runner "$pos" 2 "$w" '🐱' ltr "$off" '█' RING cycle ;;
        mouse)       _runner "$pos" 2 "$w" '🐭' ltr "$off" '·' SMOKE fade ;;
        ufo)         _runner "$pos" 2 "$w" '🛸' ltr "$off" '=' TOX_NEON cycle ;;
        comet)       _runner $(( span-pos )) 2 "$w" '☄' rtl "$off" '─' "$(_pick "$seed" ICE_GLACIER ICE_FROSTFIRE)" fade ;;
        caterpillar) _runner $(( span-pos )) 2 "$w" '🐛' rtl "$off" '●' "$(_pick "$seed" FOREST_DEEP TOX_NEON)" cycle ;;
        fish)        _runner $(( span-pos )) 2 "$w" '🐟' rtl "$off" '~' "$(_pick "$seed" OCEAN_SURF OCEAN_TEAL OCEAN_DUSK)" cycle ;;
        train)       _runner $(( span-pos )) 6 "$w" '🚂🚃🚃' rtl "$off" '·' SMOKE fade ;;
        wave)        local s='' n=$(( w-2 )) sp; sp="$(_pick "$seed" OCEAN_SURF OCEAN_TEAL OCEAN_DUSK)"; local -n SP="$sp"; local sm=${#SP[@]}
                     for ((i=0;i<n;i++)); do local col=${SP[$(( (i+off)%sm ))]}
                         if   [ $(( (i+off)%15 )) -eq 0 ]; then s+=$'\e[38;5;'"$col"m'🌊'; ((i++))
                         elif [ $(( (i*3+off)%41 )) -eq 0 ]; then s+=$'\e[38;5;81m''🐟'; ((i++))
                         elif [ $(( (i*5+off)%59 )) -eq 0 ]; then s+=$'\e[38;5;195m''🫧'; ((i++))
                         else s+=$'\e[38;5;'"$col"m'~'; fi; done
                     printf '%s%s' "$s" "$R" ;;
        sparkle)     local s='' hot=$(( pm/40+seed )) br; br=$(_pick "$seed" 226 231 201 51 213)
                     for ((i=0;i<w-2;i++)); do
                         if   [ $(( (i*7+hot)%13 )) -eq 0 ]; then s+=$'\e[1;38;5;'"$br"m'✦'; ((i++))
                         elif [ $(( (i*5+hot)%19 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''✨'; ((i++))
                         elif [ $(( (i*3+hot)%23 )) -eq 0 ]; then s+=$'\e[38;5;'"$br"m'·'
                         else s+=$'\e[38;5;236m''·'; fi; done
                     printf '%s%s' "$s" "$R" ;;
        fireworks)   local c=$(( (w-2)/2 )); local ray=$(( pm*(c-2)/1000 )); local fp; fp="$(_pick "$seed" FIRE_CLASSIC FIRE_EMBER FIRE_VIOLET)"
                     if [ "$pm" -lt 120 ]; then printf '%s\e[38;5;245m.%s' "$(_dots "$c")" "$R"
                     elif [ "$pm" -lt 900 ]; then printf '%s\e[1;38;5;231m💥%s%s' "$(_cycle "$ray" '─' "$off" "$fp")" "$R" "$(_cycle "$ray" '─' $((off+5)) "$fp")"
                     else printf '%s' "$(_cycle $(( w-2 )) '█' "$off" "$fp")"; fi ;;   # full-width fire-blast finale

        race)        local V=(🏎️ 🚗 🚙 🛻 🏍️ 🚜 🚓 🚕) ga gb; ga=${V[$(( seed%8 ))]}; gb=${V[$(( (seed/5+3)%8 ))]}
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

        fight)       local F=(🥊 🤺 🥷 🏹 🤖 👹 👺 🐉 🦖 🦂 🦅 🐅 🦁 🐺 🦍 🐻 🦈 🐲 👽 🦏) a b; a=${F[$(( seed%20 ))]}; b=${F[$(( (seed/7+5)%20 ))]}; [ "$b" = "$a" ] && b=${F[$(( (seed/7+6)%20 ))]}
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
                     case "$catch" in 0) cf=440 ;; 1) cf=670 ;; 2) cf=890 ;; *) cf=1001 ;; esac
                     local tgt=$(( catch==3 ? 750 : cf )); [ "$tgt" -lt 1 ] && tgt=1
                     local march=$(( pm*span/1000 )) wide=$(( span/2>6?span/2:6 ))
                     local gap=$(( wide-(wide-1)*pm/tgt )); [ "$gap" -lt 1 ] && gap=1
                     local predcol=$(( span-march )); [ "$predcol" -gt "$span" ] && predcol=$span; [ "$predcol" -lt 0 ] && predcol=0
                     local preycol=$(( predcol-gap-2 )); [ "$preycol" -lt 0 ] && preycol=0
                     if [ "$catch" -ne 3 ] && [ "$pm" -ge "$cf" ]; then                  # CAUGHT (frozen tableau at the catch spot)
                         local cc=$(( span - cf*span/1000 )); [ "$cc" -lt 0 ] && cc=0; [ "$cc" -gt $(( span-4 )) ] && cc=$(( span-4 ))
                         printf '%s💥%s😋%s' "$(_dots "$cc")" "$pd" "$(_dots $(( span-cc-4 )))"
                     elif [ "$catch" -eq 3 ] && [ "$pm" -ge 900 ]; then                  # ESCAPE
                         local np=$(( preycol-(3+span/6) )); [ "$np" -lt 0 ] && np=0; local pdc=$(( predcol+2 )); [ "$pdc" -gt "$span" ] && pdc=$span
                         printf '💨%s%s%s%s💢%s' "$(_dots "$np")" "$pr" "$(_dots $(( pdc-np-2 )))" "$pd" "$(_dots $(( span-pdc )))"
                     else local lung=''; [ "$gap" -le 2 ] && lung='💨'; local aft=$(( span-preycol-gap-4 )); [ "$aft" -lt 0 ] && aft=0
                         printf '%s%s%s%s%s%s' "$(_dots "$preycol")" "$pr" "$(_cycle "$gap" '·' "$off" SMOKE)" "$pd" "$lung" "$(_dots "$aft")"; fi ;;

        party)       local PR=(🥳 🎉 🦄 🤡 🎈 🥁 🎺 🐘 🎊 🪅) out='' n=$(( w-2 )) cp; cp="$(_pick "$seed" DISCO_NEON DISCO_CANDY DISCO_VAPOR RING)"; local -n CP="$cp"; local cm=${#CP[@]}
                     for ((i=0;i<n;i++)); do if [ $(( (i+off)%5 )) -eq 0 ]; then out+=$'\e[1m'"${PR[$(( (i/5+off)%${#PR[@]} ))]}"$'\e[0m'; ((i++))
                         else out+=$'\e[38;5;'"${CP[$(( (i+off)%cm ))]}"m'▀'; fi; done
                     printf '%s' "$out" ;;
        dance)       local DA=(🕺 💃 👯 🪩 🥳 🤖 🦄) out='' n=$(( w-2 )) cen=$(( (w-9)/2 )) cp; cp="$(_pick "$seed" DISCO_NEON DISCO_VAPOR RING)"; local -n CD="$cp"; local cm=${#CD[@]}
                     local txt; txt="$(_text '♪DANCE♪' "$off" RING)"
                     for ((i=0;i<n;i++)); do if [ "$i" -eq "$cen" ]; then out+="$txt"; i=$(( i+8 )); continue; fi
                         if [ $(( (i+off)%4 )) -eq 0 ]; then out+=$'\e[1m'"${DA[$(( (i/4+off)%${#DA[@]} ))]}"$'\e[0m'; ((i++))
                         else out+=$'\e[38;5;'"${CD[$(( (i+off)%cm ))]}"m'▀'; fi; done
                     printf '%s%s' "$out" "$R" ;;

        converge)    local half=$(( (w-2)/2 )); local fn=$(( pm*half/700 )); [ "$fn" -gt "$half" ] && fn=$half; local cp; cp="$(_pick "$seed" RING FIRE_CLASSIC ICE_GLACIER DISCO_NEON)"
                     if [ "$pm" -lt 730 ]; then local mid=$(( (w-2)-2*fn )); [ "$mid" -lt 0 ] && mid=0
                         printf '%s%s%s' "$(_cycle "$fn" '█' "$off" "$cp")" "$(_dots "$mid")" "$(_cycle "$fn" '█' $((off+7)) "$cp")"
                     else local sidew=$(( (w-11)/2 )); printf '%s%s%s' "$(_cycle "$sidew" '█' "$off" "$cp")" "$(_text ' ✦BOOM✦ ' "$off" FIRE_CLASSIC)" "$(_cycle "$sidew" '█' $((off+7)) "$cp")"; fi ;;
        marquee)     local MSGS=('>> CLAUDE CODE << keep shipping >> ' '++ stay caffeinated ++ touch grass ++ ' '~~ vibe coding ~~ small diffs win ~~ ')
                     local msg="${MSGS[$(( seed%3 ))]}"; local ml=${#msg}; [ "$ml" -lt 1 ] && ml=1
                     local winw=$(( w-2 )) full='' start k
                     for ((k=0; k*ml < winw+ml; k++)); do full+="$msg"; done
                     start=$(( (pm*ml/1000)%ml )); _text "${full:start:winw}" "$off" RING ;;

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
                     elif [ "$pm" -lt 700 ]; then printf '%s💥%s%s%s💥%s' "$Lg" "$(_cycle $(( half-2 )) '─' "$off" FIRE_CLASSIC)" "$(_text ' DRAW! ' "$off" RACE_GOLD)" "$(_cycle $(( half-2 )) '─' "$off" FIRE_CLASSIC)" "$Rg"
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
                     elif [ "$res" -lt 6 ]; then local fl; fl=$(_pick "$seed" '✨' '🌟')
                         printf '%s🚀%s%s' "$(_cycle $(( span-8 )) '╿' "$off" FIRE_EMBER)" "$fl" "$(_text ' ORBIT! ' "$off" ICE_GLACIER)"
                     elif [ "$res" -lt 9 ]; then local CL=(231 196 51) sc=${CL[$(( (pm/40)%3 ))]}
                         printf '%s\e[1;38;5;%dm💥💥💥%s%s%s' "$(_dots $(( span/2-6 )))" "$sc" "$R" "$(_cycle 3 '✺' "$off" FIRE_CLASSIC)" "$(_text ' RUD! ' "$off" FIRE_CLASSIC)"
                     else local ab; ab=$(_pick "$seed" '💨' '🧯')
                         printf '🗼🚀%s%s%s' "$(_text ' ABORT ' "$off" RACE_STEEL)" "$ab" "$(_dots $(( span-9 )))"; fi ;;

        seth)        local NAME='SETH M. WOODBURY' L=16 c=$(( span/2 )) fin=$(( seed%3 ))
                     local band; band=$(_pick "$seed" "${SETHPALS[@]}")                                                       # random color scheme each run
                     local tl quip
                     tl=$(_pick "$seed" 'ships code' 'made this' 'builds proteins' 'fueled by happy hour' 'was here' 'commits at 2am' 'folds proteins @ IPD' 'high on life' 'designs diffusion-limited enzymes' 'relies on claude')
                     quip=$(_pick "$(( seed+1 ))" 'EN GARDE!' 'BEHOLD!' 'WITNESS ME!' 'KABOOM!' 'TA-DA!' 'ZAP! ZAP!')
                     if   [ "$pm" -lt 100 ]; then local q=" ⚡ $quip ⚡ " qw sh; qw=$(( ${#q}+2 )); sh=$(( (span-qw-4)/2 )); [ "$sh" -lt 0 ] && sh=0       # ⚔ wizards square up
                         printf '🧙%s%s%s🧙' "$(_dots "$sh")" "$(_text "$q" "$off" "$band")" "$(_dots $(( span-qw-4-sh<0?0:span-qw-4-sh )))"
                     elif [ "$pm" -lt 220 ]; then local cl sh; cl=$(( 1+(pm-100)/40 )); sh=$(( (span-15-4*cl)/2 )); [ "$sh" -lt 0 ] && sh=0             # ⚡ charging staffs
                         printf '🧙%s%s%s%s%s🧙' "$(_cycle "$cl" '✦' "$off" ELECTRIC)" "$(_dots "$sh")" "$(_text ' CHARGING… ' "$off" "$band")" "$(_dots "$sh")" "$(_cycle "$cl" '✦' $((off+3)) ELECTRIC)"
                     elif [ "$pm" -lt 390 ]; then local bl g; bl=$(( (pm-220)*(c-4)/170 )); [ "$bl" -lt 0 ] && bl=0; g=$(( span-2*bl-4 )); [ "$g" -lt 0 ] && g=0   # bolts converge
                         printf '🧙%s%s%s🧙' "$(_cycle "$bl" '═' "$off" ELECTRIC)" "$(_dots "$g")" "$(_cycle "$bl" '═' $((off+4)) ELECTRIC)"
                     elif [ "$pm" -lt 450 ]; then local bl; bl=$(( c-6 )); [ "$bl" -lt 0 ] && bl=0; local CLS=(231 226 51 201) sc=${CLS[$(( (pm/30)%4 ))]}   # 💥 COLLISION
                         printf '🧙%s\e[1;38;5;%dm💥💥💥%s%s🧙' "$(_cycle "$bl" '═' "$off" ELECTRIC)" "$sc" "$R" "$(_cycle "$bl" '═' $((off+4)) ELECTRIC)"
                     elif [ "$pm" -lt 560 ]; then local lp; lp=$(( (span-L)/2 )); [ "$lp" -lt 0 ] && lp=0                                              # ✦ NAME bursts out (centered)
                         printf '%s%s%s' "$(_cycle "$lp" '═' "$off" "$band")" "$(_text "$NAME" "$off" "$band")" "$(_cycle $(( span-lp-L )) '═' "$off" "$band")"
                     elif [ "$pm" -lt 740 ]; then local fc msg mw lp; fc=${FLASH[$(( (pm/15+seed)%${#FLASH[@]} ))]}; msg='⚡ CREATED BY SETH M. WOODBURY ⚡'; mw=$(( ${#msg}+2 )); lp=$(( (span-mw)/2 )); [ "$lp" -lt 0 ] && lp=0   # 🔆 held + flashing
                         printf '%s\e[1;38;5;%dm%s%s%s' "$(_solid "$lp" '═' "$fc")" "$fc" "$msg" "$R" "$(_solid $(( span-lp-mw<0?0:span-lp-mw )) '═' "$fc")"
                     elif [ "$pm" -lt 920 ]; then local sig="SETH M. WOODBURY $tl" sl lp; sl=${#sig}; lp=$(( (span-sl)/2 )); [ "$lp" -lt 0 ] && lp=0     # name + funny tagline (holds ~3s)
                         printf '%s%s%s' "$(_cycle "$lp" '─' "$off" "$band")" "$(_text "$sig" "$off" "$band")" "$(_cycle $(( span-lp-sl )) '─' "$off" "$band")"
                     elif [ "$pm" -lt 970 ]; then case "$fin" in                                                                                      # 🎆 FINALE (random)
                             0) printf '%s' "$(_cycle $(( span-2 )) '▰' "$off" "$band")" ;;
                             1) local s='' i; for ((i=0;i<span-2;i++)); do if [ $(( (i+off)%6 )) -eq 0 ]; then s+=$'\e[1m''🎉'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'▀'; fi; done; printf '%s%s' "$s" "$R" ;;
                             *) local s='' i; for ((i=0;i<span-2;i++)); do if [ $(( (i*7+off)%9 )) -eq 0 ]; then s+=$'\e[1;38;5;231m''✦'; ((i++)); else s+=$'\e[38;5;'"${RING[$(( (i+off)%NR ))]}"m'·'; fi; done; printf '%s%s' "$s" "$R" ;;
                         esac
                     else local sig="🎉 SETH M. WOODBURY — $tl 🎉" sl lp; sl=$(( ${#sig}+2 )); lp=$(( (span-sl)/2 )); [ "$lp" -lt 0 ] && lp=0           # 🏆 signature card (centered)
                         printf '%s%s%s' "$(_cycle "$lp" '─' "$off" "$band")" "$(_text "$sig" "$off" RING)" "$(_cycle $(( span-lp-sl )) '─' "$off" "$band")"; fi ;;
        *)           _runner "$pos" 2 "$w" '🐭' ltr "$off" '·' SMOKE fade ;;
    esac
}

# ---- standalone player (runs only when executed, not when sourced) -----------
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
    # `test-animations loop`  -> smooth, forever (great in a tmux split below Claude)
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
        printf '\n  \e[1m✨ test-animations\e[0m — %d animation(s) @ %d cols, Ctrl-C to stop\n' "${#styles[@]}" "$width"
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
