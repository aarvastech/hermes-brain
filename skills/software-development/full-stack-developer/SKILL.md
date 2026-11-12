---
name: full-stack-developer
description: Use when building a feature across data, API and client.
---

# Full-stack developer

## When to Use

Use this when a feature spans the database, the API, the web or mobile client, and the tests. It sets the order of work, the stack conventions for AARVAS, and what must be checked before calling a feature done.

## Order of work

0. **Trace the production read path first.** Before building a screen, confirm which store and API the screen will read in production, and confirm that store already receives the real events. A screen built on generated seed data cannot be connected to real events later without a rewrite. If the event pipeline already exists, reuse it and build the screen on top.
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
- Web and mobile clients of one product must call the same API prefix and contracts. Check route parity before building phone screens. A phone app that calls an older API shows different data from the web, which is hard to fix after both ship.
- When a feature has a demo mode, keep the demo as a data source behind the same contract, not a separate code path. Switching from demo to live then changes configuration only.
- Before writing a client adapter, call each endpoint it will use against a local run and read the real keys. A client written against an assumed shape fails silently (empty lists, undefined fields), and the tests written from the same assumption pass.
- A client screen whose backend route does not exist must not ship as live. Either build the route first, or hide the screen and skip its tests with a TODO that names the missing route. Never delete the tests.
- A route for an action the backend cannot perform yet returns 422 with a clear message. Do not accept the request and fake the result.
- Role-based visibility is enforced on the server. The client's tab table only hides what the server already refuses. Test the server refusal for each role that must not see an action.
- A screen that does not draw a field still receives it. Scope each role's response as an allow-list of fields on the server, and check the raw JSON for every role with curl: no forbidden key may appear, not only in what the screen shows.
- Free-text notes default to private. Share a note with a family role only when a per-item flag is set. Vitals and clinical fields reaching a family role are a disclosure decision: confirm the consent scope before exposing them.
- An empty state must say why it is empty. "No open alerts" or "None scheduled" shown while the source is not connected reads as a clean status. Show "not on the platform yet" when the data source is missing, and "none" only when the source answered with no rows. A 404 from an old route must never render as an empty list.
- Fields a safety gate checks (for example a data-mode value that an AI gateway tests) are configuration, not display text. Renaming them to remove a word weakens the gate. Change display strings only.
- A production-grade app shows no demo, sample or synthetic labels in responses or UI. Scan the API output and the built bundle for those words, and also check internal names that leak into data fields.
- Client role names must match the identity provider's realm roles exactly. Grep the client's role map and the realm before creating roles.

## Product naming and identifiers

- App-facing names, bundle IDs, Android packages, URL schemes and stored-key names carry the product name only. Internal workstream or project names do not appear in them. Grep the mobile and web trees for the internal name before each commit.
- A URL scheme is set in two places: `app.json` and any constant in the code. Change both together, then grep for the old value.
- A bundle ID is permanent once published. Get the owner's explicit approval for the final ID before any store registration, and note that the ID is pending until then.
- Renaming an app does not rename backend contracts (API paths, realm names, environment variable names). Leave those unchanged, and list them as a separate approved change when they must move.
- A new redirect scheme needs a matching redirect URI in the identity provider's client config. Flag it as a backend change.

## Mobile test runs

- Jest's default 5-second timeout can fail a heavy screen test under load. Rerun once before treating it as a regression, and raise the limit for that single test only if the rerun fails too.
- Read the exit code of the real test command, not the exit code of a pipeline. A pipeline reports the status of its last filter, so run the test command alone and capture its output to a file.
- Do not clean up background processes with `pkill -f <pattern>` when the pattern appears in your own shell command. It kills the shell running the cleanup.

## Autonomy

- Proceed with ordinary development without waiting for approval: code, tests, branches, draft PRs, docs, local infrastructure on the existing host.
- Between reports, keep executing the queued items that need no approval. A message that only states status, with no tool call behind it, is idle. Ask only the one question that blocks the next item, and do that item while the question is open.
- A background-job notice reports that a job finished, not what it found. Open the result file and check its timestamp before reporting its outcome, and do not repeat an old result as new.
- Stop and ask only for: purchases or new paid services, changes to production servers or live DNS, destructive operations on data, and account or credential changes (adding scopes, creating accounts, rotating secrets). Report the exact action needed and continue with everything else.

## Output format

- What changed, by layer (data, core, API, client)
- Tests run, with exact summary lines and commit hash
- What is simulated, sandbox or live
- What is not verified
