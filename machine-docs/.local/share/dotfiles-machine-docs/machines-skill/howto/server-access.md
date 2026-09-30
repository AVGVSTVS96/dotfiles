# Server access

Verified September30: ssh bassim@server.tail43f1c6.ts.net (100.113.223.113) with existing Mac key; password/root login disabled and Mac-only restrictions removed. Other-device authentication and normal Mac ssh server alias remain untested.

Host Ed25519 fingerprint: SHA256:DtV/0bYzbpUjGlNfKzY2mytBIDmXRfd4QZlZcm8CAWI. Compare/pin the independently console-verified identity before trusting a new client. Do not treat ssh-keyscan alone as trusted identity evidence.

## Recovery and boot

Use [Comet](comet-kvm.md) when SSH is unavailable. Observe screen/power before input; boot passes through Limine and LUKS console unlock. Reboot durability is untested: inspect actual sshd bind/service ordering and firewall policy, then test with recovery available. Do not change listeners/DNS/Tailscale settings from historical recipes.

Login/sudo user bassim. Historical Keychain disk-unlock item was used for LUKS/login/sudo during installer setup; current equality is unverified. Follow [secret handling](secrets.md) and the current task's secure authentication workflow. Never type a password at a shell prompt or log/transcribe it. If prompt/focus is uncertain, observe first. No password rotation without user instruction.

Server retains Fish by explicit user choice; deployed port follows latest zshrc behavior, not zsh login-shell adoption. chsh never ran; Mac zsh unchanged. Keep input short through KVM. Ghostty Super+R and launcher Super+Space are historical desktop bindings. WoL unavailable with onboard NIC unplugged.

[September30 setup configuration, rollback and original evidence](../../docs/supporting/current-state.md#completed-ssh-setup-and-tailnet-correction--verified-2026-09-30) are retained as a dated setup record.
