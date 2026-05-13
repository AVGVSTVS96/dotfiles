#!/usr/bin/env bash
set -u

interval=15

while [ "$#" -gt 0 ]; do
  case "$1" in
    -i|--interval)
      if [ "$#" -lt 2 ]; then
        echo "watch: --interval requires a value" >&2
        exit 2
      fi
      interval="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if ! [[ "$interval" =~ ^[1-9][0-9]*$ ]]; then
  echo "watch: interval must be a positive integer" >&2
  exit 2
fi

if [ "$#" -eq 0 ]; then
  echo "usage: watch.sh [--interval seconds] -- <command...>" >&2
  exit 2
fi

started=$(date +%s)
poll=0

summarize() {
  printf '%s' "$1" \
    | sed -e $'s/\x1b\[[0-9;]*m//g' \
    | awk 'NF { line=$0 } END { print line }' \
    | tr -s '[:space:]' ' ' \
    | cut -c 1-140
}

trap 'echo "watch: interrupted after $(( $(date +%s) - started ))s"; exit 130' INT TERM

while true; do
  poll=$((poll + 1))
  elapsed=$(( $(date +%s) - started ))

  output=$("$@" 2>&1)
  rc=$?
  summary=$(summarize "$output")

  if [ "$rc" -eq 0 ]; then
    if [ -n "$summary" ]; then
      printf '✓ %s poll=%d +%ss exit=0 %s\n' "$(date +%H:%M:%S)" "$poll" "$elapsed" "$summary"
    else
      printf '✓ %s poll=%d +%ss exit=0 done\n' "$(date +%H:%M:%S)" "$poll" "$elapsed"
    fi
    exit 0
  fi

  if [ -n "$summary" ]; then
    printf '· %s poll=%d +%ss exit=%d %s\n' "$(date +%H:%M:%S)" "$poll" "$elapsed" "$rc" "$summary"
  else
    printf '· %s poll=%d +%ss exit=%d\n' "$(date +%H:%M:%S)" "$poll" "$elapsed" "$rc"
  fi

  sleep "$interval"
done
