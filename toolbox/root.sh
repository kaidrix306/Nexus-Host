#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")

# ==================================================
#  SSH COMMANDER v3.1 | ACCESS CONTROL SYSTEM
# ==================================================

# --- THEME & COLORS ---
RED="${NX_R}"
GREEN="${NX_G}"
YELLOW="${NX_Y}"
BLUE="${NX_B}"
PURPLE="${NX_M}"
CYAN="${NX_C}"
WHITE="${NX_W}"
GRAY="${NX_W}"
NC="${NX_N}"

CONFIG_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.bak"

# --- HELPER FUNCTIONS ---

msg_info() { echo -e "  ${BLUE}>${NC}  $1"; }
msg_ok()   { echo -e "  ${GREEN}+${NC}  $1"; }
msg_warn() { echo -e "  ${YELLOW}!${NC}  $1"; }
msg_err()  { echo -e "  ${RED}x${NC}  $1"; }

get_conf_status() {
    local param=$1
    local default=$2
    local val=$(grep -E "^${param}" "$CONFIG_FILE" | tail -n 1 | awk '{print $2}')
    
    if [[ -z "$val" ]]; then val="$default"; fi
    
    if [[ "$val" == "yes" ]]; then
        echo -e "${GREEN}[ ON ]${NC}"
    else
        echo -e "${RED}[ OFF ]${NC}"
    fi
}

get_ssh_port() {
    local port=$(grep -E "^Port" "$CONFIG_FILE" | head -n 1 | awk '{print $2}')
    if [[ -z "$port" ]]; then echo "22 (Default)"; else echo "$port"; fi
}

# --- HEADER UI ---

draw_header() {
    nx_box "$1"
}

# --- ACTIONS ---

enable_access() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    msg_info "Unlocking Server Access..."
    
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    sed -i '/^PermitRootLogin/d' "$CONFIG_FILE"
    sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
    echo "PermitRootLogin yes" >> "$CONFIG_FILE"
    echo "PasswordAuthentication yes" >> "$CONFIG_FILE"
    
    msg_ok "Config Updated (Root: YES, Pass: YES)"
    
    msg_info "Reloading SSH Daemon..."
    systemctl restart ssh
    
    msg_ok "Service Restarted."
    echo ""
    echo -e "${YELLOW}  IMPORTANT: Ensure a strong Root Password is set!${NC}"
    read -p "  Press Enter to continue..."
}

secure_lockdown() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    msg_warn "LOCKDOWN MODE INITIATED"
    echo -e "  This will ${RED}DISABLE${NC} Root Login & Password Auth."
    echo ""
    echo -ne "${PURPLE}  > Confirm Lockdown? (y/N): ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i '/^PermitRootLogin/d' "$CONFIG_FILE"
        sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
        echo "PermitRootLogin no" >> "$CONFIG_FILE"
        echo "PasswordAuthentication no" >> "$CONFIG_FILE"
        
        systemctl restart ssh
        msg_ok "Server Secured (Key-Only Access)."
    else
        msg_info "Operation Cancelled."
    fi
    read -p "  Press Enter to continue..."
}

#  UPDATED PASSWORD FUNCTION
set_root_pass() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    msg_info "ROOT PASSWORD MANAGEMENT"
    echo ""
    
    echo -e "  ${GREEN}[1]${NC} Quick Set Password ${GRAY}(Hidden Input)${NC}"
    echo -e "  ${BLUE}[2]${NC} Use passwd Command ${GRAY}(Manual Secure Flow)${NC}"
    echo ""
    
    echo -ne "${PURPLE}  > Choose option: ${NC}"
    read choice
    
    case $choice in
        1)
            echo ""
            read -sp "Enter new root password: " pass
            echo ""
            read -sp "Confirm password: " confirm_pass
            echo ""
            
            if [[ "$pass" != "$confirm_pass" ]]; then
                msg_err "Passwords do not match!"
            elif [[ -z "$pass" ]]; then
                msg_err "Password cannot be empty!"
            else
                echo "root:$pass" | chpasswd
                if [ $? -eq 0 ]; then
                    msg_ok "Root password updated successfully."
                else
                    msg_err "Failed to update password."
                fi
            fi
            ;;
            
        2)
            echo ""
            passwd root
            echo ""
            if [ $? -eq 0 ]; then
                msg_ok "Password updated successfully."
            else
                msg_err "Password change failed."
            fi
            ;;
            
        *)
            msg_err "Invalid option."
            ;;
    esac

    echo ""
    read -p "  Press Enter to continue..."
}

restore_backup() {
    echo -e "${GRAY}  ------------------------------------------${NC}"
    if [ -f "$BACKUP_FILE" ]; then
        msg_info "Restoring backup..."
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl restart ssh
        msg_ok "Configuration restored."
    else
        msg_err "No backup file found."
    fi
    read -p "  Press Enter to continue..."
}

# --- ROOT CHECK ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Run as root.${NC}"
    exit 1
fi

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "  ${WHITE}ACCESS CONTROLS:${NC}"
    echo -e "  ${GREEN}[1]${NC} Enable Root & Passwords"
    echo -e "  ${RED}[2]${NC} Secure Lockdown"
    echo ""
    echo -e "  ${WHITE}MANAGEMENT:${NC}"
    echo -e "  ${YELLOW}[3]${NC} Set Root Password"
    echo -e "  ${BLUE}[4]${NC} Restore Backup"
    echo ""
    echo -e "  ${GRAY}[0] Exit${NC}"
    echo ""
    echo -ne "${PURPLE}  root@ssh:~# ${NC}"
    read option
    
    case $option in
        1) enable_access ;;
        2) secure_lockdown ;;
        3) set_root_pass ;;
        4) restore_backup ;;
        0) clear; exit 0 ;;
        *) msg_err "Invalid Option"; sleep 1 ;;
    esac
done
