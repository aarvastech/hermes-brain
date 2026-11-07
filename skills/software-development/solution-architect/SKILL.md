---
name: solution-architect
description: Use when designing system architecture or tradeoffs.
---

# Solution architect

## When to Use

Use this for any architecture question: how a system is split, where data lives, how parts integrate, or whether to build, integrate or buy.

Use this when deciding how a system is structured, what each part owns, how parts talk, and what it costs to change later. Write the decision down (ADR), then check it against the rules below.

## Method

1. **State the problem and the constraints first.** Users, data sensitivity, deadline, budget, existing systems that must keep working, regulations.
2. **List two or three realistic options.** Include "use an existing product or integrate" and "do nothing".
3. **Compare on the same axes:** correctness risk, security exposure, time to first working version, cost to change, operating burden, dependency on third parties.
4. **Pick one, say why, and name what it rules out.**
5. **Write an ADR:** context, decision, alternatives rejected and why, consequences, reversal cost, owner, status (approved, proposed, open).
6. **Set a check:** how we will know it was the right call (a test, a metric, or a review date).

## Rules for systems that hold personal or health data

- **One source of truth per fact.** One patient identity, one timeline. Roles are access rules on shared data, not separate databases per role.
- **Default deny.** Every route and every read asks: who is the caller, what role, what relationship to this patient, is that access active now. Test the denial, not just the grant.
- **Audit every read and every write** with actor, action, target and time. No payloads in audit rows.
- **Put external systems behind adapters** with a mode: live, sandbox or simulated. Show the mode in every response and on screen. Never let simulated look live.
- **Multi-step writes must not leave partial state.** Use one transaction, or an outbox written in the same transaction and applied after. Protect concurrent updates with a version check. Test a race and a failure in the middle.
- **Schema changes go through versioned migrations** with an upgrade test on the previous schema and on a fresh database.
- **Events and workflows are data, not hardcoded flows.** Timeouts and escalation paths come from configuration. Every event records owner, timeline and resolution.
- **Clinical logic needs sign-off.** Thresholds and automated actions carry a flag until a qualified clinician approves them. Never present a notification as a dispatch.
- **Keep the demo on production code.** A demo is a configuration and data setting, not a separate product.
- **Hosting:** isolate the stack (network, database, service user, volumes). Only the reverse proxy is public. Admin and database ports stay private. Backups and a restore test come before go-live. Rollback is a tagged previous image. For the DNS-switch order, firewall checks and go-live gate, see references/isolated-stack-hosting.md.
- **India context for health and identity:** check data-localisation and consent requirements (DPDP Act, ABDM rules) before storing real data; pick an Indian hosting region for real patient data.

## Review checklist

- Is each responsibility owned by exactly one module?
- Does every external call have a mode and a fallback?
- Can a failure in the middle of any flow leave a partial record? If yes, what reconciles it?
- Can a revoked user still read something? Test it.
- What breaks at ten times the load? At one tenth of the staff?
- What must a clinician, a lawyer or the founder approve before this ships?
- Is any claim in a document or a demo backed by a test or a source? Label what is not.

## Output format

- Problem and constraints
- Options compared (table)
- Decision and reason
- Consequences, reversal cost, open approvals
- Check to run and when
