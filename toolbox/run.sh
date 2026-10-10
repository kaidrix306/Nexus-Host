#!/usr/bin/env bash
# NexusCloud Toolbox - tunnels, web terminal, system tools
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master}"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "$REPO_RAW/lib/ui.sh" 2>/dev/null) 2>/dev/null
if ! type nx_banner >/dev/null 2>&1; then   # offline fallback so the menu ALWAYS renders
    NX_R=$'\e[1;91m'; NX_G=$'\e[1;92m'; NX_Y=$'\e[1;93m'; NX_B=$'\e[1;94m'
    NX_M=$'\e[1;95m'; NX_C=$'\e[1;96m'; NX_W=$'\e[1;97m'; NX_N=$'\e[0m'
    nx_banner()    { clear 2>/dev/null; echo "${NX_C}=== NEXUSCLOUD :: $1 ===${NX_N}"; }
    nx_row()       { printf '  %s%-10s%s: %s\n' "$NX_Y" "$1" "$NX_N" "$2"; }
    nx_hline()     { echo "${NX_C}+-------------------------------------------------------+${NX_N}"; }
    nx_menu_item() { printf '   %s%s%s) %s%s%s\n' "$NX_G" "$1" "$NX_N" "$NX_W" "$2" "$NX_N"; }
    nx_warn()      { echo "  ${NX_Y}[WARN]${NX_N} $*"; }
fi

pause() { echo; read -r -n 1 -s -p "  Press any key to continue..." _ || true; echo; }

# fetch_run "toolbox/cloudflare.sh"  -> local copy if present, else download from the repo
fetch_run() {
    local rel="$1" tmp url
    if [ -f "$_nx_d/../$rel" ]; then bash "$_nx_d/../$rel"; return; fi
    url="${REPO_RAW}/${rel// /%20}"; tmp="$(mktemp)"
    if curl -fsSL "$url" -o "$tmp"; then bash "$tmp"; else nx_warn "Could not download: $rel"; echo "   $url"; fi
    rm -f "$tmp"
}

draw_header() {
    local ram load ip
    ram=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    ip=$(curl -s --max-time 3 ifconfig.me 2>/dev/null)
    nx_banner "TOOLBOX"
    nx_row "User" "$(whoami)@$(hostname)"; nx_row "RAM" "$ram"; nx_row "Load" "$load"; nx_row "IP" "${ip:-unavailable}"
    nx_hline; echo
}

tools_menu() {
    local t
    while true; do
        draw_header
        echo "  ${NX_B}[ ACCESS & NETWORK ]${NX_N}"
        nx_menu_item 1 "Root Access        - enable root/sudo"
        nx_menu_item 2 "Tailscale          - mesh VPN"
        nx_menu_item 3 "ZeroTier           - virtual LAN"
        nx_menu_item 4 "Cloudflare Tunnel  - tunnel & DNS"
        echo; echo "  ${NX_Y}[ SYSTEM ]${NX_N}"
        nx_menu_item 5 "System Info        - specs & status"
        nx_menu_item 6 "Port Forward       - localtonet"
        nx_menu_item 7 "Web Terminal       - shell in your browser"
        nx_menu_item 8 "SSL Setup          - panel certificates"
        nx_menu_item 9 "RDP Installer      - not bundled yet"
        echo; nx_menu_item 0 "Back / Exit"
        echo; nx_hline
        printf '  %s>%s %sSelect tool [0-9]%s: ' "$NX_M" "$NX_N" "$NX_W" "$NX_N"
        read -r t || t=0
        case "$t" in
            1) fetch_run "toolbox/root.sh"; pause ;;
            2) fetch_run "toolbox/tailscale.sh"; pause ;;
            3) fetch_run "toolbox/zerotier.sh"; pause ;;
            4) fetch_run "toolbox/cloudflare.sh"; pause ;;
            5) fetch_run "toolbox/info.sh"; pause ;;
            6) fetch_run "toolbox/localtonet.sh"; pause ;;
            7) fetch_run "toolbox/terminal.sh"; pause ;;
            8) fetch_run "panel/pterodactyl/ssl.sh"; pause ;;
            9) nx_warn "RDP installer is not included in this repo yet."; pause ;;
            0|q|exit) exit 0 ;;
            *) nx_warn "Invalid option"; sleep 1 ;;
        esac
    done
}
tools_menu
