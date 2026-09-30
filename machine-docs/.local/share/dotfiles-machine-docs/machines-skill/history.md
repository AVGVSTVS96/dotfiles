# History

Decisions and turning points, newest first. One line each, with the why. Current fleet records override archived source briefs.

- **2026-09-30 13:59 UTC server shell and tools** Bassim, in his words: the server keeps Fish; port his latest zshrc to it rather than switching shells (he never asked for zsh as login shell). Dotfiles d60c4aa deployed on Mac and server without sudo or push; Mason/treesitter finished; Proton Pass CLI installed signed out. Claude desktop has no official Arch build and Proton ships its app as DEB/RPM only, so both wait on his choice, as does scoped Pass agent access (pass-cli agents: expiry, per-item viewer grants, audit). [Report](/Users/bassimshahidy/Documents/Codex/2026-09-30/task-5/INVENTORY-REPORT.md).
- **2026-09-30 13:41 UTC Connect completion** User specifically approved persistent Linux managed access. Existing Google account reused on both apps; official CLI device authorization completed. Linux t3code.service installed/enabled/running and normal vendor setup enabled Linger=yes. Mac→server Connected verified through live remote diagnostics PID725452 matching the pinned CachyOS service backend, including Linux desktop closed, then desktop relaunched successfully. Activity publishing off and loopback-only3773 listener. Temporary relay allocation-not-ready resolved by saved-connection retry. Remote Codex0.159.2/Claude2.1.285 authenticated; no agent job or provider login. No Connect blocker remains. [Receipt](/Users/bassimshahidy/Documents/Codex/2026-09-30/task-7/desktop/receipt.md).

- **2026-09-30 desktop clarification** User meant the T3 desktop app plus T3 Connect. GPT task installed official Linux Nightly AppImage matching the existing Mac, aligned CLI0.0.44-nightly.20260929.2456, visibly launched and relaunched in Niri through the user desktop entry. Existing binaries/shell files preserved. Both apps prepared at Connections; account authorization and Linux-only Connect exposure approval remain, with no tunnel/service created. [Receipt](/Users/bassimshahidy/Documents/Codex/2026-09-30/task-7/desktop/receipt.md).

- **2026-09-30 11:14–11:17 UTC** User selected GPT task execution for the explicitly approved official T3 install. Normal review allowed stable0.0.44 installation over pinned SSH; absolute/empty-environment version checks passed, existing CLI and shell hashes unchanged. Earlier Claude external-code denial was disclosed during review; no Claude launch, bypass, approval/network changes, logins or services. [Receipt](/Users/bassimshahidy/Documents/Codex/2026-09-30/task-7/receipt.md).

- **2026-09-30 recovery** September19 full dotfiles/NiriMod/five-level choices confirmed; Proton native SSH/structured age item conversion double-verified with cleanup complete and recoverable Trash, separate password reviews remain. Live vault not inspected.
- **2026-09-30** Fleet became canonical installed machines skill; original homelab preserved. Overview prioritizes useful access/software work, with future hardware parked.
- **2026-09-30** SSH works over existing tailnet with existing Mac key; unnecessary Mac-only restrictions removed; password/root login disabled. Other devices/reboot/alias still untested.
- **2026-09-30 reconciliation** Mac entrypoint AND primary dev; performance/infra/disposable classes are flexible resources. No server router/SPOF; Eero retained;10G goal later25G exploration, purchases unresolved.
- **2026-09-19 08:52:01 UTC** User: “ok use my existing age key”; supersedes server-specific proposals. Existing encrypted SSH secret is decryptable by it; no credentials copied in this documentation task.
- **2026-09-21** Bassim: the server has been stable since C-states were disabled;
  that is sufficient, no PSU swap. Ignore the ATX reset question. Repo stays
  public; no SOPS needed because it holds locations of secrets, not values.
- **2026-09-21** Verified server state via Comet console: only user is `bassim`
  (the `kosis` user in `handoffs/2026-09-21-fable-handoff.md` does not exist). sshd disabled.
  Created this skill as the shared source of truth. (Fable, Claude Code)
- **2026-09-20 to 21** Server joined the tailnet as `server` with
  `--accept-dns=false` (after the Codex threads; done via the console, likely by
  Machine God). Exact date not recorded.
- **2026-09-19** CachyOS installed over Comet virtual media, "Erase disk",
  LUKS2 + Btrfs zstd:3, Limine, Niri profile only. Niri + Noctalia styled after
  the reference video (Monochrome palette). Server left powered off. (Codex)
- **2026-09-19** Proton Pass: SSH key and age key converted to native items,
  2,968 bookkeeping fields scrubbed. Final retire step blocked on Proton auth. (Codex)
- **2026-09-18** Decided: drop Omarchy for CachyOS + Niri, want NiriMod, keep
  Stow, one shared age key, merge nvim into dotfiles, automate Tailscale,
  exclude OCR, defer Proton VPN. Reason: Omarchy ties config to its Lua
  Hyprland layer and shell; CachyOS ships a maintained Niri profile. (Bassim)
- **2026-09-18** Comet firmware 1.7.2 → 1.10.0; stream Medium → Ultra-high,
  WebRTC → Direct. "More than sufficient." (Codex)
- **2026-09-17** Comet KVM MCP + skill built at `~/Developer/comet-kvm`;
  installed for Codex and Claude Code. (Codex)
- **2026-09-17** Crash diagnosis: power delivery at deep idle, OS-independent
  (reproduced on a Debian live session), reset-reason register empty after all
  7 crashes. Mitigation `Global C-state Control = Disabled`. Next test: PSU swap.
  Ethernet cable moved to the X540; onboard I225 left unplugged. (Codex)
- **2026-09-16** BIOS 2423 → 3645 via Comet virtual USB. Comet TLS replaced with
  a local CA constrained to `glkvm.local`. Keychain items `com.openai.codex.omarchy.*`
  created. Ethernet troubleshooting deprioritized. (Codex, Bassim)
- **2026-09-08 to 19** Bitwarden → Proton Pass migration and dedup. Bitwarden
  kept as backup. (Codex)
- **2026-09-02** Proton Duo setup plan reviewed; no setup work followed.

2026-09-30: portable agent configuration deployed at3769c6b. Source-backed merges retain machine-owned app/Herdr/runtime data. Linux exact Claude source snapshots use an explicit local namespace because the official name is reserved. Mac ignored local permissions restored and excluded from Stow adoption; immutable skill originals preserved. See task-8/FINAL-RECEIPT.md for verification and exact remaining gaps.
