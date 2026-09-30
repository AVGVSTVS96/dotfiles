---
name: codex-orchestration
description: "Orchestrate the GPT-5.6 family (sol/luna) via Codex CLI: Claude owns intent, taste, and the final call; Codex executes and reviews bounded technical work fast and deep. Use when delegating implementation, debugging, build/type/test failures, verification, mechanical refactors, heavy code-reading, or GUI/computer-use verification to Codex/GPT-5.6, for deep web research, when asked to pair with, consult, fact-check, or get a second opinion from Codex, when spinning up fresh headless Fable 5 sessions for delegation, or to conserve the orchestrator's context window."
---

# Codex Orchestration

GPT-5.6 via Codex CLI is a relentless technical workhorse: it does not stop until the job is done, which is its superpower and its failure mode. It finds its own context, survives compaction, and holds long runs 5.5 never could; it also turns five-line changes into 300-line rewrites with 2,000 lines of tests when the prompt leaves blanks. Every delegation needs three things 5.5 didn't demand: a stopping point, a diff-size expectation, and the shape of the code you want.

Send it anything technical with a clear boundary (build/type/test failures, debugging, perf, subtle logic, mechanical refactors, verification by running the thing, heavy code-reading), and just as readily ask for a second opinion: reviewing your work (`codex exec review`), pressure-testing a diagnosis or a design under clear constraints. You own intent, taste, and the final call.

Delegate for your context window as much as for speed: take back conclusions, not file contents. Fan out independent runs concurrently; readers freely, writers only on disjoint files or separate worktrees. For self-contained work that needs Claude-grade judgment or the Claude Code ecosystem, delegate to a fresh headless Fable 5 session instead: [fable5-sessions.md](fable5-sessions.md).

Before a writing run, pin state with `git status --short` so its diff is separable from pre-existing changes; writer prompts carry a standing rule: no commit, push, deploy, or config edits unless the user asked. Review what it lands (`git diff`) for scope drift and intent, and have it report what it ran to verify. Keep final judgment on product, design, UX, API shape, and naming.

## Model and effort

Sol is the sole worker; effort is the only dial. Don't reach for terra: sol at lower effort is smarter for the same speed.

- `gpt-5.6-sol` medium — the default; replaces 5.5 medium/high. Everyday delegation, clear-spec implementation, reviews.
- `gpt-5.6-sol` low — trivial, fully-specified edits; replaces 5.5 low.
- `gpt-5.6-sol` high — hard problems: debugging, unfamiliar systems, long autonomous runs, computer use, anything expected to take 10+ minutes.
- `gpt-5.6-sol` xhigh — hard diagnosis only.
- `gpt-5.6-luna` max + pro mode — deep research only (below); never for code.

Efforts are defaults, not limits: if the output misses the bar, rerun a step up without asking.

The full ladder is `none|minimal|low|medium|high|xhigh|max|ultra`. `max` disables the token-efficiency post-training: a 2-4 point quality bump for 5-10x the burn; luna pro research is its only routine use here. `ultra` is `max` plus codex-side subagents, each inheriting the full thread history at max effort; never set it from here.

## How to run it

```bash
codex exec --dangerously-bypass-approvals-and-sandbox -m gpt-5.6-sol \
  -c model_reasoning_effort=medium -C <dir> "<prompt>" </dev/null
```

Runs take minutes and can outlive Bash's 10-minute default timeout: raise it, or background the run with `-o <file>` and poll the file. The `</dev/null` matters; an open stdin pipe hangs codex silently. If codex is missing or a run fails, report the error and offer to do the work directly.

Prompt with intent, done criteria, and non-goals, then stop:

- Give every run a stopping point and a diff budget: "done when X passes and the diff stays under ~N lines." Left unbounded, it keeps improving things you didn't ask about.
- Fill the blanks it would otherwise fill itself: point at an exemplar file for the shape you want.
- Scope tests explicitly ("extend the existing spec file, no new harnesses"); unscoped, tests balloon.
- Blocked means report, not improvise: no workarounds for failing dependencies, sandboxes, or missing credentials.
- It doesn't know when it's wrong: require the final message to prove claims with command output, not assertions.
- Rule lists are scope multipliers: it satisfies every rule maximally and literally (measured: 10 style rules produced 5x the diff). Include only rules that change behavior.
- Ask for a RISKS section in the reply; it surfaces latent-breakage analysis it does internally but won't volunteer.

Prompt it simpler than you'd prompt Claude: it does what you ask and nothing else, so drop the defensive fencing.

Multi-turn: `codex exec resume <session-id>`. The id is in startup output, and `--json` captures it machine-readably; `--last` is only safe when nothing else ran in between. Full flags and review mode: [codex-cli.md](codex-cli.md).

## Example delegation

```
Repository: /abs/path/to/repo
Goal: Add keyboard navigation to the command palette (arrows + enter, wrap at ends).
Done when: palette tests pass, `pnpm typecheck` clean, diff under ~150 lines.
Constraints: no new deps; follow the hooks pattern in `useCommandPalette.ts`; no commits.
Report: files changed, behavior summary, what you ran to verify, RISKS, assumptions.
```

## Computer use

GUI and runtime verification (real UI flows, browsers, simulators, screenshots) delegates well: [computer-use.md](computer-use.md).

## Deep research

For in-depth web research, run luna at `max` with `-c reasoning.mode="pro"`: pro mode fans the question out across parallel agents and synthesizes. Token-heavy; reserve it for research that matters. Requires codex ≥ 0.145 — the npm CLI (0.144.5) rejects the key; until it ships, use the ChatGPT.app-bundled binary: `/Applications/ChatGPT.app/Contents/Resources/codex`.

## Pairing with Fable

5.6-sol and Fable 5 are strong mutual fact-checkers. Hand sol a conclusion plus its evidence and ask it to attack; verify any decisive counterclaim before accepting it. In mixed loops, Fable plans and reviews, 5.6 implements. When the two disagree, don't average: re-derive from primary sources.

## Interactive

Go interactive only when the user wants to watch or co-drive, or Codex must ask questions mid-run:

- `HERDR_ENV=1` → read [herdr-control.md](herdr-control.md)
- `$TMUX` set → read [tmux-control.md](tmux-control.md)

The operator has authorized full local execution; run Codex with permissions bypassed.
