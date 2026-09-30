# Plan

## Immediate usable-server path — recommendations, not deployment claims

1. Reboot for installed kernel7.2.8 with Comet/LUKS recovery; prove boot durability. Dotfiles da4c02e already deployed clean on both machines, no preparation/redeployment required.
2. Finish Mason codelldb/gofumpt/goimports/oxfmt and verify editor tools.
3. Complete separate agent-settings coverage audit and deliberate provider/secret verification. No Claude/Codex configuration parity or comprehensive credential readiness claimed.
4. T3 desktop/Connect complete: matching Mac/Linux/CLI versions, live Mac→Linux service identity, Linger=yes and remote provider readiness verified. Qualify physical reboot/logout durability during remaining fleet validation; no pending login or tunnel approval.
5. Validate durable Herdr/agent/desktop use and remaining selected NiriMod/CUA-Jev checks without OCR. Each machine keeps its native shell; zshrc behavior ported to Fish, user rejected zsh login switch.

## Recovered five-level scope — September19 user choices

| Level | Scope | Present status |
|---|---|---|
|1|Full macOS/Linux dotfiles, source work and history-preserving Neovim merge|Mac+server dotfiles deployed da4c02e, clean; no extra Neovim history-merge completion inferred|
|2|Repeatable fresh-machine secret/tool/Tailscale bootstrap, existing age reuse|Bootstrap deployed; credential/secret completion unchecked; existing encrypted SSH secret decryptable by age identity|
|3|Niri/Noctalia desktop, NiriMod, configuration portability|Desktop installed historically; NiriMod/deployment verification unfinished|
|4|Shared machine skill, native inspection and CUA/Jev evaluation|Fleet skill installed; CUA/Jev integration unproven|
|5|Proton VPN later|Deferred implementation|

[Exact private September19 plan](../.local/transcripts/source-documents/linux-niri-plan-2026-09-19.md) and [Codex records51/54/56/62/65](../.local/transcripts/codex-originals/01a0b2f2-2a95-7f62-8c8d-88c7ee3f447e/messages.jsonl) preserve source. Decisions supplied/verified by parent; historical assistant implementation wording is not proof of completed deployment.

## Historical inspected-file findings from independent consultation

Read-only consultation September30, [full source](/Users/bassimshahidy/Documents/Codex/2026-09-30/task-4/consultation/consultation.txt). These were predeployment findings; da4c02e deployment supersedes old portability blockers. They are retained as provenance, not a request to redo the finished Fish port:

- zsh/.zshenv: Homebrew/sops absolute Mac paths; move portable provider PATH into noninteractive login environment.
- zsh/.zshrc: hardcoded /Users paths for cargo/bun/local bin, Mac pnpm/plugin directories, unguarded .vite-plus/env and pbcopy alias.
- restore-secrets: macOS security dependency can stop Linux workflow; encrypted secrets.env was not inspected. Review implementation without exposing values.
- Herdr: vim-herdr-navigator/drovr local sources and Neovim popup path need portable source/deployment handling; herdr-drovr and vim-herdr-navigator clean with GitHub remotes per September30 readiness; portable config still needed.
- Stow: avoid stow */; select Linux packages explicitly.

Do not copy/decrypt credentials as part of documentation work. Existing age identity can decrypt the encrypted SSH secret; identity reuse must acknowledge this exposure. Historical Proton SSH native-item and age structured-custom-item conversions were double-verified and migration cleanup completed in the recovered transcript, with originals in recoverable Trash. Do not restart conversion/cleanup. Live vault matching remains unchecked; later scoped agent grants unfinished. End-thread password-review groups are a separate remaining concern.

## Future direction — user requirements, open implementation

Mac primary dev/entrypoint; performance, stable infra and disposable-worker classes, flexible workloads. Ryzen remains hackable without taking persistent NAS/services down; temporary always-on acceptable. Windows gaming remains separate. Infra purchase not prerequisite.

Keep Eero; no server-as-router/network SPOF. Proton device protection, Tailscale access, custom DNS/network blocking, selectable home ISP/Proton exit desired. 10GbE original goal;25GbE later explored; purchases/topology unresolved.

Separate NAS,≥4 new HDDs,$400–600,redundancy/cache; SN850X/MS-02 candidates, no finalized filesystem/hypervisor.1TB infra boot SSD does not cap VM data. Avoid high-RAM demands across both infra/dev.

Proton Duo/Pass, human mail domain versus service alias subdomain, inbox/account migration and homelab SMTP belong to future personal infrastructure, not server-install prerequisites. Agent credential access needs exact runtime/item/actions/expiry. No arbitrary vault access.
