#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")

set -e

echo " Detecting OS..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "x OS detect nahi hua"
    exit 1
fi

echo " OS Detected: $OS"

# Auto run based on OS
if [[ "$OS" == "ubuntu" ]]; then
    echo " Running Ubuntu installer..."
    bash <(curl -s https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/panel/mythical/Ubuntu.sh) 

elif [[ "$OS" == "debian" ]]; then
    echo " Running Debian installer..."
    bash <(curl -s https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/panel/mythical/Debian.sh) 
else
    echo "x Unsupported OS: $OS"
    exit 1
fi

echo "+ Done! System ready."
