---
name: watch-command
description: Use when waiting for a shell condition such as GitHub PR checks, CI, bot review, deploy status, or HTTP readiness. Wrap the check command in watch.sh and call bash with usePTY:true and a timeout instead of writing a custom while/sleep loop.
---

# Watch Command

Use the bash tool with `usePTY: true` and a bash-tool `timeout`.

```bash
~/.pi/agent/skills/watch-command/watch.sh [--interval seconds] -- <check command...>
```

The check command must exit 0 when the wait condition is satisfied.

Example:

```bash
~/.pi/agent/skills/watch-command/watch.sh --interval 15 -- gh pr checks 123 --required
```

For complex predicates, wrap with `bash -lc`.

Do not write a manual `while true; sleep` loop. Use this script.
