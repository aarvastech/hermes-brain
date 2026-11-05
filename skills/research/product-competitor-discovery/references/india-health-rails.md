# India health and healthcare rails

For the Indian health product category. Status is the position as last checked. Re-check before
any claim, because programmes and sandbox terms change.

| Rail | What it is | Access route | Status (checked 2026-11-05) |
|---|---|---|---|
| ABDM / ABHA | Health ID and consent-based record exchange | HIU and HIP registration, then sandbox | Not approved for our product. Use a simulated adapter until sandbox access is granted. |
| DigiLocker | Government document locker, with an upload API (JPG, PNG, PDF, 10 MB) | Requester onboarding through the partner portal | Application pending, owned by the founder. Use a simulated adapter until approved. |
| UHI (Unified Health Interface) | Open protocols for discovery, booking and lab or ambulance services | Public sandbox sign-up page | Sign-up not yet done. |
| National emergency 112 | Single emergency response number | Public number | Verified number. Shown in the app for every city. |
| Ambulance 108 | Emergency ambulance for critical care, trauma and accidents; supported in 35 states and UTs | Public number; the state service dispatches | Verified as the national service number. Confirm the number for each city from the state source before showing it. Karnataka not yet confirmed. |
| Patient transport 102 | Basic transport, mainly for pregnant women and children | Public number | Verified. Separate from 108. |
| UPI payments | Payment rail | Gateway partner with KYC | Not started. Keep payments simulated until then. |
| DLT (SMS and WhatsApp) | Mandatory registration for sending SMS or templated messages | Telecom DLT registration, plus WhatsApp business approval | Not started. Keep notifications in-app until then. |
| Pharmacy delivery (Apollo, Amazon, Blinkit) | Medicine ordering, with prescription upload | No public order API found for third parties | Partner pending. Prescription orders need a licensed pharmacy and a valid prescription from a registered practitioner. |

Rules that follow from this table:
- A simulated adapter must say so in every response.
- Never display a government service as connected unless the access route above is complete.
- An emergency number in an app is a call link, not a dispatch.
