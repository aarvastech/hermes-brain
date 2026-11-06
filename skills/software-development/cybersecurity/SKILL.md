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
- **Secrets:** environment or secret store only. Never in git, logs or client bundles. Rotate any secret that was ever committed.
- **Logging:** log who did what and when. Never log tokens, passwords, or health content. Audit rows hold no payloads.
- **Dependencies:** pin versions, run a vulnerability audit before release, remove unused packages.
- **Client:** no secrets in the app bundle; certificate pinning only if a threat model requires it; disable debug and dev menus in release builds.

## Server and network

- Only the reverse proxy is public, on 80 and 443 with TLS (Let's Encrypt). SSH restricted to known addresses or the tailnet.
- Database, cache and admin consoles bind to private networks or loopback only. Check with a port scan from outside before any go-live.
- Firewall default deny, with explicit allow rules written down.
- Patch the OS and containers on a schedule. Keep a restore test for backups.
- Separate service users per application. No root containers unless required.

## Testing

- Run the access-break test: remove a guard in a scratch copy and confirm the tests fail. Restore.
- Replay an expired, wrong-audience or wrong-issuer token and expect rejection.
- Try cross-patient reads and writes with a valid token for another patient.
- Check every write route for audit rows.
- Run a dependency vulnerability scan and record the result.

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
