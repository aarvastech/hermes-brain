---
name: pilot-hardware-sourcing
description: Use when sourcing pilot hardware; quotes only, no buying.
---

# Pilot hardware sourcing (research and quotes only)

Use this when a pilot needs devices (hubs, sensors, cameras, wearables). The agent researches, compares and drafts quote requests. The owner buys. Nothing here authorises a purchase, a vendor account, or a payment method.

## Hard rules

- Never place an order, add a payment method, or create a vendor account. The owner does all three, because the owner funds the spend.
- Never send a quote request to a vendor without the owner's explicit OK. Draft it, show it, wait.
- Subscriptions and monthly service fees need the owner's approval, separately from the device price.

## Procedure

1. Write the device list first: device type, count per home, protocol (Zigbee, Bluetooth, RTSP over PoE or Wi-Fi), and what each feeds in the platform. Take the device list from the platform's hardware spec in its repo (for example docs/hub-hardware.md) and the product document, not from memory, and cite the section used. Confirm the hub's role before shopping, since a bridge and a coordinator are different products.
2. Search for candidates with `web_search`, one query per device type, adding the city or the "India" term.
3. Read each candidate page with `web_extract`. Record the price the page shows, the page URL, and the date checked. A price that does not come from the page is not a price. Pages that return a 404 or no price are listed as "price not verified".
4. Check the certification the device needs before it touches a person. Medical readings (pulse oximeter, heart rate, fall detection) need a registration check (CDSCO for India) on the manufacturer's own page, not only a shop listing. Mark "CE marked" as a claim from the seller, not a registration.
5. Check the protocol match. For example, a Zigbee bridge does not replace a Zigbee coordinator. A camera needs its PoE switch or power, which is a separate line item.
6. Build a table per device: candidate, price seen (with URL and date), certification seen, protocol, data export to our platform (open API, webhook or none), recording or dispatch features, open questions. Put unpriced and unverified items in their own list. Do not total a partial list as if it were complete; say which lines are missing.
7. For local shops (for example Electronic City), a web listing is not stock. Say so, and list visit or call as the next step for the owner.
8. Draft each quote request in plain text (device, count, delivery area, required certification, date needed). Show it to the owner. Send only after the owner says yes.

## Pitfalls

- A search snippet can show a price that the live page does not. Confirm on the page.
- Marketplace listings change price and stock daily. Quote the date checked and say the owner must confirm at purchase.
- A fall-detection product sold as a monitoring service carries monthly fees and a third party's data terms. Treat it as a service decision, not a device line.
- Camera and recording products need a privacy check before install. Do not assume any device stores video off the hub; check the spec.
- When the owner asks for "the total", give the sum of verified lines and name the lines still missing.
- A page that fails to extract (crawl or not-found error) gives no price. Record the candidate as "price not verified", and do not fill the price from a search snippet or from a listing you did not open.
- Standalone safety wearables often bundle microphone recording, GPS tracking, or police or third-party dispatch. Treat each as a blocking question for the owner, not a default. Say whether it can be disabled.
- A device that cannot export events to our platform is a separate family app, not a source for the care record. Mark it so in the table.
- When the owner pauses a sourcing thread, stop: no searches, no vendor contact, no quote drafts. Keep the candidate table as it stands, list what is parked and why, and resume only when the owner asks.