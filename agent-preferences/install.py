# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
import argparse
import copy
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomlkit

parser = argparse.ArgumentParser()
parser.add_argument("--dry-run", "-n", action="store_true")
parser.add_argument("--target", type=Path, default=Path.home())
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
home = args.target.expanduser().resolve()
backup = home / ".local/state/dotfiles/agent-backups" / datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
changes = []

def save_backup(path):
    backup.mkdir(parents=True, mode=0o700, exist_ok=True)
    destination = backup / path.relative_to(home)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink():
        destination.symlink_to(os.readlink(path))
    else:
        shutil.copy2(path, destination)

def write(path, text, mode=0o600, backup_existing=True):
    if path.exists() and path.read_text() == text:
        return
    changes.append(str(path.relative_to(home)))
    if args.dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if backup_existing and (path.exists() or path.is_symlink()):
        save_backup(path)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as file:
            file.write(text)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)

def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = copy.deepcopy(value)

def json_merge(path, prefs):
    current = json.loads(path.read_text()) if path.exists() else {}
    expected = copy.deepcopy(current)
    merge(expected, prefs)
    if current != expected:
        write(path, json.dumps(expected, indent=2) + "\n")

claude = json.loads((repo / "agent-preferences/claude.json").read_text())
if os.uname().sysname != "Darwin":
    claude["enabledPlugins"].pop("paper-desktop@paper", None)
    claude["extraKnownMarketplaces"].pop("paper", None)
    for name in ("code-simplifier", "frontend-design", "plugin-dev"):
        claude["enabledPlugins"][name + "@claude-plugins-official"] = False
        claude["enabledPlugins"][name + "@bassim-dotfiles"] = True
json_merge(home / ".claude/settings.json", claude)
mcp_path = home / ".claude.json"
mcp_original = mcp_path.read_text() if mcp_path.exists() else "{}"
mcp_state = json.loads(mcp_original)
mcp_definitions = json.loads((repo / "agent-preferences/claude-mcp.json").read_text())
for name, definition in mcp_definitions.items():
    existing = mcp_state.get("mcpServers", {}).get(name)
    if existing is not None and existing != definition:
        raise RuntimeError(f"Existing MCP definition differs: {name}; preserve its access configuration")
    if existing is None:
        if not args.dry_run:
            backup.mkdir(parents=True, mode=0o700, exist_ok=True)
            (backup / "claude-mcp-before.json").write_text(json.dumps({name: None}) + "\n")
        mcp_state.setdefault("mcpServers", {})[name] = definition
if mcp_state != json.loads(mcp_original):
    assert not mcp_path.exists() or mcp_path.read_text() == mcp_original, "Claude local state changed concurrently"
    write(mcp_path, json.dumps(mcp_state, indent=2) + "\n", backup_existing=False)

target = home / ".codex/config.toml"
original = tomlkit.parse(target.read_text()) if target.exists() else tomlkit.document()
prefs = tomlkit.parse((repo / "agent-preferences/codex.toml").read_text())
expected = original.unwrap()
merge(expected, prefs.unwrap())
updated = copy.deepcopy(original)
merge(updated, prefs)
disabled = json.loads((repo / "agent-preferences/codex-disabled-skills.json").read_text())
skills = updated.setdefault("skills", {}).setdefault("config", tomlkit.aot())
for setting in disabled:
    if "path" in setting:
        setting["path"] = str(home / setting["path"].removeprefix("~/"))
    identity = "path" if "path" in setting else "name"
    match = next((item for item in skills if item.get(identity) == setting[identity]), None)
    if match is None:
        item = tomlkit.table()
        item.update(setting)
        skills.append(item)
    else:
        match["enabled"] = setting["enabled"]
expected["skills"] = updated.unwrap()["skills"]
assert updated.unwrap() == expected, "TOML merge changed an unowned setting"
rendered = tomlkit.dumps(updated)
assert tomlkit.parse(rendered).unwrap() == expected
write(target, rendered)

for source in (repo / "agent-preferences/protected-skills").rglob("*"):
    if source.is_file():
        write(home / ".agents/skills" / source.relative_to(repo / "agent-preferences/protected-skills"), source.read_text(), source.stat().st_mode & 0o777)

for package in ("claude", "codex", "agent-skills"):
    tracked = subprocess.check_output(["git", "-C", str(repo), "ls-files", "-z", "--", package]).decode().split("\0")
    for path in filter(None, tracked):
        source = repo / path
        relative = source.relative_to(repo / package)
        destination = home / relative
        if destination.is_symlink() and destination.resolve() == source.resolve():
            continue
        if destination.exists() or destination.is_symlink():
            if destination.is_dir() and not destination.is_symlink():
                raise RuntimeError(f"Directory conflict: {destination}")
            changes.append(str(relative))
            if not args.dry_run:
                save_backup(destination)
                destination.unlink()
        else:
            changes.append(str(relative))
    if not args.dry_run:
        subprocess.run(["stow", "--no-folding", "--ignore=.*\\.local\\.json$", "--ignore=\\.DS_Store", "--dir", str(repo), "--target", str(home), package], check=True)

for link in json.loads((repo / "agent-preferences/skill-links.json").read_text()):
    destination = home / link["path"]
    if destination.is_symlink() and os.readlink(destination) == link["target"]:
        continue
    if destination.exists() and not destination.is_symlink():
        raise RuntimeError(f"Skill link conflict: {destination}")
    changes.append(link["path"])
    if not args.dry_run:
        if destination.is_symlink():
            save_backup(destination)
            destination.unlink()
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.symlink_to(link["target"])

if os.uname().sysname != "Darwin":
    plugin_sources = json.loads((repo / "agent-preferences/claude-plugin-sources.json").read_text())
    registry = home / ".claude/plugins/installed_plugins.json"
    installed = json.loads(registry.read_text()).get("plugins", {}) if registry.exists() else {}
    missing = []
    for plugin in plugin_sources:
        installed_name = plugin["name"].replace("@claude-plugins-official", "@bassim-dotfiles")
        records = installed.get(installed_name, [])
        def matches(record):
            root = Path(record.get("installPath", ""))
            return record.get("scope") == "user" and all(
                (root / path).is_file() and hashlib.sha256((root / path).read_bytes()).hexdigest() == digest
                for path, digest in plugin["source_file_sha256"].items()
            )
        if not any(matches(record) for record in records):
            missing.append(installed_name)
    if missing:
        changes.extend("plugin:" + name for name in missing)
        if not args.dry_run:
            if home != Path.home().resolve():
                raise RuntimeError("Plugin installation requires the real home")
            catalog = repo / "agent-preferences/plugin-sources/claude-plugins-official"
            known_path = home / ".claude/plugins/known_marketplaces.json"
            known = json.loads(known_path.read_text()) if known_path.exists() else {}
            existing = known.get("bassim-dotfiles", {}).get("source")
            if existing and existing != {"source": "directory", "path": str(catalog)}:
                raise RuntimeError("Preserve existing snapshot marketplace; coordinate its source before replacing it")
            cli = home / ".local/bin/claude"
            if not existing:
                subprocess.run([str(cli), "plugin", "marketplace", "add", str(catalog)], check=True, stdout=subprocess.DEVNULL)
            for name in missing:
                subprocess.run([str(cli), "plugin", "install", "--scope", "user", name], check=True, stdout=subprocess.DEVNULL)

print(json.dumps({"dry_run": args.dry_run, "changed": changes, "backup": str(backup) if changes and not args.dry_run else None}, indent=2))
