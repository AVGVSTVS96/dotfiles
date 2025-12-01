# Chezmoi - Alternative Dotfiles Manager

## What is Chezmoi?

Chezmoi is an all-in-one dotfiles manager that could replace our current stow + sops + scripts setup. It handles symlinks, encryption, templates, and automation in a single tool with a unified workflow.

Instead of managing symlinks with stow, encrypting files with sops, and running custom scripts, chezmoi provides built-in features for all of these. It works with your existing age encryption keys and offers additional capabilities like machine-specific configurations through templates and password manager integration.

## Current Setup vs Chezmoi

| Aspect | Current (Stow + Sops) | Chezmoi |
|--------|----------------------|---------|
| **Symlinks** | `stow */` | `chezmoi apply` |
| **Encryption** | `sops -e -i file` | `chezmoi add --encrypt file` |
| **Editing secrets** | `sops file` | `chezmoi edit file` (auto-decrypt/encrypt) |
| **New machine** | stow + restore-secrets script | `chezmoi init --apply repo` |
| **Machine-specific configs** | Manual editing or branches | Templates with variables |
| **Dependencies** | stow, sops, age, custom scripts | chezmoi (includes everything) |

### Workflow Comparison

**Adding a new encrypted secret:**

```bash
# Current
vim zsh/secrets.env
sops -e -i zsh/secrets.env
git add zsh/secrets.env
git commit -m "Update secrets"

# Chezmoi
chezmoi edit ~/.config/zsh/secrets.env  # Auto-encrypts on save
chezmoi git commit -m "Update secrets"
```

**Setting up new machine:**

```bash
# Current
git clone github.com/AVGVSTVS96/dotfiles
cd dotfiles
stow */
restore-secrets

# Chezmoi
chezmoi init --apply github.com/AVGVSTVS96/dotfiles
# Done! (prompts for age key once)
```

## Key Benefits for This Setup

### 1. Use Existing Age Key
Your `~/.config/sops/age/key.txt` works directly with chezmoi. No new keys needed.

**Config (~/.config/chezmoi/chezmoi.toml):**
```toml
[encryption]
    type = "age"
    [encryption.age]
        identity = "~/.config/sops/age/key.txt"
        recipient = "age1pu9eskg36npprtn74vwe8hd0m4spyxck6hgfx93u8nxhr2pagagsmwv7d2"
```

### 2. Templates for Machine-Specific Configs
Different email for work laptop? Different settings per OS? Templates handle this elegantly.

**Example - .gitconfig:**
```gitconfig
# dot_gitconfig.tmpl
[user]
    name = AVGVSTVS96
    email = {{ .email }}  # Different per machine
    signingkey = ~/.ssh/id_ed25519
```

**Per-machine config:**
```toml
# Work laptop: ~/.config/chezmoi/chezmoi.toml
[data]
    email = "work@company.com"

# Personal laptop:
[data]
    email = "personal@gmail.com"
```

Same dotfiles repo, different outputs!

### 3. Automatic Encryption
No more manual `sops -e -i` commands. Chezmoi handles it automatically.

```bash
chezmoi add --encrypt ~/.ssh/id_ed25519  # Adds + encrypts
chezmoi edit ~/.ssh/id_ed25519           # Auto-decrypts for editing
chezmoi apply                            # Auto-encrypts on save
```

### 4. Single Command Updates
```bash
chezmoi update  # git pull + decrypt + apply all changes
```

## Migration Quick Start

### Step 1: Install and Configure (10 minutes)

```bash
# Install
brew install chezmoi

# Initialize
chezmoi init

# Configure age encryption
cat > ~/.config/chezmoi/chezmoi.toml <<EOF
[encryption]
    type = "age"
    [encryption.age]
        identity = "~/.config/sops/age/key.txt"
        recipient = "age1pu9eskg36npprtn74vwe8hd0m4spyxck6hgfx93u8nxhr2pagagsmwv7d2"
EOF
```

### Step 2: Import Dotfiles (30 minutes)

**Option A: Automated Migration Script**
```bash
# Community script available
curl -O https://raw.githubusercontent.com/twpayne/chezmoi/master/scripts/stow-to-chezmoi.sh
chmod +x stow-to-chezmoi.sh
./stow-to-chezmoi.sh
```

**Option B: Manual Import**
```bash
# Add non-secret files
chezmoi add ~/.config/git/config
chezmoi add ~/.config/bat/config
chezmoi add ~/.zshrc

# Add encrypted files
chezmoi add --encrypt ~/.ssh/id_ed25519
chezmoi add --encrypt ~/.config/zsh/secrets.env

# Add plain SSH files
chezmoi add ~/.ssh/id_ed25519.pub
chezmoi add ~/.ssh/config
```

### Step 3: Test on Second Machine (15 minutes)

```bash
# From scratch on new machine
chezmoi init --apply github.com/AVGVSTVS96/dotfiles
# Enter age key passphrase when prompted
# Everything installs automatically!
```

### Step 4: Remove Old Setup (Once Confident)

```bash
# Unstow everything
cd ~/dotfiles
stow -D */

# Archive old dotfiles
mv ~/dotfiles ~/dotfiles.backup

# Chezmoi is now managing everything
```

## When to Migrate

### ✅ Good Reasons to Migrate

- **Multiple machines** - Work laptop, personal laptop, servers with different configs
- **Tired of manual steps** - Want one command for everything
- **Need templates** - Machine-specific configurations (work vs home)
- **Want cleaner workflow** - Automatic encryption/decryption
- **Learning opportunity** - Modern, well-maintained tool

### ❌ Reasons to Stay with Current Setup

- **Current setup works well** - Don't fix what isn't broken
- **Only one machine** - Templates less valuable
- **Prefer simplicity** - Stow + sops is straightforward and proven
- **Don't want lock-in** - Current setup is plain Git, easy to modify
- **No time for migration** - Would rather spend time coding

## Decision Framework

```
Do you manage 3+ machines with different configs?
├─ Yes → Consider migrating
└─ No → Current setup probably fine

Are you frustrated with manual sops encryption steps?
├─ Yes → Chezmoi would streamline this
└─ No → Current workflow working well

Do you need work/home profile separation?
├─ Yes → Templates would help significantly
└─ No → Less benefit

Want to learn a new tool and modernize?
├─ Yes → Good learning experience
└─ No → Stick with what you know
```

## Additional Resources

- **Official Docs:** https://chezmoi.io/
- **Age Encryption Guide:** https://chezmoi.io/user-guide/encryption/age/
- **Migration from Stow:** https://github.com/twpayne/chezmoi/issues/180
- **Templates Guide:** https://chezmoi.io/user-guide/templating/

## Bottom Line

Your current stow + sops setup is **solid and working**. Chezmoi would be an **upgrade**, not a fix.

**Try it:** Install chezmoi alongside your current setup. Test with a few files. Decide after 2 weeks if the benefits are worth the migration effort.

**Skip it:** If you're happy with the current workflow and don't need advanced features, there's no pressure to change.
