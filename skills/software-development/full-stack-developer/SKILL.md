---
name: full-stack-developer
description: Use when building a feature across data, API and client.
---

# Full-stack developer

## When to Use

Use this when a feature spans the database, the API, the web or mobile client, and the tests. It sets the order of work, the stack conventions for AARVAS, and what must be checked before calling a feature done.

## Order of work

1. **Data model first.** Write the schema change as a versioned migration with an upgrade test on the previous schema and on a fresh database.
2. **Core logic next, with no HTTP.** Rules, state changes and access checks live in the service layer and are tested directly.
3. **API route third.** Thin: parse input, call the service, map errors to stable codes, never return stack traces. Declare the roles for each route. Default deny.
4. **Client last.** Call the API only. No business rules in the client. Show loading, empty, error and conflict states. Show the source and mode label of any data that is not live.
5. **Tests at each layer,** plus one journey test that crosses all of them.

## Stack conventions for AARVAS

- Backend: Python, FastAPI, SQLAlchemy (async), Alembic-style versioned migrations per module, pytest. PostgreSQL is the target database; SQLite is for fast tests only and must be backed by a PostgreSQL run before sign-off.
- Web: React, TypeScript, Vite, Vitest. Leaflet for maps, with tiles off by default.
- Mobile: Expo (React Native) for iOS and Android. Build with EAS. Same API contract as the web app.
- Auth: Keycloak OIDC. The API verifies JWTs against the realm JWKS and requires the audience.
- Infrastructure: Docker Compose per environment. Private network for data stores. Reverse proxy is the only public entry.

## Done means

- Migration applied and tested on PostgreSQL.
- Route and role tests pass, including a wrong-role denial.
- Every write writes one audit row, tested.
- Race and failure tests for multi-step writes.
- Frontend tests and a production build pass.
- Ruff or the project linter is clean on changed files.
- Evidence is saved with the commit hash it ran against.
- A test workflow in the repo runs the suite on every pull request, and its first green run has been read with skip reasons checked. A workflow that has never run is not a control.
- Multi-step writes have race and failure tests. See references/concurrency-and-failure-tests.md.

## Publishing a branch

For merging stacks into main, and for GitHub 403 errors, see references/stacked-prs-and-github-access.md.

1. Commit with a conventional message. Push with `git push -u origin <branch>`.
2. Open the PR against the parent branch when it is stacked, and keep it a draft until the owner reviews it: `gh pr create --draft --base <parent> --head <branch> --body-file <file>`.
3. Write any PR body to a file first, then pass `--body-file`. Inline shell quoting breaks on multi-line text with backticks and quotes.
4. If `gh pr edit` fails with a Projects (classic) GraphQL error, update the body through the REST endpoint: `gh api -X PATCH repos/OWNER/REPO/pulls/<n> -F body=@<file>`.
5. Confirm the PR head matches the pushed head with `gh pr view <n> --json headRefOid`.

## Pitfalls

- A pull request stacked on another must be rebased when the base changes. Rerun the tests after the rebase.
- A stacked child needs its parent's latest head in its history before its tests mean anything. Check with `git merge-base --is-ancestor <parent-head> <child-head>`.
- A generated file tracked in git causes noise and merge conflicts. Keep `__pycache__`, `.venv` and build output out of git.
- Do not put secrets, real data or hardcoded URLs in the repo. Use environment configuration.
- Client code must not decide access. The server decides; the client only hides what the server already refuses.
- Give each concurrent run its own working tree (`git worktree add <dir> <branch>`). Two runs in one tree commit into each other's branch and leave half-applied edits.
- Stacked branches: confirm the parent's latest head is an ancestor of the child before trusting the child's tests, and rerun the tests after every rebase.
- A chained shell command stops at the first failure only if each step is joined with `&&`. A `;`-joined step after a failed `cd` or `checkout` runs in the wrong directory, so a later `npm install` or merge can act on the wrong branch. Use an absolute path or the tool's `workdir` parameter for each step that changes files.
- Do not commit or switch branches in a checkout that holds someone else's uncommitted generated files. Clear them first, or use a fresh worktree.

## Autonomy

- Proceed with ordinary development without waiting for approval: code, tests, branches, draft PRs, docs, local infrastructure on the existing host.
- Stop and ask only for: purchases or new paid services, changes to production servers or live DNS, destructive operations on data, and account or credential changes (adding scopes, creating accounts, rotating secrets). Report the exact action needed and continue with everything else.

## Output format

- What changed, by layer (data, core, API, client)
- Tests run, with exact summary lines and commit hash
- What is simulated, sandbox or live
- What is not verified
