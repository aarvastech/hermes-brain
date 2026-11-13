---
name: mobile-ui-review
description: Use when reviewing app UI look, feel and layout on device.
---

# Mobile UI review

Tests and type checks prove code runs. They do not prove a screen looks right. Use this before reporting any UI as done, alongside qa-self-validation.

## Stage order (owner's required sequence)

Run these stages in order, in one run, without pausing between them. When the owner says "continue", finish stages 1-5 before any message. A status update between stages is a stop, not progress, and the owner has to ask again to get the work done.

1. Development: build the change and match it to the web app's data and sections for the same role. Read the web component's section headings and the endpoint fields it uses before writing the phone screen, then compare field by field. List any section the web shows that the phone does not. A phone screen that skips a web block (for example area staff, visits and events per hour) is a gap to fix in this stage, not after the owner reports it.
2. QA: type check, full test suite, and a render test on a real API response (see Procedure). Commit only when the checks pass.
3. UI/UX: judge the screens against the checklist and the look-and-feel rules below. Fix and re-check.
4. Product: check which roles can reach each screen, and that the API refuses roles that should not see the data.
5. Domain: check any clinical or safety wording. Thresholds stay labelled as placeholders until a qualified clinician signs off.
6. Only after stage 5, send the owner one message. Never send a check request after a single stage: what changed, what was checked, what was not checked, and the exact screen to open.

## Route check (before any walkthrough)

1. For every endpoint the app calls, confirm the platform serves it. Run `python3 scripts/check_api_routes.py <endpoints-file> <openapi-json-or-url> --prefix /app` from this skill's folder. Each MISSING path is a screen that will show an error on the phone. Fix or hide it before the walkthrough. Run it against the host the phone build calls (the public API named in the build's env file), not only the local dev server: a route that exists locally but not on the deployed API shows as a load error on the phone.
2. Call each read endpoint as each role and record the status codes. A 200 for a role that should be refused is a finding, even if the screen hides the data.

## Procedure

1. Render each role's screens, not one. For each role (family, caretaker, nurse, doctor, manager), open every tab and drill-down on device or simulator. Screenshot each. If no screenshot tool exists on the host, say so, and check data and layout with a render test instead.
2. Write a render test for each screen that reads platform data. Use a real captured response saved as a fixture (not a hand-written object), and assert that the labels a user would read are on screen. Hand-written fixtures hide shape mismatches. Capture one fixture per state the screen can render (for example an unattributed item, a resolved item, an empty list); a fixture from a shared server with one record leaves the other branches untested.
3. Judge each screenshot against the checklist. Write findings as a numbered list with the screen name.
4. Fix, rebuild, and re-capture the same screens. Do not report done from code alone.
5. Report the screens checked, the findings, and what was not checked (Android vs iOS, dark mode).

## Platform data pitfalls

- A template string around an object field prints `[object Object]` on the phone. Read the scalar field the API also returns (for example a label), and check the response shape before using a field in JSX.
- Hiding a screen in the UI is not access control. Call every read endpoint as every role and confirm the API refuses roles that should not see the data. A 200 for a family login on staff-only fields is a finding to report.
- An empty group in a list is a data gap, not a layout bug. Say which records have no source (for example, only one household has a live feed) instead of showing a blank page.
- Show a name, or a plain phrase like "Household". Never show a raw ID as a fallback.
- When names are missing, show a count (for example "24 households"), not the same placeholder word repeated. A repeated fallback reads as broken data.
- A status rule from the web app goes into one pure function with one unit test per branch (for example Stable, Watch, Critical), and its comment cites the web source file. Do not re-derive it inside each screen, or the phone drifts from the web.

## Look and feel (the owner's standard)

