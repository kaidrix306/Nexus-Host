#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")

# ====================================================
#       PTERODACTYL CONTROL CENTER v2.1
# ====================================================

# --- COLORS & STYLING ---
RED="${NX_R}"
GREEN="${NX_G}"
YELLOW="${NX_Y}"
BLUE="${NX_B}"
PURPLE="${NX_M}"
CYAN="${NX_C}"
WHITE="${NX_W}"
BOLD="${NX_W}"
NC="${NX_N}"
GOLD="${NX_Y}"
GRAY="${NX_W}"

# --- UI HELPER FUNCTIONS ---

show_header() {
    nx_box "$1"
}

status_msg() {
    # $1 = Type (OK, ERR, INFO, WAIT), $2 = Message
    case $1 in
        "OK")   echo -e "  [${GREEN} + ${NC}] $2" ;;
        "ERR")  echo -e "  [${RED} x ${NC}] $2" ;;
        "INFO") echo -e "  [${CYAN} > ${NC}] $2" ;;
        "WAIT") echo -e "  [${YELLOW} ... ${NC}] $2" ;;
    esac
}

pause() {
    echo ""
    read -p "  Press [Enter] to return to main menu..."
}

# ================== INSTALL FUNCTION ==================
install_ptero() {
    show_header "PANEL INSTALLATION"
    
    status_msg "INFO" "Initiating installation script..."
    sleep 1
    
    # Run the external script
    bash <(curl -s https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/panel/pterodactyl/install.sh)
    
    echo ""
    status_msg "OK" "Installation Sequence Complete."
    pause
}

# ================== CREATE USER ==================
create_user() {
    show_header "USER MANAGEMENT"

    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel directory not found (/var/www/pterodactyl)."
        status_msg "ERR" "Please install the panel first."
        pause
        return
    fi

    echo ""
    echo "1) Custom User Create"
    echo "2) Auto Create Admin User"
    echo ""
    read -p "Choose option: " choice

    cd /var/www/pterodactyl || exit

    if [ "$choice" = "1" ]; then
        status_msg "WAIT" "Launching manual user creation..."
        php artisan p:user:make

    elif [ "$choice" = "2" ]; then
        status_msg "WAIT" "Creating auto admin user..."

        USERNAME="user$(openssl rand -hex 2)"
        PASSWORD="$(openssl rand -base64 10)"
        EMAIL="$(openssl rand -base64 4)@email.com"
        FIRST="$(openssl rand -base64 6)"
        LAST="$(openssl rand -base64 4)"
        php artisan p:user:make -n \
            --email=${EMAIL} \
            --username=${USERNAME} \
            --password=${PASSWORD} \
            --admin=1 \
            --name-first=${FIRST} \
            --name-last=${LAST}

        echo ""
        status_msg "OK" "Auto User Created!"
        echo "Username: $USERNAME"
        echo "Password: $PASSWORD"
        echo "Email:    $EMAIL"
    else
        status_msg "ERR" "Invalid option."
    fi

    pause
}
# ================= PANEL UNINSTALL =================
uninstall_logic() {
    status_msg "WAIT" "Stopping Panel services..."
    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload

    status_msg "WAIT" "Removing cronjobs..."
    crontab -l | grep -v 'php /var/www/pterodactyl/artisan schedule:run' | crontab - || true

    status_msg "WAIT" "Deleting panel files..."
    rm -rf /var/www/pterodactyl

    status_msg "WAIT" "Dropping database and users..."
    mysql -u root -e "DROP DATABASE IF EXISTS panel;"
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    status_msg "WAIT" "Cleaning Nginx configs..."
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx || true
}

uninstall_ptero() {
    show_header "UNINSTALLATION"
    
    echo -e "${RED}  WARNING: This will delete all panel data and databases!${NC}"
    read -p "  Are you sure you want to proceed? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        status_msg "INFO" "Uninstallation cancelled."
        pause
        return
    fi

    echo ""
    uninstall_logic
    
    echo ""
    status_msg "OK" "Panel removed successfully (Wings untouched)."
    pause
}

