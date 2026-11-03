---
name: browser-vault-logins
description: "Use on a login wall in browser_exec. Vault-only credentials."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Browser, Login, Vault, Security, SSO, Keycloak]
    related_skills: [blocked-page-recovery]
---

# Browser Login via the Credential Vault

## When to Use
Any `browser_exec` task that hits a login form, SSO redirect, or auth wall —
consumer sites, internal dashboards, Keycloak/Auth0/Okta-style identity providers.

When `browser_exec` lands on a login form, credentials must flow through
`browser_vault` only — never typed, never read from chat, never read from a file the
user dropped them into (`.env`, notes, etc). Treat any pasted password as compromised
and tell the user to rotate it, even a partially-masked one.

## Procedure

1. On any login/auth page, call `browser_vault(action="list")` first. It returns
   saved items as opaque **handles** (`vault_xxx`) bound to an **exact origin** —
   never the raw credential.
2. If a matching item exists: fill the username/identifier yourself with
   `fill_input` (usernames aren't secret), then use
   `browser_vault(action="fill", handle="vault_xxx")` for the password field. The
   fill only works on the page whose origin matches what was saved.
   Before filling, run `page_info()` and confirm the URL is the login page's origin. When `list` returns several items, use the handle whose `origin` equals the page origin exactly (scheme, host, port); labels can be misleading. On
   `about:blank` or a new-tab page, call `ensure_real_tab()` and `goto_url(<app URL>)`
   first: the vault checks the active tab's origin, and `fill_input` finds no fields on a
   blank page. On Keycloak forms the username field is `#username` and the submit button
   is `#kc-login`.
3. If nothing is saved, call `browser_vault(action="save_login")` to prompt the user
   in-page. **This requires an interactive UI session** (desktop app, interactive
   CLI, terminal UI) — it fails with `prompt_unavailable` / "headless/cron/API" on
   Telegram, scheduled jobs, and other non-interactive channels. When it fails there,
   tell the user exactly which of these to use instead, since they're the only real
   paths: `hermes vault add` in a terminal, or Desktop → Settings → Passwords &
   Logins — both write to the same vault `browser_vault(list)` reads from.
4. Re-check with `browser_vault(action="list")` after the user says they've saved
   it — don't assume; confirm the handle now appears before attempting a fill.

## Pitfalls

- **Origin binding is exact and does not generalize across subdomains.** A login
  saved for `https://app.example.com` will be refused with `origin_mismatch` on
  `https://auth.example.com` even though it's the same service's SSO flow —
  Keycloak/Auth0/Okta-style setups commonly redirect to a dedicated auth subdomain.
  Always save (or ask the user to save) the login for the origin shown in the
  browser's address bar at the moment the form actually appears, not the app's
  marketing/home domain.
- **A user offering to paste credentials in chat, or saying they "saved it in a
  file," is not a vault save** — redirect them to `hermes vault add` or Desktop
  Settings every time; do not read the file or accept the paste as a workaround,
  even under time pressure, because plaintext credentials end up logged/cached
  outside the vault's access controls.
- **Success after submit is the URL reaching the app's origin, not the form disappearing.** SSO pages can clear the form while still on the auth origin. Check `page_info()` for the app URL before reporting a login.
- **`browser_vault(list)` returning empty does not mean "not saved yet"** — it can
  also mean the user saved it to a different Hermes profile or a different backend
  (e.g., Desktop app's local vault vs. the backend this session's browser tool uses).
  If the user insists it's saved, ask which exact method they used and for which
  origin before concluding it's missing.