- Do not ship plain white stacked lists. Use summary tiles and grids: each item is a tile with a colour, a name and a short meta line. A row of full-width buttons reads as an admin list and is rejected.
- Use the brand palette for tiles and headers (royal blue primary, navy titles, cyan accent). Where several groups sit on one screen (for example service areas), give each group its own colour so they read as separate regions. Keep the colour assignment stable for each named group.
- Dashboard first: a greeting or one-line status, a row of summary tiles, then grouped cards. Show counts only from a real source; say "not connected yet" for anything without one.
- Clinical role home screens (doctor, nurse) follow the same rule. A sortable table of households is the admin list the owner rejects. Use summary tiles, cards for residents who need review, and cards with buttons for the review queue. A table is acceptable only as a secondary detail that opens on tap.
- Before reporting a look as done, state the colours and layout in words and ask the owner to confirm on the phone. Do not describe a look as done from code alone.

## Checklist

- **Brand**: logo and name on every screen; navy text, royal primary, cyan accent, light blue-grey background.
- **Header and spacing**: no empty band above the title; no overlap with status bar or dev button.
- **Hierarchy**: one title per screen; section headings bolder than body; labels name the thing ("Households" for homes).
- **Words**: no raw IDs (hh-ind-01) shown to people; no technical text (HTTP 404, Bad Gateway, null); no internal words on screen: demo, synthetic, simulated, sample, test data. A wording test has no allowlist. If a required label contains a forbidden word, reword the label, and do not add an exception to the test.
- **Empty states**: every list has a plain sentence when empty, never blank or an error code.
- **Role fit**: each role sees only its own tabs and actions; hide actions a role cannot use.
- **Buttons**: one filled primary per card; secondary outlined; tap targets 44pt+; labels are verbs.
- **Density**: lists scroll; names wrap; no cards nested in cards.
- **Consistency**: same card, title and spacing on every screen.
- **Feedback**: after a tap, plain words say saved, failed or sent.

## Pitfalls

- A text-match unit test does not show a blank header band or a wrong label. Look at the screenshot.
- Negative margins inside scroll views can be ignored on device. Check on device.
- The Expo gear button is a dev-build artefact. Confirm it is absent in a release build.
- Do not call a screen finished because the bundle built.
- Expo tunnel URLs change and an old one returns 502 Bad Gateway. Recovery steps: references/expo-tunnel-preview.md. A dev server started in a foreground shell dies when that shell ends; start it under nohup and confirm the bundle returns 200 before sending the address.
- A grid tile is a `Pressable` with `accessibilityRole="button"`. Keep the escalation or secondary action as a text link, not a button in the grid.
- Commit gating: see qa-self-validation (commit only when the test exit code is 0).
- Before telling the owner to reload, check that the tunnel bundle returns 200 at that moment and quote the exact address in the same message. A tunnel that was up earlier can be down by the time the owner opens it.
- Before adding a field to a shared TypeScript interface, grep the interface for the name. Re-declaring an existing key fails `tsc` with a duplicate-identifier error, and a different type on the same key fails again. Extend the existing declaration instead.
- Group tiles can carry a status line from the platform's own state field (for example `ALL_OK`) and the open-alert count. Map the open-alert count first, then the state, then a plain fallback, so a home with an alert never reads as OK.
- Colour a group once, by its position in the list or its stable name, and keep that colour on every screen where the group appears.
- In a render test, `getByText` throws when the same label appears more than once (for example a line repeated per resident). Use `getAllByText` with `length > 0`, or scope the query with `within`.
- Show a `null` value field as "not recorded". Never show it as zero, and never fill it with a default name.
- A schedule-based guess is not a fact. Show a dose as taken by a person only when the platform confirms the person (for example `attribution_source` is `sole_client`). Otherwise show "who took it not recorded" and the prescribed person on a separate line. The same rule covers readings from a shared device: say "not assigned to a resident".
- A "Could not load…" error on a screen after a successful sign-in means a missing route or an out-of-date deployed API. It is not a sign-in fault. Check the route on the host the phone calls before changing the screen code.
- Each role's home screen reads only that role's endpoints. A screen copied from the manager's home can call a route the role is refused, and the owner sees it as a load error on the phone.
- A backend route that works on the local dev server is not live until the host the phone calls has been restarted on that code. Local tests cannot see this gap. After any backend change, check the new route on the public host with a token before asking the owner to open the app.
