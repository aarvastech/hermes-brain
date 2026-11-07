# Keycloak realm checks for an API service

Use this when a service verifies Keycloak tokens, or before any hosted realm goes live.

## Realm definition

- Declare every realm role in the realm file. A code map from a realm role to an application role does nothing until the role exists in the realm. Confirm with the admin API roles endpoint, not the file alone.
- Audience: a token only carries the API audience if the client that mints it has an `oidc-audience-mapper` protocol mapper with `included.client.audience` set to the API client id and `access.token.claim` true. Put the mapper on the client the browser uses.
- The API client that only verifies tokens is bearer-only and never mints tokens.
- Web clients have direct password login off. Keep it off in the committed realm file.

## Users

- With the Keycloak 24 user profile, a user missing a required attribute (usually email) cannot get a token. The error is `invalid_grant` with "Account is not fully set up". Give any test user an email and `emailVerified: true`, and set `requiredActions` to empty. Create the user with email in the first request. A first attempt without email fails at the token step and leaves the test user behind, so the cleanup must run even when the token request fails.

## Verifying a live realm without leaking secrets

- Read the admin password from a mode-600 env file and send it only in the request. Never print tokens, passwords or the raw admin response.
- Discovery: `GET /realms/<realm>/.well-known/openid-configuration`. Check `issuer` and `jwks_uri`.
- When calling a container port directly, send the public `Host` header so the issuer in the token matches the public hostname.
- Run the whole check in one foreground command with cleanup in a `finally` block:
  0. Read the current state first: the direct-grant flag and whether the test user already exists. An earlier interrupted run leaves both changed, so report what you found.
  1. Read the current direct-grant flag on the client, then enable it.
  2. Create a test user with a random password, assign the role, set the password.
  3. Request one token with the password grant from the same client the browser uses.
  4. Decode the header and payload. Check `alg`, that `kid` is present, `iss`, `aud` (must include the API client), `azp`, `realm_access.roles`, and `exp - iat`.
  5. In `finally`: delete the test user and restore the direct-grant flag. Print the final state of both.
- To check the signature itself, fetch the realm JWKS, select the key whose `kid` matches the token header, and verify with that key, the expected audience and the issuer. Then check that a wrong audience and a tampered token are both rejected.
- Print decoded claims only. Never print the token string.
- If the command needs an approval, the approval blocks it. Ask once, then run it in the foreground so the approval appears in the chat.
