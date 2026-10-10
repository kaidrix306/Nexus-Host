#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")

# ==================================================
#  TAILSCALE MESH COMMANDER v3.0
# ==================================================

# --- THEME & COLORS ---
# Neon Cyberpunk Palette
RED="${NX_R}"
GREEN="${NX_G}"
YELLOW="${NX_Y}"
BLUE="${NX_B}"
PURPLE="${NX_M}"
CYAN="${NX_C}"
WHITE="${NX_W}"
GRAY="${NX_W}"
NC="${NX_N}"  # No Color

# --- HELPER FUNCTIONS ---

msg_info() { echo -e "  ${BLUE}>${NC}  $1"; }
msg_ok()   { echo -e "  ${GREEN}+${NC}  $1"; }
msg_warn() { echo -e "  ${YELLOW}!${NC}  $1"; }
msg_err()  { echo -e "  ${RED}x${NC}  $1"; }

get_hostname() {
    if command -v hostname &> /dev/null; then hostname
    elif [ -f /etc/hostname ]; then head -n 1 /etc/hostname
    else echo "Unknown-Host"; fi
}

# --- HEADER UI ---

draw_header() {
    local host_name=$(get_hostname)
    local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    
    # Defaults
    local ts_status="${GRAY}NOT INSTALLED${NC}"
    local ts_ip="${GRAY}---${NC}"
    local exit_node="${GRAY}OFF${NC}"
    local health_check="${RED}DISCONNECTED${NC}"

    # Check Installation & Status
    if command -v tailscale &>/dev/null; then
        if systemctl is-active --quiet tailscaled; then
            ts_status="${GREEN}ACTIVE (MESH ONLINE)${NC}"
            
            # Fetch IP
            local ip_fetch=$(tailscale ip -4 2>/dev/null)
            if [[ -n "$ip_fetch" ]]; then
                ts_ip="${CYAN}$ip_fetch${NC}"
                health_check="${GREEN}CONNECTED${NC}"
            else
                ts_ip="${YELLOW}Needs Auth${NC}"
            fi

            # Check Exit Node
            if tailscale status --self | grep -q "exit node"; then
                exit_node="${PURPLE}ACTIVE${NC}"
            fi
        else
            ts_status="${RED}SERVICE STOPPED${NC}"
        fi
    fi

    nx_banner "TAILSCALE MESH COMMANDER"
    echo -e "  Device  : $host_name"
    echo -e "  System  : $os_info"
    echo -e "  Status  : $ts_status"
    echo -e "  IP      : $ts_ip"
    echo -e "  Exit    : $exit_node"
    echo -e "  Health  : $health_check"
    nx_hline; echo ""
}

# --- ACTIONS ---

install_tailscale() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    msg_info "Initializing Setup Sequence..."
    
    # 1. Download
    echo -ne "  ${CYAN}[1/3]${NC} Downloading Core Binaries... "
    if curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1; then
        echo -e "${GREEN}DONE${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        read -p "Press Enter..."
        return
    fi
    
    # 2. Service
    echo -ne "  ${CYAN}[2/3]${NC} Configuring Systemd Service... "
    if sudo systemctl enable --now tailscaled >/dev/null 2>&1; then
        echo -e "${GREEN}DONE${NC}"
    else
        echo -e "${YELLOW}SKIP (Check Logs)${NC}"
    fi

    # 3. Auth
    echo -e "  ${CYAN}[3/3]${NC} Authentication Required"
    echo ""
    echo -e "${YELLOW}  +--------------------------------------------------+${NC}"
    echo -e "${YELLOW}  |  ACTION: Click the link generated below to auth  |${NC}"
    echo -e "${YELLOW}  +--------------------------------------------------+${NC}"
    echo ""
    
     tailscale up
    
    echo ""
    msg_ok "Device successfully joined the Mesh!"
    read -p "  Press Enter to return..."
}

uninstall_tailscale() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    msg_warn "DESTRUCTIVE ACTION: UNINSTALL"
    echo -e "  This will sever the connection to your private network."
    echo ""
    echo -ne "${PURPLE}  > Confirm Removal? (y/N): ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        msg_info "Stopping Services..."
         systemctl stop tailscaled 2>/dev/null
         systemctl disable tailscaled 2>/dev/null
        
        msg_info "Removing Packages (Auto-Detect)..."
        if [ -x "$(command -v apt)" ]; then sudo apt purge tailscale -y -qq >/dev/null 2>&1
        elif [ -x "$(command -v dnf)" ]; then sudo dnf remove tailscale -y -q >/dev/null 2>&1
        elif [ -x "$(command -v apk)" ]; then sudo apk del tailscale >/dev/null 2>&1; fi
        
        msg_info "Wiping Configuration..."
        sudo rm -rf /var/lib/tailscale /etc/tailscale
        
        msg_ok "Tailscale completely removed."
    else
        msg_info "Operation Cancelled."
    fi
    read -p "  Press Enter to continue..."
}

network_map() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    msg_info "Scanning Mesh Network..."
    echo ""
    if command -v tailscale &>/dev/null; then
        # Pretty print status
        tailscale status | awk '{printf "  \033[1;96m%-20s\033[0m %-15s \033[1;92m%-10s\033[0m %s\n", $2, $1, $4, $5}'
    else
        msg_err "Tailscale not installed or not running."
    fi
    echo ""
    read -p "  Press Enter to return..."
}

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "  ${WHITE}CORE OPERATIONS:${NC}"
    echo -e "  ${GREEN}[1]${NC} Install        ${GRAY}(Join Mesh)${NC}"
    echo -e "  ${RED}[2]${NC} Uninstall     ${GRAY}(Leave Mesh)${NC}"
    echo -e ""
    echo -e "  ${WHITE}DIAGNOSTICS:${NC}"
    echo -e "  ${CYAN}[3]${NC} View Network Map        ${GRAY}(List Peers)${NC}"
    echo -e "  ${YELLOW}[4]${NC} Troubleshooting Logs    ${GRAY}(Debug)${NC}"
    echo -e ""
    echo -e "  ${GRAY}[0] Exit Commander${NC}"
    echo ""
    echo -ne "${BLUE}  root@tailscale ~# ${NC}"
    read option
    
    case $option in
        1) install_tailscale ;;
        2) uninstall_tailscale ;;
        3) network_map ;;
        4) echo ""; tailscale netcheck; read -p "Enter..." ;;
        0) clear; exit 0 ;;
        *) msg_err "Invalid Option"; sleep 1 ;;
    esac
done
