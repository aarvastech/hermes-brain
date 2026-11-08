---
name: ai-feature-rollout
description: "Use when adding model-API features behind flags and budgets."
version: 1.0.0
license: MIT
metadata:
  hermes:
    tags: [llm, ai, budget, feature-flag, provenance, evaluation, gateway]
    category: software-development
---

# AI feature rollout

## When to Use

Use for any feature that calls a hosted model API: summaries, drafts, rephrasing, extraction, comparison. Read the always-on rules before writing code, and before telling anyone a feature works or costs a given amount.

## Always-on rules

- **Default everything OFF.** A global gate and one flag per feature, both false by default. A disabled call returns a DISABLED result and never reaches the provider. The live demo and production stay OFF until the owner approves enabling.
- **Provider-independent gateway.** Application code calls one AARVAS interface (`complete(request)`). The provider adapter (for example the Anthropic SDK) is the only code that knows the vendor. Keep a fake provider for tests.
- **Keys come only from the environment or a mode-600 secrets file**, never from the repo, logs, test fixtures or chat. The live smoke test is skipped unless a key and an explicit opt-in variable are both set.
- **Data-mode guard.** Refuse every call unless the data mode is set to the allowed value (synthetic only until the owner approves real data). Real patient data needs approval after review of the provider's data terms, consent and clinical governance.
- **Budget guard before each call.** Estimate the cost from the pricing table, add it to this month's ledger, and refuse the call if the total would exceed the ceiling. Nonessential features stop first. Never raise a ceiling automatically; report actual usage and cost per call and wait for approval.
- **Provenance for every completed call:** feature id, provider, model id, prompt-template id and version, SHA-256 of input, SHA-256 of output, input and output tokens, estimated cost, timestamp and flag state. Store hashes, not the input text.
- **Label every output** as AI-generated. Show the raw data it summarises beside it.
- **Mechanically validate constrained output.** When a model may only rephrase approved text, check that every number, time, dose, name and identifier from the source appears unchanged, and that no sentence adds an instruction. On failure, return the original text and record the fallback.
- **Keep AI away from safety decisions.** An AI feature must not compute or alter a severity, a threshold, an escalation timeout or a record that a human has not approved. Test that the severity field is unchanged by the summary path.

## Procedure

1. **Confirm the scope and the approvals** in the owner's decision record: which features, which provider, the ceiling, the data mode. If any is missing, stop and ask.
2. **Pricing table in code** with a source URL and read date. Take prices from the provider's pricing page, not from memory or a blog. Mark the table for re-verification before any purchase.
3. **Build the gateway** in this order: interface and fake provider, flags, data-mode guard, budget ledger, provenance record, real adapter. Keep the adapter last so every guard is tested before a network call is possible.
4. **Feature services** on top of the gateway. Each has an approved-template or prompt source, a validator, and a fallback path that works with the feature flag OFF.
5. **Evaluation fixtures:** synthetic cases in a fixtures file, with a scorer that reports validation pass rate, required-field presence, fallback rate and unchanged-severity checks. Write the report to a file under `docs/`.
6. **Tests run offline.** Cover: disabled flag never calls the provider; data-mode refusal; budget refusal at the ceiling; ledger totals per feature; provenance fields present and no input text stored; validator rejects an invented number; validator accepts a valid rephrase; severity unchanged; review state transitions.
7. **Cost measurement** only after the owner supplies the key: run a fixed synthetic set, record input and output tokens per call, multiply by the pricing table, and report cost per call per feature. Quote the pricing date.
8. **Report separately:** architecture and code, benchmark results, cost per call, quality and failure cases, clinical review status, outstanding costs. Name what was not run live.

## Pitfalls

- **A Claude or other subscription login does not give API access.** The API needs a key from the provider's console on an account with billing. Ask the owner to create the key and place it in the secrets file, and do not try to reuse a Claude Code session.
- **The budget guard must count the estimate before the call,** otherwise the last call can cross the ceiling. Reconcile the ledger against the provider's usage after each run.
- **Mocked tests of the client are not evidence the real path works.** A test that mocks the model's message method can pass while the real client has no such method. Include one unmocked construction test of the adapter with no network.
- **Pricing changes.** Prices in code go stale. Store the read date and re-verify before any cost statement.
- **Measured usage beats estimates.** Report the estimate as an estimate until a live run has produced token counts.
- **Do not describe a feature as clinically reviewed** until a documented review record exists for that version.

## Output format

- Features and flags (state of each)
- Budget: ceiling, spent, remaining
- Provenance fields recorded
- Test results (exact summary line and commit)
- Live results, or "not run: no key"
- Cost per call (measured or estimated, with the pricing date)
- Clinical review status
- Outstanding approvals