# ================= UPDATE FUNCTION =================
update_panel() {
    show_header "SYSTEM UPDATE"

    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel not found in /var/www/pterodactyl"
        pause
        return
    fi

    status_msg "INFO" "Putting panel into Maintenance Mode..."

GITHUB_REPO="pterodactyl/panel"

step() {
    echo -e "  [${CYAN} > ${NC}] $1"
}

# --- INPUT FUNCTION ---
ask() {
    local label=$1
    local default=$2
    local var_name=$3
    echo -ne "  ${PURPLE}*${NC} ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}+->${NC} "
    read input
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

# --- TIMEOUT INPUT (10s auto-default) ---
ask_timeout() {
    local label=$1
    local default=$2
    local var_name=$3
    echo -ne "  ${PURPLE}*${NC} ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}+->${NC} "
    if ! read -t 10 input; then
        echo -e "\n  ${GOLD}... Timeout - using default: ${WHITE}$default${NC}"
        eval "$var_name=\"$default\""
        return
    fi
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

# --- FETCH GITHUB VERSIONS ---
fetch_github_versions() {
    local repo=$1
    echo -e "  ${GRAY}Fetching releases from ${WHITE}$repo${GRAY}...${NC}" >&2
    local json
    json=$(curl -sf "https://api.github.com/repos/$repo/releases?per_page=20" 2>/dev/null) || {
        echo -e "  ${RED}Failed to fetch releases.${NC}" >&2
        return 1
    }
    echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data:
    if r.get('prerelease', False):
        continue
    tag = r.get('tag_name', '')
    if tag.startswith('v'):
        print(tag)
" 2>/dev/null || return 1
}

# --- VERSION SELECTOR (10s timeout) ---
select_version() {
    local repo=$1
    local var_name=$2
    local default="latest"
    echo -e "\n  ${PURPLE}::${NC} ${WHITE}Available Panel Versions${NC}"
    local tags=() disp=() i=0
    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        tags+=("$tag")
        i=$((i+1))
        disp+=("  ${GRAY}$i.${NC} ${WHITE}$tag${NC}")
    done < <(fetch_github_versions "$repo" 2>/dev/null) || true

    if [[ ${#tags[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No versions found. Using latest.${NC}"
        eval "$var_name=\"$default\""
        return
    fi

    printf '%b\n' "${disp[@]}"
    local max=${#tags[@]}
    echo -ne "\n  ${PURPLE}*${NC} ${WHITE}Select version [1-$max]${NC} ${GRAY}[1 = latest]${NC}\n  ${GRAY}+->${NC} "
    if ! read -t 10 choice; then
        echo -e "\n  ${GOLD}... Timeout - using latest: ${WHITE}${tags[0]}${NC}"
        eval "$var_name=\"${tags[0]}\""
        return
    fi
    if [[ -z "$choice" || "$choice" == "1" ]]; then
        echo -e "  ${GREEN}> ${WHITE}${tags[0]}${NC}"
        eval "$var_name=\"${tags[0]}\""
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $max ]]; then
        local idx=$((choice - 1))
        echo -e "  ${GREEN}> ${WHITE}${tags[$idx]}${NC}"
        eval "$var_name=\"${tags[$idx]}\""
    else
        echo -e "  ${GREEN}> ${WHITE}${tags[0]}${NC} (invalid input)"
        eval "$var_name=\"${tags[0]}\""
    fi
}

# --- START ---
show_header "UPDATE PANEL"

# --- DATA COLLECTION ---

select_version "$GITHUB_REPO" "version_PANEL"

# --- FINAL VALIDATION LOOP ---
echo -e "\n  ${GOLD}+-[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}|${NC} ${GRAY}Version:${NC}  $version_PANEL"
echo -e "  ${GOLD}+---------------------------${NC}"

echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(Y/n)${NC}${GRAY} [auto: Y in 10s]:${NC} "
if ! read -t 10 -n 1 -r CONFIRM; then
    echo -e "\n  ${GOLD}... Timeout - proceeding automatically...${NC}"
    CONFIRM="y"
fi
echo ""
if [[ ! "$CONFIRM" =~ [Nn] ]]; then
    echo -e "  ${GREEN}Proceeding to deployment...${NC}"
else
    echo -e "  ${RED}Installation aborted by user.${NC}"
    exit
fi

echo -e "${PURPLE}------------------------------------------------------------${NC}"

    cd /var/www/pterodactyl
    php artisan down
    sudo rm -rf /var/www/pterodactyl/*
    cd /var/www/pterodactyl
    status_msg "INFO" "Downloading latest release..."
# --- Download Pterodactyl Panel ---
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
if [[ "$version_PANEL" == "latest" ]]; then
    step "Downloading latest panel release..."
    curl -Lso panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
else
    step "Downloading panel version $version_PANEL..."
    curl -Lso panel.tar.gz "https://github.com/pterodactyl/panel/releases/download/${version_PANEL}/panel.tar.gz"
fi
tar -xzf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
    status_msg "INFO" "Setting permissions..."

    status_msg "INFO" "Updating Composer dependencies..."
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
    
    status_msg "INFO" "Clearing cache and database migration..."
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    status_msg "INFO" "Restarting Queue Workers..."
    php artisan queue:restart
    php artisan up

    echo ""
    status_msg "OK" "Panel Updated Successfully."
    pause
}

# ===================== MAIN MENU =====================
while true; do
    clear
    
    # Banner
    echo -e "${PURPLE}  ____  _                     _            _         _ ${NC}"
    echo -e "${PURPLE} |  _ \| |_ ___ _ __ ___   __| | __ _  ___| |_ _   _| |${NC}"
    echo -e "${PURPLE} | |_) | __/ _ \ '__/ _ \ / _\` |/ _\` |/ __| __| | | | |${NC}"
    echo -e "${PURPLE} |  __/| ||  __/ | | (_) | (_| | (_| | (__| |_| |_| | |${NC}"
    echo -e "${PURPLE} |_|    \__\___|_|  \___/ \__,_|\__,_|\___|\__|\__, |_|${NC}"
    echo -e "${PURPLE}                                               |___/   ${NC}"
    echo -e ""
    
    echo -e "${CYAN} +-------------------------------------------------------+${NC}"

    # --- CHECK INSTALL STATUS ---
    if [ -d "/var/www/pterodactyl" ]; then
        # Green "INSTALLED" message
        echo -e "${CYAN} |${NC} ${BOLD}${WHITE}PANEL STATUS:${NC} ${GREEN}INSTALLED +${NC}                                 ${CYAN}|${NC}"
    else
        # Red "NOT INSTALLED" message
        echo -e "${CYAN} |${NC} ${BOLD}${WHITE}PANEL STATUS:${NC} ${RED}NOT INSTALLED x${NC}                             ${CYAN}|${NC}"
    fi

    echo -e "${CYAN} +-------------------------------------------------------+${NC}"
    echo -e "${CYAN} |${NC}                                                       ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${GREEN}[1]${NC} Install       ${GRAY}:: (Fresh Install)${NC}          ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${GREEN}[2]${NC} User          ${GRAY}:: (Add Admin/User)${NC}        ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${YELLOW}[3]${NC} Update       ${GRAY}:: (Latest Release)${NC}        ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${RED}[4]${NC} Domin           ${GRAY}:: (Chang/domin/ssl)${NC}           ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${RED}[5]${NC} Uninstall       ${GRAY}:: (Remove Data)${NC}           ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${RED}[6]${NC} phpmyadmin       ${GRAY}:: (phpmyadmin Data)${NC}           ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}                                                       ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${WHITE}[0] Exit System${NC}                                   ${CYAN}|${NC}"
    echo -e "${CYAN} +-------------------------------------------------------+${NC}"
    echo ""
    echo -ne "${BOLD}${WHITE}  root@ptero:~# ${NC}"
    read choice

    case $choice in
        1) install_ptero ;;
        2) create_user ;;
        3) update_panel ;;
        4) bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/panel/pterodactyl/ssl.sh) ;;
        5) uninstall_ptero ;;
        6) bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/panel/pterodactyl/phpMyAdmin.sh) ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option selected...${NC}"; sleep 1 ;;
    esac
done
