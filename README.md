# 🌈 beautiful_fun_claude

A gorgeous, ridiculous, **fun** status line for [Claude Code](https://code.claude.com/docs/en/statusline) — a calm, colorful info bar most of the time, with periodic full‑width **animated cameos** (a wizard battle, races with photo finishes and wipeouts, fights, a UFO abduction, a rocket launch, nyan‑cat, fireworks, and more — 22 in all).

```
🐦 ─── [ligandmpnn_wrapper_cli]    📁 SethWoodbury/protein_chisel    Opus 4.8 1M·xhigh    ctx ▓▓▓▓░░ 67% · 670k/1M    ↑1903 ↓382    ◷ May 30 2:47p    5h 10% → 12:40a · 7d 11%    · small diffs win ───
```

Every few cameos, the whole bar briefly becomes something like:

```
🏁 🏆WIN! 🏎️━━🚗💨━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧙══════════════💥💥💥══════════════🧙        ✦ CREATED BY SETH M. WOODBURY ✦
```

It runs **locally** and uses **zero API tokens / zero context** — it's just a shell script Claude Code pipes session JSON to.

---

## What the bar shows

| Segment | Meaning |
|---|---|
| 🦌 mascot | Stable per‑session emoji (same session = same critter; handy in `/resume`). |
| `─── … ───` | White→blue end‑caps (white points inward). Toggle `SHOW_DECO`. |
| `[name]` | Session name (snake‑cased, shortened). |
| `📁 dir` | Current folder, or `owner/repo` in a git repo. |
| `Opus 4.8 1M·xhigh` | Model + reasoning effort. |
| `ctx ▓▓░░ 67% · 670k/1M` | Context fuel gauge + token headroom. |
| `↑1903 ↓382` | Lines added / removed. |
| `◷ May 30 2:47p` | Session start time (cached). |
| `5h 10% → … · 7d 11%` | Subscription rate‑limit windows (or `◆ api $X.XX` on API billing). |
| `· small diffs win` | A rotating quip. |

Colors are role‑based: grey = info, teal = your name, warm ramp = anything that "fills up."

## Dependencies

- **bash 4+**
- **[jq](https://jqlang.github.io/jq/)** (required — JSON parsing)
- **coreutils** `date` / `stat` — works with GNU (Linux) **or** BSD/macOS variants
- A terminal with **256‑color** support (almost all modern ones)
- *Optional:* a `claude-limit` CLI on `PATH` enables a rate‑limit‑recovery hint (auto‑hidden if absent)

## Install

```bash
git clone https://github.com/SethWoodbury/beautiful_fun_claude.git
cd beautiful_fun_claude
./install.sh
```

`install.sh` copies `statusline.sh` + `statusline-animations.sh` to `~/.claude/`, the preview tools to `~/.local/bin/`, makes them executable, and merges this into `~/.claude/settings.json` (backing it up first):

```json
{
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "refreshInterval": 1 }
}
```

> **`refreshInterval: 1`** makes the bar repaint ~once a second so the periodic animation cameos can actually move. Prefer a calmer bar? Set it to `60` (the cameos then won't animate), or turn cameos off entirely with `ANIM_ENABLED=0` near the top of `statusline.sh`.

Changes appear on your next interaction with Claude Code. Then:

```bash
test-animations          # smooth full reel of all animations
test-animations seth     # just one (run a few times — they're randomized)
test-animations loop      # play forever (nice in a tmux split)
```

### 🤖 Install via someone else's Claude (copy‑paste prompt)

Paste this into a Claude Code session and it'll do the whole install:

> Please install the **beautiful_fun_claude** Claude Code status line for me from `https://github.com/SethWoodbury/beautiful_fun_claude`.
> Steps: (1) make sure `jq` is installed (it's required); (2) `git clone` that repo to a temp dir and run its `./install.sh` — which copies `statusline.sh` and `statusline-animations.sh` into `~/.claude/`, copies `test-animations` and `test-animations-claude` into `~/.local/bin/`, makes them executable, and **merges** (does not overwrite) this into my `~/.claude/settings.json`: `"statusLine": {"type":"command","command":"~/.claude/statusline.sh","refreshInterval":1}`; (3) confirm `~/.local/bin` is on my `PATH`; (4) tell me to run `test-animations` in a terminal to see the reel, and that the status bar updates on my next message. Note: `refreshInterval:1` repaints the bar every second so the occasional animation cameos can move — mention I can set it to 60 (no cameo motion) or set `ANIM_ENABLED=0` in `~/.claude/statusline.sh` to disable cameos. Don't change any other settings of mine.

## Configuration

Everything lives in the **CONFIG** and **PALETTE** blocks at the top of `~/.claude/statusline.sh`:

| Knob | Default | Notes |
|---|---|---|
| `ANIM_ENABLED` | `1` | Master on/off for in‑bar cameos. |
| `ANIM_EVERY` | `20` | Seconds between cameos (a cameo plays once per window). |
| `ANIM_FRAMES` | `10` | Length of a cameo in ~1s frames (`seth` overrides to 18s). |
| `ANIM_MAXW` | `200` | Max animation width (≈ your bar width). |
| `ANIM_STYLES=(…)` | all 22 | Which animations rotate; trim to your favorites. |
| `SHOW_DECO` | `1` | The `───` end‑caps. |
| `SHOW_MASCOT`/`SHOW_QUIP`/`SHOW_DIR`/`SHOW_SEVEN_DAY`/… | `1` | Per‑segment toggles. |
| `TZ_OVERRIDE` | `""` | Pin a timezone (default = system local). |
| `EMOJI`/`QUIPS`/`DECO` | — | The mascot pool, quip list, end‑cap gradient. |

Animation palettes and per‑style color/behavior live in `~/.claude/statusline-animations.sh`.

## The animations (22)

`rainbow nyan mouse ufo comet caterpillar fish train wave sparkle fireworks race fight chase party dance converge marquee abduct duel rocket seth`

Highlights: **race** (random lead changes, photo finishes, ~25% wipeouts), **fight** (random knockbacks + winner), **chase** (random early/late catch or escape), **rocket** (`T-3→LIFTOFF` then orbit/RUD/abort), **seth** (an 18‑second wizard‑battle signature — see below).

## Debugging / authoring animations

`test-animations` plays *smoothly*, but the Claude bar only repaints ~once a second, so it shows each cameo as a handful of discrete frames. To see **exactly** what the bar shows (and catch overflow):

```bash
test-animations-claude            # bar-accurate sim of every animation
test-animations-claude race        # one style (choppy, 1s/frame, like the bar)
SEED=7 SIMW=200 test-animations-claude seth   # pin outcome + width; piped output prints a per-frame width/overflow report
```

## Make it yours

The **`seth`** animation is a personal signature ("SETH M. WOODBURY"). To rename or remove it: edit the `seth)` case in `statusline-animations.sh` (the `NAME`/taglines), or just drop `seth` from `ANIM_STYLES` in `statusline.sh`. Same goes for any animation you don't want — trim the `ANIM_STYLES` list.

## License

MIT — see [LICENSE](LICENSE). Have fun. 🌈
