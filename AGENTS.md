# domainSSL — agent guide

This repo is a single-shell-script Let's Encrypt certificate grabber using [lego](https://github.com/go-acme/lego) v3.8.0 (bundled Linux amd64 binary). There is no build, test, lint, or package system.

## Key facts

- **Primary artifact:** `domainSSL.sh` — prompts for a domain, downloads lego from CDN, stops nginx, runs the HTTP-01 challenge, restarts nginx, copies certs to `/home/ssl/<domain>/`.
- **Install invocation:** `bash <(curl -s -L git.io/dmSSL)` — the shortlink redirects to `raw.githubusercontent.com/moeik/domainSSL/master/domainSSL.sh`.
- **Platform constraint:** Linux-only, requires `nginx`, `wget`, and port 80 free.
- **Prerequisite:** The domain must already resolve to the server's IP before running.
- **Bundled lego:** `lego/lego_v3.8.0_linux_amd64.tar.gz` is vendored for distribution; the script re-downloads it from jsdelivr CDN at runtime. Update both when bumping.
- **CDN URL in script:** `https://cdn.jsdelivr.net/gh/moeik/domainSSL@master/lego/lego_v3.8.0_linux_amd64.tar.gz` — when updating the lego version or script, update this URL and replace the tarball in `lego/`.
- **Cert output:** `/home/ssl/<domain>/1.pem` (cert) and `/home/ssl/<domain>/1.key` (key).
- **Auto-renewal:** The script has two modes: interactive (`bash <(curl -s -L git.io/dmSSL)`) and non-interactive renewal (`... --renew`). The interactive flow now asks whether to install a daily cron job at 3 AM. The renewal mode enumerates `/home/ssl/*/` directories, runs `lego renew --days 30` for each, and copies refreshed certs. The cron job invokes the master branch raw URL — changes to `domainSSL.sh` are reflected automatically.
