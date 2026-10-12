#!/usr/bin/env bash
command=$(jq -r '.tool_input.command // empty')
if grep -Eq '(^|[;&|(]|sudo( -[^[:space:]]+)*)[[:space:]]*pkill([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-[[:alnum:]]*f[[:alnum:]]*|--full)([[:space:]]|$)' <<<"$command"; then
  echo "pkill -f matches whole command lines, including the shell running this command, so it kills itself. Kill by a saved PID, or by process name with pkill -x <name>." >&2
  exit 2
fi
