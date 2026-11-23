# Playwright role checks on a live web app

Use this for read-only QA of a signed-in app across roles. Install once in a venv outside the repo: `python3 -m venv <dir>/qa-venv && <dir>/qa-venv/bin/pip install playwright && <dir>/qa-venv/bin/python -m playwright install chromium`.

## Read-only rules

- Navigation only: `goto` routes and click nav links. Never click save, tick, confirm, submit, or delete. Write checks are a separate step that needs an explicit approval naming the record and the action.
- For each role, sign in through the real login form, then wait for the redirect back to the app before reading the page.
- Scope any write check to the target record. Find the record's heading, then the control inside that container, and assert the container's status text before clicking. A text-only locator matches the first occurrence on the page, which can belong to a closed record.

## Secrets

- Load passwords from a 600-mode env file inside the script. Never print them, pass them in a URL, or echo the file. When checking the file, print only key names and `<set>`.
- Browser and shell output is stored in logs. A password in output is a leak; rotate it at once.

## What to collect per role

1. Tabs or nav links visible, compared with the role's expected set.
2. Body text of home and every reachable screen, written to a file.
3. Grep the dumps for `undefined`, `null`, `NaN`, `[object`, and staff-only names the role must not see. Count hits per screen.
4. Page errors from `page.on('pageerror')` per screen.
5. A phone-width screenshot of each screen, for a visual pass.

## Layout checks

- Measure the main card: `getBoundingClientRect()` left and right margins should match (centre offset near 0).
- `document.documentElement.scrollWidth - clientWidth` should be 0 at 390 px and 1280 px.
- A stylesheet edit that does not change the measurements may be cached. Confirm the browser loaded the new file before trusting a result.

## Reporting

- Give the table of tabs per role, the page-error count, and the grep hits. A `visit at (undefined)` line is a real bug even when the screenshot looks fine.
- State what was not checked: the content inside each screen, and any write action.