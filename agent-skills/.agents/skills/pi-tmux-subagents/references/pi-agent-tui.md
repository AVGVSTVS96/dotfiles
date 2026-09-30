# pi agent TUI

**Useful flags for `pi` agent:**

- `--model <pattern>`: model name/pattern; supports `model:thinking` shorthand.
- `--thinking off|minimal|low|medium|high|xhigh`
- `--list-models [search]`: inspect available model names if a pattern fails.

**Model IDs:**
- codex / gpt-5.5 = `gpt-5.5`
- claude opus 4.7 = `claude-opus-4.7`

```bash
# Launch pi tui:
pi

# Launch pi with specific model and thinking level:
pi --model gpt-5.5 --thinking low
pi --model 'gpt-5.5:low' # shorthand

pi --model claude-opus-4.7 --thinking high
pi --model 'claude-opus-4.7:high' # shorthand
```


**Inside pi:**

- `Ctrl+P`: next scoped model.
- `Shift+Ctrl+P`: previous scoped model.
- `Shift+Tab`: cycle thinking level.
- `/model`: interactive model selector.
- `/help`: help.
- `/name`: give session a title/name

**Submit prompts through tmux:**

Paste/type, send Enter separately, then capture to verify. If text remains in pi's editor, send Enter again.

```bash
cat <<'PROMPT' | tmux load-buffer -
Your prompt...
PROMPT
tmux paste-buffer -t %140 && tmux send-keys -t %140 C-m
sleep 0.2 && tmux capture-pane -p -t %140 -S -40 | tail -n 20
```

While pi works, Enter queues a steering message after the current tool turn.

**Send TUI keys through tmux:**

```bash
tmux send-keys -t %140 C-p     # Ctrl+P
tmux send-keys -t %140 BTab    # Shift+Tab
```

Prefer launch flags for a fresh pane; use TUI keys for already-running agents.
