# Fish counterpart of ~/.zshenv's secrets: sh evaluates the decrypted dotenv exactly as zsh
# does, then only the variables it defines are exported into fish.
set -gx SOPS_AGE_KEY_FILE ~/.config/sops/age/key.txt

if test -r $SOPS_AGE_KEY_FILE; and command -q sops
    set -l plain (sops -d ~/dotfiles/zsh/secrets.env)
    set -l names (string replace -rf '^export ([A-Za-z_][A-Za-z0-9_]*)=.*' '$1' -- $plain)
    for entry in (printf '%s\n' $plain | sh -c 'set -a; eval "$(cat)"; env -0' | string split0)
        set -l pair (string split -m1 = -- $entry)
        contains -- $pair[1] $names; and set -gx $pair[1] $pair[2]
    end
end
