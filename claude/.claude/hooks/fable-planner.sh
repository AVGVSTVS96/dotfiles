#!/usr/bin/env bash
# Plan and reviewer agents run on Fable while an account that holds a Fable reset still has Fable left this week:
# that reset gives back the week Fable used, so the Fable is free; once none does, they keep their own model (Opus).
set -euo pipefail
input=$(cat)
jq -e '.tool_input | (.subagent_type == "Plan" or .subagent_type == "reviewer") and (.model // "") == ""' <<<"$input" >/dev/null || exit 0
key=$(cat "$HOME/.config/cliproxyapi/key" 2>/dev/null) && [ -n "${ANTHROPIC_BASE_URL:-}" ] || exit 0
snapshot=$(curl -sN -m 3 -H "Authorization: Bearer $key" "$ANTHROPIC_BASE_URL/v8/management/deck/events" 2>/dev/null | head -1 | sed 's/^data: //' || true)
jq -e --argjson now "$(date +%s000)" '[.. | objects | select(has("heldResets") and .standing != "signed-out")
  | select(any(.heldResets[]; .kind == "fable" and .left > 0 and (.expiresAt == null or .expiresAt > $now)))
  | .fable | select(. != null and .used != null and .used < .cutoff)] | length > 0' <<<"$snapshot" >/dev/null 2>&1 || exit 0
jq '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: (.tool_input + {model: "fable"})}}' <<<"$input"
