#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Line 1: dir / model / context %.
# Line 2: session id + costs.
#
# Cost uses Claude Code's own client-side estimate (cost.total_cost_usd), which
# is cumulative for the current session and model-agnostic. We accrue each
# session's increment into a monthly total persisted in statusline-state.json.
#
# NOTE: cost.total_cost_usd is an ESTIMATE ("may differ from your actual bill")
# and is NOT your account's billed monthly extra-usage figure -- that number is
# not available to a statusline script. The monthly total here accrues from the
# moment this script was installed onward; it does not include earlier spend.
# The "~" prefix marks the figures as estimates.

STATE_FILE="$HOME/.claude/statusline-state.json"

input=$(cat)

# ── parse fields ──────────────────────────────────────────────────────────────
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id')

# Persist per-session context usage for `recap` (transcripts don't record the window size).
ctx_dir="$HOME/.local/state/recap/ctx"
mkdir -p "$ctx_dir" 2>/dev/null &&
  echo "$input" | jq -c '.context_window' > "$ctx_dir/$session_id.json" 2>/dev/null
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# ── state file bootstrap ──────────────────────────────────────────────────────
if [ ! -f "$STATE_FILE" ]; then
  echo '{"sessions":{},"monthly":{"month":"","total":0}}' > "$STATE_FILE"
fi
state=$(cat "$STATE_FILE" 2>/dev/null || echo '{"sessions":{},"monthly":{"month":"","total":0}}')

# Reset monthly total when the calendar month rolls over.
current_month=$(date +%Y-%m)
stored_month=$(echo "$state" | jq -r '.monthly.month')
if [ "$stored_month" != "$current_month" ]; then
  state=$(echo "$state" | jq --arg m "$current_month" '.monthly = {"month": $m, "total": 0}')
fi

# ── accrue this session's increment into the monthly total ────────────────────
# cost.total_cost_usd is cumulative per session, so we add only the delta since
# the last invocation for this session id.
prev_cost=$(echo "$state" | jq -r --arg s "$session_id" '.sessions[$s].last_cost // 0')
delta=$(awk -v c="$session_cost" -v p="$prev_cost" \
  'BEGIN { d = c - p; if (d < 0) d = 0; printf "%.6f", d }')

if awk -v d="$delta" 'BEGIN { exit !(d+0 > 0) }'; then
  monthly_total=$(echo "$state" | jq -r '.monthly.total')
  monthly_total=$(awk -v m="$monthly_total" -v d="$delta" 'BEGIN { printf "%.6f", m + d }')
  state=$(echo "$state" | jq \
    --arg s "$session_id" \
    --argjson lc "$session_cost" \
    --argjson mt "$monthly_total" \
    '.sessions[$s].last_cost = $lc | .monthly.total = $mt')
  echo "$state" > "$STATE_FILE"
fi

monthly_total=$(echo "$state" | jq -r '.monthly.total')

# ── format cost display ───────────────────────────────────────────────────────
# Monthly total (estimate): always shown.
monthly_fmt=$(awk -v v="$monthly_total" 'BEGIN { printf "~$%.2f", v }')

# Session delta (this session's spend since start): shown only when > ~$0.00.
session_fmt=""
if awk -v v="$session_cost" 'BEGIN { exit !(v+0 > 0.004) }'; then
  session_fmt=$(awk -v v="$session_cost" 'BEGIN { printf "+$%.2f", v }')
fi

# ── line 1 (dir / model / context) ────────────────────────────────────────────
short_dir=$(basename "$(dirname "$current_dir")")/$(basename "$current_dir")
if [ -n "$used" ]; then
  line1=$(printf "\033[1;36m%s\033[0m \033[1;90mwith\033[0m \033[1;35m%s\033[0m \033[1;90mat\033[0m \033[1;90m[\033[0m\033[0;32m%.0f%%\033[0m\033[1;90m]\033[0m" \
    "$short_dir" "$model" "$used")
else
  line1=$(printf "\033[1;36m%s\033[0m \033[1;90mwith\033[0m \033[1;35m%s\033[0m" \
    "$short_dir" "$model")
fi

# ── line 2 (session id + costs) ───────────────────────────────────────────────
costs_part=$(printf "\033[90m costs %s" "$monthly_fmt")
if [ -n "$session_fmt" ]; then
  costs_part=$(printf "%s \033[0;32m%s\033[90m" "$costs_part" "$session_fmt")
fi
costs_part="${costs_part}$(printf '\033[0m')"

line2=$(printf "\033[1;90m-r \033[0m\033[1;32m%s\033[0m%s" "$session_id" "$costs_part")

printf "%s\n%s" "$line1" "$line2"
