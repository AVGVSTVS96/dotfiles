# Inventory

## Roles and access

| Machine | Role | Access / evidence |
|---|---|---|
| MacBook bassims-macbook-pro-3 | Entrypoint and primary development | Tailnet100.70.87.59 recorded September21; current user role decision |
| server | Performance; temporarily always-on | bassim@server.tail43f1c6.ts.net,100.113.223.113; SSH verified September30 |
| Windows AVGVSTVS / win-gaming-pc | Gaming | Tailnet100.71.143.87 recorded September21 |
| Comet Pro RM10 | Server console/boot/recovery | https://glkvm.local working; LAN192.168.4.85 historical lease; Keychain helper |
| Future infra / NUC workers | Stable infrastructure / disposable compute | No finalized purchase/topology |

## Server hardware — recorded September16–21, not reinventoried

Ryzen7 5700G/Cezanne iGPU; ASUS ROG STRIX B550-F GAMING non-WiFi, BIOS3645;16GiB DDR4; Samsung850 EVO500GB SATA; CorsairCX600M. IntelI225 onboard unplugged, X540 add-in used. Global C-state Control disabled; preserve. Only onboard NIC has recorded WoL support, so WoL unavailable while unplugged.

## Server software — September30 console observation unless dated

CachyOS rolling Arch-family x86_64; bassim uid/gid1000, home/home/bassim, configured shell/bin/fish. OpenSSH10.5p1-1 observed installed before setup. Existing host public keys include Ed25519/ECDSA/RSA/MLDSA44-Ed25519. Verified Ed25519 fingerprint: SHA256:DtV/0bYzbpUjGlNfKzY2mytBIDmXRfd4QZlZcm8CAWI.

September30 GPT verification via pinned SSH/Comet: T3 Code desktop0.0.44-nightly.20260929.2456 at /home/bassim/Applications/T3-Code-Nightly.AppImage, launcher /home/bassim/.local/bin/t3code-nightly and validated user desktop entry. Actual Niri launch/relaunch and About version verified; Linux CLI /home/bassim/.local/bin/t3 and existing Mac /Applications/T3 Code (Nightly).app match exactly. Existing Claude Code2.1.285, Codex0.159.2, Herdr0.9.3 and shell hashes preserved. Shell/PATH deployment is tracked separately. Both desktops signed into the same T3 Connect account; Mac→server live service-backed connection verified with desktop closed and after relaunch. Linux t3code.service enabled/active with Linger=yes, managed cloudflared2026.5.2, activity publishing off, loopback-only3773 listener. Remote Codex0.159.2/Claude2.1.285 report authenticated; no agent job started. No Connect blocker remains; physical reboot/logout durability untested. [Current desktop/Connect receipt](/Users/bassimshahidy/Documents/Codex/2026-09-30/task-7/desktop/receipt.md).

September21 storage/desktop record: LUKS2+Btrfs compress=zstd:3,4GB FAT /boot, Limine/limine-snapper-sync; Niri+Noctalia monochrome, Ghostty and Chrome. Boot requires console LUKS unlock; unattended reboot recovery not qualified. NiriMod explicitly chosen, deployment unverified. September30: root Snapper config exists, rollback untested; ChatGPT Desktop chatgpt-bin26.915.31945-1 installed, Exec chatgpt %U.

## Addresses and paths

Server tailnet100.113.223.113 freshly observed; server LAN192.168.4.89 and eero gateway192.168.4.1 / subnet192.168.4.0/22 historical leases/record. Keep Eero; server is not router. Use [access](howto/server-access.md) for SSH trust and [Comet](howto/comet-kvm.md) for recovery.

Fleet: ~/Developer/fleet. Dotfiles: ~/dotfiles. Neovim source: ~/Documents/GitHub/nvim. Generic live Comet source: ~/Developer/comet-kvm; fleet package snapshot is not the installed plugin. Runtime config remains ~/.config/comet-kvm/config.json. Secret locations, never values: [secrets](howto/secrets.md). Historical detailed inventory remains in original homelab and Git history.
