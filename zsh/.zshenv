# Load encrypted secrets with sops
export SOPS_AGE_KEY_FILE=~/.config/sops/age/key.txt
eval "$(sops -d ~/dotfiles/zsh/secrets.env)"
