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
2. Start Metro on loopback only, with `--offline` and no `CI=1`, from the app directory: `NODE_OPTIONS="--require <scratch>/loopback-listen-shim.js" EXPO_PACKAGER_PROXY_URL=http://<tailscale-ip>:8081 EXPO_PUBLIC_<API>_URL=http://<tailscale-ip>:<api-port> npx expo start --offline --port 8082`. Run it under `script -q -f -c "..." <logfile>` so Expo gets a pseudo-TTY. Start it as background=true, not with nohup.
3. Forward the tailnet address to loopback: `socat TCP-LISTEN:8081,bind=<tailscale-ip>,fork,reuseaddr TCP:127.0.0.1:8082`.
4. Verify with `ss -ltn` that the API and the forwarder listen only on the tailscale address, and that Metro listens only on 127.0.0.1. Verify with curl that the public address refuses those ports.
5. Verify the manifest over the tailnet with `Accept: multipart/mixed,application/expo+json,application/json`, `expo-platform: ios`, and `Expo-Accept-Signature: true`. Expect HTTP 200. Then fetch the bundle URL from the manifest. The first build takes about 30s; a warm build about 5s. Warm it before the phone asks: fetch the
   bundle URL from the manifest with curl. Otherwise the phone shows "The request timed out" while
   the host is still building.
6. On the phone, open `exp://<tailscale-ip>:8081` from Notes. Expo Go's own server list does not discover tailnet addresses.

## Pitfalls
- Expo's CLI calls `httpServer.listen(port, undefined)`, which binds all interfaces, and `--localhost`/`--host` do not change that. The loopback shim pins that one call to 127.0.0.1. Keep the shim in the scratch dir, not the repo.
- `CI=1` or stdin from `/dev/null` makes Expo non-interactive. The phone then sees HTTP 500 "Input is required, but 'npx expo' is in non-interactive mode".
- Without `--offline`, Expo asks "Log in / Proceed anonymously" on the server terminal. The phone then sees "The request timed out". Choosing an account is the user's decision, so use `--offline` instead.
- Phone error "There was a problem running the requested project": check the Metro log first.
- Never bind the API or Metro to the public interface. Dev-auth bypass accepts a fixed OTP, so the port must stay private.
