#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")
REPO_RAW="https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master"

# --- CONFIG & SEMA UI COLORS ---
CYAN="${NX_C}"
PURPLE="${NX_M}"
GRAY="${NX_W}"
WHITE="${NX_W}"
GREEN="${NX_G}"
RED="${NX_R}"
GOLD="${NX_Y}"
NC="${NX_N}"

# --- HELPER FUNCTIONS ---
pause() {
    echo -e ""
    echo -ne "  ${GRAY}Press any key to return to grid...${NC}"
    read -n 1 -s -r
}

get_metrics() {
    UPT=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
}

show_header() {
    nx_banner "PANEL > 1"
}

# --- OMNI-GRID MENU ---
panel_menu() {
    while true; do
        show_header
        
        echo -e "  ${GOLD}  AVAILABLE DEPLOYMENTS${NC}"
        echo -e "  ${GRAY}+--------------------------+--------------------------+${NC}"
        echo -e "  ${GRAY}|${NC} ${PURPLE}[1]${NC} Pterodactyl          ${GRAY}|${NC} ${PURPLE}[5]${NC}  Pteroca             ${GRAY}|${NC}"
        echo -e "  ${GRAY}|${NC} ${PURPLE}[2]${NC} WHMCS Bridge         ${GRAY}|${NC} ${PURPLE}[6]${NC}  Paymenter           ${GRAY}|${NC}"
        echo -e "  ${GRAY}|${NC} ${PURPLE}[3]${NC} Jexactyl             ${GRAY}|${NC} ${PURPLE}[7]${NC}  Convoy              ${GRAY}|${NC}"
        echo -e "  ${GRAY}|${NC} ${PURPLE}[4]${NC} Reviactyl            ${GRAY}|${NC} ${PURPLE}[8]${NC}  Mythical Dash       ${GRAY}|${NC}"
        echo -e "  ${GRAY}|${NC}                          ${GRAY}|${NC} ${RED}[0]${NC}  Exit                ${GRAY}|${NC}"
        echo -e "  ${GRAY}+--------------------------+--------------------------+${NC}"
        echo ""
        echo -ne "  ${CYAN}l${NC} ${WHITE}Select Module [0-8]:${NC} "
        read p

        case $p in
            1)  echo -e "  ${CYAN}> Executing Pterodactyl Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/pterodactyl/run.sh")
                pause ;;
            2)  echo -e "  ${CYAN}> Executing WHMCS Bridge Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/whmc/install.sh")
                pause ;;
            3)  echo -e "  ${CYAN}> Executing Jexactyl Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/Jexactyl/install.sh")
                pause ;;
            4)  echo -e "  ${CYAN}> Executing Reviactyl Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/reviactyl/run.sh")
                pause ;;
            5)  echo -e "  ${CYAN}> Executing Pteroca Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/pteroca/install.sh")
                pause ;;
            6)  echo -e "  ${CYAN}> Executing Paymenter Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/paymenter/run.sh")
                pause ;;
            7)  echo -e "  ${CYAN}> Executing Convoy Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/Convoy/install.sh")
                pause ;;
            8)  echo -e "  ${CYAN}> Executing Mythical Dash Routine...${NC}"
                bash <(curl -s "${REPO_RAW}/panel/mythical/run.sh")
                pause ;;
            0)  echo -e "\n  ${RED}Shutting down Uplink. Goodbye!${NC}"
                exit 0 ;;
            *)  echo -e "  ${RED}! Invalid Selection${NC}"
                sleep 1 ;;
        esac
    done
}

# Run the menu
panel_menu
