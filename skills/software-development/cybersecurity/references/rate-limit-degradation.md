# Rate-limit store outages: designated fallback

Use this when a shared rate-limit store (Redis or similar) can be unavailable while the application must keep serving. Default behaviour for logins and writes is fail closed. Safety-critical operations need a narrower rule, because a fail-closed outage there can stop a patient alert.

## Decision table

| Operation during a store outage | Behaviour |
|---|---|
| Login or auth failure path | 503 `rate_limit_unavailable`; nothing is written |
| Any write not designated | 503 `rate_limit_unavailable`; nothing is written |
| Designated safety-critical operation | Served under a per-process fallback limit (below) |
| Read routes not designated | Their normal response; they do not run the write budget. State this and test it. |
| Unauthenticated request, any route | 401, as normal. The fallback never skips authentication. |

## Designated list

- Define the designated operations as one constant in code. Every route in that list must exist; every route not in it must be covered by a test that proves it fails closed during an outage.
- Add a test that fails when a new route is added without a decision on whether it is designated.
- Keep the list short and reviewed. Adding a route to it is a safety decision, not a refactor.

## Fallback limiter

- In-memory, per process, keyed by the authenticated principal, plus a process-wide total cap per window.
- Both limits come from configuration, are validated as positive integers, and have conservative defaults. Neither can be unlimited.
- A request over either limit gets 429 with a Retry-After value.
- Authentication and role checks run before the fallback. A fallback never bypasses them.
- The fallback limit is per process. Across N processes the effective limit is N times the per-process value. Say this in the security review and in the operator status output. Do not claim a global limit.

## Mode state machine

- Switch to degraded on the first store failure.
- While degraded, probe the store at most once per second. Switch back to shared enforcement on the first successful probe. Recovery needs no restart.
- Test recovery: start with the store down, bring it up, assert enforcement returns to the shared store within one probe interval, and that the shared limit then applies.

## Audit and logs

- Write one audit row when degraded mode starts and one when it ends. Use a system actor with no role. Include the start time and, at the end, the duration and the counts of fallback-served and fallback-limited requests.
- The audit write is best effort. A database failure must be logged and must not change the response to the emergency request.
- Keep the rate-limit store and the audit store separate. A transition audit must not depend on the store that just failed.
- If the database is unavailable when the transition happens, the log line is the only record. Log at error level with the event name and time, and state in the security review how those lines are reconciled into the audit table after recovery.
- Log fallback 429s once per window per principal and endpoint, not per request. Never log tokens, passwords, connection URLs or payloads.

## Operator visibility

- The unauthenticated health endpoint returns 503 with a body that names only the status (for example `degraded`), so an external monitor alerts.
- An operator-only status route returns the mode, the time degraded mode began, the duration, the fallback counts and the designated list. Give it default-deny roles and audit the read.

## Tests to require

- Outage: a designated operation succeeds within the fallback limit for an authorised principal.
- Per-principal limit trips; a second principal is unaffected.
- Process-wide cap trips.
- Unauthenticated request during the outage gets 401.
- Non-designated write during the outage gets 503 and writes nothing.
- Recovery returns to shared enforcement; the shared limit applies again.
- Exactly one start row and one end row per outage; a second outage makes a second pair.
- A failing audit database does not change the designated operation's response.
- Two application instances against one real store: shared limit enforced across both; during an outage each enforces its own fallback.
