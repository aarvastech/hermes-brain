---
name: cybersecurity
description: Use when securing an app, server or health data.
---

# Cybersecurity

## When to Use

Use this for threat modelling, secure design review, security testing, server hardening, secrets handling, and incident response for AARVAS or any system that touches personal or health data.

## Threat model first

For each feature, answer:
- What data is it, and who is the data about (patient, family, staff)?
- Who can reach it (public internet, tailnet, internal service)?
- What does an attacker gain by abusing it (a patient record, a family member's access, a service account)?
- What is the worst credible outcome, and how would we know it happened (audit, alert)?

## Application security checklist (OWASP-style)

- **Authentication:** OIDC tokens verified against the realm JWKS; issuer, audience, expiry and key id checked; fail closed when keys cannot be fetched. No dev or bypass login in hosted builds.
- **Authorisation:** default deny on every route. Check role and the patient relationship (grant, care-team assignment) at read time, not only at write time. Test that revoked access stops working.
- **Input validation:** typed schemas, range checks, size limits on bodies and uploads, reject unknown fields where it matters.
- **Output:** no stack traces, no internal ids in errors, no other patient's data in lists. Stable error codes.
- **Injection:** parameterised queries only. No string-built SQL.
- **Files:** type and size checks, scan before storage, store outside the web root, encrypt at rest for health documents, signed short-lived download links.
- **Sessions and tokens:** short-lived access tokens, refresh handling on mobile in secure storage, logout revokes the session.
- **Secrets:** environment or secret store only. Never in git, logs or client bundles. Rotate any secret that was ever committed. Keep local secret files outside the repo at mode 600, and load them into the process environment. Never echo their values into chat, logs or command output.
- **Logging:** log who did what and when. Never log tokens, passwords, or health content. Audit rows hold no payloads.
- **Dependencies:** pin versions, run a vulnerability audit before release, remove unused packages.
- **Client:** no secrets in the app bundle; certificate pinning only if a threat model requires it; disable debug and dev menus in release builds.

## Server and network

- Only the reverse proxy is public, on 80 and 443 with TLS (Let's Encrypt). SSH restricted to known addresses or the tailnet.
- Database, cache and admin consoles bind to private networks or loopback only. Check with a port scan from outside before any go-live.
- Firewall default deny, with explicit allow rules written down.
- Forwarded client addresses: trust `X-Forwarded-For` only when the direct peer is a known proxy address. Take the rightmost entry that the proxy added, not the leftmost, because a client can supply any leftmost value. The proxy must overwrite the header, not append to it. Caddy: `header_up X-Forwarded-For {remote_host}`.
- Shared limits: counters that live in one process give each worker its own limit. Keep them in a shared store (Redis) on a private network with a password from the environment and no published port. A limit check on a protected operation fails closed (503 and no write) when the store is unreachable, logs the error class without the connection URL, and never falls through to allow.
- Safety-critical operations during a store outage are not covered by the fail-closed rule for logins and writes, because blocking them can stop a patient alert. Use the designated-fallback pattern in references/rate-limit-degradation.md, with its limits, audit and recovery rules.
- Expose a no-detail health endpoint (200 when the store responds, 503 otherwise) and state in the security review that an external monitor must poll it.
- Patch the OS and containers on a schedule. Keep a restore test for backups.
- Separate service users per application. No root containers unless required.

## Testing

- Run the access-break test: remove a guard in a scratch copy and confirm the tests fail. Restore.
- Replay an expired, wrong-audience or wrong-issuer token and expect rejection.
- Try cross-patient reads and writes with a valid token for another patient.
- Check every write route for audit rows.
- Shared-state controls (rate limits, sessions, locks) need two application instances against one real store in the test. A single instance with an in-memory store cannot show that a limit set in one process applies to the other, and it hides the per-process counter bug.
- Test the failure path of each shared store: stop it, then confirm the protected operation returns the fail-closed error and writes nothing.
- Run a dependency vulnerability scan and record the result.
- For live identity checks (roles, audience, token claims, user profile), follow references/keycloak-realm-checks.md. Create any test identity with a random secret, remove it and restore every flag in the same command.

## Incident response

- Contain first: revoke affected tokens, rotate secrets, block the route.
- Preserve logs.
- Assess what data was exposed and about whom.
- For India: CERT-In directions (2022) require reporting certain incidents within six hours and keeping logs for 180 days. Confirm the current rules with counsel.
- Data breaches involving personal data may need notice under the DPDP Act 2023 and its rules. Confirm with counsel.
- Write a post-incident note with timeline, cause, fix and a test that would have caught it.

## Output format

- Threat model summary
- Findings by severity, with file and line
- Tests that prove each fix (failing first)
- Residual risk and owner
