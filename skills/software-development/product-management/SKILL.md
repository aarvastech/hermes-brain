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
3. **Decide build, integrate, partner or defer** for each capability. Reuse an existing product or standard where it is good enough. When a national or platform service already covers a category (for example a government health ID or document locker), the decision is to integrate with it, not to build a copy; record that as the decision basis.
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
- Match the prospect's operating model before designing screens. A home-care operator sells service areas and client households; a facility operator sells units and wings. Ask the discovery question first, then build the model they recognise.
- One app per organisation, multi-user by role. People outside the organisation (families, elders) get a separate consumer app. An individual practitioner is an organisation of one.
- Demo labelling is the owner's decision. The owner may drop repeated synthetic labels for an internal demo. The rule that a simulated action is never shown as completed stays in force regardless.

## Decision rights

- Keep building ordinary development without waiting for approval.
- Ask the owner only for: spending, production or public changes (DNS, firewall, deployment), accounts and credentials, legal or clinical sign-off, and anything irreversible.
- When cutting scope, show the full list, what each option costs, and what it leaves out. Let the owner choose. Never cut silently, and never stop the rest of the build while waiting.
- Report status in three groups: verified done, in progress, and blocked on the owner. Keep each item to one line with its evidence.
- When the owner asks what is happening, answer first with the current state: running, not started, or blocked. Name the one next step. Only then give detail, and only if asked.
- When an item needs the owner, give a numbered list of choices with one recommended option first, and say what each costs. A bare question with no options forces another round trip.
- Do not describe work as in progress until its command has actually been started. Say "next" or "not started" until then.
- Keep the owner's reviewing load small: one PR per reviewable change, and say which PRs are safe to merge now and which wait for a decision.

## Decision records

- Give every decision an ID, one owner, and one status: approved, proposed, open, or prerequisite.
- Split a bundle of decisions into one entry each, so each can be approved and tracked separately.
- Quote the owner's scope. Anything broader than what the owner said is recorded as proposed, not approved.
- An approved decision does not mean the feature exists. Record the implementation step it needs as a prerequisite entry.
- Before reusing an earlier prototype as the base for a product, check it against the brief's no-copy rules and the competitor matrix. An overlapping prototype is a candidate to retire, not a base to extend.

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
