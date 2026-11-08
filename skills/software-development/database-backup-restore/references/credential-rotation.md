# Rotating a database credential

Rotation is only safe once every consumer is known. A rotated password breaks each service that still holds the old one, so inventory first, then change them in order.

## 1. Inventory every consumer (read-only)

- Running containers: compare a hash of each container's env values with a hash of the old secret. Print only the container name and MATCH or none, never the value:
  `docker inspect <c> --format '{{range .Config.Env}}{{println .}}{{end}}'` piped to a script that compares `sha256(value)` against `sha256(old_secret)`.
- Code defaults: grep the literal old credential across the tracked tree and history, including settings files, compose files, alembic.ini and test fixtures. A default in code is a consumer for any deployment that does not override it.
- Orchestrator secrets (K3s or Kubernetes Secrets, compose env files, CI variables): list the secret names that reference the database, not the values.
- Background jobs and backups: cron entries, scheduled workflows, backup scripts. Check whether each uses its own credential.
- Off-host environments you cannot inspect are UNVERIFIED consumers. Report them as unknown, and do not claim they are unaffected.

## 2. Procedure (only after an approved window)

1. Take a dump of the database before any change.
2. Generate the new password with a CSPRNG and write it only to the secret store, never to the repo, logs or chat.
3. Set the new password on the database role with `ALTER ROLE`. Keep the old one valid until step 6 passes, if the database supports it; otherwise rely on the dump for rollback.
4. Update each consumer's secret, then restart services one at a time in dependency order: database clients first, then workers, then the API.
5. Remove any code default and any committed credential in the same change.
6. Verify: each service health endpoint returns OK, one login or read path succeeds, and no service still connects with the old password (check the database's connection log or `pg_stat_activity` user list).

## 3. Rollback

- Restore the old password on the role and in the secret store, then restart the consumers in the same order.
- If the old password was not kept, restore from the dump only as a last resort, since it rolls data back.

## 4. Git history is separate

Rewriting history does not revoke a credential that has already been read or cloned. Rotate first, then decide on history cleanup. A history rewrite needs its own approval, a mirror backup, and a plan for every clone and open PR.
