# SOPS secrets loading for fish
set -gx SOPS_AGE_KEY_FILE ~/.config/sops/age/key.txt

if test -f ~/dotfiles/zsh/secrets.env
    # sops -d outputs "export VAR=value" lines
    # Parse and convert to fish set -gx commands
    for line in (sops -d ~/dotfiles/zsh/secrets.env 2>/dev/null | string match -rv '^#|^$|^sops_')
        set -l cleaned (string replace 'export ' '' $line)
        set -l parts (string split -m1 '=' $cleaned)
        if test (count $parts) -eq 2
            set -gx $parts[1] $parts[2]
        end
    end
end
