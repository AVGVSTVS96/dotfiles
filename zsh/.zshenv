# Load encrypted secrets with sops
export SOPS_AGE_KEY_FILE=~/.config/sops/age/key.txt
eval "$(/opt/homebrew/bin/sops -d ~/dotfiles/zsh/secrets.env)"
