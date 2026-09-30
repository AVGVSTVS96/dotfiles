# Current state and unknowns — verified SSH update 2026-09-30

This documentation worker ran no machine probes. Parent-supplied [live verification](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/live-cachyos-verification.md) records read-only Comet observations at **2026-09-30 08:23 UTC**. Unrechecked hardware/storage/desktop facts retain the historical September 21 date.

| Area | Last recorded state | Limits / next verification |
|---|---|---|
| Server | Ryzen 7 5700G, ASUS B550-F, 16 GiB, Samsung 850 EVO 500 GB; CachyOS installed September 19. User bassim. | September 30: CachyOS rolling, Arch family, x86_64; bassim uid/gid 1000, /home/bassim, configured /bin/fish. Physical hardware not freshly inventoried. |
| Desktop | Niri + Noctalia v5, monochrome theme, Ghostty/fish and Chrome. | Installed fish is not a current shell preference decision; NiriMod recorded wanted, not installed. |
| Storage / boot | LUKS2+Btrfs zstd:3, Limine; console passphrase needed for boot. No off-machine backup recorded. | Never equate snapshots with backup; storage additions remain proposals. |
| Stability | C-states disabled, stable as of September 21; onboard I225 unplugged, X540 used. | No new crash evidence; do not change BIOS or schedule PSU replacement. |
| Remote admin | September 30: sshd active/enabled; strict-host-key Mac SSH login succeeded as bassim. IPv4 listener only 100.113.223.113:22. | Key-only bassim access from tailnet devices possessing an authorized key; no Mac source pin. UFW permits port22 only inbound on tailscale0 to that address. Other-device login and reboot durability untested. |
| Tailscale | September 30: tailscaled active, server IPv4 100.113.223.113; systemd-resolved/NetworkManager DNS wiring warning persists. | Other historical peer addresses unverified. No DNS or tailnet configuration changes; MagicDNS may fail. |
| Comet | glkvm.local, verified HTTPS with local CA, Keychain-backed client; firmware 1.10.0 recorded September 18. | Generic hardware qualification dated September 17 used 1.7.2. Do not claim newer firmware qualified by those tests. TLS renewal recorded pending. |
| Secrets | SOPS+existing age key; Proton Pass items; Keychain for Comet and recorded disk-unlock location. | Latest identity recovery supplied by parent; vault inspection/retirement status not verified here. |
| Dotfiles / Neovim | Cross-platform Stow work and history merge were planned. Current zshrc authoritative. | Repository portability, pending work and isolated fish candidate are not deployed by fleet. |
| Future infra | Dedicated infrastructure, NAS and router separation desired; server must not act as router. | Role requirements recovered (see decisions); exact hardware purchases, NAS/router topology and deployment remain unverified. Existing server can run 24/7 temporarily. |

Historical outstanding items: Proton final verification/21-original retirement, DNS, DHCP reservation, NiriMod, dotfiles portability, Comet certificate renewal, and agent CUA/Jev support on Niri. Their current status is unknown. Proton Duo was selected over 1Password on September 2; its setup completion remains unverified. Proton VPN/device and selectable-exit requirements are recovered, but deployment remains unverified. No old task is automatically authorized by copying its plan.

## September 30 reconciliation

Targeted ChatGPT architecture/network/NAS/Mac-role requirements and decisive Codex key decisions are incorporated from parent evidence. Theo transcript-mirror research and primary T3/application documentation are indexed in [supplemental evidence](supplemental-evidence-2026-09-30.md); no video-watching or complete-history claim is made.

No application install route has been selected or executed. Official Arch Linux preview route was reported, but CachyOS-specific compatibility and native Wayland remain uncertain; install script's full upgrade is a material tradeoff. Claude Desktop official beta is Debian/Ubuntu-targeted and package-updated; community Arch package/AUR audit remains pending. T3/CLI availability does not establish installed state. Software-native updates are preferred with convenience exceptions.

