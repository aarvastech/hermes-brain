# Public-exposure preflight

Run before proposing any public DNS record, firewall opening or reverse-proxy change on a host that
already runs other services. Read-only. Change nothing until the user approves the proposal.

## 1. Resolve every name the change would touch

```
for h in <apex> <www> <demo> <auth>; do echo "-- $h"; dig +short A $h; dig +short CNAME $h; done
dig +short -x <ip>          # reverse DNS: shows the hosting provider behind an address
```

If a name already resolves to a server that serves a live site, that name is a conflict. Propose a
new subdomain instead, and say why.

## 2. Identify this host's public address and what answers on it

```
curl -4 -s https://ifconfig.me                       # this host's IPv4
curl -sI -m 10 -H "Host: <name>" https://<ip>/ -k    # headers only; shows what answers that IP
```

Check IPv4 and IPv6 separately. A host can have a public IPv6 while its IPv4 belongs to another host.

## 3. Listeners and existing proxies

```
ss -ltnp | grep -E ':(80|443|8080|8443)\b' || echo none
for s in nginx caddy apache2 traefik; do systemctl is-active $s 2>/dev/null | sed "s/^/$s: /"; done
tailscale serve status 2>&1 | head -3               # if Tailscale is installed
```

If a proxy is active, list its virtual hosts and mark each one as untouched. Do not edit a shared proxy
config to add a site unless the user approved that exact file.

## 4. Firewall policy

```
sudo -n ufw status verbose
sudo -n iptables -S INPUT
```

Record the default policy and every allowed port. Note any chain that tailnet tooling adds
(for example `ts-input`), so a rule is not mistaken for a public one.

## 5. What the proposal must contain

- The exact DNS record (type, name, value, TTL) and the rule that makes it unique.
- The exact firewall rules to add, with comments, and the rules that stay closed.
- The services that must not be published, such as the database, cache and admin consoles.
- The rollback: the record to delete, the rules to remove, and the fallback host that keeps serving.
- Each item that needs the user's approval, listed separately.

Keep the private administration path (for example a tailnet) available and do not make it required for
public visitors when the user has asked for public access.

## 6. Validate the compose stack before the proposal

With placeholder values in the shell only (never written to a tracked file):

```
export SUMMIT_PG_PASSWORD=x ...
docker compose -p <project> -f <file> config --quiet && echo OK
docker compose -p <project> -f <file> config | grep -B3 published
```

Only the public listener (typically the reverse proxy on 80 and 443) may publish a port. Databases,
caches and admin consoles publish none.
