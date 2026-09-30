# Source ledger — captured 2026-09-30

`source-manifest.json` records source HEAD, initial status, SHA-256 of each tracked working-tree file and consumed external document hashes. Copied content is local source, not recovered whole conversations. Original sources remain intact.

| Source | Locator | Use |
|---|---|---|
| S1 homelab | /Users/bassimshahidy/Developer/homelab; HEAD 6e160623ab9d137df5e6c32cb8b675a694c3b764 | History-preserving basis; dated skill, inventory, status, history, plans and source pointers. Untracked .shots/ excluded. No local AGENTS.md found in source. |
| S2 Comet | /Users/bassimshahidy/Developer/comet-kvm; HEAD 0072fabb287fdbdab6d7972cf67417a6b404b1d0 | Generic package snapshot. AGENTS.md, skills/comet-kvm/SKILL.md, manifests and license retained. Source tracked tree clean. |
| S3 reconciled parent plan | /Users/bassimshahidy/Documents/Codex/2026-09-30/task/fleet-plan.md | Exact recovered key decisions, public identity inventory, shell correction and consolidation direction. Referenced, not copied. |
| S4 shell | /Users/bassimshahidy/.zshrc → /Users/bassimshahidy/dotfiles/zsh/.zshrc | Current source authority; retirement/Herdr comments read. No shell configuration copied or altered. |
| S5 older digest | /Users/bassimshahidy/Documents/codex-thread-digest/SUMMARY-2026-09-21.md | Secondary context read before scope correction; missing Proton rollout and dated coverage explicitly acknowledged. Not copied. |
| S6 local memory | /Users/bassimshahidy/.codex/memories/memory_summary.md and rollout_summaries/ | Broad topics and selected old CachyOS/dotfiles/Comet summaries read before scope correction. No further retrieval; not copied. |

Exact age decision raw locator supplied by parent: `/Users/bassimshahidy/.codex/sessions/2026/09/17/rollout-2026-09-17T22-16-50-01a0b2f2-2a95-7f62-8c8d-88c7ee3f447e.jsonl`, event 2026-09-19 08:52:01 UTC. Proton follow-up thread: `01a0b909-bb73-72f3-ac3f-85ec5abe86ea`, event 2026-09-19 10:25:15 UTC; parent plan references `/Users/bassimshahidy/.codex/memories/rollout_summaries/2026-09-19T09-40-17-1Z6q-proton_pass_secret_organization_and_review_resolution.md`. This unit did not independently inspect these raw messages or decrypt anything.

Old summaries read: `2026-09-19T11-57-36-Eze0-cachyos_niri_noctalia_install_and_filesystem_comparison.md`, `2026-09-18T05-16-50-vwtg-minimal_cachyos_niri_dotfiles_migration_plan.md`, `2026-09-20T22-44-27-qs3y-glinet_comet_kvm_open_source_customization.md` in ~/.codex/memories/rollout_summaries. These summarize proposals and older observations, not current machine facts. Further source paths in machines-skill/artifacts.md are pointers, not files copied or audited by this pass.

## S7 — Supplemental parent evidence, incorporated September 30

[supplemental-evidence-2026-09-30.md](../supplemental-evidence-2026-09-30.md) is a durable archive of the parent delegation from thread `01a0f107-b8d6-7530-88e6-8d120c7af00a`. It indexes exact Codex decision IDs/times (K1–K2), retrieved ChatGPT requirements with UTC topic locators (H1–H9), Theo mirror/primary research (T1–T4), T3 primary documentation and application research (A1–A7).

ChatGPT retrieval provides dates/topic locators rather than stable original URLs; most entries are attributed summaries. Research links are preserved exactly as supplied; this worker did not browse them again or independently verify external availability. Parent checked application sources September 30; original research does not establish installation, runtime behavior or user selection. Transcript mirrors were read in sections, not videos watched; no full transcript copied. Older broad summaries remain secondary and do not override the reconciled requirements.

Current map: [decisions](../decisions.md) → short confirmed direction; [state](../current-state.md) → dated observations vs deployment unknowns; [coverage](../coverage-gaps.md) → actually unchecked inputs; [migration](../migration.md) → source/consumer boundaries. The supplemental archive is research provenance, not an operational checklist.

## S8 — Live CachyOS observation and subsequent privilege blocker

[Live verification](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/live-cachyos-verification.md), parent read-only Comet observations at September 30 08:23 UTC. Subsequent approved setup began 08:28 UTC; sudo -n checks required password and made no key/config/firewall changes (parent delegation). [Evidence screenshot](/Users/bassimshahidy/Documents/Codex/2026-09-30/task/fish-linux-work/ssh-privilege-check.jpg) referenced only. Local paths checked; no new history retrieval, machine actions or credential entry by this documentation worker.

## S9 — Completed tailnet SSH, September 30

Direct user approval in thread01a0f107-b8d6-7530-88e6-8d120c7af00a covered key-based existing-tailnet SSH; latest delegation supplied explicit correction of unintended Mac-only restriction. Comet console privileged checks and actual strict-host-key Mac SSH verified the final policy. See [current state](current-state.md#completed-ssh-setup-and-tailnet-correction--verified-2026-09-30) for public fingerprints, exact configuration, rollback and external evidence paths. S8 remains historical; its blocker is resolved. No new secrets or identities.
