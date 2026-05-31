# 🌈 beautiful_fun_claude

A gorgeous, ridiculous, **fun** status line for [Claude Code](https://code.claude.com/docs/en/statusline) — a calm, colorful info bar most of the time, with periodic full‑width **animated cameos** (a wizard battle, races with photo finishes and wipeouts, fights, a UFO abduction, a rocket launch, nyan‑cat, fireworks, and more — **23 in all**).

![status bar](assets/statusbar.svg)

Every ~20 seconds the whole bar briefly turns into a full‑width animation — a race finish, the signature wizard battle, and 20+ more:

![race finish](assets/race.svg)

![seth signature](assets/seth.svg)

<sub>(GitHub can't show ANSI color in a code block, so these are SVG snapshots of real output — on your machine the colors are live and the cameos animate.)</sub>

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

> **macOS:** the system `bash` is 3.2 — too old (the scripts use bash‑4 namerefs/`readarray`). Install a modern one: `brew install bash` (and ensure it's used). `jq`: `brew install jq`.

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
test-animations            # preview the animations exactly as the bar shows them
test-animations seth        # just one (run a few times — they're randomized)
test-animations --list      # all animation names    (--help for usage)
test-animations-fast         # smooth, full-fps preview  (test-animations-fast loop = run forever)
```

### 🤖 Install with Claude (copy‑paste prompt)

Paste this into a Claude Code session and it'll do the whole install:

> Please install the **beautiful_fun_claude** Claude Code status line for me from `https://github.com/SethWoodbury/beautiful_fun_claude`.
> Steps: (1) make sure `jq` is installed (it's required); (2) `git clone` that repo to a temp dir and run its `./install.sh` — which copies `statusline.sh` and `statusline-animations.sh` into `~/.claude/`, copies the `test-animations` and `test-animations-fast` preview tools into `~/.local/bin/`, makes them executable, and **merges** (does not overwrite) this into my `~/.claude/settings.json`: `"statusLine": {"type":"command","command":"~/.claude/statusline.sh","refreshInterval":1}`; (3) confirm `~/.local/bin` is on my `PATH`; (4) tell me to run `test-animations` in a terminal to preview, and that the status bar updates on my next message. Note: `refreshInterval:1` repaints the bar every second so the occasional animation cameos can move — mention I can set it to 60 (no cameo motion) or set `ANIM_ENABLED=0` in `~/.claude/statusline.sh` to disable cameos. Optionally I can set `SIG_NAME`/`SIG_GH` in `~/.claude/statusline-animations.sh` to put my own name in the `credits` animation. Don't change any other settings of mine.

## Configuration

Everything lives in the **CONFIG** and **PALETTE** blocks at the top of `~/.claude/statusline.sh`:

| Knob | Default | Notes |
|---|---|---|
| `ANIM_ENABLED` | `1` | Master on/off for in‑bar cameos. |
| `ANIM_EVERY` | `20` | Seconds between cameos (a cameo plays once per window). |
| `ANIM_FRAMES` | `10` | Length of a cameo in ~1s frames (`seth` overrides to 18s). |
| `ANIM_MAXW` | `200` | Max animation width (≈ your bar width). |
| `ANIM_STYLES=(…)` | all 23 | Which animations rotate; trim to your favorites. |
| `SHOW_DECO` | `1` | The `───` end‑caps. |
| `SHOW_MASCOT`/`SHOW_QUIP`/`SHOW_DIR`/`SHOW_SEVEN_DAY`/… | `1` | Per‑segment toggles. |
| `TZ_OVERRIDE` | `""` | Pin a timezone (default = system local). |
| `EMOJI`/`QUIPS`/`DECO` | — | The mascot pool, quip list, end‑cap gradient. |
| `SIG_NAME`/`SIG_GH` | — | **Your** name + GitHub handle for the customizable `credits` animation (in `statusline-animations.sh`). |

Animation palettes and per‑style color/behavior live in `~/.claude/statusline-animations.sh`.

## The animations (23)

`rainbow nyan mouse ufo comet caterpillar fish train wave sparkle fireworks race fight chase party dance converge marquee abduct duel rocket seth credits`

Highlights: **race** (random lead changes, photo finishes, ~25% wipeouts), **fight** (random knockbacks + winner), **chase** (random early/late catch or escape), **rocket** (`T-3→LIFTOFF` then orbit/RUD/abort), **seth** (the author's 18‑second wizard‑battle signature), **credits** (the same epic reel but **customizable** — set `SIG_NAME`/`SIG_GH` to put your own name in it; it still credits the framework).

## Debugging / authoring animations

Two previewers:

```bash
test-animations [style]       # BAR-ACCURATE: exactly what the bar shows (choppy ~1s/frame)
test-animations-fast [style]  # SMOOTH: full-fps preview (test-animations-fast loop = run forever)
```

`test-animations` mirrors the bar's discrete‑frame reality and, when piped/captured, prints a per‑frame **width + OVERFLOW/BLANK** report — handy when authoring a new animation:

```bash
SEED=7 SIMW=200 test-animations seth | less   # pin a random outcome + width
test-animations --list                         # all animation names
```

## Make it yours

- **Put your own name in it:** set `SIG_NAME` and `SIG_GH` in `statusline-animations.sh` (or export them) — the **`credits`** animation then stars *you* (and still credits the framework). The **`seth`** animation is the author's own signature.
- **Pick your animations:** trim `ANIM_STYLES` in `statusline.sh` to just the ones you like (drop `seth`/`credits` if you don't want a signature reel).
- **Recolor anything:** palettes and per‑style behavior live in `statusline-animations.sh`; the bar's own colors are in the `PALETTE` block of `statusline.sh`.

## Updating · Uninstalling · Troubleshooting

- **Update:** `git pull && ./install.sh` (re‑run‑safe; it re‑backs‑up `settings.json`).
- **Uninstall:** remove `~/.claude/statusline.sh`, `~/.claude/statusline-animations.sh`, and `~/.local/bin/test-animations{,-fast}`; delete the `statusLine` key from `~/.claude/settings.json` (or restore the `settings.json.bak.<timestamp>` the installer saved).
- **Bar is blank?** `~/.local/bin` isn't on your `PATH`, or `jq` isn't installed.
- **Cameos don't move?** `refreshInterval` isn't `1` in `settings.json` (a higher value means the bar repaints too rarely to animate).
- **Colors look off?** Your terminal may not support 256‑color, or it's overriding the palette via a theme.

## License

MIT — see [LICENSE](LICENSE). Have fun. 🌈
