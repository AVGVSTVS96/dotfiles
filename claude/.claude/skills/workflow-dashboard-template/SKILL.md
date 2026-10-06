---
name: workflow-dashboard-template
description: Live HTML dashboard for a Claude Code dynamic workflow (the Workflow tool). Use when asked to create a visualization, dashboard, tracker or "mission control" for a workflow that is running or just ran.
---

# Workflow dashboard

A Bun server reads a workflow run's transcripts incrementally and serves one HTML page that polls it every 2 s:

- stages from the script's `meta.phases`
- a timeline lane per lead
- leads with expandable detail: right now, result, context used, steps over time, where the time went, files, task brief
- an activity column
- a "needs you" panel

## Start it

```sh
bun ~/.claude/skills/workflow-dashboard-template/server.ts [wf_runId | run dir]
```

With no argument it watches the newest run. It finds the run's script on its own and takes the title from `meta.name` and the project from the leads' working directory. It prints its URL.

To keep it running after your turn ends, on Linux:

```sh
systemd-run --user --unit=workflow-dashboard-<runId> --setenv=HOST=$(tailscale ip -4 | head -1) \
  bun ~/.claude/skills/workflow-dashboard-template/server.ts <runId>
journalctl --user -u workflow-dashboard-<runId> -o cat -n 1
```

On macOS, use `nohup … &` instead of `systemd-run`.

Open the URL once in the user's preview. Don't keep reopening windows.

| Env           | Default                       | Use                                                                                                          |
| ------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `HOST`        | `127.0.0.1`                   | Bind to the Tailscale IP when the viewer is on another machine (T3's preview runs on the Mac)                |
| `PORT`        | `4777`                        | Takes the next free port if this one is busy                                                                 |
| `TITLE`       | `meta.name`                   |                                                                                                              |
| `PROJECT`     | the leads' working directory  |                                                                                                              |
| `SCRIPT`      | found automatically           | Path to the workflow script, if it isn't found                                                               |
| `DECISIONS`   | none                          | Path to a decisions JSON file (see below)                                                                    |
| `CONTEXT_CAP` | `400000`                      | The cap line on each lead's context chart                                                                    |

## Richer panels

The dashboard works on any run. These conventions in the workflow script light up more of it:

- Label agents `<phase>:<name>`, like `build:query`, and pass `phase` with titles that match `meta.phases`.
- Start every prompt with the same shared context. The task brief then shows only the part that differs.
- Lead result fields:
  - `status`: `pass` `fail` `partial` `blocked` `done` `failed`. Sets the state color.
  - `headline` or `summary`: the result line and summary bullets.
  - `metrics: [{ name, value, bar, meetsBar }]`: rows with a meter against the pass bar.
  - `decisions: [{ question, recommendation }]` and `blockers: [{ what, needs }]`: shown under "Questions it raised".
- `DECISIONS` file, re-read on every poll:

  ```json
  {
    "needsYou": [{ "now": true, "when": "Before stage 3", "title": "…", "detail": "…" }],
    "decided": [{ "match": "text from a lead's question", "answer": "…" }]
  }
  ```

  A lead's question shows as Decided when its text contains a `match`.

## Changing it

The skill's files are symlinks into `~/dotfiles/claude/.claude/skills/workflow-dashboard-template/`, the single source.

- After editing `index.html`, reload the page.
- After editing `server.ts`, run `systemctl --user restart workflow-dashboard-<runId>`.
- After adding a new file, run `~/dotfiles/install-agents`. It links files one by one.
