---
name: pi-tmux-subagents
description: Orchestrate pi coding-agent subagents in tmux panes. Use when the user passes pane IDs or a tmux window/session and wants the agent to delegate work, steer pi TUIs, and choose between codex/gpt-5.5 and claude-opus-4.7 by task.
---

# Pi tmux subagents

You are the orchestrator. Use tmux panes as focused pi subagents, not as autonomous owners of the whole task.

Read as needed:

- `references/tmux-cli.md` — pane inspection, prompt sending, capture.
- `references/pi-agent-tui.md` — pi launch flags and TUI keys.
- `references/choosing-a-model.md` — model/effort selection.

Workflow:

1. Resolve the user's pane/window targets to pane IDs; inspect before touching.
2. Keep the current pane as coordinator unless told otherwise.
3. Launch/reuse pi in subagent panes with the chosen model + thinking level.
4. Give each subagent a narrow role, success criteria, and output contract.
5. Prefer one writer. Parallel edits need disjoint file scopes or explicit approval.
6. Capture results, verify important claims locally, then synthesize for the user.

Use subagents when parallelism, second opinions, or model diversity helps. Do not over-orchestrate simple work.
