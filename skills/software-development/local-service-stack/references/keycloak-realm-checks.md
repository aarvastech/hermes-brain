# Keycloak realm checks (self-hosted, compose)

Use after any change to a realm file, and before any hosted use of the realm.

## Import strategy

- A realm JSON mounted with `--import-realm` is imported only when the realm does not exist yet.
  The default import strategy, `IGNORE_EXISTING`, leaves an existing realm unchanged.
- To apply a realm-file change to an existing realm, either reset the realm in a disposable stack
  (remove that stack's Keycloak database volume, not any other volume), or apply the change through
  the admin REST API. Then verify with the checks below. A restart alone proves nothing.

## Reaching a strict-hostname instance

- With `--hostname-strict=true`, a request whose Host header differs from the configured hostname
  is refused or gets the wrong issuer.
- From the host, reach the container by its bridge IP and send the configured hostname as the Host
  header:
  `IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>)`
  `curl -s -H "Host: <configured-hostname>" http://$IP:8080/realms/<realm>/.well-known/openid-configuration`
- Keep the admin console off any public route. Reach it only over loopback or a private overlay.

## Checks

1. **Discovery.** The `issuer` in the openid-configuration must equal the public URL the API expects.
2. **Roles.** Get an admin token from the master realm with the admin-cli password grant. Read the
   admin user and password from the env file without printing them. Then GET
   `/admin/realms/<realm>/roles` and confirm every role the code maps (for example a manager role).
3. **Audience.** GET `/admin/realms/<realm>/clients`. The client that issues tokens to the app must have
   an `oidc-audience-mapper` with `included.client.audience` set to the API's client id. Without it,
   the access token has no matching `aud`, and an API that requires the audience rejects every token.
4. **Token end to end.** Confirm a real token from the realm fails the API when the audience is wrong
   and passes when it is right. Do this in a throwaway realm or a second stack, not in the realm you
   intend to host, so no test user is left behind.

## Pitfalls

- A missing role in the realm file is not created by a code mapping. The code only names the role; the
  realm must define it.
- Print no secret values. Read the env file inside the same command that uses it, and keep it at mode 600.
