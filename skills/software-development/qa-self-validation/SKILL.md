---
name: qa-self-validation
description: Use when building code. QA and verify before reporting.
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
4. Check access boundaries with a test that tries to break them: unauthenticated, wrong role, non-granted family, other patient. The test must fail when the guard is removed. If you can, remove the guard temporarily, confirm the test fails, then restore it.
5. Check audit: each write path writes an audit row. Count write endpoints against audit assertions.
6. Check migrations: run the upgrade on the previous schema and on a fresh database.
7. Lint the changed folders with the project linter.
8. Write a short QA report with: tests run (exact lines), scope check result, claim-grep result, access-break result, audit result, open issues, and what you did not check.

## Pitfalls

- A passing suite does not prove a workflow works end to end. Trace one real path from the entry point to the stored result.
- Do not trust a checked-in test-output file. Regenerate it.
- QA reports; the owner decides. Do not merge or push to main from QA.

## Output format

- Tests: exact summary line (commit), skipped: list and reason
- Scope: files changed, outside-scope changes: none or list
- Claim check: hits and how each is handled
- Access break test: which guard, pass or fail
- Audit: write endpoints covered out of total
- Open issues: list
- Not checked: list
