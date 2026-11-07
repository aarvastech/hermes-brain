# Isolated stack hosting: public switch, rollback and checks

Use this when deploying a service stack to a host that also runs other services, or when a public DNS record will switch to the new host.

## Before any change to DNS or firewall

1. Inspect existing DNS records for the name and its neighbours. A name may already point to a live service on another host. Confirm the current IP with the public resolver, not the local one.
2. Confirm the host's public IP and the ports that are already listening: `ss -ltnp`. Check that the ports you need (80, 443) are free and that no existing proxy owns them.
3. Check the firewall with `ufw status verbose` and the iptables INPUT chain. Note any tailnet chains so they are not disturbed.
4. Write the exact DNS change and firewall change as a proposal. Do not apply them until the owner says yes.

## Shape of the stack

- One compose project with its own name. Only the reverse proxy publishes ports. Application, database, cache and identity services sit on internal networks with no published ports.
- Admin consoles are not routed by the proxy. Reach them over the tailnet or loopback.
- Separate service user, named volumes per data store, and secrets from a mode-600 env file outside the repo.
- Bind any test or admin port to loopback. Verify with `ss -ltn` after start.

## Starting a subset safely

- Start the identity and database services alone first, check them, and only then start the proxy. Starting the proxy early can publish ports before the firewall is ready.
- Check discovery and key endpoints with the public Host header on the internal address before any DNS change.

## Switching DNS with a rollback

- Keep the old host serving until the new one passes its checks.
- Lower the record TTL before the switch, and note the old value.
- Switch the record, then confirm resolution from a public resolver and a TLS handshake.
- Rollback is the old record value. Write it down before the switch.

## Backups and restore

- Run a backup job on a schedule and keep a copy outside the data volume.
- A backup counts only after a restore test into a scratch database, with row counts compared. Record the result.

## Checks that must pass before go-live

- Only ports 80 and 443 are reachable from outside. Test from outside the host, not from the host itself.
- Identity discovery and key endpoints respond over HTTPS on the public name.
- The admin console returns not found on the public name.
- Backup restore test passed and recorded.
- A tagged previous image exists for rollback.
