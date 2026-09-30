---
name: jj-vcs
description: Work effectively in jj (Jujutsu) version control repos. Use when detecting .jj directory, committing changes, or managing version control in jj-based projects.
---

# jj Version Control for Agents

jj (Jujutsu) is a modern VCS that can coexist with git. It uses fundamentally different mental models that enable fearless experimentation and powerful history manipulation.

**Related files in this skill:**
- `commands.md` - Command reference and git translation
- `workflows.md` - Workflow patterns (squash, edit, stacked changes)

## Detection

```bash
# jj repo has .jj directory (may coexist with .git)
ls -d .jj 2>/dev/null && echo "jj repo"
```

If `.jj` exists, use jj commands instead of git.

## Core Mental Model

### Everything is a Commit

In git: working tree → staging → commits → stash → "in progress" states.
In jj: **only commits**. Your working copy IS a commit (`@`).

```bash
vim file.txt         # Edit file
jj status            # Shows changes in @ (not "uncommitted")
jj log               # @ visible in history
```

**Implication**: No "forgot to commit" risk. Every edit auto-snapshots.

### Change IDs vs Commit IDs

| ID Type | Stability | Example | Use For |
|---------|-----------|---------|---------|
| Change ID | Stable across rewrites | `qpvuntsm` | Referencing work |
| Commit ID | Changes on any edit | `f7b5e2a` | Git compatibility |

### Automatic Descendant Rebasing

When you modify a commit, all descendants auto-rebase:

```
Before: A → B → C
Edit A...
After:  A' → B' → C'   (automatic)
```

### Conflicts are First-Class

Git: Conflicts block operations, require immediate resolution.
jj: Conflicts recorded in commits. Continue working, resolve later.

```bash
jj rebase -d main        # Creates conflict
jj new -m "continue"     # Can still work!
```

### Operation Log = Safety Net

Every command recorded. Undo ANY operation.

```bash
jj undo                  # Undo last operation
jj op log                # See all operations
jj op restore <op-id>    # Jump to any state
```

**Philosophy**: Experiment fearlessly. You can always go back.

## Workflow Decision Tree

```
What are you doing?
│
├─ Simple feature/fix?
│  └─ SQUASH WORKFLOW
│     jj new -m "feat" → edit → jj squash (or jj new for next)
│
├─ Complex multi-part task?
│  └─ STACKED CHANGES
│     jj new -m "part 1" → edit → jj new -m "part 2" → edit → ...
│
├─ Fix specific earlier commit?
│  └─ EDIT WORKFLOW
│     jj edit <id> → fix → jj new
│
├─ Scattered fixes across stack?
│  └─ ABSORB PATTERN
│     edit files → jj absorb
│
└─ Made a mistake?
   └─ jj undo
```

See `workflows.md` for detailed patterns.

## Quick Start (Default Workflow)

```bash
# 1. Create change with intent
jj new -m "feat: implement feature"

# 2. Edit files (auto-captured)
# ... make changes ...

# 3. Review
jj diff
jj status

# 4. Continue to next task
jj new -m "feat: next task"
# Previous work now in @-

# 5. Push when ready
jj bookmark create my-feature -r @-
jj git push -b my-feature
```

## Essential Commands (Quick Reference)

```bash
# Status
jj status                    # Working copy state
jj log                       # History (mutable)
jj diff                      # Changes in @

# Creating work
jj new -m "message"          # New change
jj describe -m "message"     # Describe current

# History manipulation
jj squash                    # Move @ to parent
jj squash --into <id>        # Move @ to specific commit
jj absorb                    # Distribute fixes intelligently

# Pushing
jj bookmark create name -r @
jj git push -b name

# Safety
jj undo                      # Undo last op
jj op log                    # Operation history
```

See `commands.md` for full reference.

## When to Use This Skill

Activate when:
- `.jj` directory exists
- User mentions jj or Jujutsu
- Need version control in jj-based project

For commands: see `commands.md`
For workflows: see `workflows.md`
