---
name: product-management
description: Use when scoping, prioritising or planning product work.
---

# Product management

## When to Use

Use this when deciding what to build, in what order, for whom, and how we will know it worked. Use it before writing a plan, a backlog or a demo script.

## Method

1. **Problem and user first.** Name the user (role, setting, daily task) and the pain in their words. Write one sentence: for [user] who [pain], [product] does [outcome], unlike [existing option].
2. **Check the market before claiming a gap.** Look at named competitors and public government products (for AARVAS: Aarogya Setu 2.0, ABDM, DigiLocker, Silvora, Kshemam, Mediqzy, SmartPilot, Portea, Dozee, HealthPlix). Record the source and the evidence level: verified, advertised or not established. Never call a feature unique without that evidence.
3. **Decide build, integrate, partner or defer** for each capability. Reuse an existing product or standard where it is good enough.
4. **Prioritise by value and risk.** Score each item on user value, dependence on approvals, dependence on third parties, and cost of being wrong. Work the items that unblock other work first.
5. **Define done in terms of a user journey.** A feature is done when a named role completes the journey on production code, the tests cover the access rules, and the audit trail shows it.
6. **Set success measures** before launch: one or two numbers that would show the product is useful (for example, time from alert to acknowledgement, bookings completed per week, visits tracked end to end).
7. **Name the owner and status** for every decision. Separate approved decisions from proposals and open questions.

## Rules for AARVAS

- The summit demonstrates the production product on the same code and decisions. Do not plan a separate demo-only product.
- Label every screen and claim by evidence level: live, sandbox, simulated or roadmap.
- Keep scope to what can be tested end to end before the date. Cut by journey, not by screen.
- Each user role gets one journey that works end to end before any role gets a second screen.
- Show the cut clearly to the founder with what is in, what is roadmap, and why.
- Clinical and regulatory decisions have a named approver before real use.

## Backlog format

For each item: user role, journey step, acceptance test, dependency or approval needed, evidence level, owner, status.

## Demo script

For each demo: the role, the starting data, the steps in order, the expected result, the label shown on screen, and the fallback if a network call fails.

## Output format

- Problem and user
- Market check (table: product, claim, source, evidence level)
- Build, integrate, partner or defer per capability
- Prioritised list with reasons
- Done criteria and success measures
- Decisions needed, with owner and status
