# Computer Use

Delegate GUI and runtime verification to Codex: real UI flows, browsers, simulators, screenshots, independent runtime inspection. 5.6 is the strongest computer-use model available; use sol at `high`. Don't delegate checks you can run directly (typecheck, lint, tests). Launching apps, simulators, or browsers to verify work is fine without asking; ask first only if the run could disrupt the user's environment beyond that.

```bash
ARTIFACT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/codex-cu.XXXXXX")
codex exec --dangerously-bypass-approvals-and-sandbox -m gpt-5.6-sol \
  -c model_reasoning_effort=high --add-dir "$ARTIFACT_DIR" \
  -C <dir> -o "$ARTIFACT_DIR/report.md" "<prompt>" </dev/null
```

The prompt must be self-contained:

- exact behavior to verify, platform and app type
- launch commands, credentials, fixtures
- whether source edits are allowed (default no)
- where screenshots and logs go (the artifact dir)
- a pass/fail/blocked verdict with steps performed, observed behavior, and screenshot paths

Read the report, spot-check the screenshots yourself, then summarize for the user.
