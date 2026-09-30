# Supplemental evidence — parent reconciliation, 2026-09-30

Source: supplemental delegation from parent thread `01a0f107-b8d6-7530-88e6-8d120c7af00a`, received 2026-09-30. These are supplied research/retrieval notes, not independent verification by the fleet documentation worker. No new conversation retrieval or browsing occurred in this unit. Original local sources remain linked in [sources](../sources.md). This archive does not assert that every historic conversation was enumerated.

## Recovered user decisions: Codex

- **K1 — 2026-09-19 08:52:01 UTC**, thread `01a0b2f2-2a95-7f62-8c8d-88c7ee3f447e`: exact user quote “ok use my existing age key”. Supersedes earlier assistant proposals for separate/server-specific age identities. SOPS+age remains the config-secret workflow.
- **K2 — 2026-09-19 10:25:15 UTC**, thread `01a0b909-bb73-72f3-ac3f-85ec5abe86ea`: proper Proton items for existing SSH and age identities, verification before originals removed. Completion remains unverified; no present deletion authorization.
- Existing MacBook/GitHub public candidate fingerprint `SHA256:dWiI06FW8tGfnittrev+k3XVv3TKVlGbM2ZQgDBOOrM` does not imply fleetwide private-key sharing. No new identities or SSH changes performed.

## Recovered requirements: ChatGPT

The following are parent retrieval summaries with UTC dates/topic locators, not stable original URLs. Only H5 contains an exact retrieved quotation. Requirements establish intent; candidate hardware/topology and deployment are separate questions.

| ID / event date UTC | Retrieved requirement | Interpretation / boundary |
|---|---|---|
| H1 — 2026-09-16 05:53:31; topology candidate 06:00:37 | Proton VPN for every device, custom DNS, whole-network ad/tracker blocking; 10G Mac/PC/server; Linux server must not be router/network SPOF; retain Eero Wi-Fi. | Dedicated routing hardware considered; final topology unselected. |
| H2 — 2026-09-16 06:09:27 | Remote access through SF home with selectable home ISP or Proton exit. | Deployment unverified. |
| H3 — 2026-09-27 00:14:38 | Ryzen hackable without taking NAS down; possible SN850X in separate MS-02 for NAS; Mac entrypoint. | Not evidence of MS-02 purchase, NAS implementation or router selection. |
| H4 — 2026-09-27 18:44:54 | Separate infrastructure, performance/general development and disposable-worker roles; Windows gaming separate. | Role boundaries selected; exact box count/topology unresolved. |
| H5 — 2026-09-27 18:48:58 | Exact quote: “macbook is the entrypoint baby! shes good for general local dev ofc shes my first dev machine the machine i learned dev on so thats def still a role but remember our classes of box, do we need more than 3?” | Mac entrypoint **and** general local development; supersedes earlier no-local-Mac-dev framing. |
| H6 — 2026-09-27 18:12:15 and 18:14:34 | New HDDs, minimum four, $400–600 budget, speed and redundancy; SN850X considered for cache/performance. | Final RAID, filesystem and OS unchosen; no purchase claim. |
| H7 — 2026-09-27 19:22:31 | Avoid high-RAM requirements on both infra and dev; NVMe matters for VM performance. | Do not cap all VM storage at 1TB because infra boot SSD is 1TB. |
| H8 — 2026-09-18, Comet design discussion | JSON config, reusable machine-independent controls, explicit endpoint each operation, minimal MCP primitives, shared Codex/Claude skills/plugins. | Machine inventory stays distinct from generic KVM implementation. |
| H9 — 2026-09-02, Proton decision | Proton Duo over 1Password; custom-domain aliases and homelab SMTP desired; existing SOPS retained. | Earlier server CPU description superseded by Ryzen 5700G. Choice is not completed setup. |

## Current September 30 direction

One fleet repository for documentation, skills/plugins and tools, preserving source history/uncommitted work. No remote publication or destructive migration requested. Existing Linux server may run 24/7 temporarily; desired future infrastructure PC is not a prerequisite for progress. Prefer software-native self-updates, with convenience exceptions and discussion of material tradeoffs.

Current zshrc is most current; ai-tmux retired; fish patch unapplied. Validate against zshrc and real CachyOS before deployment. Herdr remains user-selected. Mac→server SSH over existing tailnet approved, then explicitly paused until context is recovered/documented. This describes the earlier reconciliation state. Subsequent approved setup started at 08:28 UTC and is blocked on personal sudo authentication without changes; see current-state.md. This documentation worker performs no machine actions.

## Theo research: supplied original research notes

