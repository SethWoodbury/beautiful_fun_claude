#!/usr/bin/env bash
# =============================================================================
# subagent-statusline.sh — OPTIONAL companion for beautiful_fun_claude.
# -----------------------------------------------------------------------------
# Claude Code shows running subagents in a panel BELOW the prompt (separate from
# the bottom status line — your animations never touch it). This script restyles
# each of those rows to match the theme: a status dot, the agent name in teal,
# its description in grey, and a token-count colored by the same "fills up" ramp.
#
# It's OFF by default. To enable, add to ~/.claude/settings.json:
#   "subagentStatusLine": { "type": "command", "command": "~/.claude/subagent-statusline.sh" }
# (Remove that key to go back to Claude Code's default rows.)
#
# INPUT  (stdin): JSON with .tasks[] (each: id,name,type,status,description,
#                 label,startTime,tokenCount,cwd) plus .columns.
# OUTPUT (stdout): one JSON line per row -> {"id":"<id>","content":"<styled body>"}
#                 Omit a task's id to keep its default rendering.
# Docs: https://code.claude.com/docs/en/statusline  (Subagent status lines)
# =============================================================================
set -u
command -v jq >/dev/null 2>&1 || exit 0          # jq required; bow out quietly if absent
input=$(cat)
E=$'\e'; R="$E[0m"

while IFS=$'\t' read -r id name desc status tok; do
    [ -z "$id" ] && continue
    case "$status" in
        running|in_progress|active|pending_input) dot="$E[38;5;221m◐" ;;   # working (gold)
        completed|done|success)                   dot="$E[38;5;114m●" ;;   # done (green)
        failed|error|cancelled)                   dot="$E[38;5;210m✗" ;;   # failed (coral)
        *)                                        dot="$E[38;5;245m○" ;;   # queued (grey)
    esac
    [[ "$tok" =~ ^[0-9]+$ ]] || tok=0
    if   [ "$tok" -ge 100000 ]; then tc=210
    elif [ "$tok" -ge 30000 ];  then tc=221
    elif [ "$tok" -ge 5000 ];   then tc=150
    else tc=114; fi
    tokh=''; [ "$tok" -gt 0 ] && tokh=" $E[38;5;245m·$R $E[38;5;${tc}m$(( tok/1000 ))k$R"
    content="$dot$R $E[1;38;5;80m$name$R"
    [ -n "$desc" ] && [ "$desc" != null ] && content="$content $E[38;5;245m· ${desc}$R"
    content="$content$tokh"
    jq -nc --arg id "$id" --arg c "$content" '{id:$id, content:$c}'
done < <(printf '%s' "$input" | jq -rc '.tasks[]? | [.id, (.name//"agent"), (.description//""), (.status//""), (.tokenCount//0)] | @tsv')
