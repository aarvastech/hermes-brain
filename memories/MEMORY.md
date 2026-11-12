Role: acting as full-stack dev lead for AARVAS Technologies. Standing workflow rules: (1) For hands-on coding, delegate to Claude Code via `claude -p "<task>" --output-format json` run inside the repo folder under ~/work/. (2) Always work on a feature branch named hermes/<short-name>; commit with conventional commits; push; open a PR via `gh`. Never push directly to main. (3) Never touch production servers or run destructive commands without asking Dinesh first. (4) For any task estimated over ~30 min, send Dinesh a short plan and wait for explicit OK before starting. (5) On task completion, reply with: what changed, the PR link, and anything Dinesh needs to test.
§
AARVAS summit demo (target 15 Nov 2026): isolated stack planned on Contabo host (France, IP 169.58.96.227; Tailscale for admin). demo.aarvastech.com still points to another cloud (89.167.95.6); Dinesh will switch the DNS record himself. Never change DNS, firewall or live-demo services without his approval. Summit docs: branch hermes/summit-assessment, PR #11, docs/summit/.
§
Stacked PRs: retarget each PR's base to main before merging, then confirm the merge commit is on origin/main. A hidden gh pr edit error once merged four PRs into stacked branches.
§
Summit tests: /tmp/summit-venv/bin/python; real Redis via scripts/run_summit_redis_tests.sh; PostgreSQL via throwaway container, wait for psql select 1 three times.
§
gh pr edit fails on this host with a Projects (classic) deprecation error. Update PR bodies with: gh api -X PATCH repos/aarvastech/aarvas/pulls/N -F body=@file.
§
AARVAS Care repos: ~/work/provider-platform (hermes/provider-platform, API and web) and ~/work/aarvas-mobile (hermes/aarvas-mobile, app). Public API: ~/network-site/run-api.sh behind Caddy.
§
Expo tunnel dies when its shell session ends; restart it and confirm the tunnel URL returns 200 before reporting. Web build needs VITE_KEYCLOAK_URL=https://auth.network.aarvastech.com, VITE_KEYCLOAK_REALM=aarvas-care, VITE_KEYCLOAK_CLIENT_ID=aarvas-care-web; without them it falls back to localhost:8080 realm aarvas. Summit backups: cron 21:00 UTC, status 22:00 UTC, dumps in ~/summit-backups (7-day retention, ALERT on failure).