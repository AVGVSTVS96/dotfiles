#!/usr/bin/env bash
# Plan and reviewer agents run on Fable while the Claude pool has Fable left, so held Fable resets get used; otherwise their own model.
set -euo pipefail
input=$(cat)
jq -e '.tool_input | (.subagent_type == "Plan" or .subagent_type == "reviewer") and (.model // "") == ""' <<<"$input" >/dev/null || exit 0
key=$(cat "$HOME/.config/cliproxyapi/key" 2>/dev/null) && [ -n "${ANTHROPIC_BASE_URL:-}" ] || exit 0
snapshot=$(curl -sN -m 3 -H "Authorization: Bearer $key" "$ANTHROPIC_BASE_URL/v8/management/deck/events" 2>/dev/null | head -1 | sed 's/^data: //' || true)
jq -e '[.. | objects | select(has("heldResets") and .standing != "signed-out") | .fable | select(. != null and .used != null and .used < .cutoff)] | length > 0' <<<"$snapshot" >/dev/null 2>&1 || exit 0
jq '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: (.tool_input + {model: "fable"})}}' <<<"$input"
