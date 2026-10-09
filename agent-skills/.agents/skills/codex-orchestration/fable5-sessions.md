# Driving fresh Fable 5.1 sessions (headless Claude Code)

Fresh context windows are cheap; bloated ones are not. When work is self-contained but needs Claude-grade judgment, breadth, or the Claude Code tool ecosystem (skills, MCP, subagents, CLAUDE.md), delegate it to a headless Fable 5.1 session instead of doing it in your own window. Fifty prompts to fresh sessions cost less than one 200k-token conversation.

## Canonical invocation

```bash
cd <dir> && claude -p --model claude-fable-5-1 --dangerously-skip-permissions "<prompt>"
```

Runs take minutes: background them and capture stdout to a file. The session inherits skills, CLAUDE.md, and MCP config from the directory it starts in.

## The brief-file pattern

For anything nontrivial, write the full spec to a `BRIEF.md` in the working directory and keep the prompt to one line: "Read BRIEF.md and execute it; your deliverable is findings.md." The spec stays reviewable, the prompt stays short, and the deliverable is a file you read conclusions from, never the transcript.

## Pitfalls (observed)

- **The process exits with its final message.** A `-p` delegate that backgrounds work and ends its turn expecting to be re-invoked dies before the work completes. Tell delegates explicitly: run everything to completion within the turn (launch parallel work with `&`, then shell `wait`).
- **Rescue by resuming.** If a delegate exits early, its session persists: `cd <dir> && claude -c -p "<pick up where you left off>"` continues it with full context intact.

## Useful flags

- `--effort low|medium|high|xhigh|max`: reasoning effort dial
- `--output-format json`: structured result with `session_id`, cost, and final text; capture the session id for multi-turn
- `--resume <session-id> -p "<follow-up>"`: continue a session; `--fork-session` branches it; `-c` continues the most recent in the cwd
- `--json-schema '<schema>'`: force structured final output
- `--append-system-prompt "<text>"`: role/behavior steering without touching the task prompt
- `--bare`: skip hooks, LSP, and plugins for faster startup on pure-compute delegations
- `--allowedTools` / `--disallowedTools`: scope the delegate's tool surface
- `--no-session-persistence`: throwaway runs, nothing written to disk
- Pipe context via stdin: `git diff | claude -p "review this diff"`

## Routing: Codex vs fresh Fable

- **Codex (GPT-5.6):** bounded, deep technical execution; the relentless specialist.
- **Fresh Fable 5.1:** work needing judgment, taste, multi-step orchestration, or the Claude Code ecosystem, including running its own Codex fan-outs. Two-level delegation: brief one Fable session, it drives N Codex runs, you read one findings file.

Fan out independent delegations concurrently in the background, same as Codex execs.
