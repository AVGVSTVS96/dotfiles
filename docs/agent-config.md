# Claude Code and Codex configuration

`./install-agents` brings each machine's agents in line with this repo; `bootstrap` runs it. It needs uv, Node and the `claude` CLI, and a rerun changes nothing once everything matches.

| Source | Lands in | How |
|---|---|---|
| `claude/`, `codex/`, `agent-skills/` | `~/.claude`, `~/.codex`, `~/.agents` | stowed by `./install` file by file, so sessions and installed skills stay out of the repo |
| `claude/.claude/settings.json` | `~/.claude/settings.json` | stowed as a link, so a change Claude makes shows up in `git diff`; the proxy key comes from SOPS through `apiKeyHelper` (`claude-proxy-key`) |
| `agent-preferences/claude-global.json` | `~/.claude.json` | deep-merged into Claude's account and cache store |
| `agent-preferences/codex.toml` | `~/.codex/config.toml` | deep-merged, keeping the file's formatting; `[[skills.config]]` toggles match by name |
| `enabledPlugins` and `extraKnownMarketplaces` in `settings.json` | Claude plugins | missing marketplaces are added and missing plugins installed |
| `agent-preferences/skills.txt` | `~/.agents/skills`, linked into `~/.claude/skills` | `skills add` from each source, for skills not installed yet |

Keys the repo sets win: a local change to one of them lasts until the next `./install-agents`, so change it here instead.

Personal skills live in `claude/.claude/skills` (Claude only) or `agent-skills/.agents/skills` (every agent; the symlinks in `claude/.claude/skills` show them to Claude too). Published skills, including better-github-skill, install from their source through `skills.txt`.
