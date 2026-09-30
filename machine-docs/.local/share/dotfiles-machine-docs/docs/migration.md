# Consumer migration

Machines skill is now canonical at ~/Developer/fleet/machines-skill. Shared ~/.agents/skills/machines retargeted to fleet; Claude/Codex relative links remain through shared link and are verified to read current SSH facts. Original ~/Developer/homelab untouched and retained as history/provenance. Installer derives target from its checkout; running fleet/scripts/install-skill.sh targets fleet.

Comet source snapshot at plugins/comet-kvm preserves package/license/manifests; actual Comet Git history and live consumers remain ~/Developer/comet-kvm plus Codex cache. History import and plugin consumer migration pending separately. Runtime config remains external. [Bootstrap record](supporting/migration.md).