Proton native item completion/deletion verification and agent grants remain unverified. No item access granted; any future grant needs runtime, exact item, downstream actions and expiry. Approved SSH setup and tailnet-wide source correction completed; earlier privilege blockers below are historical. Durable remote coding loop and recovery test remain incomplete.

## Bounded live command inventory and SSH blocker

Found on PATH: fish, zsh, git, ssh, tailscale, fzf, fd, rg, bat, eza, wl-copy. Target Herdr, agent CLIs, nvim, Stow and runtime commands were not on PATH in this check. Full list is in the linked live source; PATH absence does not prove packages/GUI apps are uninstalled. `/usr/bin/sshd` exists despite sshd absent from PATH.

Existing public host keys include ECDSA, Ed25519, MLDSA44-Ed25519 and RSA; no guessed fingerprint is recorded. Unprivileged `sshd -T` reported no hostkeys available, which does not establish missing keys. Main config includes drop-ins; observed userdb AuthorizedKeysCommand plus Arch PAM/auth settings require full privileged effective-policy validation.

**08:28 UTC subsequent setup status, supplied by parent:** approval already given; every `sudo -n` check required a password. No configuration, key or firewall changes were made. Pending Bassim running `sudo -v` in the **same Comet Ghostty session**, entering the password personally. [Privilege-check evidence](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/fish-linux-work/ssh-privilege-check.jpg). This is an authentication blocker, not a request for renewed approval. This documentation unit performs no machine actions.


## Completed SSH setup and tailnet correction — verified 2026-09-30

This section supersedes the earlier 08:28 privilege blocker and disabled-SSH observations. Bassim personally authenticated sudo in the Comet Ghostty session. Existing Mac Ed25519 public identity reused: `SHA256:dWiI06FW8tGfnittrev+k3XVv3TKVlGbM2ZQgDBOOrM`. No private key retrieval/distribution, new identity, host-key regeneration, age/SOPS/Proton or Tailscale ACL change.

Actual effective policy: `/etc/ssh/sshd_config.d/00-fleet-mac.conf` (historical filename retained), `AddressFamily inet`, `ListenAddress 100.113.223.113`, `AllowUsers bassim`, `AuthenticationMethods publickey`, `PubkeyAuthentication yes`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`, `AuthorizedKeysCommand none`. `sshd -t` passed; privileged `sshd -T` matched. Existing authorized key has no `from=` restriction; directory0700/file0600. No unrelated key installed.

UFW active with default deny incoming; sole rule: `100.113.223.113 22/tcp on tailscale0 ALLOW IN Anywhere # fleet-tailnet-ssh`. The former Mac-IP rule was deleted. “Anywhere” applies only to traffic arriving on tailscale0 at this destination; listener remains only the Tailscale IPv4 address. No LAN/public/wildcard/IPv6 listener; earlier LAN192.168.4.89 port22 probe timed out. Tailnet ACLs still apply. Other devices need an authorized key; no private identity was distributed and no other device login was tested.

Server Ed25519 host fingerprint, observed through Comet and matched to SSH scan: `SHA256:DtV/0bYzbpUjGlNfKzY2mytBIDmXRfd4QZlZcm8CAWI`. Real Mac SSH passed with BatchMode, IdentitiesOnly and StrictHostKeyChecking using task-local pinned known-hosts. sshd active/enabled. Reboot/boot ordering not tested; no reboot performed. Standard Mac known_hosts integration remains separate from the verified task-local pin.

Rollback through Comet: stop/disable sshd, delete only the `fleet-tailnet-ssh` UFW rule by its exact interface/destination/port specification, remove only this added drop-in and specific authorized public-key line if reverting all setup. Preserve original configuration, unrelated firewall rules, and every host key. Validate `sshd -t` before any future restart. No rollback executed.

Evidence: [final console policy](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/fish-linux-work/tailnet-final-policy.jpg), [correction command](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/fish-linux-work/correct-tailnet.txt), [pinned public host key](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/fish-linux-work/server-known-hosts). Runtime evidence remains outside fleet.
