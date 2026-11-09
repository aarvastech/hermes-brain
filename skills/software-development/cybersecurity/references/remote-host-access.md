# Read-only access to a live host or database

Use this only after the owner has approved access to the named host and account.

## Before connecting
1. Confirm the target: IP or hostname, the user, and which system it is (demo, staging, production). Repeat it back and check it matches the request. Mixing up two hosts with similar names is a common error.
2. Use a key that is installed for that account. Do not reuse a key that was shared through chat or any other channel.
3. Use `-o IdentitiesOnly=yes -o BatchMode=yes` so the connection fails instead of prompting or trying unrelated keys.

## Finding the database
- Check the platform first: `docker ps` for containers, `ss -tlnp` for listeners on 5432.
- On Kubernetes, the cluster config is often root-only. If `kubectl` reports permission denied on the kubeconfig, stop and ask for an approved route. Do not escalate privileges to read it.

## Read-only checks (counts and timestamps only)
```sql
-- Tables
SELECT table_schema, table_name FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog','information_schema') AND table_type='BASE TABLE' ORDER BY 1,2;
-- Per table, only if the table is a candidate for user, account, patient or consent data:
SELECT count(*) FROM <table>;
SELECT min(created_at), max(created_at) FROM <table>;  -- only if the column exists
```
Run these inside a read-only transaction when the role allows it: `SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY;`.

## Interpreting results
- Compare each creation range with the seed scripts and their run times. Rows created in the seed window match seed data. Anything else is UNKNOWN origin, not a real user.
- Report counts, table names and origin findings. Do not report field values.

## Do not
- Export, copy or print rows.
- Run any statement that writes, locks or alters a table.
- Restart services or change configuration while checking.