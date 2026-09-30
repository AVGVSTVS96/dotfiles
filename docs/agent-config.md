# Claude Code and Codex configuration

`./install-agents` installs the source-backed configuration on either machine. `--dry-run` lists changes; `--target PATH` supports an isolated verification home. `./install` also runs it after the existing Stow selection. It requires uv and stow; uv supplies Python >=3.11 and the pinned tomlkit0.13.3 dependency.

Preferences live in `agent-preferences/claude.json` and `codex.toml`. They merge into the live settings files, preserving settings the repository does not define. Existing Herdr hooks, Codex app/marketplace paths, project trust, accounts, history and generated hook hashes stay local. No auth stores or session history are tracked. Claude user-scope Onshape MCP is merged by its source endpoint only; authentication stays per machine.

`claude`, `codex` and `agent-skills` are Stow packages installed with `--no-folding`. Global instructions, commands, output styles, rules and local skill source files are linked individually. Skill directory links are listed separately in `skill-links.json`, retaining the original relative targets. Runtime files subsequently created in these directories do not enter the repository.

Before changing any existing file or link, the helper saves it beneath `~/.local/state/dotfiles/agent-backups/<UTC timestamp>/`, preserving its relative path. Settings replacements are atomic. The Claude auth/account store itself is never backed up; adding the source MCP definition records only the prior absent definition. Re-running with unchanged preferences makes no changes. Existing non-symlink directory conflicts stop installation instead of deleting a directory.

## Preserved differences and remaining coverage

The Mac's notify/Sky computer-use command, app paths, desktop/controller/account data and project trust are not copied to Linux. Linux's managed app configuration, web_search, model_verbosity and Herdr integrations remain. Mac Herdr hooks also remain byte-for-byte; neither settings overlay owns the hook scripts.

Paper Desktop is left Mac-only: its enabled-plugin setting and marketplace are not added on Linux. Existing Linux plugin selections are preserved. Mac-only cua-driver MCP is untouched on Mac and not migrated. Onshape's definition is portable, but this migration does not create or transfer an OAuth login.

Native Codex inventory confirms Gmail and Slack are already installed and enabled on Linux under openai-curated-remote. Their managed catalogs are not duplicated and account connections are not tested. The personal Comet plugin is absent on Linux. Computer-history and the old computer-use plugin remain app/platform-owned. Common app plugin preferences and the source disabled Chrome DevTools/OpenAI Docs/Onshape MCP definitions are merged. This is configuration coverage, not authenticated provider/plugin readiness.

The Codex source disables hatch-pet and four GitHub skills; the helper preserves those selections and adapts only the hatch-pet source path to this home. Its source rule allows `but`; it is preserved verbatim.

`skill-provenance.json` records transferred local source snapshots. Two repositories have Bassim-authored commits; other unregistered local skills retain their files without an authorship claim. `installed-skills.json` records47 third-party origins and source-folder hashes from the existing lockfile; their installed trees are not blindly vendored or fetched from unpinned current branches. System/synced/plugin-managed skills remain managed by their applications. Broken existing Mac links are recorded in the audit, not replaced with guessed sources. The machines documentation snapshot described below provides Linux reference coverage; the Comet runtime integration remains separate.

The heterogeneous `~/.claude.json` cache/account store is never tracked. Only the source-backed Onshape MCP entry and six confirmed global preferences below are merged; all other local keys are retained.

GitButler skill source files carry the Mac immutable flag. The helper preserves those originals in place and manages byte-identical copies from protected-skills instead of changing their links/flags. Linux receives the same content without imposing Mac file flags.

## Enabled portable Claude plugins

The three source-enabled portable plugins (code-simplifier, frontend-design and plugin-dev) are installed on Linux through Claude's native plugin CLI from an exact source-only marketplace snapshot. `claude-plugin-sources.json` records origins, observed versions/commit metadata and file SHA256 values. Cache leases, installation registries, auth and runtime state are excluded. Linux owns the generated local marketplace/installed registry; the Mac marketplace and installed plugins stay unchanged. Installation is skipped when the recorded source files already match. Existing conflicting marketplace sources stop installation for coordination.

Claude reserves the official namespace for Anthropic-hosted sources, so Linux's exact source snapshot uses `bassim-dotfiles`. The three active source plugin IDs map to that namespace on Linux; the official IDs are disabled there to avoid loading duplicates. Source files are unchanged and SHA256-verified. Mac IDs and registry stay unchanged. This is an explicit packaging difference, not a new upstream plugin version.

Only Git-tracked package sources are adopted. Stow explicitly excludes *.local.json and .DS_Store, preserving ignored repo-local/runtime permission files. Backup directories are private (0700).

## Portable continuation

38 existing third-party skill trees are captured byte-for-byte with origins, file hashes and licensing evidence in third-party-skill-snapshots.json; upstream code was not updated. Apache/MIT notices are retained under agent-preferences/licenses. Six recorded skill folders are absent; three additional skill licenses were not established. unresolved-skill-sources.json records these nine gaps; the five exposed broken links are not repaired from guesses.

Linux's machines skill resolves to a29-Markdown-file snapshot of canonical fleet docs. Only a location/write-back note is appended to SKILL.md. Private transcripts, local/auth/cache state and Mac credential helpers are excluded. Mac's canonical machines links remain unchanged; fleet is never modified by this installer.

Six confirmed Claude global-store preferences are merged at their original precedence: autoConnectIde, copyFullResponse, preferredNotifChannel, workflowSizeGuideline, teammateMode and claudeInChromeDefaultEnabled=false. No account-store backup or wholesale transfer occurs; backups contain only those preference keys. The installed2.1.285 config-panel/schema code confirms them. Native autoUpdates=false protection, deprecated showSpinnerTree, generated claudeCodeHints and account/cache/history keys remain local. deepLinkTerminal is auto-derived from TERM_PROGRAM; diffSidebarOpen is session UI state; fallbackAvailableWarningThreshold has no established current consumer. They remain local. In particular, settings.json's notification channel remains auto while the source store choice is ghostty, matching the Mac's existing two-layer state.

Comet dependencies resolve and import using the canonical locked source on CachyOS, including PyAV; no external ffmpeg executable is required. This proves Python/runtime compatibility only. The existing macOS Keychain helper cannot run on Linux; no credentials, endpoint configuration or grants are transferred, and no KVM service was contacted. Paper Desktop local service and the Mach-O cua-driver remain unavailable on Linux.
