---
name: tmux
description: Control tmux from the CLI for session/window/pane inspection, command execution, capture, and troubleshooting. Use when the user asks to work in a specific tmux target (pane id like %232, window name/index, or session name), run commands in existing panes, validate pane output, or automate interactive terminal workflows.
---

# tmux CLI Control

Use tmux as a remote terminal control plane: inspect targets, send input, verify output, and keep work scoped to the pane/session the user names.

## Core Workflow

1. Resolve the target the user provided.
2. Inspect the target state before sending input.
3. Send input with explicit Enter handling.
4. Capture pane output and verify the action happened.
5. Report what was run and what changed.

## Resolve Targets

Accept user target hints in these forms:

- Pane id: `%232`
- Session name: `workspace`
- Window selector: `workspace:6` or `workspace:6.2`
- Window name/title hints (resolve via listing)

Use:

```bash
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} pane=#{pane_id} active=#{pane_active} cmd=#{pane_current_command} title=#{pane_title}'
```

If the user gave a session/window name instead of a pane id, resolve it to a concrete pane id first.

## Inspect and Capture

Before sending commands, quickly inspect context:

```bash
tmux display-message -p -t %232 'session=#{session_name} window=#{window_index} pane=#{pane_index} cmd=#{pane_current_command}'
tmux capture-pane -p -t %232 -S -30
```

Use `capture-pane` again after actions to verify outcomes.

## Send Input Reliably

For normal shell commands:

```bash
tmux send-keys -t %232 "echo hello" C-m
```

For arbitrary text (safer quoting):

```bash
tmux send-keys -t %232 -l -- "text with spaces and symbols"
tmux send-keys -t %232 C-m
```

For multiline payloads, prefer tmux buffers:

```bash
cat <<'PROMPT' | tmux load-buffer -
line 1
line 2
PROMPT
tmux paste-buffer -t %232
tmux send-keys -t %232 C-m
```

## Critical Gotcha: Prompt Not Actually Sent

Interactive agents often leave prompt text in the input line when only text is injected and Enter is not sent correctly. Never assume the prompt executed just because text appears in the pane.

Always do all three steps:

1. Insert prompt text (`send-keys -l` or `paste-buffer`).
2. Send Enter separately with `tmux send-keys -t <target> C-m`.
3. Verify by capturing pane output; if prompt is still sitting in input, send `C-m` again and re-check.

## Safety and Accuracy

- Prefer targeting a specific pane id once resolved.
- Echo or capture output after each important action.
- Keep commands idempotent when possible during testing.
- If multiple panes are plausible, list options and pick the one matching user intent.

## Interactive Coding Agents

For agent-specific launch commands, prompt-delivery patterns, and verification tactics, read:

- `references/coding-agents.md`
