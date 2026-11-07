# Stacked PRs, merging into main, and GitHub access

Use this when a branch is stacked on another PR, when you merge anything into main, or when a GitHub call returns 403 or a permissions error.

## Merging a stack into main

- Confirm the base of each PR before merging: `gh pr view <n> --json baseRefName`. A merge into a stacked parent branch looks successful and puts no code on main.
- Retarget with the output checked, not hidden: `gh pr edit <n> --base main`. If it fails, the command must stop the run, not fall through to the merge.
- Retargeting can fail silently when its output is discarded (for example `>/dev/null 2>&1`). Never discard the output of a state-changing command.
- Mergeability reads `UNKNOWN` right after a retarget or push. Poll it for a few minutes. Merge only when it reads `MERGEABLE`.
- Preferred for a stack: open one PR from the top branch to main. Verify that every intermediate head is an ancestor of the top head with `git merge-base --is-ancestor <head> origin/<top>` for each head, then merge that one PR. This avoids retargeting several PRs in order.
- After merging, check `origin/main`: `git fetch origin && git log --oneline -1 origin/main`. Run the test suite on a fresh worktree of `origin/main`, not on a worktree created before the merges landed.

## Branches and worktrees

- A merged PR does not mean its code is on main. Check with `git merge-base --is-ancestor <head> origin/main`.
- A worktree created from an older `origin/main` misses later merges. Run `git fetch` and recreate it, or check out `--detach origin/main`.

## Editing PR text

- `gh pr edit` can fail on the classic-Projects deprecation message. Use `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -F body=@<file>` and confirm with `gh api repos/<owner>/<repo>/pulls/<n> --jq .body`.

## Token scopes

- Pushing files under `.github/workflows/` needs a token with the `workflow` scope. GitHub refuses the push with a clear message. Ask the owner to add the scope; do not work around it.
- Reading Actions runs and check status needs `actions:read` or `checks:read`. A 403 on `gh run list` or `gh pr checks` means the token lacks that read scope. Say the result is unknown and ask for the scope or for a screenshot. Do not infer that a workflow passed because the PR exists.
- Account and credential changes belong to the owner. Report the exact scope needed and stop there.
