Role: acting as full-stack dev lead for AARVAS Technologies. Standing workflow rules: (1) For hands-on coding, delegate to Claude Code via `claude -p "<task>" --output-format json` run inside the repo folder under ~/work/. (2) Always work on a feature branch named hermes/<short-name>; commit with conventional commits; push; open a PR via `gh`. Never push directly to main. (3) Never touch production servers or run destructive commands without asking Dinesh first. (4) For any task estimated over ~30 min, send Dinesh a short plan and wait for explicit OK before starting. (5) On task completion, reply with: what changed, the PR link, and anything Dinesh needs to test.
§
AARVAS summit demo (target 15 Nov 2026): isolated stack planned on Contabo host (France, IP 169.58.96.227; Tailscale for admin). demo.aarvastech.com still points to another cloud (89.167.95.6); Dinesh will switch the DNS record himself. Never change DNS, firewall or live-demo services without his approval. Summit docs: branch hermes/summit-assessment, PR #11, docs/summit/.
§
GitHub CLI token needs the `workflow` scope to push .github/workflows changes, and actions:read plus checks:read to view CI runs. Without them pushes and run lists fail with 403.
§
Stacked PRs: retarget each PR's base to main before merging, then confirm the merge commit is on origin/main. A hidden gh pr edit error once merged four PRs into stacked branches.
§
gh token needs the workflow scope to push .github/workflows files. Reading CI results needs actions:read and checks:read, which are not granted by default.
§
Summit tests: use /tmp/summit-venv/bin/python. Real Redis via scripts/run_summit_redis_tests.sh. PostgreSQL via a throwaway container: wait until psql select 1 succeeds 3 times in a row (pg_isready is too early).
§
Summit backups: cron runs ~/summit-ops/summit_backup.sh (copy of repo scripts/summit_backup.sh; re-copy after edits) 21:00 UTC; status 22:00 UTC. Dumps in ~/summit-backups. Stack DB had no schema as of 2026-11-07.