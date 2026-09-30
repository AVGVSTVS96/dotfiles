# Driving interactive Codex in tmux

Requires `$TMUX` (or a user-named target). tmux has no agent-status detection; verify everything by capturing the pane.

## Session loop

1. **Spawn.** Split without stealing focus and capture the new pane id:

```bash
PANE=$(tmux split-window -h -d -c <dir> -P -F '#{pane_id}')
tmux send-keys -t "$PANE" "codex --dangerously-bypass-approvals-and-sandbox -m gpt-5.6-sol" C-m
```

To use an existing pane instead, resolve its id via `tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'`.

2. **Check the screen before prompting.** Startup dialogs (e.g. update prompts) can block the composer:

```bash
tmux capture-pane -p -t "$PANE" -S -40
```

Confirm the header shows `gpt-5.6-sol` and the composer (`›`) is ready.

3. **Prompt.** Insert the text and Enter as two separate commands; the gap between calls lets the composer settle (don't use `sleep`, some harnesses block it):

```bash
tmux send-keys -t "$PANE" -l -- "your prompt"
```

```bash
tmux send-keys -t "$PANE" C-m
tmux capture-pane -p -t "$PANE" -S -20
```

If nothing started, re-capture before retrying: text still in the composer means send `C-m` again; an empty composer means resend the prompt. A blind `C-m` can submit nothing or accept an unexpected dialog. For multiline prompts use a buffer:

```bash
cat <<'PROMPT' | tmux load-buffer -
line 1
line 2
PROMPT
tmux paste-buffer -t "$PANE"
tmux send-keys -t "$PANE" C-m
```

4. **Wait by polling.** Re-capture the pane every 15-30s; runs may take minutes, so don't rapid-fire. Codex is done when its final message renders and the composer is idle again (no spinner/`Working` indicator above the status line). Read the answer from the same capture.

5. **Iterate** (repeat 3–4), and close when finished: `tmux kill-pane -t "$PANE"`.
