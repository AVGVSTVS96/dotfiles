# Codex CLI Reference

The canonical `codex exec` invocation, tier ladder, and prompting rules live in SKILL.md; this is the long tail.

## Flags

- `-m gpt-5.6-sol|gpt-5.6-luna`: sol for all work, luna only for pro research; ladder in SKILL.md
- `-c model_reasoning_effort=none|minimal|low|medium|high|xhigh|max|ultra`: set explicitly; warnings in SKILL.md
- `-o <file>`: write the final message to a file for clean capture
- `--json`: stream events as JSONL on stdout (session id, progress, failures); pair with `-o` for background runs
- `--skip-git-repo-check`: required outside a git repo
- `--output-schema <file>`: force the final message into a JSON Schema shape
- `-i <image>`: attach screenshots
- `--add-dir <dir>`: grant extra writable roots
- `--ephemeral`: throwaway run, nothing persisted, not resumable
- `--color never`: plain logs for capture

Always end scripted invocations with `</dev/null`; an open stdin pipe hangs codex silently before any API call.

## Stdin

Pipe long context via stdin (it arrives as a `<stdin>` block appended to the prompt):

```bash
git diff | codex exec --dangerously-bypass-approvals-and-sandbox -m gpt-5.6-sol "Review this diff for correctness."
```

## Reviews

`codex exec review` is a dedicated review mode, sharper than prompting for a review yourself:

```bash
codex exec review --uncommitted -m gpt-5.6-sol -c model_reasoning_effort=medium -o <file> "Focus on correctness regressions."
```

Pick the diff with `--uncommitted`, `--base <branch>`, or `--commit <sha>`. Supports `--json` and `-o`.

Ask for findings first: severity, file:line, concrete failure mode, fix direction; no edits. Require an explicit "nothing found" naming what it inspected; an empty review otherwise reads as a failed run and triggers pointless reruns. Findings are evidence, not verdicts: spot-check the cited code before relaying, and separate confirmed from unverified.

Review small local diffs yourself; delegate only when a second perspective adds something, never to avoid reading the code.

## Sessions

```bash
codex exec resume <session-id> "<follow-up>"
codex exec resume --last "<follow-up>"    # only safe when nothing else ran in between
```

The session id appears in exec's startup output; `--json` captures it machine-readably. Capture it whenever you might fan out more runs before following up. `--last` is cwd-filtered; add `--all` for cross-directory lookup.

If a final message fails to deliver, resume and have it diff against its previous output rather than regenerate — rewrites drift.

## Interactive

```bash
codex --dangerously-bypass-approvals-and-sandbox -m gpt-5.6-sol
```

Drive it through herdr or tmux (see the control files). `codex resume` reopens a previous interactive session (add `--include-non-interactive` to reopen exec sessions in the TUI); `codex fork` branches one.
