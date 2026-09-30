# Fleet

Bassim's plan and operating knowledge for his machines, plus shared skills and tools. **MacBook is the entrypoint and primary development machine.** Performance, stable infrastructure and disposable workers are resource classes, not rigid workload walls. Experiments must not interrupt persistent services or storage.

| Machine / class | Role | State |
|---|---|---|
| MacBook | Primary development, fleet control and remote entrypoint | In use |
| Ryzen 7 5700G / CachyOS `server` | Current performance machine; temporarily always-on | SSH over Tailscale verified September 30 |
| Future infrastructure box | Stable NAS, VMs, VPN/DNS and persistent services | Hardware/storage/topology unselected |
| Future cheap NUCs | Disposable workers | Planned |
| Windows `AVGVSTVS` | Gaming | Separate from server plan |
| Comet KVM | Console, boot/unlock and recovery | `https://glkvm.local`, working |

**Access:** `ssh bassim@server.tail43f1c6.ts.net` (`100.113.223.113`) with the existing Mac key. Host Ed25519 fingerprint: `SHA256:DtV/0bYzbpUjGlNfKzY2mytBIDmXRfd4QZlZcm8CAWI`. Password/root SSH login disabled; unnecessary Mac-only restrictions removed. Other-device authentication and reboot durability remain untested. No `Host server` alias exists and ordinary known_hosts lacks the target; current pinned trust is task-local. See [status](machines-skill/status.md) and [access](machines-skill/howto/server-access.md).

The installed **machines** skill resolves to this repository. Dotfiles are deployed and clean on Mac+server at `da4c02e`. Each machine keeps its shell: Mac zsh unchanged, server Fish retained; chsh never ran. Latest zshrc **behavior** is ported into Fish, not a choice to change the login shell. Live Fish resolves Claude, Codex, Herdr and T3; Neovim plugins are lockfile-aligned. Tealdeer retained to resolve bootstrap conflict.

T3 desktop/CLI/Mac versions match; Mac→Linux service-backed Connect verified with Linux desktop closed, then desktop relaunched. Linux service enabled/running with Linger=yes; transient relay allocation error resolved. Remote Codex0.159.2/Claude2.1.285 report authenticated; no new agent jobs started. Credentials/provider state is not comprehensively verified; separate agent-settings coverage audit is ongoing, so Claude/Codex configuration parity is not claimed. Desktop configs, authorized_keys, original source repositories and Claude settings were preserved.

## Next steps

1. Reboot for installed kernel7.2.8 with Comet/LUKS recovery available, then verify boot durability.
2. Finish four Mason tools: codelldb, gofumpt, goimports and oxfmt (pending normal Neovim start).
3. Complete the separate agent-settings coverage audit and deliberate credentials/provider authentication checks; do not infer parity or authentication from binary/PATH checks.
4. Qualify T3 physical reboot/logout durability during fleet validation; service-backed connection and provider readiness already verified, with no pending Connect login or approval.
5. Prove durable Herdr/agent and desktop workflows, complete remaining selected NiriMod/CUA-Jev evaluation, and record repeatable-bootstrap/recovery results.

The order is an implementation recommendation; full macOS/Linux dotfiles, NiriMod, history-preserving Neovim merge, automatic Tailscale and machine-skill/CUA evaluation are recovered user choices, not optional substitutions. Proton VPN remains later. [Plan](machines-skill/plan.md) records concrete portability findings and remaining choices.

## Future infrastructure

Keep Eero and keep the server out of the router/network single-point-of-failure role. Goals: Proton protection for all devices, Tailscale access, custom DNS and network ad/tracker blocking. Original wired goal was 10GbE; later 25GbE exploration does not select a switch/router or purchase. NAS direction: at least four new HDDs, $400–600, redundancy/cache; filesystem/hypervisor unchosen. A 1TB infrastructure boot NVMe is not a VM-capacity ceiling. Mail domain, service-alias subdomain and inbox/account migration belong to future personal infrastructure.

## Where things live

- [machines-skill/](machines-skill/SKILL.md): current inventory, status, plan, decisions and operating procedures; update in place.
- [docs/decisions.md](docs/decisions.md): compact user intent and identity exposure; [docs/sources.md](docs/sources.md): evidence index. Detailed historical audit/research is preserved under `docs/supporting/`; private original captures stay Git-ignored under `.local/transcripts/`.
- `plugins/comet-kvm/`: generic source snapshot with its package boundary intact. Installed Comet consumers still use `~/Developer/comet-kvm` and Codex's cache; their migration is a separate pending action.
- [AGENTS.md](AGENTS.md): repository rules. Current verified skill facts and latest user decisions override historical briefs/source snapshots. Source coverage is expanding: nine original ChatGPT captures and selected Codex exports, not every conversation.
