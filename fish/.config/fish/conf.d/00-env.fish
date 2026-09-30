# Fish counterpart of ~/.zshenv: Homebrew and the user-installed CLIs (agents, herdr, node)
# for every fish, including non-interactive ones started by ssh commands and T3 Code.
for brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew
    if test -x $brew
        $brew shellenv fish | source
        break
    end
end
fish_add_path -P -m ~/.local/share/fnm/aliases/default/bin ~/.local/bin
fish_add_path -P -a ~/Library/pnpm ~/.local/share/pnpm
