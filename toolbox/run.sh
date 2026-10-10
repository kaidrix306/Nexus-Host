#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")
REPO_RAW="https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main"

# ==================================================
#  SERVER UTILITY MENU | v3.0 (Dashboard UI)
# ==================================================

# --- COLORS ---
RED="${NX_R}"
GREEN="${NX_G}"
YELLOW="${NX_Y}"
BLUE="${NX_B}"
PURPLE="${NX_M}"
CYAN="${NX_C}"
WHITE="${NX_W}"
GRAY="${NX_W}"
NC="${NX_N}"

# --- HELPER FUNCTIONS ---
pause() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    echo ""
}

# --- HEADER UI ---
draw_header() {
    nx_banner "SERVER CONTROL PANEL"
    USER=$(whoami); HOST=$(hostname)
    RAM=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    CPU=$(uptime | awk -F'load average:' '{ print $2 }')
    IP=$(curl -s ifconfig.me 2>/dev/null)
    nx_row "User" "$USER"; nx_row "Host" "$HOST"; nx_row "RAM" "$RAM"; nx_row "Load" "$CPU"; nx_row "IP" "${IP:-Unavailable}"
    nx_hline; echo ""
}

# ===================== TOOLS MENU =====================
tools_menu() {
    while true; do
        clear

        draw_header

        # -- SECTION 1 --
        echo -e "${BLUE}  [ ACCESS & NETWORK ]${NC}"
        echo -e "  ${GREEN}1)${NC} Root Access         ${GRAY}:: Enable Root/Sudo${NC}"
        echo -e "  ${GREEN}2)${NC} Tailscale           ${GRAY}:: Mesh VPN Setup${NC}"
        echo -e "  ${GREEN}3)${NC} Zerotier            ${GRAY}:: Wifi VPN Setup${NC}"
        echo -e "  ${GREEN}4)${NC} Cloudflare DNS      ${GRAY}:: Tunnel & DNS${NC}"
        echo ""

        # -- SECTION 2 --
        echo -e "${YELLOW}  [ SYSTEM OPERATIONS ]${NC}"
        echo -e "  ${GREEN}5)${NC} System Info         ${GRAY}:: Specs & Status${NC}"
        echo -e "  ${GREEN}6)${NC} Port Forward        ${GRAY}:: TCP/UDP${NC}"
        echo ""

        # -- SECTION 3 --
        echo -e "${PURPLE}  [ GUI & TERMINAL ]${NC}"
        echo -e "  ${GREEN}7)${NC} Web Terminal        ${GRAY}:: Browser Shell${NC}"
        echo -e "  ${GREEN}8)${NC} RDP Installer       ${GRAY}:: Remote Desktop${NC}"
        echo -e "  ${GREEN}9)${NC} SSL Panel           ${GRAY}:: SSL Setup${NC}"
        echo ""

        # -- FOOTER --
        echo -e "${CYAN}------------------------------------------------------------${NC}"
        echo -e "  ${RED}0) <- Back / Exit${NC}"
        echo -e "${CYAN}------------------------------------------------------------${NC}"

        # -- INPUT --
        echo ""
        echo -e "${GRAY}------------------------------------------------------------${NC}"
        echo -ne "${GREEN}> ${CYAN}Select Tool ${GRAY}[0-9]${CYAN} > ${NC}"
        read t

        case $t in
            1)
                echo -e "\n${YELLOW} Running Root Access Script...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/root.sh")
                pause ;;

            2)
                echo -e "\n${YELLOW} Running Tailscale Installer...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/tailscale.sh")
                pause ;;

            3)
                echo -e "\n${YELLOW} Running Zerotier Installer...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/zerotier.sh")
                pause ;;

            4)
                echo -e "\n${YELLOW} Running Cloudflare Script...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/cloudflare.sh")
                pause ;;

            5)
                echo -e "\n${YELLOW} Fetching System Info...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/info.sh")
                pause ;;

            6)
                echo -e "\n${YELLOW} Running Port Forward Tool...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/localtonet.sh")
                pause ;;

            7)
                echo -e "\n${YELLOW} Installing Web Terminal...${NC}"
                bash <(curl -s "${REPO_RAW}/toolbox/terminal.sh")
                pause ;;

            8)
                echo -e "\n${YELLOW} Installing RDP...${NC}"
                echo -e "${RED}RDP installer was not included in this repo.${NC}"
                pause ;;

            9)
                echo -e "\n${YELLOW} Installing SSL Panel...${NC}"
                echo -e "${YELLOW}Use${NC} ${WHITE}bash nexus.sh panel${NC} ${YELLOW}for SSL setup instead.${NC}"
                pause ;;

            0)
                clear
                echo -e "${GREEN}Goodbye ${NC}"
                exit ;;

            *)
                echo -e "${RED}Invalid Option${NC}"
                sleep 1 ;;
        esac
    done
}

# --- RUN ---
tools_menu
