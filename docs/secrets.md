# Secrets Management

Sensitive data like API keys and SSH keys are encrypted with **sops + age** so they can be safely committed to this public repo.

## The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│  Your Machine                                               │
│                                                             │
│  ┌──────────────┐         ┌─────────────────┐             │
│  │ Master Key   │────────▶│ sops decrypts   │             │
│  │ (age key)    │         │ encrypted files │             │
│  └──────────────┘         └─────────────────┘             │
│        │                           │                       │
│        │                           ▼                       │
│        │                  ┌─────────────────┐             │
│        │                  │ Secrets loaded  │             │
│        │                  │ into shell/apps │             │
│        │                  └─────────────────┘             │
│        │                                                   │
│        └─────────────▶ (kept in secure backup)            │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  GitHub Repo (Public)                                       │
│                                                             │
│  ✓ Encrypted API keys        (safe - unreadable gibberish) │
│  ✓ Encrypted SSH keys        (safe - unreadable gibberish) │
│  ✓ sops config               (public info, no secrets)     │
│                                                             │
│  ✗ Master key                (NEVER committed)             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## What Gets Encrypted

**API Keys & Tokens** - All stored in `zsh/secrets.env`
- OpenAI, Anthropic, XAI APIs
- GitHub CLI token
- Graphite auth token

**SSH Credentials** - Git authentication and commit signing
- Private key (encrypted)
- Public key (plain text - not secret)
- Config (public hosts only, private hosts excluded)

## How It Works

### Daily Use
When you open a new shell, `.zshenv` automatically decrypts secrets and loads them into your environment. You don't notice anything - it just works.

### Editing Secrets
```bash
sops zsh/secrets.env    # Opens in your editor, auto-encrypts on save
```

Sops handles all the encryption/decryption. You edit plain text, it saves encrypted.

### New Machine Setup
```
1. Restore master key from backup → ~/.config/sops/age/key.txt
2. Clone this repo
3. Run: stow */
4. Run: restore-secrets
5. Restart shell
```

Done! All secrets decrypted and configured.

## Key Files

**`.sops.yaml`** - Tells sops which files to encrypt and which key to use

**`restore-secrets`** - Script that sets up SSH keys, GitHub CLI, and Graphite on new machines

**`~/.config/sops/age/key.txt`** - Master encryption key (backup securely!)

## Security Model

✅ **Safe to commit:** Encrypted files (they're just gibberish without the key)

❌ **Never commit:** The master key itself

🔑 **Critical:** Backup the master key securely. Without it, encrypted files are permanently unreadable.

## Quick Reference

```bash
# Edit encrypted secrets
sops zsh/secrets.env

# Test decryption manually
sops -d zsh/secrets.env

# Re-encrypt after manual edits
sops -e -i zsh/secrets.env
```
