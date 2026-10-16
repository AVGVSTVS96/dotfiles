## MacOS system setup

#### Use duti to remap the vscode:// URL scheme to the Cursor application
```bash
# get bundle ID
➜ osascript -e 'id of application "Cursor"'
# returns com.todesktop.230313mzl4w4u92 as of 2025

# run duti to vscode:// to Cursor
➜ duti -s com.todesktop.230313mzl4w4u92 vscode
```

## Troubleshooting

#### ~/Documents folder inaccessible - "Operation not permitted" (2025-11-12)

TCC database corruption caused complete inability to access ~/Documents directory from terminal tools. Most commands failed with "Operation not permitted" when CWD was under Documents.

**Fix:**
```bash
tccutil reset SystemPolicyDocumentsFolder
```

## Archive sync

My commonplace archive (`~/Developer/personal/commonplace`) keeps itself current through the `dev.commonplace.sync` LaunchAgent, which `commonplace install` writes there. It syncs at login, when Messages' `chat.db` changes, and when a hook kicks it: Claude Code's SessionEnd (`agent-preferences/claude-macos.json`) and Codex's Stop (`~/.codex/hooks.json`, outside this repo, next to herdr's hook). Its launcher, `data/commonplace-sync`, needs Full Disk Access once, for Messages and `~/Documents`. The CLI is linked as `~/.local/bin/commonplace`.
