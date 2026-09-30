---
name: gh-pr-merge
description: Create and merge GitHub pull requests using a squash workflow, then clean up branches and return to main. Use when the user asks to create a PR and merge it, merge a PR, or directly calls gh-pr-merge.
---

# gh-pr-merge

Create PR, squash merge, cleanup branches, and switch to main.

## Usage

Run `/gh-pr-merge` after committing changes on a feature branch.

## Workflow

1. Push current branch to remote
2. Create PR with `gh pr create`
3. Squash merge with `gh pr merge --squash --delete-branch`
4. Switch to main
5. Fetch and prune stale refs

## Commands

```bash
# Push branch
git push -u origin HEAD

# Create PR (interactive or with flags)
gh pr create --title "title" --body "body"

# Squash merge and delete remote branch
gh pr merge --squash --delete-branch

# Cleanup and switch to main
git checkout main
git fetch --prune
```

## Notes

- `gh pr merge --delete-branch` deletes both remote branch and local branch automatically
- Use `--squash` to combine all commits into one clean commit
- `git fetch --prune` removes stale remote-tracking refs
