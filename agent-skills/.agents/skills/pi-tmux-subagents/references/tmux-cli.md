# tmux CLI

Resolve panes:

```bash
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} pane=#{pane_id} active=#{pane_active} cmd=#{pane_current_command} title=#{pane_title} path=#{pane_current_path}'
```

Inspect before use:

```bash
tmux display-message -p -t %140 'session=#{session_name} window=#{window_index} pane=#{pane_index} cmd=#{pane_current_command} path=#{pane_current_path}'
tmux capture-pane -p -t %140 -S -40 | tail -n 30
```

Send a shell command:

```bash
tmux send-keys -t %140 "pi --model gpt-5.5 --thinking low" C-m
```

Send a prompt safely: paste/type, send Enter separately, then capture to verify. If text remains in the editor, send Enter again.

```bash
cat <<'PROMPT' | tmux load-buffer -
You are pane %140. Task: ...
Return: findings, files touched, tests run, blockers.
PROMPT
tmux paste-buffer -t %140 && tmux send-keys -t %140 C-m
sleep 0.2 && tmux capture-pane -p -t %140 -S -40 | tail -n 20
```

Use pane IDs after resolving. Avoid targeting a whole window once panes are known.
