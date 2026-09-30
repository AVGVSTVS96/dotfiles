# jj Workflow Patterns

Detailed workflow patterns for agents working in jj repositories. Choose based on task complexity.

## Philosophy: Fearless Experimentation

jj's operation log records every command. You can always undo:

```bash
jj undo                  # Undo last operation
jj op log                # See history
jj op restore <op-id>    # Jump to any state
```

This means: **try things**. If it doesn't work, undo and try something else.

---

## Squash Workflow (Recommended Default)

**Use for**: Simple features, fixes, most daily work.

**Philosophy**: Treat `@` as a staging area. Work accumulates, then gets "flushed" to parent.

### Pattern

```bash
# 1. Create new change from your base
jj new main -m "feat: implement feature"

# 2. Edit files
# ... make changes ...

# 3. Review what's captured
jj diff
jj status

# 4. Option A: Done, move to next task
jj new -m "feat: next task"
# Previous work is now in @-

# 4. Option B: Need to add more to parent
# ... make more changes ...
jj squash                # Move @ to parent
```

### When to Squash vs New

| Situation | Action |
|-----------|--------|
| Work is complete, starting next task | `jj new` |
| Incremental addition to current work | `jj squash` |
| Need to split work into multiple commits | `jj new` between logical units |

### Interactive Squash

```bash
jj squash -i             # Select which hunks to move
```

Equivalent to `git add -p` but for moving changes between commits.

---

## Edit Workflow

**Use for**: Fixing specific earlier commit, surgical modifications.

**Philosophy**: Directly modify the commit in place. Descendants auto-rebase.

### Pattern

```bash
# 1. Navigate to the commit to fix
jj edit <change-id>

# 2. Make fixes
# ... edit files ...

# 3. Return to tip (descendants already rebased)
jj new
```

### Caution

Edit workflow puts you "inside" an earlier commit. All edits amend that commit directly. Use when you specifically want to modify an existing commit, not create new work.

### Alternative: Insert Before/After

Instead of editing in place, insert a new commit:

```bash
# Insert fix AFTER a specific commit
jj new <change-id> -m "fix: correction"
# ... make fix ...
jj rebase -r @ -A <change-id>

# Insert fix BEFORE a specific commit
jj new -B <change-id> -m "fix: prerequisite"
# ... make fix ...
```

---

## Stacked Changes (Complex Tasks)

**Use for**: Multi-part features, PR stacks, large refactors.

**Philosophy**: Build a chain of dependent commits. Each is independently reviewable.

### Pattern

```bash
# 1. Start stack from base
jj new main -m "feat: part 1 - data model"
# ... implement data model ...

# 2. Continue stack
jj new -m "feat: part 2 - API endpoints"
# ... implement API ...

# 3. Continue stack
jj new -m "feat: part 3 - UI components"
# ... implement UI ...

# 4. Review stack
jj log -r 'main..@'

# 5. Create bookmarks for PRs
jj bookmark create feat-part1 -r @--
jj bookmark create feat-part2 -r @-
jj bookmark create feat-part3 -r @

# 6. Push stack
jj git push -b feat-part1 --allow-new
jj git push -b feat-part2 --allow-new
jj git push -b feat-part3 --allow-new
```

### Fixing Earlier in Stack

When you need to fix "part 1" while on "part 3":

```bash
# Option A: Edit in place
jj edit <part1-change-id>
# ... fix ...
jj new                   # Return to tip (parts 2 & 3 auto-rebased)

# Option B: Fix from current, absorb
# ... make fixes in files from part 1 ...
jj absorb                # Intelligently distributes to correct commit
```

### Updating Stack After Feedback

```bash
# Fetch latest main
jj git fetch

# Rebase entire stack
jj rebase -b @ -d main@origin

# Push updates (force push happens automatically)
jj git push -b feat-part1
jj git push -b feat-part2
jj git push -b feat-part3
```

---

## Absorb Pattern

**Use for**: Scattered fixes that belong in different commits.

**Philosophy**: Let jj figure out where changes belong based on which commit last touched each line.

### Pattern

```bash
# 1. You have a stack
jj log
# @    part 3
# ○    part 2
# ○    part 1
# ○    main

# 2. Make fixes to various files
# ... fix bug in file from part 1 ...
# ... fix bug in file from part 2 ...
# ... fix bug in file from part 3 ...

# 3. Absorb
jj absorb

# Each fix automatically goes to the commit that last modified that line
```

### Selective Absorb

```bash
jj absorb src/api.rs     # Only absorb changes to this file
```

### When Absorb Fails

If absorb would create conflicts, it aborts. Fall back to manual squash:

```bash
jj squash --into <specific-commit>
```

---

## Conflict Handling

**Philosophy**: Conflicts don't block. Record them, resolve when ready.

### Deferred Resolution

```bash
# 1. Operation creates conflict
jj rebase -d main        # Conflict in @

# 2. Check conflict state
jj status                # Shows conflicted files
jj log -r 'conflict()'   # Shows conflicted commits

# 3. Continue working despite conflict
jj new -m "more work"    # Can create new commits

# 4. Resolve when ready
jj prev                  # Go back to conflicted commit
jj resolve               # Open merge tool
# OR just edit files to remove conflict markers
```

### Resolution Propagates

Once you resolve a conflict, descendants see the resolved state automatically.

---

## Parallel Development (Advanced)

**Use for**: Working on multiple features that need to coexist locally.

### Mega-Merge Pattern

```bash
# 1. Create merge of multiple features
jj new feature-a feature-b -m "dev: local merge"

# 2. Work with both features active
# ... develop in combined state ...

# 3. Distribute changes to appropriate features
jj squash --into <feature-a-id> <paths-for-a>
jj squash --into <feature-b-id> <paths-for-b>

# 4. Abandon the merge commit (it was just for local dev)
jj abandon @
```

---

## Workflow Selection Guide

| Task | Workflow | Why |
|------|----------|-----|
| Simple feature | Squash | Straightforward, safe default |
| Bug fix | Squash or Edit | Edit if fixing specific commit |
| Large feature | Stacked | Reviewable chunks |
| Code review feedback | Absorb | Distributes fixes automatically |
| Refactor across files | Stacked | Logical separation |
| Exploratory work | Squash | Safe accumulation, easy undo |
| Fixing earlier commit | Edit | Direct modification |
| Multiple independent tasks | Parallel (mega-merge) | Keep separate but test together |

---

## Common Scenarios

### "I started work but need to switch tasks"

```bash
# Your work is already in @, just leave it
jj new main -m "urgent: other task"
# ... do urgent work ...
jj new <previous-work-id>  # Return to previous work
```

### "I want to see what changed in my stack"

```bash
jj log -r 'main..@'              # All commits in stack
jj diff -r main..@               # Combined diff
```

### "I need to reorder commits in stack"

```bash
jj rebase -r <commit-to-move> -A <after-this-commit>
```

### "I want to combine two commits"

```bash
jj squash -r <later-commit>      # Squashes into its parent
```

### "I want to split a commit"

```bash
jj split -r <commit>             # Interactive split
```

### "I messed up and need to start over"

```bash
jj op log                        # Find good state
jj op restore <op-id>            # Jump back
```
