# domainSSL — agent guide

This repo is a single-shell-script Let's Encrypt certificate grabber using [lego](https://github.com/go-acme/lego) v3.8.0 (bundled Linux amd64 binary). There is no build, test, lint, or package system.

## Key facts

- **Primary artifact:** `domainSSL.sh` — unified CLI with menu and subcommands. No build/test/lint system.
- **Install invocation:** `bash <(curl -s -L https://raw.githubusercontent.com/tealiving/domainSSL/master/domainSSL.sh)` or `bash <(curl -s -L git.io/dmSSL)` (shortlink — update both if repo changes).
- **Platform constraint:** Linux-only, requires `nginx`, `wget`, and port 80 free. Domain must resolve to server IP before running.
- **CLI subcommands:**
  - `domainSSL.sh` → interactive menu (issue, status, cron install/remove, renew)
  - `domainSSL.sh <domain>` → issue cert for domain directly
  - `domainSSL.sh --renew` → renew all managed certs (used by cron)
  - `domainSSL.sh --cron [off]` → install/remove daily cron job
  - `domainSSL.sh --status` → show certificate expiry for all domains
- **Bundled lego:** `lego/lego_v3.8.0_linux_amd64.tar.gz` vendored; script re-downloads from jsdelivr CDN at runtime. Update both when bumping.
- **CDN URL in script (`$LEGO_URL`):** `https://cdn.jsdelivr.net/gh/moeik/domainSSL@master/lego/lego_v3.8.0_linux_amd64.tar.gz`
- **Cert output:** `/home/ssl/<domain>/1.pem` (cert) and `/home/ssl/<domain>/1.key` (key).
- **Lego state path:** `/var/lib/domainssl/lego/` (persistent, not `/tmp`). Both modes use `lego --path="$LEGO_DIR"`.
- **Old-state migration:** If `/tmp/.lego/` exists and `$LEGO_DIR/accounts` doesn't, the script copies the old state on first run — no re-issuance needed.
- **Auto-renewal:** The renewal mode enumerates `/home/ssl/*/` directories, runs `lego renew --days 30` for each, and copies refreshed certs. The cron job invokes the master branch raw URL — changes to `domainSSL.sh` are reflected automatically.
