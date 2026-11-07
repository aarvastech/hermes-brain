# Clinical safety approver: role, independence and approval record

Use this when a feature needs a named clinician to approve thresholds, escalation timeouts, or clinical alert wording before real use.

## What the role does

- Reviews the thresholds (SpO2, heart rate, fall timing, inactivity triggers) and the escalation timeouts for the intended patient group.
- Approves each value, or returns it with a changed value and a reason.
- Checks alert wording: states the observed event, does not imply an unconfirmed diagnosis, does not recommend treatment, and states the limits of automated monitoring.
- Re-approves whenever a threshold, timeout or alert text changes.
- Does not operate the system, respond to live alerts, make product decisions, or write the code.

## Who qualifies

- Mandatory: MBBS and a valid registration with the NMC or the relevant State Medical Council.
- Preferred: MD or DNB in geriatrics, emergency medicine, general medicine or critical care; experience with elderly and chronic-disease patients; experience with emergency escalation; exposure to remote monitoring or digital health.
- Not the author of the thresholds under review, not a founder or product owner, not on the software development team.
- Declares any commercial, consulting or pilot relationship with facilities that use the platform.

## Approval record (required fields)

- Full legal name and medical qualification.
- NMC or State Medical Council registration number.
- Specialty and relevant clinical experience.
- Date of approval.
- Exact configuration and threshold version reviewed. Without a version, an approval cannot be tied to what runs.
- Signed declaration that the configuration was reviewed.
- Requested modifications and their clinical justification.

## Gating

- Until a named approver signs a version, every event built on those thresholds is flagged demo-only in the data and in every notification.
- An approver's refusal blocks release of that configuration. State in the role description who may override it, and that the override is itself recorded.
- A non-physician qualification (for example BDS) does not satisfy the physiological-threshold requirement. A dental-specific feature can have a dental reviewer.

## Engagement

- Part-time, project-based, with re-review whenever a clinical configuration changes.
- State the consultant's data access: synthetic configuration and examples only, unless a separate agreement covers patient data.
- Say that the approval is advisory governance for the product, not a clinical service to patients. Ask counsel to confirm the wording and who holds professional indemnity.
- Give a fee range in the posting before interviews.
