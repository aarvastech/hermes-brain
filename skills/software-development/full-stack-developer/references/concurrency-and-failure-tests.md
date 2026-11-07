# Concurrency and failure tests for multi-step writes

Use this for any status change, state transition, or write that touches more than one table or service.

## Version check (the write itself)

- Keep a version column on the record. The first statement in the write transaction is a conditional update: set version = version + 1 where id matches and version equals the version the caller read.
- If zero rows match, roll back and return a conflict with a stable error code. Write no other rows.
- Read the record and its version before the transaction starts. A check made outside the transaction passes sequential tests and fails only under concurrency.

## Race test

- Start both transitions with asyncio.gather on the real database backend (PostgreSQL where the suite supports it).
- Hold each transition at its commit point, with an event or barrier released only after both have passed the status check. Without the hold, the two calls often run one after the other and the test passes for the wrong reason.
- Assert: exactly one succeeds, the other gets the conflict code, and the side-effect rows (events, audit rows, notifications) match one transition's worth.
- Control: run the same single transition on a different record and compare row counts.
- Retry after conflict: the losing caller re-reads and sees the winning state. Assert the retry is then rejected or applied exactly once, whichever the rules say.

## Failure injection

- For each later step (workflow start, audit write, notification write, consent write), make it raise in turn.
- After each injected failure, assert: the status is unchanged, no consent row exists, no audit row exists for the failed change, and no notification row exists.
- Then retry without the injected failure and assert exactly one set of rows.

## Pitfalls

- A test that only runs two calls one after another proves nothing about the race. Hold the window open.
- Assert on row counts, not on the absence of an exception.
- Run the race test on the production database backend. SQLite serialises writes differently and can hide the bug.