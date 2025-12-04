# env.nu
#
# Installed by:
# version = "0.109.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# ======================
# === SOPS Secrets ===
# ======================
$env.SOPS_AGE_KEY_FILE = ($env.HOME | path join ".config" "sops" "age" "key.txt")

# Decrypt and load secrets from sops-encrypted file
let secrets_file = ($env.HOME | path join "dotfiles" "zsh" "secrets.env")
if ($secrets_file | path exists) and ($env.SOPS_AGE_KEY_FILE | path exists) {
    let decrypted = (^sops -d $secrets_file | lines)
    for line in $decrypted {
        # Parse "export VAR=value" or "export VAR='value'"
        if ($line | str starts-with "export ") {
            let parts = ($line | str replace "export " "" | split row "=")
            let key = ($parts | first)
            let value = ($parts | skip 1 | str join "=" | str trim -c "'" | str trim -c '"')
            load-env { ($key): $value }
        }
    }
}

# =====================
# === XDG Base Dirs ===
# =====================
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")

# ==================
# === Editor/CLI ===
# ==================
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# ================
# === Bat/Less ===
# ================
$env.BAT_THEME = "tokyonight_night"

# ===============
# === Lazygit ===
# ===============
$env.LG_CONFIG_FILE = ($env.HOME | path join ".config" "lazygit" "config.yml")

# ===========
# === FZF ===
# ===========
$env.FZF_DEFAULT_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git"
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
$env.FZF_ALT_C_COMMAND = "fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# ===========
# === NVM ===
# ===========
$env.NVM_DIR = ($env.HOME | path join ".nvm")

# ============
# === PNPM ===
# ============
$env.PNPM_HOME = ($env.HOME | path join "Library" "pnpm")

# ============
# === PATH ===
# ============
use std/util "path add"

# Homebrew
path add "/opt/homebrew/bin"
path add "/opt/homebrew/sbin"

# User local binaries
path add ($env.HOME | path join ".local" "bin")

# PNPM
path add $env.PNPM_HOME

# Cargo (Rust)
path add ($env.HOME | path join ".cargo" "bin")

# Bun
path add ($env.HOME | path join ".cache" ".bun" "bin")

# Cursor Editor
path add "/Applications/Cursor.app/Contents/Resources/app/bin"

# NVM - find active node version and add to path
let nvm_versions = ($env.HOME | path join ".nvm" "versions" "node")
if ($nvm_versions | path exists) {
    let node_dirs = (ls $nvm_versions | where type == dir | sort-by modified | reverse)
    if ($node_dirs | length) > 0 {
        let latest_node = ($node_dirs | first | get name)
        path add ($latest_node | path join "bin")
    }
}

# Local node_modules (project-specific, highest priority)
path add "./node_modules/.bin"
