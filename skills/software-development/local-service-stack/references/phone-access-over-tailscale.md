# Phone access to a local service over Tailscale

Use only after the user approves the overlay plan. Synthetic data only. The device and the host
must be signed into the same tailnet.

## 1. Install Tailscale on the host (Debian/Ubuntu)

Use the signed apt repository, not an unsigned script. Check the release codename first
(`. /etc/os-release; echo $VERSION_CODENAME`).

```bash
sudo -n mkdir -p /usr/share/keyrings
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/<codename>.noarmor.gpg \
  | sudo -n tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/<codename>.tailscale-keyring.list \
  | sudo -n tee /etc/apt/sources.list.d/tailscale.list >/dev/null
sudo -n apt-get update -qq
sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tailscale
sudo -n systemctl enable --now tailscaled
```

## 2. Connect the host (the user must complete the login)

```bash
sudo -n tailscale up --accept-dns=false --hostname=<short-host-name> --timeout=20s
```

`tailscale up` prints a login URL and then times out while it waits. Without `sudo`, the same command fails with `checkprefs access denied`. Run it with `sudo`, or run `sudo tailscale set --operator=$USER` once so later commands work without it. The URL belongs to the
user's account, so the user opens it. Do not complete it on the user's behalf. If the URL expires,
run the command again for a fresh one. Once the user confirms, check with:

```bash
tailscale status            # host and the phone should both be listed
tailscale ip -4             # the host's overlay address, e.g. 100.x.y.z
tailscale ping -c 3 <phone-overlay-ip>
```

`tailscale ping` may report a relayed path (DERP) with no direct connection. That is still a
private path and fine for a smoke test. Do not open ports on the public interface to improve it.

## 3. Bind the services to the overlay address only

- API: `--host <overlay-ip> --port <api-port>`. Check with `ss -ltn`.
- Forwarder for a dev server: `socat TCP-LISTEN:<fwd-port>,bind=<overlay-ip>,fork,reuseaddr TCP:127.0.0.1:<server-port>`
  (install `socat` from apt). Start it with `exec` in a background call.

After each start, confirm with `ss -ltn` that every listener is on the overlay address or on
loopback. Then confirm the public address refuses each port:
`curl -s -m 3 -o /dev/null -w '%{http_code}' http://<public-ip>:<port>/` should print 000.

## 4. Expo / Metro dev server behind the forwarder

The Expo CLI here starts Metro with `httpServer.listen(port, undefined)`, which binds every
interface. The `--localhost` and `--host` flags do not change that. Do not edit `node_modules`.
Load a shim from the scratch directory instead:

```js
// <scratch>/loopback-listen-shim.js  (loaded via NODE_OPTIONS, never written into the repo)
const http = require('http');
const orig = http.Server.prototype.listen;
http.Server.prototype.listen = function (...args) {
  if (typeof args[0] === 'number' && (args[1] === undefined || typeof args[1] === 'function')) {
    args.splice(1, 0, '127.0.0.1');
  }
  return orig.apply(this, args);
};
```

Start Metro on a free port, not the forwarder's port. Run it under a pseudo-terminal, not as a
plain background job:

```bash
cd <app-dir> && export NODE_OPTIONS="--require <scratch>/loopback-listen-shim.js" \
  EXPO_PUBLIC_<APP>_API_URL=http://<overlay-ip>:<api-port> \
  EXPO_PACKAGER_PROXY_URL=http://<overlay-ip>:<fwd-port> && \
  exec script -q -f -c "npx expo start --port <server-port>" <scratch>/metro.log
```

- `EXPO_PACKAGER_PROXY_URL` is the URL written into the manifest, so the phone fetches bundles
  through the forwarder.
- `EXPO_PUBLIC_*` values are read when the config is loaded, so set them before starting Metro.
- Do not set `CI=1`, and do not redirect stdin from `/dev/null`. Either makes Expo non-interactive,
  and then the manifest endpoint returns HTTP 500 to the phone with "Input is required, but 'npx
  expo' is in non-interactive mode". Curl from the host can still return 200 while the phone gets
  the 500, so check the log, not only curl. After any restart run
  `grep -c "non-interactive" <scratch>/metro.log` and expect 0.
- Expo's own "use port N instead?" prompt is the same failure mode. Choose a free port up front.

Verify: `ss -ltn` shows the server on `127.0.0.1` only. Then fetch the manifest through the
overlay address (`curl -H 'expo-platform: ios' -H 'Accept: application/expo+json' http://<overlay-ip>:<fwd-port>/`).
The `launchAsset` URL must use the overlay address, not loopback.

## 5. Phone side (user)

- Install the device's Tailscale app and sign in with the same account. Confirm it is connected.
- Install Expo Go. Expo Go's home screen lists only servers it finds on the local network, so an
  overlay address never appears there. Open the URL instead: in Notes, type
  `exp://<overlay-ip>:<fwd-port>` and tap it. iOS hands the link to Expo Go. Use the manual-URL
  option only if the link does not open Expo Go.
- Warm the bundle from the host before the phone asks for it. A cold first build takes about
  30 seconds, and the phone gives up earlier with "The request timed out". Fetch the bundle URL
  from the manifest once with curl; a warm build takes about 5 seconds.
- Before asking the user to retry, check that the server log has no new errors, and after a
  retry check for the phone's requests (for example `ss -tn` on the forwarder port). A screen
  error on the phone with an empty server log means the phone never reached the server.
- Match the project's SDK to the Expo Go on the phone before starting anything. The App Store
  build is the current SDK only, so a project on an older SDK shows "Project is incompatible with
  this version of Expo Go". See the Expo skill's SDK check.
- If the phone shows "You need to be signed in to Expo Go and Expo CLI", the host served an unsigned manifest. Sign the CLI in on the host first (the Expo skill, step 2a). Do not work around it with `--offline`.
- Use only synthetic test identifiers (for example `+1555...` numbers and a dev code).

## 6. Stop

Stop each process by a bracketed pattern so the `pkill` command line cannot match itself, for example
`pkill -f '[s]ocat TCP-LISTEN:8081'`. A plain `pkill -f 'expo start ...'` matches the shell that
runs it, which kills the session that issued the command. Confirm with `ss -ltn` afterwards. Keep
the scratch dir. Leave Tailscale connected unless the user asks for it to be disconnected.
