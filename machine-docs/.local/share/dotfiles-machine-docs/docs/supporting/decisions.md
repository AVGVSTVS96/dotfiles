# Decisions and provenance

| Decision date | Decision | Evidence / confidence |
|---|---|---|
| 2026-09-30 | Bootstrap fleet locally before machine setup; no remote publication or machine/security changes. Minimal primitives; dedicated infra/NAS/router separation later; server must not become router. | Current delegated user scope; confirmed direction, not deployed architecture; [supplemental evidence](supplemental-evidence-2026-09-30.md). |
| 2026-09-30 | Current zshrc governs shell portability; ai-tmux retired, Herdr preferred; fish candidate isolated and not deployed. Linux shell preference remains unresolved. | Supplied fleet-plan.md; local zshrc comments inspected, lines 277–292. |
| 2026-09-19 08:52:01 UTC | “ok use my existing age key” supersedes exploratory separate-age-identity proposals. Preserve SOPS+age; no new age identity. | Thread 01a0b2f2-2a95-7f62-8c8d-88c7ee3f447e, exact message recovered by parent and supplied in fleet-plan.md. Raw rollout locator in sources.md. |
| 2026-09-19 10:25:15 UTC | Store existing SSH and age keys as proper Proton items; verify replacements before removing originals. | Thread 01a0b909-bb73-72f3-ac3f-85ec5abe86ea, supplied recovery; organization of existing keys, not creation. Completion unverified; no present deletion authorization. |
| 2026-09-21 | C-states disabled is sufficient; no PSU swap unless fault returns. | homelab machines-skill/history.md and status.md, recorded user decision. |
| 2026-09-18–19 | Replace Omarchy with CachyOS + Niri/Noctalia; keep minimal app set, Ghostty and Chrome, Stow portability. | homelab history/plan and prior digest. Installation recorded complete; remaining migration levels are proposals. |
| 2026-09-17 onward | Comet exposes named hardware primitives; model owns reasoning. One canonical implementation/skill, no OCR, agent loops or attached-machine model. Never replay uncertain input/power. | comet-kvm/AGENTS.md and README.md, preserved package constraints. |

## Identity boundaries

Existing MacBook/GitHub ED25519 public fingerprint: `SHA256:dWiI06FW8tGfnittrev+k3XVv3TKVlGbM2ZQgDBOOrM` (parent's read-only inventory, supplied fleet-plan.md). No private key was read or copied by this bootstrap.

The encrypted SSH file is reported as SOPS JSON with one age recipient, zero PGP recipients, version 3.11.0, not decrypted. Its encrypted private identity has not been matched to the public fingerprint. Presence of keys in authorized_keys is not approval to deploy them. Mac client identity, server host identity and SOPS decryption identity serve different roles. No fleetwide SSH reuse policy is inferred.

Proton/Keychain item names in the historical secrets guide describe locations only; counts, contents and current presence have not been freshly verified here. Older public-repository decisions do not authorize publishing fleet. Mac→server SSH over the existing tailnet was approved, then explicitly paused for context recovery/documentation. Subsequent parent-approved setup started September 30 08:28 UTC and is blocked on personal sudo authentication, with no key/config/firewall changes. See current-state.md. This documentation worker does not perform setup. Older enablement recipes remain historical proposals.

## Current architecture and operating preferences

Source: parent-reconciled [supplemental evidence](supplemental-evidence-2026-09-30.md), requirement IDs H1–H9. These requirements are confirmed intent, not deployed topology.

- MacBook is both the entrypoint and a general local development machine (H5, September 27); earlier no-local-Mac-dev framing is superseded.
- Separate infrastructure/NAS, performance/general-development and disposable-worker roles; Windows gaming separate. Keep Ryzen hackable without interrupting NAS. Existing server can run 24/7 temporarily; a future infra PC is not required to start.
- Server must not be router/network SPOF; retain Eero Wi-Fi. Desired: 10G Mac/PC/server, custom DNS/network ad blocking, Proton VPN on devices, remote access via SF home with selectable ISP/Proton exit. Routing hardware/topology remains unselected.
- NAS intent: at least four new HDDs, $400–600 budget, speed/redundancy; SN850X/MS-02 are candidates. RAID/filesystem/OS, purchases and placement unresolved. Avoid high-RAM requirements on both infra/dev; do not infer a 1TB VM-storage cap from boot SSD size.
- Prefer software-native self-updates; convenience exceptions allowed with material tradeoffs discussed. Proton Duo chosen over 1Password; aliases/SMTP desired, setup unverified.

Research supports evaluating one durable remote coding loop on Mac+Ryzen+Comet; it does not select T3, replace Herdr/CachyOS, authorize installs or define runtime permissions. Proton agent access remains desired: specify runtime, item, downstream actions and expiry before any grant. No arbitrary-vault access is authorized.

## September 30 SSH scope correction

User approved key-authenticated bassim SSH from existing tailnet devices; Mac-only source restriction was unintended and has been removed from authorized_keys, AllowUsers and UFW. Keep Tailscale-only listener/interface, password and root login disabled, existing host keys and age identity. Existing Mac public identity reused; this does not establish private-key sharing or fleetwide identity policy.
