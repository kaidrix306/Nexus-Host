#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")
nx_banner "EXTRAS > CASAOS"

# ===================== COLORS =====================
RED="${NX_R}"
C_MAIN="${NX_C}"
C_SEC="${NX_G}"
C_LINE="${NX_W}"
NC="${NX_N}"

# ===================== PAUSE =====================
pause() {
  read -rp "Press Enter to continue..."
}

# ===================== CASAOS MENU =====================
casaos_menu() {
  while true; do
    clear
    echo -e "${C_LINE}-------------- CASAOS MENU --------------${NC}"
    echo -e "${C_MAIN} 1) Install CasaOS"
    echo -e " 2) Uninstall CasaOS"
    echo -e " 3) Exit${NC}"
    echo -e "${C_LINE}----------------------------------------${NC}"
    read -rp "Select > " cs

    case "$cs" in
      1)
        clear
        echo -e "${C_MAIN} Installing CasaOS...${NC}"
        curl -fsSL https://get.casaos.io | bash
        echo
        echo -e "${C_SEC}+ CasaOS Installed Successfully${NC}"
        echo -e "${C_SEC} Access: http://SERVER_IP${NC}"
        pause
        ;;
      2)
        clear
        echo -e "${C_MAIN} Uninstalling CasaOS...${NC}"

        if command -v casaos-uninstall >/dev/null 2>&1; then
          casaos-uninstall
        fi

        systemctl stop casaos.service 2>/dev/null
        systemctl disable casaos.service 2>/dev/null

        rm -rf \
          /casaos \
          /usr/lib/casaos \
          /etc/casaos \
          /var/lib/casaos \
          /usr/bin/casaos \
          /usr/local/bin/casaos

        echo
        echo -e "${C_SEC}+ CasaOS Completely Removed${NC}"
        pause
        ;;
      3)
        clear
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid Option${NC}"
        pause
        ;;
    esac
  done
}

# ===================== START =====================
casaos_menu
