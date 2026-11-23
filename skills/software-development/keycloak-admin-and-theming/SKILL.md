---
name: keycloak-admin-and-theming
description: Use when administering Keycloak users, realms or themes.
---

# Keycloak admin and login theming

## Procedure: admin commands

1. Log in from inside the container, using the container's own environment variables so no password appears in the command line or the logs:
   `docker exec <kc-container> sh -c '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user "$KEYCLOAK_ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD"'`
2. Create users with `create users -r <realm> -s username=<u> -s enabled=true -s emailVerified=true -s email=<e> -s firstName=<f> -s lastName=<l> -s 'attributes.<name>=["<value>"]'`. Create accounts without passwords. The owner sets each password with the owner's own script or `set-password`; never set or print one in chat.
3. Verify with `get users -r <realm> -q username=<u> --fields username,enabled,requiredActions`. An empty `requiredActions` list is expected for a password-less account.
4. Change realm settings with `update realms/<realm> -s <key>=<value>`, and read the setting back.

## Procedure: login theme change

1. Keep the current theme name. Put the new theme in place, then run the file-permission and template checks below.
2. Set `loginTheme` on the realm only after the theme files are present in the container.
3. Restart Keycloak only when no sign-in is in progress, and tell the owner that sessions will end.
4. Render the sign-in page in a browser (Playwright), at phone and desktop widths. Check the title, the logo, the button, and the card's bounding box. Do not decide from the HTTP status.
5. Check `docker logs <kc-container>` for `TemplateNotFoundException` and `ERROR` lines. Any hit means the page is broken even if the status is 200 or 500 on the first request.
6. If anything fails, set `loginTheme` back to the previous theme name at once, then re-test.

## Pitfalls

- A FreeMarker import of a template path that does not exist returns HTTP 500 on the sign-in page for every user. The container log shows `TemplateNotFoundException`. Remove the bad import, then re-test the page.
- Copy theme files in as root (`docker exec -u 0` for `mkdir` or `mv`, then `chmod -R a+rX`). The Keycloak user cannot create folders in the theme root, and the failure is a permission error that looks like a missing file.
- Keycloak caches theme stylesheets. An edit to an existing CSS file can keep serving the old copy after a restart. Put new rules in a newly named file, list it in `theme.properties` under `styles=`, and confirm the browser loads that file.
- Judge a layout change from measurements, not from the page status. Check the card's left and right margins and the page's horizontal overflow at 390 px and 1280 px.
- The token issuer must equal the public address that clients use (the `--hostname` setting). The API can fetch the signing keys over an internal URL; it does not need the public one.
- Keep admin credentials and the QA account list out of the repo and out of chat. Record only account names and roles.
