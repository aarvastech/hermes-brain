---
name: healthcare-domain
description: Use when handling clinical, patient or lab workflows.
---

# Healthcare domain

## When to Use

Use this for patient records, clinical workflows, emergency response, lab orders and results, hospital admission and discharge, prescriptions, telemedicine, or any feature where a wrong state could harm a person. This is orientation for product and engineering decisions. It is not medical advice, and clinical content needs a qualified clinician to approve it.

## Core concepts to model correctly

- **Patient identity:** one person, one identity. Family members, caregivers and doctors are relationships with a scope and a time window, not copies of the record.
- **Encounter:** a visit, admission, home visit or teleconsult. Has a start, status changes and an end.
- **Observation:** a vital sign or measurement with value, unit, time, device or source, and who recorded it. A sensor reading is an observation with source "device".
- **Order and result:** a lab or imaging order has a status (ordered, collected, received, resulted, validated, released). A result is not released until validated. Critical results need an acknowledgement.
- **Medication:** a prescription is an order from a registered clinician. Administration records who gave what, when. Changes need clinician authorisation.
- **Care plan:** goals, tasks, responsible role, due time, completion. Missed tasks escalate.
- **Consent:** who may see what, for which purpose, until when, and who granted it. Revocation takes effect at read time.

## Safety rules for software

- A notification is not an action. Never imply an ambulance, doctor or pharmacy has been dispatched or has accepted unless a real system confirmed it.
- Clinical thresholds (SpO2, heart rate, blood pressure, fall timing) are configuration. They need a named clinician's sign-off before real use. Until then, flag every event as demo-only.
- Physiological thresholds need a registered physician (MBBS), ideally with geriatrics, emergency or critical-care experience. A dentist or other non-physician qualification does not qualify. Record the approver in the decision log with the sign-off date. For the role's duties, qualifications, independence rules and the approval record fields, see references/clinical-approver-role.md.
- AI may draft notes, summarise history, rephrase approved wording and suggest checks. It must not diagnose, prescribe, change a dose or schedule, or set or change an emergency severity. A clinician approves every draft before it enters the record.
- AI rephrasing of an approved template must be validated mechanically: every number, time, dose and medication name from the template must appear unchanged in the output, and no sentence may add a medical instruction. On failure, return the original template and record the fallback.
- Every AI output is labelled AI-generated and stored with its model, version, prompt-template version and time. Keep the raw data it summarises visible beside it.
- Show time and source for every clinical value. Stale data must look stale.
- Missing data is not normal data. Show "not recorded" rather than zero.
- Alarms need an acknowledgement, an owner, and escalation when unacknowledged.
- Units matter. Store the unit with the value. Reject values out of plausible range.
- Duplicate detection matters for patients, orders and results.

## Indian context

- **ABHA** is the national health ID under ABDM. Linking requires the patient's consent and an approved integration. Do not generate or store ABHA numbers as if they were real until integration is approved.
- **DigiLocker** holds official documents. Pulling a record needs the owner's consent through the DigiLocker partner flow.
- **Telemedicine** is governed by NMC telemedicine guidelines. A registered practitioner must consult; the platform does not replace the consult.
- **Prescriptions** require a registered medical practitioner's identity and registration number. Demo prescriptions must be marked not valid.
- **Pharmacy** dispensing of scheduled drugs requires a valid prescription and a licensed pharmacy.
- **Emergency numbers:** 112 is the national emergency number. 108 is the ambulance service in most states. 102 is patient transport. Check the state or city before showing a number.
- **Clinical standards:** NABH accreditation is a common hospital expectation. Record which standard a feature supports, and do not claim certification.
- **Interoperability:** HL7 FHIR is the standard used by ABDM and many vendors. Map internal models to FHIR resources for exchange.

## Questions to ask before building a clinical feature

- Who acts on this information, and within what time?
- What happens if they do not?
- What is the minimum data they need?
- Who must approve the logic?
- What is the audit record a regulator or a court would want?

## Output format

- Clinical concept and who uses it
- Data model implications
- Safety rules that apply
- Approvals needed and by whom
- What is simulated or demo-only
