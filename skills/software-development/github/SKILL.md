---
name: github
description: "GitHub via gh CLI: PRs, issues, reviews, repos, auth."
version: 2.0.0
author: Ben Barclay (benbarclay), Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, gh, git, pull-requests, issues, code-review, repos, auth, ci]
    category: software-development
    related_skills: [codebase-inspection, requesting-code-review]
---

# GitHub

Work GitHub end to end with the `gh` CLI (REST fallback where noted): auth,
issues, the PR lifecycle, issue-to-PR delivery, code review, and repo
management. This skill consolidates six former skills; each workflow lives
complete in its reference file — ALWAYS read the matching reference before
starting that workflow, the body below only routes.

## Routing

| Task | Read first |
|---|---|
| Auth broken / new machine / token or SSH setup / gh login | `references/auth.md` |
| Create, triage, label, assign, close issues | `references/issues.md` |
| Branch, commit, open PR, watch CI, merge | `references/pr-workflow.md` |
| Carry an ISSUE to a verified PR (full delivery loop) | `references/issue-to-pr.md` |
| Review someone's PR: diffs, inline comments, verdict | `references/code-review.md` |
| Clone/create/fork repos, remotes, releases | `references/repo-management.md` |

Supporting assets: `scripts/gh-env.sh` + `scripts/git-credential-token.py`
(auth helpers), `templates/` (PR bodies, bug report, feature request),
`references/ci-troubleshooting.md`, `references/conventional-commits.md`,
`references/github-api-cheatsheet.md`, `references/review-output-template.md`.

## Core discipline (applies to every workflow)

- Preflight once per session: `gh auth status` — if it fails, go to
  `references/auth.md` before anything else.
- Prefer `gh` over raw REST; drop to `gh api` only for endpoints the
  porcelain lacks (the cheatsheet lists them).
- Never report CI green without checking `gh pr checks` yourself; never
  claim merged without verifying `state,mergedAt`.
- Before `git checkout` of a branch in a clone that tracks generated files, check `git status --short`. Tracked `__pycache__` or other generated-file changes block the checkout. Save them to a tar first, then restore those paths with `git checkout -- <paths>`. Only do this after you confirm no non-generated changes exist.
- Before posting any branch or commit link, confirm the remote has it: `git ls-remote origin <branch>`
  must return the same SHA as `git rev-parse <branch>`. A commit that exists only locally produces a
  link that does not resolve. A delegated run's claim that it pushed is not evidence, so run this check
  yourself.
- When the reviewer asks to hold a PR, open it with `gh pr create --draft` and say in the body what it
  is waiting for. On repos with no CI status checks, commit the test output to the branch as a file so
  the reviewer has the record with the PR.
- Stop tracking a file that is already gitignored with `git rm -r --cached <path>`. This keeps
  the file on disk. Do not delete it, and do not rewrite history unless the user approves that
  separately.
- Write PR and issue bodies to a file and pass `--body-file`. Inline `--body` with backticks, quotes or `$` gets mangled by shell quoting, and a mangled body reads as a wrong claim. After any push, re-read the body and check any head hash it cites against `gh pr view <n> --json headRefOid`.
- `gh pr view --json mergeable` often returns `UNKNOWN` for a short time after a push. Re-query after a few seconds before reporting a conflict or a clean merge. A status read straight after a push is not evidence.
- If `gh pr edit --body-file` exits 0 but the body does not change, set it with `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -F body=@<file>` and read it back. A GraphQL deprecation warning in the `gh pr edit` output (for example about Projects classic) means the edit was not applied, so go straight to the API route. Check the body after any edit, whichever command you used.
- Read full context before writing: `gh issue view --comments` /
  `gh pr view --comments` — decisions live in threads, not titles.
- A PR showing `MERGED` does not prove the change reached the target branch. After any merge, fetch and check `git merge-base --is-ancestor <merge-commit> origin/<base>`. Merging a stacked PR into its parent branch lands nothing on main.
- Before merging a PR whose base is not `main`, retarget it with `gh pr edit <n> --base main`, then read `baseRefName` back and stop unless it says `main`. Do not hide the command's output: a failed retarget that goes unseen merges into the wrong branch.
- For a stack, either retarget and merge each PR bottom-up, or open one PR from the top branch into main after confirming every stack head is an ancestor of it.
- Pushing a change under `.github/workflows/` needs the token's `workflow` scope; GitHub rejects the push without it. Reading Actions runs needs `actions:read` and reading check status needs `checks:read`. A 403 names the missing scope; ask the owner to add it, then retry.
- Inside a loop over several PRs, stop on the first failed state change (`set -e`, or check `$?` after each one). Do not silence state-changing commands with `>/dev/null 2>&1` in a loop that keeps going: a later PR then merges into the wrong parent.
- Sweep for duplicates before creating anything:
  `gh pr list --search` / `gh issue list --search`.

## Verification

- The workflow's own reference file defines done for that task.
- Cross-cutting: every claim about remote state (CI, merge, release,
  issue state) is backed by a fresh `gh` read, never memory.
