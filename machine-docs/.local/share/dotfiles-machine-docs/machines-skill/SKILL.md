---
name: machines
description: Source of truth for Bassim's homelab. Machine inventory (CachyOS server, MacBook, Windows PC AVGVSTVS, GL.iNet Comet KVM glkvm), tailnet and LAN IPs, dated live status, plan, and how-tos. Use when asked to reach, check, reboot, or change the server; ssh or Tailscale to any machine; drive the Comet KVM console or ATX power; work on dotfiles for Linux, Niri, Proton Pass, or where a secret lives; or whenever any agent needs an IP, hostname, MAC, user, or hardware fact.
---

# Machines

Shared source of truth for Bassim's homelab. Every agent reads the same files;
every agent that changes machine state writes back. Owner: Bassim Shahidy.
Repo: `~/Developer/fleet` (canonical installed machines skill).

## Glossary

- **server**: the Ryzen desktop running CachyOS, the only homelab box.
- **Omarchy**: the Arch-based distro that ran on it until 2026-09-19. Abandoned.
- **Comet / glkvm**: the GL.iNet KVM attached to the server. The only display.
- **Machine God**: Bassim's Grok Bot agent, the usual liaison for homelab tasks.
  Other agents do not defer to it; they read and write this skill like anyone.
- **Fable**: Claude Fable 5.1, the Claude Code model that built this skill.
- **NiriMod**: a graphical settings editor for the Niri compositor. Wanted, not installed.
- **Reference look**: the YouTube desktop (`youtu.be/53N9HBM-nDM`) the Niri theme copies.

## Rules

1. **Read `status.md` before acting.** It is dated. If the snapshot is older
   than a day or the task depends on it, re-verify with `scripts/status-check.sh`
   (in this skill folder, macOS only) or a Comet screenshot.
2. **Write back in the same session.** Changed a machine, a setting, a plan?
   Update `status.md` (and `history.md` for decisions). See `howto/updating.md`.
3. **No secrets, ever.** Name where a secret lives (Keychain service, Proton
   Pass item title). Never its value, not even in a screenshot description.
4. **Label every fact.** `verified YYYY-MM-DD` means an agent observed it.
   `recorded` means it came from a thread or document and may be stale.
5. **Destructive actions need Bassim.** Power cycles when the OS is responsive,
   disk formats, BIOS changes, and deleting data all require his explicit ask.
   Read-only probes never do.

## Quick facts (SSH/server OS verified 2026-09-30; other addresses recorded 2026-09-21)

| Thing | Value |
|---|---|
| Tailnet | `bassim101@gmail.com`, MagicDNS suffix `tail43f1c6.ts.net` |
| Server | `server` · CachyOS · Tailscale `100.113.223.113` · LAN `192.168.4.89` |
| Server user | `bassim` (uid 1000, wheel, fish). No other accounts exist |
| Server SSH | **working** with existing Mac key over Tailscale; password/root login disabled; alias/reboot/other devices untested |
| Comet KVM | name `server` in the Comet config · `https://glkvm.local` · LAN `192.168.4.85` |
| MacBook | `bassims-macbook-pro-3` · `100.70.87.59` · the agent host |
| Windows PC | `win-gaming-pc` (hostname `AVGVSTVS`) · `100.71.143.87` |
| LAN | `192.168.4.0/22`, eero router `192.168.4.1` (recorded) |

Host Ed25519: `SHA256:DtV/0bYzbpUjGlNfKzY2mytBIDmXRfd4QZlZcm8CAWI`. Mac is entrypoint and primary dev. Full detail in `inventory.md`; current ordered work in `plan.md`.

## Access ladder

Try in order. Stop at the first one that works.

```
1. Tailscale + SSH     ssh bassim@server.tail43f1c6.ts.net     (verified; see status.md)
2. Comet KVM console   screenshot -> type/press -> screenshot   howto/comet-kvm.md
3. ATX power           only if the OS is unresponsive           howto/comet-kvm.md
```

Wake-on-LAN is not available: the only NIC with WoL support is unplugged.

## Files

| File | Read it when |
|---|---|
| `inventory.md` | You need an IP, hostname, user, MAC, disk, or hardware fact |
| `status.md` | You are about to touch a machine, or want to know what is open |
| `plan.md` | You are picking up homelab work and need priorities |
| `history.md` | You wonder why something is the way it is |
| `artifacts.md` | You need the original evidence: Codex outputs, thread digests, repos |
| `howto/comet-kvm.md` | You will drive the server console or power from an agent |
| `howto/server-access.md` | You need SSH, Tailscale, disk unlock, or login details |
| `howto/secrets.md` | You need a credential or must decide where one lives |
| `howto/updating.md` | You changed something and must record it |

## Tools available on the Mac

- `tailscale` CLI, `ssh`, `nc`, `security` (Keychain), `age`, `sops`, `bw`.
- Comet KVM MCP server from `~/Developer/comet-kvm`: Claude Code plugin
  `comet-kvm@skills-dir` and Codex plugin `comet-kvm@personal`, both verified
  2026-09-21. Any other MCP client uses the stdio command in `howto/comet-kvm.md`.
- `scripts/status-check.sh` (this folder) for a read-only live probe from the Mac.

## Linux documentation snapshot

On Linux this skill is a dated, read-only documentation snapshot under ~/.local/share/dotfiles-machine-docs. The canonical repo remains ~/Developer/fleet on the Mac; it has not been recreated here. Coordinate write-back with that canonical repo rather than editing the snapshot. Private transcript references and Mac credential helpers are deliberately unavailable here. Do not infer current access or service availability from a historical recipe. The appended location note is the only adaptation to the canonical skill source.
