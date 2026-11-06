---
name: local-service-stack
description: "Use when smoke-testing a service with local DB and cache."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [local-dev, docker, postgres, redis, alembic, smoke-test, security]
    category: software-development
    related_skills: [github, claude-code, systematic-debugging]
---

# Local Service Stack for Smoke Tests

Bring up a service with its database and cache on this machine, run an end-to-end
smoke test against it, and leave it running for a human to inspect. Synthetic data only.

## When to Use
- A repo's API needs Postgres and Redis to run, and you need a real end-to-end check
  beyond unit tests with mocks.
- The user wants to try a service on a device before any hosted deployment.

Not for: hosted environments, production data, or exposing a service to other networks.
Those need explicit approval first.

A phone or other device on the user's own private overlay network (Tailscale) is in scope
for a local test, once the user approves the overlay plan. It is not a hosted deployment, so
it does not need the hosted-deployment approval. See `references/phone-access-over-tailscale.md`.

## Procedure

0. **Public-exposure preflight before proposing any DNS or firewall change.** Follow `references/public-exposure-preflight.md`: resolve the hostname, confirm which host answers, list listeners and firewall policy, and propose exact changes only after that.

1. **Pre-flight.** Check `docker info`. Check which interfaces are routable with
   `ip -4 -o addr show`. Note the repo's tracked env files by name only. Do not read their
   contents and do not reuse their values.
   On a host that already runs another service (including the agent itself), also run `ss -ltn`,
   `docker ps`, `free -h` and `df -h` before proposing a second stack. Give the new stack its own
   compose project, network, volume and service user. Do not read or change the other service's
   config or secrets. The other service's host access is the blast radius for any mistake in the new
   stack.

2. **Secrets go outside the repo.** Create a scratch dir under
   `~/.hermes/cache/scratch/<stack-name>/` with mode 700. Generate each password with
   `python3 -c "import secrets;print(secrets.token_urlsafe(24))"`. Write them to a file with
   mode 600. Never print them and never write them into the repo.

3. **Start the DB and cache, bound to loopback only.** Use `-p 127.0.0.1:<host>:<container>`.
   Pick host ports that are not in use. Use the image the repo's compose file names, and if
   that is a TimescaleDB image, use the TimescaleDB image too. Wait with a readiness loop:
   `pg_isready` inside the container, or `redis-cli ping`. Image pulls can reset mid-transfer;
   retry the pull rather than changing the image.

4. **Run every process from the scratch directory.** Settings libraries that read `.env` from
   the working directory will silently load the repo's tracked env file if you run from the
   repo root. Put the service's config in a `run.env` in the scratch dir, load it with
   `set -a; . ./run.env; set +a`, and set `PYTHONPATH` to the repo.

5. **Migrations use a scratch copy of the Alembic config.** A relative `script_location`
   resolves against the working directory. Copy `alembic.ini` to the scratch dir and rewrite
   `script_location` to an absolute path. Check the exit code of the command itself, not of
   `| tail`. Redirect output to a log file and read the log.

6. **Start the API in the background, bound to the address you intend.** Launch it with
   `terminal(background=true, notify_on_complete=false)` and make the server the last command:
   `exec <server command> > <log> 2>&1`. `exec` keeps the tracked pid on the server itself, so
   stopping it by pattern hits the right process. Use a bracketed pattern such as
   `pkill -f '[u]vicorn <module>'`: a plain pattern also matches the shell running the `pkill`,
   which ends that session and the command with it. Do not use `nohup`, `&` or `setsid` inside the
   background call; the terminal tool rejects them. Servers never exit, so no completion notice is
   wanted. Probe readiness with `curl` in a separate call.

7. **Smoke-test with a table of expected status codes.** Use `templates/api-smoke-test.sh`.
   Include both the happy path and the default-deny cases: unauthenticated 401, another
   user's resource 403, and a request after revoke 403. A green happy path alone proves little
   about access control.

8. **Verify the bindings before any device talks to it.** Run `ss -ltn` and confirm each
   service listens only on the address you meant (loopback, or the overlay address). Then `curl`
   the host's public address on each port and confirm it is refused. Do this after every restart.

9. **Tear down only when asked.** Stop the API process and `docker rm -f` the containers.
   Keep the scratch dir, because it holds the generated credentials.

## Pitfalls

- **Dev-auth bypass must stay on private addresses only: loopback or the approved overlay
  address, never a public one.** A bypass that accepts a fixed code or a `dev-<id>` token logs in
  anyone who can reach the port, so binding it to a public address is an exposure.
- **A public address is not a private network.** On a hosted VM the only routable interface is
  often public. Binding the API there, even briefly, exposes it. For a phone to reach a
  loopback-bound service, use a private overlay network (for example Tailscale) on both
  devices, and only after the user approves that plan. Never use an open port or a public tunnel.
- **Relative paths resolve against the working directory.** Alembic `script_location`, the
  env file, and any fixture path all do this. Run from a directory where only the paths you
  mean are reachable.
- **Exit codes disappear behind a pipe.** Read the command's exit code directly, or
  redirect to a log, before saying a migration or test passed.
- **Dev servers can bind every interface even when a flag says otherwise.** Check with `ss -ltn`
  after start, not the flag name. Some dev servers hard-code `listen(port)` with no host, which
  binds all interfaces. Pin the bind from the scratch dir instead of editing the dependency. The
  recipe is in `references/phone-access-over-tailscale.md`.
- **Keep the packager and the forwarder on different ports.** Some dev servers refuse to start
  when another process already holds their default port, even if that process is only a
  forwarder. Run the server on a free port and point the forwarder at it.
- **Choose hosting only in-country when the user is in India.** Any option that moves data off the
  local machine (a VM, managed database, object store, or a third-party sign-in) must be an India
  region, and a non-India vendor must be called out before use. Patient and personal data stays in
  India, and a development build that calls an overseas service is for testing only, never for real data.
- **Staging a compose stack that has a public reverse proxy.** A bare `docker compose up -d` also starts the proxy, which publishes 80 and 443 and exposes the stack before DNS and firewall approval. Name the internal services explicitly (`up -d <db> <cache> <auth>`), then check the published-port list in `docker ps` before going further.
- **A config file is not live until the running service loads it.** Some services import data files only on first start. Keycloak's `--import-realm` skips an edited realm file when the realm already exists in its database volume, so a restart looks applied but is not. Verify the running service through its API after any change. Checks are in `references/keycloak-realm-checks.md`.
- **Smoke-test data is local only.** Use synthetic identifiers such as `+1555...` numbers and
  placeholder names. Never use real customer or patient data here, even for a quick check.

- **A hostname may already serve a live site on another host.** Resolve the name before proposing a record. Creating or moving it can take a live service offline.
- **Validate compose files with placeholder values in the shell only.** Run `export VAR=placeholder` then `docker compose -p <project> -f <file> config --quiet`. Check that the published-port list shows only the intended public listener. Never write the placeholder into a tracked file.

## Verification
Done means: containers report ready, migrations exit 0, the API answers 401 with no token,
every row of the smoke table matches its expected code, and `ss -ltn` plus the public-address
refusal confirm the bindings. Report the table's actual output. Run the smoke script against the
address a device will use (`BASE=http://<overlay-ip>:<port>/api/v1 bash smoke.sh`), not only
against loopback, because loopback hides binding mistakes.
