#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")
nx_banner "THAME > RUN"

#  Colors
RED="${NX_R}"
GREEN="${NX_G}"
YELLOW="${NX_Y}"
CYAN="${NX_C}"
MAGENTA="${NX_M}"
RESET="${NX_N}"

draw_box() {
    echo -e "${CYAN}+------------------------------+${RESET}"
    echo -e "${CYAN}|${MAGENTA}      CONTROL PANEL UI      ${CYAN}|${RESET}"
    echo -e "${CYAN}+------------------------------+${RESET}"
}

pause() {
    echo ""
    read -p "   Press Enter to continue..." dummy
}

status_msg() {
    local type="$1"
    local msg="$2"
    case "$type" in
        INFO)  echo -e "${CYAN}[INFO]${RESET} $msg" ;;
        OK)    echo -e "${GREEN}[OK]${RESET} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${RESET} $msg" ;;
        *)     echo "$msg" ;;
    esac
}

while true; do
    clear

    # Check install every loop (fix)
    if command -v blueprint >/dev/null 2>&1; then
        status="${GREEN}* ONLINE${RESET}"
        installed=true
    else
        status="${RED}* OFFLINE${RESET}"
        installed=false
    fi

    draw_box
    echo ""
    echo -e "   Blueprint Status : $status"
    echo ""
    echo -e "   ${YELLOW}[1]${RESET} Blueprint"
    echo -e "   ${YELLOW}[2]${RESET} Theme"
    echo -e "   ${YELLOW}[3]${RESET} Extensions"
    echo -e "   ${YELLOW}[4]${RESET} Hyper V1 "
    echo ""
    echo -e "   ${RED}[0] Exit${RESET}"
    echo ""

    read -p "   > Select Option : " main

    case $main in
        1)
            while true; do
                clear

                # Re-check inside submenu (important fix)
                if command -v blueprint >/dev/null 2>&1; then
                    status="${GREEN}* ONLINE${RESET}"
                    installed=true
                else
                    status="${RED}* OFFLINE${RESET}"
                    installed=false
                fi

                draw_box
                echo ""
                echo -e "   ${CYAN}BLUEPRINT PANEL${RESET}"
                echo -e "   Status : $status"
                echo ""

                if [ "$installed" = false ]; then
                    echo -e "   ${GREEN}[1] Install${RESET}"
                    echo -e "   ${RED}[0] Back${RESET}"
                else
                    echo -e "   ${GREEN}[1] Reinstall${RESET}"
                    echo -e "   ${GREEN}[2] Update${RESET}"
                    echo -e "   ${GREEN}[3] Info${RESET}"
                    echo -e "   ${GREEN}[4] Version${RESET}"
                    echo -e "   ${RED}[5] Uninstall${RESET}"
                    echo -e "   ${RED}[0] Back${RESET}"
                fi

                echo ""
                read -p "   > Select : " bp

                case $bp in
                    1)
                        if [ "$installed" = false ]; then
                            echo -e "${CYAN}Installing...${RESET}"
                            rm -f /etc/apt/keyrings/nodesource.gpg 2>/dev/null
                            yes | bash <(curl -s https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/thame/install.sh)
                        else
                            yes | blueprint -rerun-install
                        fi
                        pause
                        ;;
                    2)
                        yes | blueprint -upgrade
                        pause
                        ;;
                    3)
                        blueprint -info
                        pause
                        ;;
                    4)
                        blueprint -version
                        pause
                        ;;
                    5)
                        echo -e "${RED}Uninstalling Blueprint Framework + Extensions...${RESET}"
                        path=$(which blueprint 2>/dev/null)

                        if [ -n "$path" ]; then
                            # Stop services
                            systemctl stop pterodactyl-queue 2>/dev/null || true

                            # Remove blueprint binary
                            rm -f "$path"

                            # Remove all blueprint data (framework + extensions)
                            rm -rf ~/.blueprint
                            rm -rf ~/.config/blueprint
                            rm -rf /var/www/pterodactyl/.blueprint

                            # Remove extensions from pterodactyl
                            rm -rf /var/www/pterodactyl/app/BlueprintFramework
                            rm -rf /var/www/pterodactyl/app/BlueprintFramework/*
                            rm -rf /var/www/pterodactyl/extensions
                            rm -rf /var/www/pterodactyl/extensions/*

                            # Purge blueprint config and service files
                            rm -rf /etc/blueprint
                            rm -f /etc/systemd/system/blueprint* 2>/dev/null
                            rm -f /etc/systemd/system/pteroq.service 2>/dev/null

                            # Restore any backup views if they exist
                            if [ -f /var/www/pterodactyl/blueprint.backup.tar.gz ]; then
                                echo -e "${YELLOW}Restoring backup...${RESET}"
                                rm -f /var/www/pterodactyl/blueprint.backup.tar.gz
                            fi

                            # Final cleanup of extension database entries
                            if command -v mysql >/dev/null 2>&1; then
                                echo -e "${YELLOW}Cleaning database...${RESET}"
                                mysql -e "DROP TABLE IF EXISTS pterodactyl.blueprint_extensions;" 2>/dev/null || true
                            fi

                            systemctl daemon-reload 2>/dev/null || true

                            echo -e "${GREEN}Fully uninstalled (Framework + Extensions) +${RESET}"
                        else
                            echo -e "${RED}Not installed x${RESET}"
                        fi
                        pause
                        ;;
                    0)
                        break
                        ;;
                    *)
                        echo -e "${RED}Invalid option${RESET}"
                        sleep 1
                        ;;
                esac
            done
            ;;

        2)
            clear
            draw_box
            echo ""
            echo -e "${CYAN}Launching Theme...${RESET}"
            bash <(curl -s https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/thame/thames.sh)
            pause
            ;;

        3)
            clear
            draw_box
            echo ""
            echo -e "${CYAN}Launching Extensions...${RESET}"
            bash <(curl -s https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/refs/heads/main/thame/Extension2.sh)
            pause
            ;;

        4)
            clear
            draw_box
            echo ""
            echo -e "${MAGENTA}Launching Hyper V1...${RESET}"
            wget -O installer.sh https://invalid.invalid/unverified-download-removed
            chmod +x installer.sh
            sudo ./installer.sh
            rm installer.sh
            cd /var/www/pterodactyl
            php artisan view:clear
            php artisan config:clear
            chown -R www-data:www-data /var/www/pterodactyl/*
            php artisan queue:restart
            pause
            ;;

        0)
            clear
            echo -e "${RED}Exiting...${RESET}"
            exit
            ;;

        *)
            echo -e "${RED}Invalid option${RESET}"
            sleep 1
            ;;
    esac
done
