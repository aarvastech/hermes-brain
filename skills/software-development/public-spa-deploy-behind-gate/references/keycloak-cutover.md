# Moving a gated SPA to Keycloak sign-in

Use when the public demo gate must give way to real identity. Each step has a check. Passwords are set by the owner, never by the agent and never in chat.

## 1. Realm and clients (in the Keycloak container, env creds, no printing)
- Run kcadm inside the container with `$KEYCLOAK_ADMIN` and `$KEYCLOAK_ADMIN_PASSWORD` from the container env. Do not echo them.
- Create a new realm for the app. Do not reuse a realm that another system uses. Set sign-up off, reset-password off, brute-force protection on, `sslRequired=external`.
- Realm roles for each care role. Use the exact role names the client app's role map reads (grep the client for its role map first). A name mismatch makes the app show no access even though sign-in works. Clients: one public web client (PKCE, redirect URI for the site only) and one mobile client (custom scheme and `exp://` redirect only).
- Check: `kcadm get realms` lists the new realm, and the OIDC discovery URL answers.

## 2. Public issuer address
- Keycloak's `hostname` is set globally in the compose file. Set the per-realm `attributes.frontendUrl` to the public HTTPS origin so the `iss` claim matches the public address.
- The API still fetches keys from an internal URL. Keep two settings: the internal base URL for JWKS, and the public issuer URL for `iss`. Using one value for both fails token validation.

## 3. Reach Keycloak without changing its container
- The Keycloak container usually sits only on internal Docker networks. Don't recreate it to publish a port. Run a small relay container on the same network that publishes `127.0.0.1:<port>` and forwards to the Keycloak container IP (for example `alpine/socat TCP-LISTEN:<port>,fork,reuseaddr TCP:<ip>:8080`). Get the IP from `docker inspect`.
- Check: `curl http://127.0.0.1:<port>/realms/<realm>` returns 200.

## 4. Public HTTPS route
- Add an auth site block to the proxy Caddyfile that reverse-proxies to the relay. Block `/admin*` and the master realm (`respond 404`). Keep this block outside the demo gate, since Keycloak has its own login.
- Confirm the DNS record resolves to the host before restarting the proxy, or certificate issuance fails.
- Check: discovery over HTTPS returns 200 with the expected `issuer`; `/admin/` returns 404 from outside.

## 5. Staff accounts without passwords
- Create one user per staff member. The username can be a readable login name if the API maps it to the staff ID through the organisation profile (a `sign_in_names` table). Map every login name in the profile, and test the mapping in the production sign-in path (the dev-bypass tests skip it). Assign the realm role. Give each user an email, because the user profile requires one to finish setup. Use a clearly fake domain for test accounts and say so.
- Set passwords through a script that reads input with hidden prompts and passes the value to kcadm with `-e` (never on a command line or in the log). Tell the owner the script path and let them run it.
- Each `docker exec` call starts a fresh kcadm session. Run `kcadm config credentials` at the start of every exec, or the later commands fail with an auth error that looks like a bad admin password.
- Check: the account can sign in once a password is set. Do not claim this until a real sign-in has succeeded.

## 6. API and web switch
- API: production mode (dev bypass off). Verify the bearer token with JWKS, take the username claim as the staff ID, and reject tokens without it. Keep the dev header only in dev mode.
- Gate: move the API route outside the demo gate once the API requires real tokens. Otherwise the phone app can't call it without the gate login.
- Web: build with the Keycloak URL, realm and client ID set. Build from a clean env so the local dev settings don't leak in.
- Check: sign in in a real browser for at least two roles, and confirm each sees only its own scope. A 401 at the API after sign-in usually means the issuer setting in step 2 is wrong.

## Pitfalls
- Do not switch the live public site before the staff passwords exist. The role picker goes away and every visitor is locked out.
- Audience checks are a gap until the API verifies the audience claim. Note it in the report instead of calling sign-in complete.
- The app may send its token in a header other than `Authorization` once the gate is gone. Accept the app's header in production, and make sure the proxy passes it through unchanged.
- Deleting a user needs the id, not the username: look the id up with `get users -q username=...` first. A delete by username silently does nothing.
