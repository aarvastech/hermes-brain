# Architecture blueprint: method and checklist

Use this for a multi-section architecture document. Build it from evidence, not from the plan. A capability that appears only in a roadmap is not an existing asset.

## Order of work

1. **Repository inventory first.** For each repo in scope, record purpose, last commit, owner and whether it is active. Check the IP boundary with a word-boundary search of source for any third-party name the owner has excluded. Exclude vendored folders from the search, and note that a text search is not a provenance review.
2. **Capability evidence.** Classify each capability with a status and a cited file path and test or run result:
   - IT: implemented and tested
   - INT: implemented, not sufficiently tested
   - PART: partially implemented
   - PLAN: planned, documented only
   - NI: not implemented
   A test that passes only because it mocks the thing under test is INT, not IT. Check the real path unmocked before setting the status.
3. **Component classification** for every proposed component:
   - EXIST: existing owned asset
   - OSS: existing open-source dependency (record its licence from the lockfile)
   - 3P: third-party integration
   - NEW: new development
   - VERIFY: ownership or technical check still needed
4. **Competitor research from primary sources.** Use vendor pages, official API docs and the open-source repo's own licence. Mark anything not verified as UNVERIFIED. Record rate-limited or blocked fetches as UNVERIFIED rather than guessing. Do not claim uniqueness; state which features overlap with competitors and which need validation.
5. **Build, integrate or partner.** For each capability, pick one: BUILD (strategic IP), INTEGRATE (licensed tech or service), PARTNER (external provider delivers the service). Name what it rules out.
6. **Demo dependency graph.** For any live demo, identify the serving repo, the deployment method (cluster manifest, compose file, workflow), and each external host it depends on. Use read-only checks only (headers, DNS, deployment files). Never change a live service while inventorying it.

## Document outline (20 sections)

1. Repository and IP inventory
2. Current product and architecture assessment (capability table with evidence, test status, security gaps)
3. Competitor research (verified features, API availability, licensing, pricing, market)
4. Build, integrate, partner matrix
5. Target platform architecture (layers, each marked EXIST, NEW or PART)
6. Domain model or ontology (state if not implemented, and the mapping strategy)
7. Unified context architecture (who sees what, under which consent)
8. Agent or component catalogue (responsibilities, inputs, outputs, tools, data scope, approval, stage)
9. Orchestration and communication
10. Interoperability (standards and systems, each with a classification)
11. Security, consent, tenant isolation
12. Clinical or domain safety and governance
13. First end-to-end workflows (which exist, which are planned)
14. Deployment architecture (current and target)
15. Implementation backlog (ordered, with the blockers)
16. Dependencies and parallel workstreams
17. Acceptance criteria and test strategy
18. Operating cost estimates (verified prices with source and date; unknowns marked)
19. Third-party dependencies and licence register
20. Risks and phased roadmap; a section stating what the document does NOT claim

## Writing rules

- Each section opens with its status, then its evidence. Plans go under a Planned label.
- Put the decisions the owner must make in one list at the end, numbered.
- Keep the document as a draft PR for review. Do not merge a blueprint without approval.
- Separate the blueprint PR from any hygiene or code PR, so review and rollback stay independent.
