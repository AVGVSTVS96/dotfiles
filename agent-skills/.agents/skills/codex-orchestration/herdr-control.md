# Driving interactive Codex in herdr

Requires `HERDR_ENV=1`. herdr natively detects Codex agent status, so you can block on it finishing instead of polling.

## Session loop

1. **Spawn.** Find your pane id with `herdr pane list`, split, and launch:

```bash
NEW=$(herdr pane split <your-pane-id> --direction right --no-focus | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')
herdr pane run "$NEW" "cd <dir> && codex --dangerously-bypass-approvals-and-sandbox"
```

Pane ids are not durable; re-read from `pane list` after panes close.

2. **Check the screen before prompting.** Startup dialogs (e.g. update prompts) can block the composer:

```bash
herdr pane read "$NEW" --source visible --lines 30
```

Always use `--source visible` for Codex panes (`recent` returns nothing). Confirm the header shows the configured sol model and the composer (`›`) is ready.

3. **Prompt.** Send the text and Enter as two separate commands; the gap between calls lets the composer settle (don't use `sleep`, some harnesses block it):

```bash
herdr pane send-text "$NEW" "your prompt"
```

```bash
herdr pane send-keys "$NEW" Enter
herdr pane read "$NEW" --source visible --lines 15
```

If nothing started, re-read the pane before retrying: text still in the composer means send Enter again; an empty composer means resend the prompt. A blind Enter can submit nothing or accept an unexpected dialog.

4. **Wait, then read the answer:**

```bash
herdr wait agent-status "$NEW" --status done --timeout 180000
herdr pane read "$NEW" --source visible --lines 60
```

On timeout, read the pane; Codex may be waiting on a question.

5. **Iterate** (repeat 3–4), and close when finished: `herdr pane close "$NEW"`.
