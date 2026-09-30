# Durable artifacts

Where the evidence lives on the Mac. Paths are absolute; nothing here is
copied into this repo. Read these when a fact in this skill needs its source.

## Repos

| Path | What |
|---|---|
| `~/Developer/fleet` | Canonical current repository; ~/Developer/homelab retained original |
| `~/Developer/comet-kvm` | Comet KVM MCP server + skill (README, AGENTS.md, verification.md) |
| `~/dotfiles` | Stow-based dotfiles, `git@github.com:AVGVSTVS96/dotfiles.git`, uncommitted changes pending |
| `~/Documents/GitHub/nvim` | Neovim config (LazyVim), symlinked to `~/.config/nvim`; separate repo, to be merged into dotfiles |

## Codex outputs (Sep 2026)

| Path | What |
|---|---|
| `/Users/bassimshahidy/Documents/Codex/2026-09-30/task-7/desktop/receipt.md` | Official T3 Linux desktop installed, visibly launched/relaunched; exact Mac/CLI alignment; source/hash/launcher evidence and completed same-account Mac→Linux service-backed Connect verification |
| `/Users/bassimshahidy/Documents/Codex/2026-09-30/task-7/receipt.md` | GPT T3 stable0.0.44 install; normal approval history, installer/hash evidence, version/PATH checks, preservation comparison; no services/logins |
| `~/Documents/codex-thread-digest/SUMMARY-2026-09-21.md` | Digest of the 8 homelab threads, Sep 9 to 19 |
| `~/Documents/codex-thread-digest/index.json` | Thread IDs, labels, rollout paths, sizes |
| `~/Documents/Codex/2026-09-16/all-right-we-ve-got-the/outputs/HANDOFF.md` | Omarchy recovery handoff: hardware table, BIOS 3645 flash, crash tests, NIC fault, Keychain items, KVM TLS |
| `…/all-right-we-ve-got-the/outputs/bios/` | ASUS B550-F BIOS 3645 package + USB image |
| `…/all-right-we-ve-got-the/outputs/glkvm-tls/`, `work/glkvm-tls-private/` | Comet CA and signing material |
| `…/all-right-we-ve-got-the/outputs/omarchy-access/` | `unlock-omarchy.py` KVM unlock helper (Omarchy era) |
| `~/Documents/Codex/2026-09-16/read-outputs-handoff-md-and-its/outputs/FRESH-DIAGNOSIS.md` | Crash diagnosis (Sep 17): power-delivery-at-idle hypothesis, C-state mitigation, PSU test plan |
| `…/read-outputs-handoff-md-and-its/outputs/claude-review/WHAT-WE-MISSED.md` | Reset-reason register audit across 7 crashes |
| `…/read-outputs-handoff-md-and-its/outputs/power-capture/` | NCT6798 voltage capture procedure and samples |
| `~/Documents/Codex/2026-09-19/https-www-youtube-com-watch-v/` | CachyOS install workspace (Sep 19) |
| `~/Documents/Codex/2026-09-17/the-omarchy-server-is-up-and/outputs/omarchy-dotfiles-migration-plan.md` | Dotfiles migration plan. Omarchy-specific parts superseded; ownership model and app map still apply |
| `~/Documents/Codex/2026-09-08/codex-threads-01a06199-a8c4-7800-b672/outputs/` | Proton Pass migration evidence: `proton-organization-plan-2026-09-19.md`, `review-resolution-status.json`, verification JSONs |
| `~/Documents/Codex/2026-09-08/codex-threads-01a06199-a8c4-7800-b672/work/bin/pass-cli` | Proton `pass-cli` 2.3.3 built from source, not on PATH |
| `~/Library/Application Support/Codex Password Reconciliation/` | Bitwarden exports (`raw/`), credential review app (`review-app/credential-review.html`) |

## Raw threads

Codex rollouts under `~/.codex/sessions/2026/09/`. IDs and sizes in the digest
index. The two Omarchy crash threads are 250 to 300 MB each; grep them, don't
read them.

| Prefix | Thread |
|---|---|
| `01a0b987` | Install CachyOS with Omarchy styling (Sep 19) |
| `01a0b909` | ProtonPass Implementation (Sep 19) |
| `01a0b2f2` | Dotfiles / Secrets / Auth (Sep 18 to 19) |
| `01a0b28d` | Comet KVM agent integration (Sep 17 to 18) |
| `01a0af10` | Proton Duo setup plan reopen (empty) |
| `01a0ad6e` | omarchy-server graphics crash (Sep 16 to 17) |
| `01a0aa5b` | omarchy-server install troubleshooting (Sep 16 to 17) |
| `01a083bd` | ProtonPass Setup (rollout missing; continued in `01a0b909`) |

## Handoffs

`~/Developer/homelab/handoffs/` holds task briefs passed between agents. They
are point-in-time and may be superseded; current fleet history/status and latest user decisions win on conflict.
