# Claude Code and Codex configuration

`./install-agents` brings each machine's agents in line with this repo; `bootstrap` runs it. It needs uv, Node and the `claude` CLI, and a rerun changes nothing once everything matches.

| Source | Lands in | How |
|---|---|---|
| `claude/`, `codex/`, `agent-skills/` | `~/.claude`, `~/.codex`, `~/.agents` | stowed by `./install` file by file, so sessions and installed skills stay out of the repo |
| `agent-preferences/claude.json`, plus `claude-macos.json` on the Mac | `~/.claude/settings.json` | deep-merged: keys the repo doesn't set, like herdr's hooks, stay |
| `agent-preferences/claude-global.json` | `~/.claude.json` | deep-merged into Claude's account and cache store |
| `agent-preferences/codex.toml` | `~/.codex/config.toml` | deep-merged, keeping the file's formatting; `[[skills.config]]` toggles match by name |
| `enabledPlugins` and `extraKnownMarketplaces` in the Claude JSON | Claude plugins | missing marketplaces are added and missing plugins installed |
| `agent-preferences/skills.txt` | `~/.agents/skills`, linked into `~/.claude/skills` | `skills add` from each source, for skills not installed yet |

Keys the repo sets win: a local change to one of them lasts until the next `./install-agents`, so change it here instead.

Personal skills live in `claude/.claude/skills` (Claude only) or `agent-skills/.agents/skills` (every agent; the symlinks in `claude/.claude/skills` show them to Claude too). Third-party skills install from their source through `skills.txt`. The few kept in `agent-skills` (dogfood, electron, slack, vercel-sandbox, to-issues, to-prd, write-a-skill, zoom-out) are no longer published by their source and keep its license next to them.
