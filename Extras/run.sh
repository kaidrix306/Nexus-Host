#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")
nx_banner "EXTRAS > RUN"

# ===================== COLORS =====================
RED="${NX_R}"
GREEN="${NX_G}"
CYAN="${NX_C}"
GRAY="${NX_W}"
NC="${NX_N}"
URL="https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/Extras"
# ===================== PAUSE =====================
pause() {
  read -rp "Press Enter to continue..."
}

# ===================== INFRA MENU =====================
infra_menu() {
  while true; do
    clear
    echo -e "${GRAY}-------------- INFRA MENU --------------${NC}"
    echo -e "${CYAN} 1) Cockpit"
    echo -e " 2) CasaOS"
    echo -e " 3) 1Panel"
    echo -e " 4) LXC/LXD"
    echo -e " 5) Docker"
    echo -e " 6) vpanel"
    echo -e " 7) Back${NC}"
    echo -e "${GRAY}----------------------------------------${NC}"
    read -rp "Select > " im

    case "$im" in
      1)
        clear
        echo -e "${CYAN}Installing KVM + Cockpit...${NC}"
        bash <(curl -fsSL $URL/Cockpit.sh)
        echo -e "${GREEN}Access: https://SERVER_IP:9090${NC}"
        pause
        ;;
      2)
        clear
        echo -e "${CYAN}Installing CasaOS...${NC}"
        bash <(curl -fsSL $URL/casaos.sh)
        pause
        ;;
      3)
        clear
        echo -e "${CYAN}Installing 1Panel...${NC}"
        bash <(curl -fsSL $URL/cpanel.sh)
        pause
        ;;
      4)
        clear
        echo -e "${CYAN}Installing  LXC/LXD...${NC}"
        sudo usermod -aG lxd root
        bash <(curl -fsSL $URL/Cockpit.sh)
        pause
        ;;
      5)
        clear
        echo -e "${CYAN}Installing  docker...${NC}"
        bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/Extras/docker.sh)
        pause
        ;;

      6)
        clear
        echo -e "${CYAN}Installing  docker...${NC}"
        echo -e "${RED}vpanel was not part of this repo - skipping.${NC}"
        pause
        ;;
      7)
        clear
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option!${NC}"
        pause
        ;;
    esac
  done
}

# ===================== START =====================
infra_menu
