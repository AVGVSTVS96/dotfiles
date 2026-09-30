# Migration boundary

## Completed 2026-09-30

Created `~/Developer/fleet` via local no-hardlinks clone of homelab, preserving its original Git commits and layout. Removed clone origin so this checkout has no publication target. Copied tracked working-tree sources only, with SHA-256 manifest; old checkouts were not changed.

Comet tracked source is copied under `plugins/comet-kvm/`, retaining its MIT license, package metadata, lockfile, tests, generic skill, and both native plugin manifests. This is a provenance-tracked snapshot; Comet Git history is still in `~/Developer/comet-kvm`. A real history-preserving subtree import remains pending. Do not describe this initial snapshot as that import.

Excluded `.git` copies, `.shots`, .DS_Store, virtualenvs, caches, dist outputs, runtime config, credentials, private TLS material, password exports and raw conversations. Current zshrc was inspected and referenced, not copied. No external history artifacts or personal secret files were copied.

## Installed consumers remain on existing paths

Machines links: `~/.agents/skills/machines`, `~/.claude/skills/machines`, `~/.codex/skills/machines` still resolve through homelab. Comet consumers include `~/.claude/skills/comet-kvm`, `~/plugins/comet-kvm`, and the cached Codex personal plugin. Runtime config stays at `~/.config/comet-kvm/config.json`. Parent fleet plan reports these consumer paths; this pass did not alter or fully re-inventory them.

## Pending controlled consolidation

Parent-reconciled findings are incorporated in docs/supplemental-evidence-2026-09-30.md. Choose canonical operational paths; import Comet history in a disposable branch/clone while preserving its package boundary and upstream license; verify imported authors/dates/messages and tree bytes. Existing source checkout remains recovery. Review package-relative launch/manifest paths before any cutover. Update skill installer and source references only with a deliberate path migration, then verify links and both plugin ecosystems. No installer or plugin launch was executed here.

The initial snapshots may diverge from their working source repositories. Compare source hashes/HEAD and reconcile deliberately; no automatic sync framework is introduced. Untracked homelab `.shots/` remains untouched in the source and excluded from fleet.
