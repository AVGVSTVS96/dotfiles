# Choosing a model

Use the user's subjective model notes as policy.

## codex / gpt-5.5

No-bs, narrow technical engineer. Best for precise implementation and troubleshooting.

Use for:

- fast straightforward coding
- build/test/type failures
- deep debugging
- subtle correctness issues
- performance/concurrency/mechanical refactors

Watch for:

- overcomplicating simple product needs
- losing the big picture
- dense or confusing explanations

Effort:

- `low`: default for small/medium straightforward engineering; fast and usually enough.
- `medium`: more moving pieces or uncertainty.
- `high`: large technical scope, subtle bugs, hard debugging.
- `xhigh`: only when other attempts fail or the issue is genuinely difficult.

## claude-opus-4.7

Creative, craft-minded engineer. Better at intent, architecture, APIs, organization, and clear explanations.

Use for:

- product/API judgment
- architecture and module boundaries
- code organization and maintainability
- creative alternatives
- translating/simplifying Codex findings
- documentation/prose quality

Watch for:

- missing subtle technical bugs
- less depth than Codex on hard troubleshooting

Effort:

- `medium`: simple straightforward tasks, explanations, or summaries
- `high`: default. Lower levels noticeably degrade quality.
- `xhigh`: complex synthesis only; often prefer Claude high + Codex high instead.

## Pairing

- Claude frames the shape; Codex validates or implements.
- Codex finds the bug; Claude checks whether the fix is product/API-relevant.
- Codex writes code; Claude makes the new code more simple, clean, and elegant.
- Codex implements a new feature; Claude cleans up the code or proposes a better architecture or API.
- Codex verifies technical accuracy; Claude writes the explanation.
