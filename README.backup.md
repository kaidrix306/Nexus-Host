# ⚡ Nexus Host

<div align="center">

**A unified terminal hub for server installation and management.**

![Bash](https://img.shields.io/badge/Bash-Installer-00E5FF?style=for-the-badge&logo=gnubash&logoColor=black)
![Linux](https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Debian-FF3DCE?style=for-the-badge&logo=linux&logoColor=white)

</div>

Nexus Host brings server installation tools, management utilities, status checks, and extensions into one Bash interface.

## Quick Start

On a compatible Linux server, run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/nexus.sh)
```

Review scripts before running them with elevated privileges. Back up important data before changing your server.

## Menu Options

| Option | Feature |
|---:|---|
| 1 | Install Pterodactyl Panel |
| 2 | Install Wings Node |
| 3 | Install Panel + Wings |
| 4 | Link Wings to Panel |
| 5 | System Status |
| 6 | Open Master Hub |
| 7 | Panel Manager |
| 8 | Wings Manager |
| 9 | Toolbox |
| 10 | Themes & Extensions |
| 11 | VM Manager |
| 12 | Extras |
| 0 | Exit |

Options depend on the scripts available in your checkout.

## Requirements

- Bash
- A compatible Linux server for installation tasks
- Internet access to download dependencies
- Root privileges for system-level changes

## Repository Structure

- `nexus.sh` — main launcher, splash screen, and menu
- `menu/` — menu interface and hub tools
- `panel/` — panel-related scripts
- `wings/` — Wings-related scripts
- `toolbox/` — utility scripts
- `thame/` — themes and extensions
- `setup vm/` — VM management tools
- `Extras/` — additional utilities

## Safety

- Inspect scripts before executing them as root.
- Back up server data before installation or configuration changes.
- Never publish passwords, API keys, or access tokens.

## Credits

Created by **Kaidrix** and the **NexusCloud Team**.
