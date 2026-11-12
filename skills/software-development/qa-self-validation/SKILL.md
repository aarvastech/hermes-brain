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
- A green count with skips needs the reason for each skip. Run the skipped backend (for example PostgreSQL) once with its URL set before claiming the count, and remove any throwaway container afterwards. The gated backend's passed count must reconcile: passed there equals passed on the default backend plus the skipped count. If it does not, a test depends on the backend, so resolve that before reporting the count.
- Enumerate skips from a machine-readable report, not from `grep` on console output: run with `--junitxml=<file>` and read each skipped element with its message. Console grep on `-rs` output has missed entries (a summary of 42 skips once showed 24 matching lines), so explain every skipped element before reporting the count.
- A skip count that changes between runs means a new test added a backend-gated skip. Find it with `grep -rn "skip" <test dirs>` (the `-rs` flag prints reasons, but grep finds the new case) before accepting the count.
- A CI checkout is shallow by default. Tests that read git history (for example a migration that rebuilds an earlier schema from a commit) skip silently. Set `fetch-depth: 0` on the checkout, and run pytest with `-rs` so every skip prints its reason.
- `pytest.importorskip("x")` turns a missing dev dependency into a skip, not a failure, and the whole test module disappears from the pass count. When a CI run skips a backend that passed locally, check that every module imported by the tests is declared in the project's dev extras. A local venv that happens to have the package hides the gap.
- Parametrise coverage checks over the app's route table, not over a hand-written list, and assert the table itself is complete. A hand-written list silently misses any route added later.
- After any delegated run, run `git status --short` and `git diff --stat <base>...HEAD -- <production paths>`. A delegated mutation or fix run can leave edited production files, or leave the tree on another branch, so a later commit lands in the wrong place. The only changes should be the committed test diff.
- A check-then-write that runs outside the write transaction passes every sequential test and fails only under concurrency. For each status or state transition, run two transitions on the same record at once (asyncio.gather or threads, on the real database backend). Assert that one succeeds, the other gets a conflict error, and exactly one set of side-effect rows exists (events, audit rows, notifications).
- Do not trust a checked-in test-output file. Regenerate it.
- Review a delegated run's test diff for weakened tests before accepting it. Run `git diff <base>...HEAD -- tests` and look for added skip markers, allowlist or ALLOWED entries, loosened assertions, or removed cases. A test changed to match new output is a rule change, and it needs a named reason in the report. Passing tests with a new exception is not a fix.
- A feature commit on a branch whose working tree already has unrelated modified files carries them along under `git add -A` or `git commit -a`. Stage named paths only, and check `git diff --cached --stat` before each commit.
- When a test asserts a value that a rule change makes false, update the assertion to the new rule and name the change in the report. Do not weaken the rule to keep the old assertion green.
- A fixture captured from a live API is evidence of the contract at that time. Re-capture it after any change to the endpoint's shape, and check that its field names match the types the code reads.
- After renaming a visible label, identifier or route, grep the test tree for the old string before running the suite. Assertions on the old text fail only in the full run, in files the change did not otherwise touch.
- A test that passes alone but fails in the full run, with a wall-clock message, is a timing flake. The wall clock is the input, so the test measures machine load. Replace the wait with an injected clock advanced by exactly the interval under test. Then run the file five times in a row before accepting the fix, and confirm the production code is unchanged against the base.
- When a parent branch adds a mandatory config value (for example an audience check that fails closed), child branches whose tests build the app without it will fail. Fix the test's setup and never the guard. Rebase the child, then rerun the full suite before pushing.
- A rebased branch needs `git push --force-with-lease`, since a plain push is rejected. Use it only on feature branches, never main.
- Clear unrelated generated-file changes (bytecode, lockfiles) before a rebase. They block it, and they should not be committed. Restore them with `git checkout --` for the specific paths, after checking they are generated.
- Apply each mutation with a script that asserts the replacement count (for example `assert s.count(old) == 1`) before rerunning tests. An unmatched replacement leaves the code unmutated, and the suite then passes for the wrong reason.
- Before deleting a git worktree, move the shell out of it or pass `workdir` on every call. A shell left inside a removed worktree fails every later command, so the check looks broken when it is not.
- A background run's completion only means the process exited. Read its result record and check `is_error` and `subtype` before trusting the summary. A usage or rate-limit error can exit cleanly with the error text in `result`. A wrapper that launches the agent with `nohup ... &` inside a subshell exits at once, so its completion notice arrives before the agent has started. Wait for the agent's own result file, and do not report it done until that file is complete.
- A test server started before a commit keeps serving the old code, and a probe against it reports false findings. Before trusting any probe, check the port owner: `ss -ltnp` must show the pid, its start time must be after the commit's time, and `/proc/<pid>/cwd` must be the repo. A new server that logs `address already in use` means the old one is still answering. Stop the listening pid that `ss -ltnp` reports, not only the parent you started: a uvicorn reloader child can keep the port after its parent is killed. Confirm `ss` shows no listener, then start the new one and check its log for `address already in use` before trusting it.
- Re-verify a finding against the running code before reporting it. A probe that shows a leak can come from a stale server; a test that exercises the handler directly can pass while the live process returns the old answer.
- Gate a commit on the test result. Run the tests, store `$?` in a variable, and commit only when it is 0 (`if [ $J -eq 0 ]; then git commit ...; fi`). A `;` between test and commit commits a red build, and the failure is only seen afterwards. When the test run is backgrounded, the commit must sit inside the same job's `if`. A commit in a later call reads the result after it has already been written.
- A UI change can pass every test and still look wrong. Tests prove the code runs, not the layout. For any visible change, check the screen on the device with the mobile UI review skill before reporting it done.
- Do not say a job is running until the tool call that starts it has been issued. Until then, say "not started". After it starts, report its state as issued and pending until you have read its output. Also do not report a job as finished, or a merge as done, before reading its result record and the state it should have produced.
- A PostgreSQL container that answers one readiness probe is not ready: the server restarts during initialisation. Require several consecutive successful `select 1` queries before running tests.
- A PR description reports the head it was verified at, and mergeability can read UNKNOWN or stale right after a push. Recheck after a short wait. Treat it as a conflict only when a file conflict or a failing base comparison shows it.
- Never discard the output of a command that changes state: merges, retargets, pushes, deletes. A command that fails silently still lets the next step run. Read its result, then verify the state it should have produced (for example `gh pr view <n> --json baseRefName,state` and `git ls-remote origin <branch>`). After a merge, check that the code is on the target branch itself, not on a parent branch.
- Before reporting a merge as complete, check the target branch. A PR can show MERGED with its code landing in a stacked parent. See references/stacked-prs-and-github-access.md in full-stack-developer.
- Use the tool's background flag (`background=true`) for long jobs, not a trailing `&` in a foreground command. The foreground rejects `&` and the job never starts. Foreground calls also time out near the tool limit (about seven minutes), so poll a background job in short calls instead of one long sleep.
- Never put a credential in a browser URL or in a printed command. Browser tool output and shell output are stored in the session log, so `https://user:pass@host` in a `new_tab` call leaks the password. Read the secret into a variable inside the call, pass it only to the login step, and redact it in output. If it leaks, rotate it at once.
- Test a deployed site through the path a real user takes: the browser, with the access gate, then the app's own sign-in. A curl 200 on the app shell and API does not prove the page renders. Capture the rendered `document.title`, the body text and the first error. A blank root with a 200 page means a render or startup error, so add an error boundary before guessing.
- An access gate that uses the HTTP `Authorization` header clashes with an app that sends its own Bearer token in the same header. Requests then return 401 and the app shows "No access". Test the gate and the app login together, end to end, before calling either one working.
- To find which process owns a listening port, read `/proc/net/tcp`: match the local port as `format(port, '04X')` in hex with state `0A` (LISTEN), then map the socket inode through `/proc/<pid>/fd`. Decimal port strings never match.
- Before reporting a public build as clean, grep the served bundle (fetched through the gate), not the local dist folder. Caching and a stale file copy can differ from what users receive.
- QA reports; the owner decides. Do not merge or push to main from QA.

## Status reporting

- Say explicitly when nothing is running. A message that lists earlier work without saying it is finished reads as still in progress.
- Lead with the verified result and its exact command or count. Put unverified claims after it, labelled as unverified.
- Name each blocker and the one person who can clear it, with the exact action needed (for example the token scope to add). Do not stop at "blocked".
- When an earlier message in the conversation was wrong, correct it in the next message in one sentence, before the new status. Do not let it stand because the new status is correct.

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
