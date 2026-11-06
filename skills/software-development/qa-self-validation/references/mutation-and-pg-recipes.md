# Recipes for QA self-validation

Use these when the SKILL.md rules call for a mutation check or a database run.

## Mutation-check a guard (scratch worktree)

Never edit the branch under review. Use a throwaway worktree.

1. Create the worktree at the branch under test:
   `git worktree add -q <scratch>/qa-wt <branch>`
2. Record the baseline: `cd <scratch>/qa-wt && <venv>/bin/python -m pytest <paths> -q -p no:cacheprovider > base.txt 2>&1; echo $?`
3. Break one guard, for example replace the authorize check with `if False and ...` (a one-line edit with sed or python). Save a backup first: `cp file file.bak`. In a python edit, assert the old text occurs exactly once before writing (`assert s.count(old) == 1`). A replace that matches nothing leaves the guard intact, and the run then looks like a passing guard.
4. Rerun the same command. Record the exit code, the summary line and the FAILED node ids: `grep -E '^FAILED' out.txt`.
5. Restore from the backup and confirm the worktree is clean: `git -C <scratch>/qa-wt status --short` (only pycache noise allowed).
6. Repeat for each guard: the service-level check and the route-level role gate are separate guards.
7. Remove the worktree from the main checkout, never from inside it: first `cd <main-checkout>`, then `git worktree remove --force <scratch>/qa-wt`. Then `git worktree list` should show only the main checkout. If the shell's working directory was left inside the removed worktree, every later command fails with exit 126 "No such file". Pass `workdir=<main-checkout>` on each terminal call, or open a new shell session, before retrying.

Interpretation:
- Many failures from one guard: good coverage, report the count.
- Zero failures: the guard is untested. Add a test before claiming it.
- Only one failure, from a different guard: check that the test named actually covers the guarded route.

## Run a test suite against a throwaway PostgreSQL

1. Pick a free loopback port and a unique container name. Do not reuse names of existing containers, and do not touch containers you did not start.
   `NAME=qa-pg-$RANDOM; PORT=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")`
2. Start it bound to loopback only, using the image the project's compose file names (for AARVAS summit: `timescale/timescaledb:latest-pg16`): `docker run -d --name $NAME -e POSTGRES_USER=qa -e POSTGRES_PASSWORD=qa -e POSTGRES_DB=qa -p 127.0.0.1:$PORT:5432 <image>`. Or run `bash scripts/pg_ephemeral.sh up` from this skill.
3. Wait until ready: `docker exec $NAME psql -U qa -d qa -tAc "select 1"` must succeed three times in a row, up to about 90 seconds. Do not use a single `pg_isready` check: it passes while the server is still initialising, and the first test connection then fails with "the database system is starting up".
4. Run the suite with the URL set to the driver the project uses (check the project's database URL scheme first). Save output to a file.
5. Always remove it, even after a failure: `docker rm -f $NAME`. Then `docker ps` should show only the containers that were running before.

Report the counts from a PostgreSQL run separately from the SQLite run. Name the driver and the server version.
