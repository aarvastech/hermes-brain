#!/usr/bin/env python3
"""List API paths the app calls that the platform does not serve.

usage: check_api_routes.py <endpoints-file> <openapi-json-file-or-url> [--prefix /app]

- Reads string and template paths that start with '/' from the endpoints file.
- Replaces ${...} placeholders and {param} segments with a single marker, so
  '/households/${enc(hid)}' matches '/app/households/{hid}' in the spec.
- Prints every app path that the spec does not serve, and exits 1 if any are missing.
- --prefix is added to each app path before comparing. Use --prefix "" when the
  endpoints file already holds full paths.
"""
import json
import re
import sys
import urllib.request


def app_paths(src: str) -> set[str]:
    found = set()
    for m in re.finditer(r"[`\"'](/[^`\"']*)[`\"']", src):
        p = m.group(1)
        if p.startswith("//") or " " in p:
            continue
        p = re.sub(r"\$\{[^}]*\}", "{x}", p)
        p = p.split("?")[0]
        if re.search(r"[a-zA-Z]", p):
            found.add(p)
    return found


def norm(p: str) -> str:
    p = re.sub(r"\{[^}]*\}", "{}", p).rstrip("/")
    return p or "/"


def load_spec(src: str) -> dict:
    if src.startswith("http"):
        with urllib.request.urlopen(src, timeout=30) as r:
            return json.load(r)
    with open(src, encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    args = sys.argv[1:]
    prefix = "/app"
    if "--prefix" in args:
        i = args.index("--prefix")
        prefix = args[i + 1]
        del args[i:i + 2]
    if len(args) != 2:
        print(__doc__)
        return 2
    with open(args[0], encoding="utf-8") as f:
        src = f.read()
    served = {norm(p) for p in load_spec(args[1]).get("paths", {})}
    calls = sorted(app_paths(src))
    missing = [prefix + p for p in calls if norm(prefix + p) not in served]
    print(f"app paths: {len(calls)}; not served by the platform: {len(missing)}")
    for m in missing:
        print("  MISSING", m)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
