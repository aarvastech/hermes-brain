---
name: mobile-store-listing-prep
description: "Use when preparing an Expo app for Apple or Play listing."
version: 1.0.0
license: MIT
metadata:
  hermes:
    tags: [expo, app-store, play-store, bundle-id, privacy-policy, data-safety]
    category: software-development
---

# Mobile store listing preparation

## When to Use
An Expo app is about to be registered in App Store Connect or Google Play Console, or its names, identifiers or store text are being changed. Read the always-on rules before editing any identifier.

## Always-on rules
- **Product names are brand names.** App-facing names, slugs and URL schemes use the company's product name from its brand material (for example "AARVAS Care"), never an internal project or codename. Internal module names may stay, but nothing a user or store reviewer sees may use them.
- **Bundle identifiers are permanent once published.** Apple and Google treat a changed identifier as a new app. Get the owner's explicit decision before setting or changing one, and record it in the decision log.
- **Check that the scheme matches.** The URL scheme in `app.json` and the hardcoded scheme in app code and the auth redirect must be identical. A mismatch breaks sign-in only on the device, which tests on a simulator may not catch.
- **Identity-provider redirect URIs must allow the new scheme.** Add the scheme to the sign-in client on the identity server before the app is tested on a device. This is a server change and needs approval.
- **Store claims match the build.** Any feature shown as live must work in the build. Simulated or demo-only features are labelled in the app and in the listing, and the listing does not claim real integrations.
- **Never enter, paste or commit store credentials.** The owner signs in to Expo, Apple and Play, creates the signing material, and uploads. Hermes prepares checklists and text only.

## Procedure
1. **Confirm the names and identifiers** with the owner, in writing: display name, slug, iOS bundle ID, Android package, URL scheme. Replace all old identifiers in `app.json`, README, store checklist, auth and config files.
2. **Grep the whole app for the old values** (names, scheme, package, old slug, storage keys tied to the name). Exclude `node_modules` and lockfiles. Leave backend contract names (API paths, realm names, environment variable names) unchanged unless the owner has approved a backend change.
3. **Run the full app check** (typecheck, lint, unit tests). Tests that render full screens can exceed Jest's default 5-second per-test timeout under load. Set a per-test timeout on those render-heavy tests. Do not rerun until green.
4. **Verify each app's exit code,** not just the test summary line. Keep the output in the repo under `docs/`.
5. **Privacy policy URL:** a public HTTPS page that opens without login and at a stable address. The page must describe what the app actually collects today, and must say which data is synthetic and which features are simulated. Legal review happens before publication.
6. **Data safety (Play) and privacy labels (Apple):** answer them from the code and the policy, and make sure both match. Account data, health-related data, device data and location each need an answer.
7. **Listing text and screenshots:** only show what the build does. Screenshots show the demo-data label. Do not use a screenshot of a feature that is not in the build.
8. **Report what is not verified:** no device run, no store submission, no live sign-in, no legal review.

## Pitfalls
- **A reused internal name in the store listing** is visible to reviewers and to customers, and is hard to undo once the app is public.
- **A plain `scp` of a key file onto a server** replaces that user's whole `authorized_keys` file. Use an append method; see the cybersecurity skill.
- **Rejected or mismatched listing data** is most often caused by a privacy policy that describes features the build does not have, or the reverse. Compare the two before submitting.
- **A draft app in Play Console counts as registered,** but not as published. Do not describe it as live.

## Output format
- Identifiers table (app, display name, slug, scheme, bundle ID, package, owner decision status)
- Files changed and the grep result for old values
- Check results with exit codes and commit hash
- Store forms still needed from the owner
- Items not verified
