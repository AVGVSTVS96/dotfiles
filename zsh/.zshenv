# Make Homebrew tools available to non-interactive SSH sessions (Mosh/Moshi).
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load encrypted secrets with sops
export SOPS_AGE_KEY_FILE=~/.config/sops/age/key.txt
eval "$(/opt/homebrew/bin/sops -d ~/dotfiles/zsh/secrets.env)"

# Vite+ bin (https://viteplus.dev)
. "$HOME/.vite-plus/env"
