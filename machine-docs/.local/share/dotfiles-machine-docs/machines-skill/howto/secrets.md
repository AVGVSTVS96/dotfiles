# Where secrets live

Never write a secret value into this repo, a chat summary, or a screenshot
description. Point at its home instead.

## Homes

| Secret | Home | Notes |
|---|---|---|
| Comet KVM admin password | Mac Keychain, service `com.openai.codex.omarchy.kvm-admin`, account `admin` | Read by the Comet client via `security find-generic-password -w`. Always-allow granted |
| Server LUKS / login / sudo password | Mac Keychain, service `com.openai.codex.omarchy.disk-unlock`, account `omarchy-server` | Item name is Omarchy-era. Recorded 2026-09-19 as the value given to the CachyOS installer; not re-verified since. Open item 2 in `status.md` |
| Everything personal (logins, passkeys, TOTP, recovery codes) | Proton Pass, account `bassim101@gmail.com` (Proton Duo plan) | 640 active items, 21 passkeys as of 2026-09-19. Vaults still in migration layout: `Merged credentials` + `Needs review` |
| MacBook SSH key | Proton Pass, SSH Key item `MacBook — SSH — id_ed25519`; live key in `~/.ssh` | Signing identity. Separate from the age key by decision |
| age key for SOPS / dotfiles | Proton Pass custom item `SOPS / dotfiles — age key`; live key `~/.config/sops/age/key.txt` | Reuse existing age identity; it also decrypts existing encrypted SSH secret |
| Bitwarden vault | Kept intact as the migration source/backup; `bw` CLI and app installed | Do not edit or delete. Org/shared scope never audited |

## Rules agents follow

- Comet authentication uses its external password helper; credential values stay in the helper/client, never logs, files in this repo or chat. Server login/sudo is a separate credential/prompt. Use the secure workflow authorized by the active setup task; do not infer permission to retrieve a server password from a location record. Personal sudo validation may be required. Never type credentials at an ordinary shell prompt.
- If a password appears on the server's screen (typed into the wrong window),
  say that it happened and clear the scrollback; do not repeat the value.
- New machine credentials go to Proton Pass with a recognizable title; add the
  title (not the value) to this table.
- No password changes on any account without Bassim's explicit ask.

## Identity exposure

Parent-reconciled September30: existing encrypted SSH secret is decryptable by the existing age identity. Giving a host that age identity gives it cryptographic access to that SSH secret wherever ciphertext is available. This is the real exposure of deliberate existing-identity reuse, not an assertion of newly copied private keys. Historical key conversions and cleanup were double-verified per recovered Proton records20–23/42–43, originals recoverable Trash; live item matching remains unchecked. Do not restart migration or treat separate password-review groups as incomplete key conversion. No new deletion authorization.

[Original Proton records20–23/42–43](../../.local/transcripts/codex-originals/01a0b909-bb73-72f3-ac3f-85ec5abe86ea/messages.jsonl) supply historical completion; this is not fresh vault inspection.
