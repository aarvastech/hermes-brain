---
name: qa-self-validation
description: Use before reporting code done; rerun, mutate, audit.
---

# QA self-validation

Use this before telling the user anything is done. Agents such as Claude Code report success in their own words. Treat those reports as claims to verify, not as results.

## Rules

1. Rerun the tests yourself in a fresh venv. Do not reuse the agent's output.
   - Quote the exact summary line (passed, failed, skipped counts).
   - If any tests are skipped, list them and say why. A skip is not a pass.
2. Check scope with git, not with the agent's summary.
   - Run `git diff --stat <base>...HEAD` and list every changed file.
   - Confirm no file outside the approved folders changed: no live demo, no deployment files, no other realm, nothing on main.
3. Check for false claims in code and text.
   - grep for words that imply something real that is not: dispatched, sent to, delivered, live, verified, placed a call, real.
   - Each hit must sit inside a test that asserts absence, or be labelled SIMULATED, SANDBOX or roadmap.
   - A status set by a person (for example "on the way", "arrived") must not read like a sensor-derived fact. Label its source in the UI and in the code comment (for example "self-reported").
4. Mutation-check every access guard. Break each guard in a scratch git worktree (never in the working tree), rerun the suite, and confirm tests fail. A guard whose removal leaves the suite green is untested. The failures you see are the evidence; report them by name and count. Covers: unauthenticated, wrong role, non-granted family, other patient, default deny. Procedure: references/mutation-and-pg-recipes.md.
   - Also check route-table completeness: a test must fail if a new route is added without role and audit coverage.
4b. Verify each claimed fail-before-fix test. Create a worktree at the parent commit of the fix, copy in only the new test file, and run it there. It must fail with the named assertion. If it passes on the parent, the test does not cover the bug. Remove the worktree afterwards.
5. Check audit: each write path writes an audit row, and so does each read of patient data (profile, timeline, reminders, appointments, location). Count the routes that touch patient data against the audit assertions, reads included.
6. Check migrations: run the upgrade on the previous schema and on a fresh database.
7. Lint the changed folders with the project linter.
8. Write a short QA report with: tests run (exact lines), scope check result, claim-grep result, access-break result, audit result, open issues, and what you did not check.

9. Check requirement coverage. Map each requirement in the brief to a test, a named gap, or a demo label before reporting. A requirement that is silently absent reads as an overclaim once the owner finds it, so report it as a gap in the QA report.
10. Check that the work is on the remote. Confirm `git ls-remote origin <branch>` returns the local head and the PR's head commit matches it. Report the PR URL. A reviewer cannot see local commits, so unpushed work is not delivered. A PR body written before a later push goes stale: after every push, compare the head hash the body cites with `gh pr view <n> --json headRefOid`, and edit the body if they differ. If the body cites a test-output commit, say which commit the evidence was run against, since the evidence commit itself moves the head.

## Pitfalls

- A passing suite does not prove a workflow works end to end. Trace one real path from the entry point to the stored result.
- Read the exit code of the real command, not of a pipeline. `cmd | tail` returns tail's status. Write output to a file and read `$?` from the command itself, or set `set -o pipefail`.
- A mutation run that turns tests red is not a bug. It shows the guard is covered. Only treat a failure as a bug when the unmutated suite fails.
- A green count with skips needs the reason for each skip. Run the skipped backend (for example PostgreSQL) once with its URL set before claiming the count, and remove any throwaway container afterwards.
- A skip count that changes between runs means a new test added a backend-gated skip. Find it with `grep -rn "skip" <test dirs>` (the `-rs` flag prints reasons, but grep finds the new case) before accepting the count.
- Parametrise coverage checks over the app's route table, not over a hand-written list, and assert the table itself is complete. A hand-written list silently misses any route added later.
- Check which branch the working tree is on after any delegated run. A failed run can leave it on a different branch, and a later commit then lands in the wrong place.
- A check-then-write that runs outside the write transaction passes every sequential test and fails only under concurrency. For each status or state transition, run two transitions on the same record at once (asyncio.gather or threads, on the real database backend). Assert that one succeeds, the other gets a conflict error, and exactly one set of side-effect rows exists (events, audit rows, notifications).
- Do not trust a checked-in test-output file. Regenerate it.
- When a parent branch adds a mandatory config value (for example an audience check that fails closed), child branches whose tests build the app without it will fail. Fix the test's setup and never the guard. Rebase the child, then rerun the full suite before pushing.
- A rebased branch needs `git push --force-with-lease`, since a plain push is rejected. Use it only on feature branches, never main.
- Clear unrelated generated-file changes (bytecode, lockfiles) before a rebase. They block it, and they should not be committed. Restore them with `git checkout --` for the specific paths, after checking they are generated.
- Apply each mutation with a script that asserts the replacement count (for example `assert s.count(old) == 1`) before rerunning tests. An unmatched replacement leaves the code unmutated, and the suite then passes for the wrong reason.
- Before deleting a git worktree, move the shell out of it or pass `workdir` on every call. A shell left inside a removed worktree fails every later command, so the check looks broken when it is not.
- QA reports; the owner decides. Do not merge or push to main from QA.

## Output format

- Tests: exact summary line (commit), skipped: list and reason
- Scope: files changed, outside-scope changes: none or list
- Claim check: hits and how each is handled
- Access break test: which guard, pass or fail
- Audit: write endpoints covered out of total
- Requirements: each brief item mapped to a test, a named gap, or a demo label
- Reviewer findings: each finding answered with a commit hash and a named test, or marked open. An unanswered finding is open, not implied fixed.
- Remote: branch head matches `origin`, PR URL and head commit
- Owner actions: the items only the owner can do (decisions, approvals, accounts, reviews), kept separate from engineering open issues
- Open issues: list
- Not checked: list
