# NexusCloud

One-command Pterodactyl Panel + Wings installer, plus themes, extensions, SSL tools and more.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/nexus.sh)
```

`bash nexus.sh panel | wings | both | link | status`  -  option 6 opens the full hub menu.

## Layout
- `nexus.sh` main installer (Panel, Wings, link node, status)
- `menu/` hub menu, `panel/` other panels (Jexactyl, Convoy, Paymenter, Reviactyl...)
- `wings/`, `thame/` (Blueprint themes/extensions), `Extras/`, `setup vm/`
- `publish.sh` replaces kaidrix306 and pushes with gh

Ubuntu 22.04+/Debian 11+, root, 2GB RAM, domain pointed at the server, ports 80/443.
License: CC0-1.0

## Shared UI
Every script sources `lib/ui.sh` for the bright-colour palette (falls back to
fetching it from your repo if run standalone via `curl | bash`). Colours are
aliased per-script to the same eight bright tones nexus.sh uses — no dim or
grey anywhere in the repo.

## Removed for safety
`menu/run.sh` from the original repo was a disguised backdoor: it wrote fake
credentials to `~/.netrc` and silently downloaded + executed a remote payload
from the original author's domain. It has been deleted, not adapted. A few
other menu entries pointed at *other* un-shared repos by the original author
(zerotier/tailscale/rdp helpers, an alternate wings manager, a VPS panel
clone) — these now either point at the matching script that's actually
included in this repo, or show a "not included" message instead of silently
failing or fetching strangers' code.
