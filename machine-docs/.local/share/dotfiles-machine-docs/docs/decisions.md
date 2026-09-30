# Current decisions

MacBook is entrypoint and primary development. Three flexible resource classes: performance (5700G today), stable infra/NAS/services (future), disposable NUC workers (future). Windows remains gaming. Existing server can run24/7 temporarily; dev experiments must not disrupt persistent storage/services.

No server router/network SPOF; keep Eero. Proton device protection, Tailscale access, custom DNS/network blocking desired;10G original goal and25G exploration do not finalize purchases. NAS≥4 new HDDs,$400–600,redundancy/cache; filesystem/hypervisor open,1TB boot NVMe not VM ceiling.

Reuse existing age identity (exact September19 08:52:01 UTC decision). It decrypts the existing encrypted SSH secret; acknowledge exposure when distributing it. Proper Proton SSH/age item management and later scoped agent access desired, historical conversion/cleanup completion double-verified in recovered Proton transcript; live vault verification remains unchecked. Mail-domain/aliases/account migration are future infra.

Each machine retains its shell: Mac zsh unchanged, server Fish; zsh login switch explicitly rejected and chsh never ran. Latest zshrc behavior port deployed into Fish at da4c02e; ai-tmux retired. Native self-updates preferred with pragmatic exceptions. [History](../machines-skill/history.md) records rationale; [sources](sources.md) preserves evidence.

Recovered September19 settled scope: NiriMod, full macOS/Linux dotfiles, pending intended commits/pushes, fresh-clone/no-squash Neovim git-filter-repo history merge, automatic Tailscale, Proton VPN later, no OCR and machine skill/CUA-Jev evaluation. [Source plan](../.local/transcripts/source-documents/linux-niri-plan-2026-09-19.md), Codex records51/54/56/62/65. Desktop+repeatable bootstrap is the scope; CLI-first is a milestone.
