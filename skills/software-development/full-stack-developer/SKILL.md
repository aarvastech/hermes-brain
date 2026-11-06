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

## Pitfalls

- A pull request stacked on another must be rebased when the base changes. Rerun the tests after the rebase.
- A generated file tracked in git causes noise and merge conflicts. Keep `__pycache__`, `.venv` and build output out of git.
- Do not put secrets, real data or hardcoded URLs in the repo. Use environment configuration.
- Client code must not decide access. The server decides; the client only hides what the server already refuses.

## Output format

- What changed, by layer (data, core, API, client)
- Tests run, with exact summary lines and commit hash
- What is simulated, sandbox or live
- What is not verified
