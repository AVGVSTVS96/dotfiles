# jj Command Reference

Complete command reference for agents working in jj repositories.

## Status & Inspection

```bash
jj status                          # Working copy state
jj log                             # Commit history (mutable only)
jj log -r '::'                     # All history
jj log -r 'mine()'                 # My commits only
jj log -r 'main..@'                # Commits between main and @
jj diff                            # Changes in @ vs parent
jj diff -r @-                      # Changes in parent
jj diff -r A..B                    # Diff between two revisions
jj show                            # Full commit details of @
jj show <rev>                      # Full commit details of revision
```

## Creating & Describing Changes

```bash
# Create new change
jj new                             # Empty change on @
jj new -m "message"                # With description
jj new <rev>                       # On specific revision
jj new <rev1> <rev2>               # Merge commit

# Describe changes
jj describe -m "message"           # Set @ description
jj describe -r <rev> -m "message"  # Set specific revision description

# Commit (describe + new)
jj commit -m "message"             # Describe @ and create new empty @
```

### Multi-line Messages

```bash
jj describe -m "$(cat <<'EOF'
feat: add authentication

- Add login form component
- Implement JWT handling
- Add auth middleware
EOF
)"
```

## History Manipulation

### Squash (Move Changes)

```bash
jj squash                          # Move @ changes to parent
jj squash -r <rev>                 # Move <rev> to its parent
jj squash --into <target>          # Move @ to specific target
jj squash -i                       # Interactive selection
```

### Split (Divide Changes)

```bash
jj split                           # Interactive split of @
jj split -r <rev>                  # Split specific revision
jj split <paths>                   # Split specific files to first commit
```

### Absorb (Smart Distribution)

```bash
jj absorb                          # Distribute @ changes to ancestors
jj absorb <paths>                  # Absorb only specific files
```

Absorb analyzes which ancestor last touched each line and moves changes there automatically.

### Edit (Direct Modification)

```bash
jj edit <rev>                      # Make <rev> the working copy
# ... make changes (auto-amend) ...
jj new                             # Move to new change when done
```

### Rebase

```bash
jj rebase -b @ -d <dest>           # Rebase branch onto dest
jj rebase -s <src> -d <dest>       # Rebase source + descendants
jj rebase -r <rev> -d <dest>       # Rebase only <rev>
jj rebase -r <rev> -A <after>      # Insert after
jj rebase -r <rev> -B <before>     # Insert before
```

### Other

```bash
jj abandon <rev>                   # Abandon revision, rebase descendants
jj duplicate <rev>                 # Copy revision
jj restore <paths>                 # Restore files from parent
jj restore -r <rev> <paths>        # Restore from specific revision
```

## Navigation

```bash
jj prev                            # Move @ to parent
jj next                            # Move @ to child
jj prev 2                          # Move 2 commits back
jj next --conflict                 # Move to child with conflicts
```

## Bookmarks (Branches)

```bash
jj bookmark list                   # List all bookmarks
jj bookmark create <name>          # Create at @
jj bookmark create <name> -r <rev> # Create at revision
jj bookmark set <name> -r <rev>    # Move/create bookmark
jj bookmark move <name> -r <rev>   # Move existing bookmark
jj bookmark delete <name>          # Delete bookmark
jj bookmark forget <name>          # Remove without remote deletion
```

**Note**: Bookmarks don't auto-follow commits. Always move explicitly after work.

## Git Integration

```bash
# Remote sync
jj git fetch                       # Fetch from default remote
jj git fetch --all-remotes         # Fetch from all
jj git push                        # Push tracked bookmarks
jj git push -b <name>              # Push specific bookmark
jj git push -c <change-id>         # Push change (creates bookmark)
jj git push --allow-new            # Allow new bookmark creation

# Import/Export
jj git import                      # Import git changes to jj
jj git export                      # Export jj changes to git

# Remotes
jj git remote list
jj git remote add <name> <url>
jj git remote remove <name>
```

## Operation Log (Undo/Time-Travel)

```bash
jj op log                          # Show operation history
jj op log --limit 10               # Last 10 operations
jj undo                            # Undo last operation
jj undo <op-id>                    # Undo specific operation
jj op restore <op-id>              # Restore to operation state
jj op diff <op1> <op2>             # Compare operations
```

### Time-Travel Inspection

```bash
jj --at-op=<op-id> log             # View repo at past operation
jj --at-op=<op-id> diff -r @       # View diff at past state
```

## Conflict Resolution

```bash
jj resolve                         # Open merge tool
jj resolve --list                  # List conflicted files
jj resolve <path>                  # Resolve specific file
```

## Revsets (Selection Language)

### Symbols

| Symbol | Meaning |
|--------|---------|
| `@` | Working copy |
| `@-` | Parent of @ |
| `@--` | Grandparent |
| `@+` | Children of @ |
| `<bookmark>` | Bookmark target |
| `<change-id>` | Specific change |

### Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `::x` | x + ancestors | `::@` |
| `x::` | x + descendants | `@::` |
| `x..y` | Between x and y | `main..@` |
| `x & y` | Intersection | `mine() & mutable()` |
| `x \| y` | Union | `@- \| @+` |
| `~x` | Complement | `~empty()` |

### Functions

```bash
mine()                  # My commits
mutable()               # Unpushed commits
empty()                 # Empty commits
all()                   # All commits
heads()                 # Commits with no children
conflict()              # Conflicted commits
description(pattern)    # Commits with pattern in message
file(pattern)           # Commits touching files
author(pattern)         # Commits by author
```

### Examples

```bash
jj log -r 'mine() & mutable()'           # My unpushed work
jj log -r 'main..@'                      # Work since main
jj log -r 'description(fix)'             # Commits mentioning "fix"
jj log -r 'file("*.rs")'                 # Commits touching Rust files
```

## Git Translation Table

| Git | jj |
|-----|-----|
| `git status` | `jj status` |
| `git diff` | `jj diff` |
| `git log` | `jj log -r '::'` |
| `git log --oneline` | `jj log` |
| `git show <rev>` | `jj show <rev>` |
| `git add . && git commit -m "msg"` | `jj describe -m "msg"` |
| `git add -p` | `jj squash -i` |
| `git commit --amend` | (just edit files) |
| `git commit --amend -m "msg"` | `jj describe -m "msg"` |
| `git reset HEAD~` | `jj squash` |
| `git reset --hard HEAD~` | `jj abandon @` |
| `git checkout <rev>` | `jj new <rev>` |
| `git checkout -b <name>` | `jj new` + `jj bookmark create <name>` |
| `git branch` | `jj bookmark list` |
| `git branch <name>` | `jj bookmark create <name>` |
| `git branch -d <name>` | `jj bookmark delete <name>` |
| `git merge <branch>` | `jj new @ <branch>` |
| `git rebase <base>` | `jj rebase -b @ -d <base>` |
| `git rebase -i` | `jj squash`, `jj split`, `jj rebase` |
| `git cherry-pick <rev>` | `jj duplicate <rev>` |
| `git revert <rev>` | `jj revert -r <rev>` |
| `git stash` | (not needed - work is in @) |
| `git reflog` | `jj op log` |
| `git fetch` | `jj git fetch` |
| `git pull` | `jj git fetch` + `jj rebase -b @ -d main@origin` |
| `git push` | `jj git push -b <bookmark>` |
| `git push -u origin <branch>` | `jj bookmark track <name>@origin` |
