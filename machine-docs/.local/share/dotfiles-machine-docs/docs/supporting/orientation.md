# Orientation — 2026-09-30

Fleet is a local consolidation checkout, not a deployed machine configuration. The initial unit collects existing documentation and generic source safely before any setup.

- `machines-skill/`: preserved September 21 inventory, status, history, access/secrets-location guides and read-only probe source. Its old absolute paths and install helper still target homelab; do not run the helper as a fleet cutover.
- `plugins/comet-kvm/`: complete tracked generic Python/MCP package, lockfile, tests, skill, MIT license and Claude/Codex manifests. Not installed or requalified from this location.
- `handoffs/`: point-in-time briefs, subordinate to verified records and later decisions.
- `docs/`: current scope, reconciled decisions, dated state, provenance, coverage gaps and migration boundaries.

Keep current source repositories and consumers working. Review new evidence into docs/decisions.md and docs/current-state.md with date/source; do not silently rewrite historical snapshots. A later controlled cutover must establish one operational source of truth.
