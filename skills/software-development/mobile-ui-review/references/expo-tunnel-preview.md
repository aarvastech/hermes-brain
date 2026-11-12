# Expo tunnel preview: recovery recipe

Use when the owner reports a 502 Bad Gateway or "No server is connected" in Expo Go, or when a previously shared tunnel link stops answering.

## Steps

1. Check whether the dev server process is alive and whether the tunnel answers. Use the bundle URL that the current log reports, not an old one:
   - `curl -s -o /dev/null -m 400 -w "%{http_code}" "https://<host>/index.bundle?platform=android&dev=true&hot=false"`
   - 200 means the tunnel is up. 502 means the tunnel died even if the process is still running.
2. Restart with a fresh tunnel, from the app directory. Run it in the background and keep the log:
   - `npx expo start --tunnel --port <port> > <log> 2>&1`
   - Wait about 90 seconds, then read the new host from the log: `grep -oE "[a-z0-9-]+\.[a-z0-9.-]*on\.expo\.app" <log> | head -1`.
3. Check the new host with the bundle curl above before giving the owner a link. Tunnel hosts change on every restart, so the old link will not work.
4. Give the owner the `exp://<host>` link. Do not give a link you have not checked.

## Pitfalls

- A 502 means the dev server or its tunnel stopped. The cause of an earlier stop was not confirmed, so read the dev server log for the exit before naming a cause. Restart with the steps above, and tell the owner the link can stop again.
- Stop the old server with an exact PID or the exact command line. A broad `pkill -f` pattern can match your own shell and kill the gateway (exit -15).
- The host's port can be held by an earlier process. If a restart fails with `address already in use`, find that PID before starting another server.
- A `200` on the bundle proves the build compiled. It does not prove the owner's phone loads it, so ask the owner to confirm on the device.