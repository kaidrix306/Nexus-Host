#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")
nx_banner "TOOLBOX > LOCALTONET"

# --- COLORS ---
RED="${NX_R}"
GREEN="${NX_G}"
YELLOW="${NX_Y}"
BLUE="${NX_B}"
MAGENTA="${NX_M}"
CYAN="${NX_C}"
BOLD="${NX_W}"
NC="${NX_N}"

# --- HEADER ---
clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${BOLD}${MAGENTA}        LOCALTONET CONTROL PANEL ${NC}"
echo -e "${CYAN}==================================================${NC}"

# --- MENU ---
echo -e "${YELLOW}Select an option:${NC}"
echo -e "${GREEN}1) Install Localtonet${NC}"
echo -e "${RED}2) Uninstall Localtonet${NC}"
echo -e "${BLUE}3) Run Localtonet${NC}"
echo -e "${CYAN}4) Exit${NC}"
echo
read -p "Enter choice [1-4]: " choice

case $choice in

1)
    echo -e "${BLUE}[*] Installing Localtonet...${NC}"
    curl -fsSL https://localtonet.com/install.sh | sh
    echo -e "${GREEN}[+] Installation Complete!${NC}"
    ;;

2)
    echo -e "${RED}[*] Uninstalling Localtonet...${NC}"
    rm -rf ~/.localtonet
    rm -f /usr/local/bin/localtonet
    echo -e "${GREEN}[+] Uninstalled Successfully!${NC}"
    ;;

3)
    # Check install
    if ! command -v localtonet &> /dev/null; then
        echo -e "${YELLOW}[!] Localtonet not found. Install first.${NC}"
        exit 1
    fi

    echo -e "${YELLOW} Enter your Auth-Token:${NC}"
    read -p "Token > " USER_TOKEN

    if [ -z "$USER_TOKEN" ]; then
        echo -e "${RED}x Token missing!${NC}"
        exit 1
    fi

    echo -e "${BLUE}[*] Setting Token...${NC}"
    localtonet authtoken "$USER_TOKEN"

    read -p "Enter Port (default 8080): " PORT
    PORT=${PORT:-8080}

    echo -e "${MAGENTA} Starting tunnel on port ${PORT}...${NC}"
    localtonet tcp --port $PORT
    ;;

4)
    echo -e "${CYAN}Bye bro ${NC}"
    exit 0
    ;;

*)
    echo -e "${RED}Invalid option!${NC}"
    ;;

esac
