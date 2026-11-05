---
name: product-competitor-discovery
description: "Check the market before proposing product features."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, competitors, product, market, discovery, build-vs-buy]
    category: research
---

# Product competitor discovery

## When to Use

Use before proposing or building any product feature, integration, or go-to-market claim. Skip only
for fixes to existing internal code that no user will see.

Run this before any build proposal. The founder's standing rule: check whether the market
already has the product, and how to differ, before writing code.

## Procedure

1. **Name the category and the users.** Write one line: who uses it, what job it does. Note the
   country and the regulator, because local rules change which competitors and partners matter.
   If the users are in India, list the national rails for the category before any private
   competitor, because those rails decide what must be integrated rather than rebuilt: health
   records and ABHA (ABDM), document locker (DigiLocker), provider discovery and booking (UHI),
   payments (UPI), and SMS or WhatsApp sending (DLT registration). Check the sandbox and partner
   terms for each. Use Indian rules as the primary compliance frame; foreign frameworks are
   secondary. The rails table, with status and last-check date, is in `references/india-health-rails.md`.
2. **List the incumbents.** Include government platforms and national infrastructure, not only
   startups. Search the official site and the app store listing for each one. Store listings show
   the developer's claims and user reviews, so read both.
3. **Extract capabilities from primary sources.** Use `web_extract` on the official pages and store
   listings. Search results are snippets: use them to find sources, not as evidence. A matrix row built
   only from a search snippet is labelled "ADVERTISED (search snippet only)", and its page goes on the
   pending-extraction list. Do not describe what a product does from a snippet about a company or press item. Pull user
   reviews for complaints; they name the gaps competitors have not fixed.
   Extract in small batches. A batch that hits a rate limit returns errors for the URLs it did not
   reach, so retry each failed URL alone in its own call. Any URL that still fails is a source gap,
   not a finding.
4. **Classify each capability's evidence level** before comparing:
   - VERIFIED: you used it or checked it in code, a test, or a live workflow.
   - ADVERTISED: stated on the vendor's page or store listing only.
   - LIMITED: restricted to selected providers or geographies.
   - COMING SOON: announced without a release.
   - NOT ESTABLISHED: no evidence found. Say so instead of guessing.
   Never call a competitor feature absent because you did not find it. Mark it NOT ESTABLISHED.
5. **Decide each proposed feature:** BUILD (core to our differentiator, no mature alternative),
   INTEGRATE (a public API or government interface exists), PARTNER (needs a commercial or
   regulatory agreement), or DEFER (no evidence of demand, or blocked). Give one reason per decision.
6. **Find the differentiator by combination, not by a single feature.** Compare the set of
   capabilities that no single incumbent is shown to combine. Write that as a hypothesis to test,
   and list the competitors you have not yet checked.
7. **Report the matrix** with the evidence level and the source URL on each row, plus the
   not-yet-researched list. Do not write "unique" or "first" unless every incumbent in step 2 has
   been checked.
   State the study's status in the first line of the report: complete, or incomplete with the
   named gaps. Do not describe an incomplete study as done.

## Pitfalls

- Do not copy the incumbent's core feature set. When a government app already offers a function
  for the same users (records, ABHA, locker), integrate with it or differentiate on the gaps.
- Do not trust a single snippet for a feature claim. Confirm it on the vendor page or the store listing.
- Store-listing reviews are a cheap source of gaps. Read the lowest-rated recent reviews and list
  each complaint that a feature could fix.
- Government and regulated dependencies (partner onboarding, sandbox access, DLT, payments KYC)
  are on the critical path. Name the approval, the owner, and the wait time for each.
- A third-party data API that wraps a retailer's public website is not a partner API. It does not license orders, carts or prescriptions. Look for the platform's own partner programme before making any order-flow claim.
- A vendor page behind a login, or one with no feature list, is NOT ESTABLISHED. Do not infer a feature from a marketing snippet.
- Any transaction that depends on a licensed professional or regulated product (prescription medicine, payments, KYC) is PARTNER or DEFER until the licence holder is named.
- Competitor pricing or device prices from press articles are dated. Record the date of the source.
- A capability that a competitor's own page says it does is ADVERTISED, even when the page is
  authoritative. Do not promote it to VERIFIED until you have used the product or a live workflow.
- Finding that a competitor offers a feature changes the plan. Re-check the planned differentiator
  against the matrix before building it. A differentiator that the matrix shows as already offered
  is not a differentiator, however good the feature.

## Output

A matrix with columns: capability, incumbents, evidence level, source, decision (BUILD / INTEGRATE /
PARTNER / DEFER), reason. Then the list of dependencies that need the founder's action.