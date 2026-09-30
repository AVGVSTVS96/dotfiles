# Interactive Agents in tmux

Use this guide when controlling coding agents in an existing tmux pane.

## Required Launch Commands

- Start Claude Code with `c` alias when available.
- If alias `c` is unavailable, run: `claude --dangerously-bypass-permissions`
- Start Codex with: `codex --yolo`

## Agent Session Workflow

1. Resolve target pane from user input (`%pane`, `session`, or `window`).
2. Check current process in pane:

```bash
tmux display-message -p -t %232 'cmd=#{pane_current_command}'
```

3. If needed, launch the requested agent in that pane using `send-keys` + `C-m`.
4. Wait briefly, then capture output to confirm startup banner/prompt.
5. Inject prompts with explicit Enter handling and verify they were consumed.

## Prompt Injection Pattern (Important)

Use this exact pattern to avoid unsent prompts:

```bash
tmux send-keys -t %232 -l -- "your prompt text here"
tmux send-keys -t %232 C-m
sleep 0.2
tmux capture-pane -p -t %232 -S -40 | tail -n 20
```

If the prompt text is still sitting at the input line, it was not submitted. Send Enter again:

```bash
tmux send-keys -t %232 C-m
sleep 0.2
tmux capture-pane -p -t %232 -S -40 | tail -n 20
```

## Robust Multiline Prompt Pattern

```bash
cat <<'PROMPT' | tmux load-buffer -
Implement X.
Then run tests.
Summarize failures.
PROMPT
tmux paste-buffer -t %232
tmux send-keys -t %232 C-m
```

## Useful Diagnostics

```bash
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} pane=#{pane_id} cmd=#{pane_current_command} active=#{pane_active}'
tmux capture-pane -p -t %232 -S -80
tmux display-message -p -t %232 'title=#{pane_title} path=#{pane_current_path}'
```

## Common Mistakes

- Sending prompt text but forgetting `C-m`.
- Assuming visible text means the agent received the prompt.
- Targeting a window/session selector repeatedly instead of locking onto a pane id.
- Launching Claude without `c` or `claude --dangerously-bypass-permissions`.
- Launching Codex without `--yolo`.
