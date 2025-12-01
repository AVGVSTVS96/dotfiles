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
