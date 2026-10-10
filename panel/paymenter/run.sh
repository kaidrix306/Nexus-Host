#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")

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
    bash <(curl -s https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/panel/paymenter/install.sh)
    
    echo ""
    status_msg "OK" "Installation Sequence Complete."
    pause
}

# ================== CREATE USER ==================
create_user() {
    show_header "USER MANAGEMENT"

    if [ ! -d /var/www/paymenter ]; then
        status_msg "ERR" "Panel directory not found (/var/www/paymenter)."
        status_msg "ERR" "Please install the panel first."
        pause
        return
    fi

    echo ""
    echo "1) Custom User Create"
    echo "2) Auto Create Admin User"
    echo ""
    read -p "Choose option: " choice

    cd /var/www/paymenter || exit

    if [ "$choice" = "1" ]; then
        status_msg "WAIT" "Launching manual user creation..."
        php artisan app:user:create

    elif [ "$choice" = "2" ]; then
        status_msg "WAIT" "Creating auto admin user..."

        USERNAME="user$(openssl rand -hex 2)"
        PASSWORD="$(openssl rand -base64 10)"
        EMAIL="$(openssl rand -base64 4)@email.com"
        FIRST="$(openssl rand -base64 6)"
        LAST="$(openssl rand -base64 4)"
        php artisan tinker --execute="\App\Models\User::create([
        'first_name'=>'$FIRST',
        'last_name'=>'$LAST',
        'email'=>'$EMAIL',
        'password'=>bcrypt('$PASSWORD'),
        'role_id'=>1,
        'is_admin'=>1
        ]);"

        echo ""
        status_msg "OK" "Auto User Created!"
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
    systemctl stop paymenter.service 2>/dev/null || true
    systemctl disable paymenter.service 2>/dev/null || true
    rm -f /etc/systemd/system/paymenter.service
    systemctl daemon-reload

    status_msg "WAIT" "Removing cronjobs..."
    crontab -l | grep -v 'php /var/www/paymenter/artisan schedule:run' | crontab - || true

    status_msg "WAIT" "Deleting panel files..."
    rm -rf /var/www/paymenter

    status_msg "WAIT" "Dropping database and users..."
    mysql -u root -e "DROP DATABASE IF EXISTS paymenter;"
    mysql -u root -e "DROP USER IF EXISTS 'paymenter'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    status_msg "WAIT" "Cleaning Nginx configs..."
    rm -f /etc/nginx/sites-enabled/paymenter.conf
    rm -f /etc/nginx/sites-available/paymenter.conf
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
    cd /var/www/paymenter
    php artisan down
    cd /var/www/paymenter
    status_msg "INFO" "Downloading latest release..."
    curl -L https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz | tar -xz
    status_msg "INFO" "Setting permissions..."
    chmod -R 755 storage/* bootstrap/cache/
    php artisan migrate --force --seed
    status_msg "INFO" "Updating Composer dependencies..."
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
    
    status_msg "INFO" "Clearing cache and database migration..."
    php artisan view:clear
    php artisan config:clear
    chown -R www-data:www-data /var/www/paymenter/*
    
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
    echo -e "${CYAN}   ___                         _           ${NC}"
    echo -e "${CYAN} | _ \__ _ _  _ _ __  ___ _ _| |_ ___ _ _ ${NC}"
    echo -e "${CYAN} |  _/ _\` | || | '  \/ -_) ' \  _/ -_) '_|${NC}"
    echo -e "${CYAN} |_| \__,_|\_, |_|_|_\___|_||_\__\___|_|  ${NC}"
    echo -e "${CYAN}           |__/                           ${NC}"
    echo -e ""
    echo -e "${GREEN}    P A Y M E N T E R   M A N A G E R${NC}"
    echo -e ""
    echo -e "${CYAN} +-------------------------------------------------------+${NC}"

    # --- CHECK INSTALL STATUS ---
    if [ -d "/var/www/paymenter" ]; then
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
    echo -e "${CYAN} |${NC}  ${RED}[5]${NC} Thames       ${GRAY}:: (Remove Data)${NC}           ${CYAN}|${NC}"
    echo -e "${CYAN} |${NC}  ${RED}[6]${NC} Uninstall       ${GRAY}:: (Remove Data)${NC}           ${CYAN}|${NC}"
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
        4) bash <(curl -fsSL https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/panel/pterodactyl/ssl.sh) ;;
        5) echo -e "${YELLOW}This module was not part of this repo - skipping.${NC}"; sleep 1 ;;
        6) uninstall_ptero ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option selected...${NC}"; sleep 1 ;;
    esac
done
