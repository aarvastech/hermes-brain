# Upgrading an Expo app across an SDK major

Use when the phone's Expo Go is on a newer SDK than the project, or when `expo install` moves a project to a new major.

## Order of operations
1. Read the current and target versions: `node -p "require('expo/package.json').version"` and `npm view expo@<N> version`.
2. Upgrade the core package with the official tool, not a hand-picked list: `npx expo install expo@~<N>`, then `npx expo install --fix`, then `npx expo install --check` (must say dependencies are up to date).
3. Run the type check. A new TypeScript major may stop loading `@types/*` automatically. Fix with explicit `types` in `tsconfig.json` (for Jest: `"types": ["jest"]`).
4. Check any generator or tool pinned to an older TypeScript. If a dev-only package conflicts, use an npm `overrides` entry that points it at the project's own TypeScript, then verify its output is byte-identical against the committed artifact. Record the override so it can be removed later.
5. Pin `react-test-renderer` to the exact installed `react` version. The renderer refuses to run on a mismatch, and Expo's list may not include it.
6. If `expo install` leaves duplicate or misplaced native modules (for example `expo-modules-core` not found by jest-expo), do a clean reinstall: move `node_modules` and the lockfile to a backup directory (never delete), then `npm install`. Do not try `npm dedupe` first; it often cannot move the package.
7. Run the full verification and paste the output of each command: type check, unit tests, `expo-doctor`, and `expo export` for both platforms.

## Test timeouts after an upgrade
- A cold Jest cache (first run, or a fresh CI machine) compiles the much larger new React Native runtime. Rendering tests can exceed the default timeout. Warm runs pass. Either raise `testTimeout` for the suite or keep a Jest cache in CI.
- A matcher that prints the whole component tree on every failed `waitFor` (for example `toBeNull()` on a rendered query result under a newer React) can add seconds per retry and make a test look like a hang. Prefer `expect(...).not.toBeOnTheScreen()` from `@testing-library/react-native` for absence checks. It asserts the same thing with a readable failure.

## Verification that counts
- `expo install --check` clean, `expo-doctor` all checks passed, and `expo export --platform ios --platform android` produces both bundles.
- Run the test suite at least three times in a row. A single green run can hide a timing flake.
- After the upgrade, restart the dev server. An old Metro process keeps serving the previous SDK's bundle.
