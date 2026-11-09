---
name: database-backup-restore
description: "Use when scheduling or verifying PostgreSQL backups."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [postgresql, backup, restore, cron, pg_dump, operations]
    category: software-development
---

# Database Backup and Restore

## When to Use

Use for a PostgreSQL database in a Docker container when backups must be scheduled, verified, or restored. Read the always-on rules before claiming any backup works.

## Always-on rules

- **A backup is not evidence of recoverability.** Report success only after a restore into a scratch database has matched the source on tables, indexes, constraints and row counts. A dump that only `pg_restore --list` can read is not enough.
- **A restore check that finds zero tables must fail.** An empty source passes every row-count comparison, so the check proves nothing. Fail with an explicit message when the source has no tables.
- **Record failure as its own state.** On any failure, record the result as FAILED, write an alert file, and exit non-zero. Never leave the previous success in place as the "latest" result.
- **Keep backups outside the repo, with mode 700 on the directory and 600 on files.** Keep database ports unpublished. Use the container's local socket for `pg_dump` and `pg_restore`.
- **Do not claim a full-data restore** when the source database holds only synthetic or test data. Name the data scope in the report.
- **Drop only the objects the user approved.** Back up first, then check nothing depends on the object (foreign keys, views, code references), then drop the single object and verify it is gone.

## Procedure

1. **Confirm the container is healthy** before any dump: `docker inspect -f '{{.State.Health.Status}}' <container>` must print `healthy`.
2. **Dump** with `pg_dump -Fc --no-owner` to a `*.tmp` file. Rename to the final name only after step 3 passes.
3. **Verify** the file: non-empty, and `pg_restore --list` reads it. Only then mark SUCCESS.
4. **Prune** dumps older than the retention period, only after a verified success. Never prune before the new dump exists.
5. **Restore-test** into a fresh scratch database (`CREATE DATABASE <scratch>`), then compare every user table's row count with the source. Drop the scratch database in an EXIT trap. Use a global variable for the name so the trap can see it.
6. **Mutation-check the restore test:** add one row to the source after the dump and confirm the comparison fails. A comparison that has never failed has not been shown to detect anything.
7. **Schedule** with cron. Then prove the scheduled job runs: add a one-minute cron entry that runs the real command, wait, confirm the output and status file, then replace it with the real schedule.
8. **Add a separate status check** that exits non-zero when the last attempt failed, the alert file exists, the last success is older than the limit (about 26 hours for a daily backup), or the file it points to is missing.

## Pitfalls

- **`env -i` clears every variable you set on the same command line.** Test failure injection by passing the variable through `env -i ... VAR=value script`. Otherwise the injection never reaches the script, and the test silently takes the success path. Confirm the injected run exits non-zero before trusting a failure test.
- **A `pgrep -f <name>` check matches its own command line.** Use the exit code or a result file to decide whether a job is still running.
- **`pg_dump` warnings are not failures.** Circular foreign-key warnings from TimescaleDB continuous aggregates print on stderr with exit 0. Keep stderr in the log, and fail on the exit code.
- **A stack database with no schema backs up zero tables.** Check the table count before calling a backup meaningful. Run the migrations first, then back up.
- **Apply migrations only to the approved database.** Verify on a scratch copy first, using the same migration config.
- **Docker private networks have no internet.** A `pip install` from a container on the private network fails. Install dependencies on the default network into a named volume, then mount that volume into the private-network run.
- **Clean up scratch databases and temporary volumes** after each check. List `pg_database` entries matching the scratch prefix to confirm none remain.
- **Re-copy the backup script to the cron path after every repo change.** A stale host copy runs old logic while the repo shows the fix; compare checksums of the two copies before reporting that the schedule has the fix.
- **Restore-test a dump of the same schema version.** Migrations applied after a dump make the restored schema differ from the live one, so compare the migration version table as well as the row counts.

## References

- Credential rotation (finding every consumer before changing a database password): `references/credential-rotation.md`.
- `scripts/`: none yet. Keep the backup, status and restore-test commands in one script with subcommands, and copy it to a stable host path (not the repo worktree) for cron.
