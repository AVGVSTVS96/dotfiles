#!/usr/bin/env bash
command=$(jq -r '.tool_input.command // empty')
if grep -Eq '(^|[;&|(]|sudo( -[^[:space:]]+)*)[[:space:]]*pkill([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-[[:alnum:]]*f[[:alnum:]]*|--full)([[:space:]]|$)' <<<"$command"; then
  echo "pkill -f matches whole command lines, including the shell running this command, so it kills itself. Kill by the PID you started or looked up; killing by name (pkill -x bun) also kills every other session's processes with that name." >&2
  exit 2
fi
