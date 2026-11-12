---
name: public-spa-deploy-behind-gate
description: Use when deploying a static web app behind a Caddy gate.
---

# Public SPA deploy behind an access gate

Use this for a single-host deploy: a Vite/React static build, an API on localhost, and Caddy as the only public entry, with HTTP basic auth as the gate. Each step has a check. Do not report the site live until every check passes.

## Procedure

1. Build with the full public environment, passed on the build command in the same command, on every rebuild including one of an already-live folder (the live copy is not evidence that the new build is right), for example `VITE_KEYCLOAK_URL=<public issuer> VITE_KEYCLOAK_REALM=<realm> VITE_KEYCLOAK_CLIENT_ID=<client> VITE_API_BASE=/api npx vite build`. The app reads these at build time. A missing value silently falls back to a local default (for example `localhost:8080`, another realm, another client), and the build still succeeds. Local `.env` files can add the same fallback, so do not rely on them. Then run `scripts/verify_bundle.sh <dist> <public issuer host> <client id>`. It fails on banned local addresses and on any missing production value. A library fallback can match a banned string, so read the match before ignoring it.
2. Build, verify, then copy in one guarded chain: `npm run build && scripts/verify_bundle.sh dist <issuer host> <client id> && cp -r ~/network-site/dist ~/network-site/dist.bak-$(date +%H%M) && rm -rf ~/network-site/dist && cp -r dist ~/network-site/dist`. Keep a timestamped copy of the live folder so a bad deploy reverses in one command. Use `&&`, not `;`. A failed build leaves a partial `dist/`, and a `;` chain copies it over the good site anyway. Check the build exit code before every deploy. Replace the folder contents, don't swap the folder under a running container.
3. Restart the Caddy container after replacing the folder. A bind mount keeps the old directory, so a recreated folder can return 404 until the container restarts.
4. Keep the API on `127.0.0.1` behind Caddy. Route `/api/*` with `uri strip_prefix /api` to the API port, and send everything else to `file_server` with `try_files {path} /index.html`. Add `X-Robots-Tag noindex` while the site is not public.
5. Generate the gate password on the host, store it in a 600-mode file under `~/.hermes/secrets/`, and put only the hash in the Caddyfile (`caddy hash-password`). Never print the password or put it in chat or in a URL.
6. Verify from outside the server with curl: no credentials gives 401 with `WWW-Authenticate`; a wrong password gives 401; the right one gives 200 on `/app`; the API returns JSON with the right credentials.
7. Verify in a real browser (see qa-self-validation): page title, rendered body text, and the first JS error. A blank root means a render or startup error. Add an error boundary that shows the message, then read it.
   - Do not put credentials in the URL (`https://user:pass@host/`) to test the gate. Browsers refuse `fetch` from such a page, and the URL and password end up in the tool output and logs. Instead send the gate login as a header. Use CDP `Network.setExtraHTTPHeaders` with `Authorization: Basic <base64>`. That matches a browser that has saved the login, and the password never appears in a URL.
   - Check the other sub-paths the app uses (for example a household detail page and an alerts page), not only the entry route. A route that works on `/` can still fail on deep links.
8. Grep the served bundle through the gate for banned wording and for `localhost`. Report the matches.
9. Rotate the gate password after any test that printed it, then confirm the old one gives 401.

## Pitfalls

- A gate that uses the `Authorization` header conflicts with an app that sends its own Bearer token. The gate rejects the app's API calls with 401 and the app shows a no-access screen. Move the app token to a separate header, or move to real sign-in, before the demo.
- A public API started as a background process does not survive a reboot. Give it a systemd service unit before any public date, and set its environment in the unit file, not in a shell.
- Port 80 and 443 need firewall rules. Check `ufw status`, and scope any change to the proxy only.
- Mismatched build settings cause a wrong sign-in or a blank page on production. A build run without the `VITE_*` values bakes in local defaults and still succeeds. Check the bundle for the production issuer and client id, not only for the absence of `localhost`.
- Before the cutover to real sign-in, create every account the app's role map expects, with the exact realm role names it reads (for example `caregiver`, `facility_manager`). An account with a missing or misnamed role lands on the no-access screen, and the first test looks like a broken deploy.
- The app's default dev role must be a user that exists in the seed data. A default such as `facility_manager` that is not in the profile returns 401 on the first call and shows a no-access screen. Set the default to a real seeded user for the demo.
- A minified build can split code into lazy chunks. Grep every `assets/*.js` file, not only the entry file, before concluding a string is absent. The entry file can show 0 matches while the app chunk has the string.
- Header-name edits in a TypeScript object literal must quote hyphenated keys (`"X-Dev-Authorization": value`). An unquoted key fails the build with a parse error, which is easy to miss when the build runs in the background.
- Do not expose database or cache ports publicly. Confirm with `ss -tln` after each deploy.
- Write helper scripts and config with the file-write tool, not a shell heredoc. A heredoc run through the shell triggers an approval prompt, and if that prompt times out the whole command is blocked, not just the script. The same step written as a file write runs without the prompt.
- Gate the deploy on the build's exit code in the same command, and read the build log for `error` before copying. A build that failed midway can still leave a partial `dist/` folder, which then goes live.
- Restart the API, then read its log for a traceback before any browser test. A new code path that raises `NameError` (for example a missing import on the sign-in path) shows in the app as "Request failed (500)" after a successful sign-in, and the dev-bypass tests may not exercise that path.
- Stop the old API by PID, found with `ss -tlnp | grep :<port>`. `pkill -f` with the same string kills your own shell.
- A build output directory tracked in git changes on every build. Treat it as a scratch copy: build into a fresh folder, verify it, and deploy from there. Do not commit the tracked output, or the next deploy diff hides real changes.
- Local dev env files (`.env.local`) are read by the build. Pass the public `VITE_*` values on the build command line so a localhost value in a local file cannot leak into the public bundle, then grep the bundle for `localhost`.

## Decision

A shared gate is acceptable for a demo only when sign-in is role-picker and no real data is on the host. For real users, replace the gate with the identity provider's sign-in. Once that sign-in works in a real browser, remove the gate block from the site (keep the API route outside any gate) and re-check with curl that the site returns 200 and the API returns 401 without a token. The cutover steps (realm, public issuer, relay, staff accounts, API mode switch) are in `references/keycloak-cutover.md`.
