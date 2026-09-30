---
name: claude-session-recovery
description: Recover lost or crashed Claude Code sessions in tmux by identifying the correct session IDs from pane state, Claude debug logs, and session JSONL indexes, then safely resuming each pane. Use when a user reports crashed Claude panes, missing context, or multiple concurrent sessions from the same repo root and needs exact session recovery with verification.
---

# Claude Session Recovery

Recover sessions with evidence first, then execute resumptions.

## Workflow

1. Collect tmux topology and pane state.
2. Find candidate Claude sessions per pane.
3. Prove best match and latest session.
4. Present planned resume commands before execution.
5. Execute resume commands in target panes.
6. Verify each pane is live in Claude UI.

## 1) Collect tmux context

Run:

```bash
tmux list-windows -t <session> -F '#I:#W:#{window_active}:#{window_panes}'
tmux list-panes -a -F '#S:#I.#P pid=#{pane_pid} cmd=#{pane_current_command} title=#{pane_title} cwd=#{pane_current_path}'
```

For suspicious panes, collect scrollback:

```bash
tmux capture-pane -p -t <session>:<window>.<pane> -S -200 | tail -n 120
```

Prefer direct evidence in pane history:
- prior `claude --resume <session-id>`
- task-specific keywords in prompt history
- cwd matching expected project lane

## 2) Find candidate sessions

Use three sources in this order:

1. Direct pane evidence
- If pane history already includes the session ID, trust it first.

2. Claude debug mapping (PID correlation)
- Match pane PID to Claude debug traces when direct evidence is missing.
- Look for `.claude.json.tmp.<pid>` or equivalent process markers in `~/.claude/debug`.

3. Session indexes and JSONL content
- Scan `~/.claude/projects/*/sessions-index.json`.
- Filter by:
  - `projectPath` and cwd alignment
  - keywords in `summary` / `firstPrompt`
  - `modified` timestamp for recency
- Confirm by opening the candidate `<session-id>.jsonl` and checking first prompt/topic fit.

## 3) Pick the correct latest session

When multiple sessions match:

1. Keep only sessions relevant to the pane’s topic and directory.
2. Sort by `modified` timestamp descending.
3. Validate top candidates by reading summary + first prompt text.
4. Select the best semantic match; do not pick latest timestamp blindly if topic mismatch.

Always explain:
- pane identifier
- chosen session ID
- concrete evidence
- why alternatives were rejected

## 4) Present approval plan before execution

Before sending keys, provide:

1. Pane-to-session mapping table.
2. Exact command per pane.
3. Why each is correct and latest for that pane.

Command pattern:

```bash
tmux send-keys -t <session>:<window>.<pane> C-c 'claude --resume <session-id> --dangerously-skip-permissions' Enter
```

## 5) Execute and verify

After running resume commands, verify:

```bash
tmux list-panes -t <session>:<window> -F '#I.#P cmd=#{pane_current_command} title=#{pane_title}'
tmux capture-pane -p -t <session>:<window>.<pane> -S -120 | tail -n 80
```

Success signals:
- `pane_current_command` switches to Claude binary (for example `2.1.xx`)
- pane title shows Claude UI
- prompt/transcript visible in pane output

If launch appears stuck, wait briefly and re-check capture output before retrying.

## Keyword strategy for topic recovery

Derive search terms from the user request and pane history instead of fixed keywords.

1. Extract nouns and exact phrases from the user description.
2. Add nearby technical terms visible in pane scrollback and cwd.
3. Search those terms against `summary`, `firstPrompt`, and JSONL leading messages.
4. Prefer sessions that match multiple independent signals (keywords + path + recency).

Avoid hardcoded project-specific term lists in this skill so it stays reusable across repos and teams.

## Output format to user

Return in this order:

1. Found sessions grouped by pane/window.
2. Proposed command per pane.
3. Evidence for correctness and recency.
4. Execution results and verification status.

Never execute recovery commands before presenting the plan unless explicitly told to proceed immediately.