Parent read timestamped transcript mirrors, not watched videos or guaranteed authoritative captions. No complete transcript reproduced here. These are useful sources and interpretations, not user decisions.

| ID | Source / inspected sections | Caveat |
|---|---|---|
| T1 | [Why I’m moving to Linux (for real)](https://www.youtube.com/watch?v=9tGrhrVKCrE), July 2026, 38:05; [mirror sections](https://www.usetranscribe.io/yt/9tGrhrVKCrE/moving-to-linux): 5:21 Tailscale+SSH/T3 interfaces, 6:14 persistent tmux, 8:37 Mac controller/fleet skill/inventory, 18:46 Comet Pro, 24:31 KVM recovery, 28:35 execution-host GitHub auth needed to clone. | Mirror generated summary confuses Railway sponsorship with homelab; exclude that summary. |
| T2 | [I’m done with terminals](https://www.youtube.com/watch?v=dLhcLqoff6k), August 2026; [mirror sections](https://arcmira.com/watch?v=dLhcLqoff6k): 8:04 session tracking, 13:22 screenshot friction with SSH/tmux, 24:51 remote work continues after client closes, 25:34 Tailscale pairing/T3 Connect. | Section-based mirror research, not verified video observation. |
| T3 | [Mac filesystem performance discussion](https://www.youtube.com/watch?v=4wVNFaFDIn8). | Only indexed transcript excerpts inspected; full page failed. No universal benchmark ratio inferred, no XFS/VDO decision. |
| T4 | [Exact surfaced X post](https://x.com/theo/status/2090528543746965991). | Direct source inaccessible; search incomplete. Mirror text is not independently verified. |

### Primary T3 documentation read by parent

Team documentation does not prove Theo personally uses every option.

- [Remote access](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md): remote-only desktop and private connection options.
- [Background service](https://github.com/pingdotgg/t3code/blob/main/docs/user/background-service.md): native t3 service, update/version mechanisms, Linux systemd user service.
- [Install](https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md): provider binaries must resolve in noninteractive login-shell environment.
- [Updating](https://github.com/pingdotgg/t3code/blob/main/docs/user/updating.md): updates can interrupt work; boot persistence and thread continuation are different.
- [Permission modes](https://github.com/pingdotgg/t3code/blob/main/docs/user/permission-modes.md): documented initial Full access default; runtime permissions must be deliberately selected.

**Parent inference, not selected implementation:** existing Mac+Ryzen+Comet fits the direction; validate one durable remote coding loop before adding hardware. Do not replace CachyOS or Herdr based on a video.

## Application research — checked by parent 2026-09-30

| ID / sources | Supplied finding | Decision boundary |
|---|---|---|
| A1 — [ChatGPT/Codex Linux preview](https://learn.chatgpt.com/docs/linux/linux-app) | Official Arch install route; script performs full system upgrade; CachyOS not explicitly named; native Wayland experimental. | No installation. Compatibility and upgrade impact require evaluation. |
| A2 — [Codex CLI](https://learn.chatgpt.com/docs/codex/cli), [Claude Code setup](https://code.claude.com/docs/en/setup) | Official Linux-native routes. | Not installed by this task. |
| A3 — [Claude Desktop](https://support.claude.com/en/articles/10065433-install-claude-desktop) | Official Linux beta targets Debian/Ubuntu; no app self-update, regular package updates deliver updates. | Arch route not selected. |
| A4 — [claude-desktop-extra](https://github.com/patrickjaja/claude-desktop-extra) | Community packaging of actual upstream Linux app for Arch, with extra features/package updates. Minimal DIY repack possible. | Neither selected nor installed; current AUR PKGBUILD not independently audited; DIY has maintenance cost. |
| A5 — [T3 downloads](https://t3.codes/download) | Upstream Linux AppImage available. | No install/runtime choice made. |
| A6 — [Proton access tokens](https://proton.me/blog/pass-access-tokens), [Pass CLI agent](https://protonpass.github.io/pass-cli/commands/agent/) | Item-scoped viewer grants can expire, be revoked and audited. | Vault viewer does not constrain downstream actions using a credential. Agent access desired, not configured or authorized for arbitrary items. |
| A7 — [Proton Duo](https://proton.me/support/get-started-proton-duo), [Pass CLI install](https://protonpass.github.io/pass-cli/get-started/installation/) | Duo includes premium Pass; official CLI installation route documented. | Existing setup/completion not newly inspected. |

Any agent grant needs exact runtime, item, downstream actions and expiry. Keep actual secrets out of repository and model context. App availability/research is not deployment authorization.
