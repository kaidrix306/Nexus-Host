#!/usr/bin/env bash
# NexusCloud Hub - master menu
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")
REPO_RAW="https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master"
ROOT_DIR="$(cd "$_nx_d/.." 2>/dev/null && pwd)"

launch() {   # launch "path/inside/repo"  -> local copy if present, else download
    if [ -f "$ROOT_DIR/$1" ]; then bash "$ROOT_DIR/$1"
    else bash <(curl -fsSL "${REPO_RAW}/${1// /%20}"); fi
}

draw_hub() {
    local up ram disk
    up=$(uptime -p 2>/dev/null | sed 's/up //'); ram=$(free -m | awk '/Mem:/ {printf "%d / %d MB",$3,$2}')
    disk=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
    nx_banner "HUB - MASTER CONTROL"
    nx_row "Host" "$(hostname)"; nx_row "Uptime" "$up"; nx_row "RAM" "$ram"; nx_row "Disk" "$disk"
    nx_hline; echo
    nx_menu_item 1 "Install Panel + Wings (quick installer)"
    nx_menu_item 2 "Panels (Pterodactyl, Jexactyl, Convoy, ...)"
    nx_menu_item 3 "Wings manager"
    nx_menu_item 4 "Toolbox (tunnels, root, system info)"
    nx_menu_item 5 "Themes & Extensions (Blueprint)"
    nx_menu_item 6 "VM manager"
    nx_menu_item 7 "Extras (Docker, Cockpit, CasaOS, ...)"
    nx_menu_item 0 "Exit"
    echo; nx_hline
}

while true; do
    draw_hub
    printf '  %s>%s %sSelect%s: ' "$NX_M" "$NX_N" "$NX_W" "$NX_N"; read -r opt
    case "$opt" in
        1) launch "nexus.sh" ;;
        2) launch "panel/1.sh" ;;
        3) launch "wings/run.sh" ;;
        4) launch "toolbox/run.sh" ;;
        5) launch "thame/run.sh" ;;
        6) launch "setup vm/menu.sh" ;;
        7) launch "Extras/run.sh" ;;
        0|exit|quit) echo "  ${NX_C}Bye from NexusCloud!${NX_N}"; exit 0 ;;
        *) nx_warn "Invalid option"; sleep 1 ;;
    esac
done
