---
name: expo-go-phone-testing-over-tailscale
description: "Use when testing Expo Go over Tailscale, private only."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [expo, expo-go, tailscale, phone-testing, local-dev]
---

# Expo Go on a phone over Tailscale

## When to use
A phone must load an Expo dev-server bundle from this host, and the host must not be reachable from the public internet. For hosted or store builds, use EAS instead.

## Procedure
0. Check the SDK match first. Expo Go on iOS is only the current SDK, and an older one cannot be
   installed. Read the project's SDK with `node -p "require('expo/package.json').version"` in the app
   directory. Ask the user to read the SDK from the phone's Expo Go error screen, if one shows. If the
   majors differ, stop. The fix is to upgrade the project to the phone's SDK, or to use an EAS
   development build. An upgrade is a change to dependencies and code, so it needs a ticket and
   the user's OK when it is more than about 30 minutes of work. Do not start Metro against a
   mismatched project and try to work around it.
1. Check that both devices show as online in `tailscale status`. Use the host's 100.x address. Confirm reachability with `tailscale ping -c 2 <phone-ip>`. A relayed (DERP) path is acceptable for a smoke test.
2. Start Metro on loopback only, signed in to Expo (step 2a), with no `--offline` and no `CI=1`, from the app directory: `NODE_OPTIONS="--require <scratch>/loopback-listen-shim.js" EXPO_PACKAGER_PROXY_URL=http://<tailscale-ip>:8081 EXPO_PUBLIC_<API>_URL=http://<tailscale-ip>:<api-port> npx expo start --port 8082`. Run it under `script -q -f -c "..." <logfile>` so Expo gets a pseudo-TTY. Start it as background=true, not with nohup.
2a. **Sign in to Expo before starting Metro.** SDK 58 needs a signed manifest, and `--offline` cannot sign one. Follow `references/headless-expo-login.md`. The user completes the browser step with their own account.
3. Forward the tailnet address to loopback: `socat TCP-LISTEN:8081,bind=<tailscale-ip>,fork,reuseaddr TCP:127.0.0.1:8082`.
4. Verify with `ss -ltn` that the API and the forwarder listen only on the tailscale address, and that Metro listens only on 127.0.0.1. Verify with curl that the public address refuses those ports.
5. Verify the manifest over the tailnet with `Accept: multipart/mixed,application/expo+json,application/json`, `expo-platform: ios`, and `Expo-Accept-Signature: true`. Expect HTTP 200. A 200 does not prove the manifest is signed, so also check the Metro log for `unable to sign manifest`. Then fetch the bundle URL from the manifest. The first build takes about 30s; a warm build about 5s. Warm it before the phone asks: fetch the
   bundle URL from the manifest with curl. Otherwise the phone shows "The request timed out" while
   the host is still building.
6. On the phone, open `exp://<tailscale-ip>:8081` from Notes. Expo Go's own server list does not discover tailnet addresses.

## Tunnel mode (public tunnel, not Tailscale)
- Use `expo start --tunnel --port <port>` only when the phone is off the tailnet. Start it with `background=true` and notify on completion, not with `nohup` inside a foreground call. A process started as a child of a finished shell session dies with that session.
- A tunnel address changes on every start. Read it from the log, check `curl` on its `index.bundle?platform=android&dev=true&hot=false` returns 200, and quote that exact address to the owner.
- A 502 "No server is connected" on the phone means the tunnel is up but the dev server behind it is gone. Restart the server, then re-check the bundle.
- Restart by stopping the process group and confirming the port is free (`ss -ltnp`), not by killing only the parent.
- Re-check the bundle URL immediately before sending an address to the owner. An earlier 200 does not cover a tunnel that dropped since.
- Full recovery steps are in the mobile-ui-review skill (its tunnel reference). Load it with skill_view(name='mobile-ui-review').

## SDK upgrades
If the SDK must change to match the phone, follow `references/sdk-major-upgrade.md`. Restart Metro after the upgrade; the old process keeps serving the previous SDK.

## Pitfalls
- After the first successful load, Expo Go shows a "Development mode" notice. It is normal. Dismiss it; it is not an error.
- Expo's CLI calls `httpServer.listen(port, undefined)`, which binds all interfaces, and `--localhost`/`--host` do not change that. The loopback shim pins that one call to 127.0.0.1. Keep the shim in the scratch dir, not the repo.
- `CI=1` or stdin from `/dev/null` makes Expo non-interactive. The phone then sees HTTP 500 "Input is required, but 'npx expo' is in non-interactive mode".
- `--offline` does not work on SDK 58. Metro logs "Offline and no cached development certificate found, unable to sign manifest", and the phone shows "You need to be signed in to Expo Go". Use a signed-in Expo session. Without `--offline`, Expo asks "Log in / Proceed anonymously" on the server terminal, and the phone sees "The request timed out" until the prompt is answered. Choosing an account is the user's decision.
- `npx expo login` needs a terminal (run it under `script -q -f -c "npx expo login" <log>`). Set `BROWSER=none` so the CLI does not call `xdg-open`, which is missing on headless hosts and crashes it. Then ask the user to open the printed link through an SSH tunnel to that link's callback port (`ssh -L <port>:localhost:<port> <host>`). The port changes on each run, so use the one in the current link. Steps: `references/headless-expo-login.md`. Never take credentials or tokens in chat.
- Phone error "There was a problem running the requested project": check the Metro log first.
- Never bind the API or Metro to the public interface. Dev-auth bypass accepts a fixed OTP, so the port must stay private.
