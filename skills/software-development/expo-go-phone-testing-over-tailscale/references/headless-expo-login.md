# Signing the Expo CLI in on a headless host

Why: on Expo SDK 58 and later, Expo Go needs a signed manifest. `--offline` cannot sign one, so
Metro reports "Offline and no cached development certificate found, unable to sign manifest", and
the phone shows "You need to be signed in to Expo Go and Expo CLI". A signed-in CLI fixes that.
The account belongs to the user. The agent never enters a password or token.

## Steps

1. Start the login under a pseudo-terminal, with the browser disabled, as a background job:
   `export BROWSER=none && exec script -q -f -c "npx expo login" <scratch>/login.log`
   Without a pseudo-terminal the CLI exits with "Input is required ... non-interactive mode".
   Without `BROWSER=none` it crashes on `xdg-open` when the host has no browser.
2. Read the log until it prints the login link. Note the callback port from the link's
   `redirect_uri=http://localhost:<port>/auth/callback`. The port is different on every run.
3. Ask the user to do two things on their own computer: open a terminal and run
   `ssh -L <port>:localhost:<port> <user>@<host>`, and leave it open. Then open the printed link
   in that computer's browser and sign in. The callback reaches the host through the tunnel.
4. Wait for the log to show `Logged in`. The script then ends with `COMMAND_EXIT_CODE="0"`.
   Do not expect the callback port in `ss -ltn` while the CLI waits. It may not listen until the
   browser flow begins, so its absence is not a failure.
5. Restart Metro without `--offline` (see the main procedure). Then check the Metro log for
   `unable to sign manifest` and expect no matches.

## If the login does not complete

- A failed run leaves the CLI exited. Start it again to get a new link and port.
- If the tunnel route fails, ask the user which fallback they want. Expo's "Proceed anonymously"
  option needs no account, but it is the user's decision, and it must be checked on the phone.
