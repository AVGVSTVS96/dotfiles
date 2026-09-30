typeset -U path

# Make Homebrew and user-installed CLIs (agents, herdr, node) available to
# non-interactive shells: ssh commands, Mosh/Moshi, T3 Code.
for brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [[ -x $brew ]] && eval "$($brew shellenv)" && break
done
unset brew
path=(
  ~/.local/share/fnm/aliases/default/bin
  ~/.local/bin
  $path
  ~/Library/pnpm(N-/)
  ~/.local/share/pnpm(N-/)
)

# Load encrypted secrets with sops
export SOPS_AGE_KEY_FILE=~/.config/sops/age/key.txt
[[ -r $SOPS_AGE_KEY_FILE ]] && eval "$(sops -d ~/dotfiles/zsh/secrets.env)"

# Vite+ bin (https://viteplus.dev)
[[ -r ~/.vite-plus/env ]] && . ~/.vite-plus/env
