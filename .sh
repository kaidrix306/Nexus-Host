[1mdiff --git a/nexus.sh b/nexus.sh[m
[1mindex 0cfaeaf..53e05aa 100644[m
[1m--- a/nexus.sh[m
[1m+++ b/nexus.sh[m
[36m@@ -132,7 +132,7 @@[m [mvalid_user()  { [[ $1 =~ ^[A-Za-z0-9_.-]{3,30}$ ]]; }[m
 #  PRE-FLIGHT[m
 # ---------------------------------------------------------------------[m
 preflight() {[m
[31m-    [ "$EUID" -eq 0 ] || die "Run as root:  sudo -i  then run again"[m
[32m+[m[32m    [ "$EUID" -eq 0 ] || die "Run as root:  -i  then run again"[m
     [ -r /etc/os-release ] || die "Cannot detect OS"[m
     # shellcheck disable=SC1091[m
     . /etc/os-release[m
[36m@@ -631,32 +631,40 @@[m [mshow_status() {[m
 #  MENU[m
 # ---------------------------------------------------------------------[m
 menu() {[m
[32m+[m[32m    local c ram disk up[m
     while true; do[m
         banner[m
[31m-        echo[m
[31m-        echo "   ${G}1${N}) ${W}Install Panel${N}"[m
[31m-        echo "   ${G}2${N}) ${W}Install Wings${N}"[m
[31m-        echo "   ${G}3${N}) ${W}Install Panel + Wings (same server)${N}"[m
[31m-        echo "   ${G}4${N}) ${W}Link Wings to Panel${N}"[m
[31m-        echo "   ${G}5${N}) ${W}System status${N}"[m
[31m-        echo "   ${G}6${N}) ${W}Hub: themes, extensions, SSL, VM, extras${N}"[m
[31m-        echo "   ${R}0${N}) ${W}Exit${N}"[m
[31m-        hline[m
[31m-        printf '  %sSelect%s: ' "$M" "$N"[m
[31m-        read -r c[m
[32m+[m[32m        ram=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%d%%", ($3/$2)*100}')[m
[32m+[m[32m        disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')[m
[32m+[m[32m        up=$(uptime -p 2>/dev/null | sed 's/^up //')[m
[32m+[m[32m        printf '\n  %s╔═══════════════════════════════════════════════════════╗%s\n' "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %sN E X U S   H O S T%s  %sCONTROL CENTER%s           %s║%s\n' "$C" "$N" "$M" "$N" "$Y" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s╠═══════════════════════════════════════════════════════╣%s\n' "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %sSYSTEM%s RAM %s%-5s%s DISK %s%-5s%s UP %s%-12.12s%s %s║%s\n' "$C" "$N" "$Y" "$N" "$G" "${ram:-N/A}" "$N" "$B" "${disk:-N/A}" "$N" "$M" "${up:-unknown}" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s╠═══════════════════════════════════════════════════════╣%s\n' "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %sDEPLOYMENT%s                                       %s║%s\n' "$C" "$N" "$M" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %s[1]%s Install Pterodactyl Panel                     %s║%s\n' "$C" "$N" "$G" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %s[2]%s Install Wings Node                           %s║%s\n' "$C" "$N" "$G" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %s[3]%s Install Panel + Wings                        %s║%s\n' "$C" "$N" "$G" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %s[4]%s Link Wings to Panel                          %s║%s\n' "$C" "$N" "$G" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s╠═══════════════════════════════════════════════════════╣%s\n' "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %sMAINTENANCE%s                                      %s║%s\n' "$C" "$N" "$B" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %s[5]%s System status                                %s║%s\n' "$C" "$N" "$G" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s║%s  %s[0]%s Exit                                         %s║%s\n' "$C" "$N" "$R" "$N" "$C" "$N"[m
[32m+[m[32m        printf '  %s╚═══════════════════════════════════════════════════════╝%s\n\n' "$C" "$N"[m
[32m+[m[32m        printf '  %s➜%s %sChoose option [0-5]:%s ' "$M" "$N" "$W" "$N"[m
[32m+[m[32m        read -r c || c=0[m
         case "$c" in[m
             1) install_panel; pause ;;[m
             2) install_wings; pause ;;[m
             3) install_panel; install_wings; pause ;;[m
             4) link_wings; pause ;;[m
             5) show_status; pause ;;[m
[31m-            6) bash <(curl -fsSL "${REPO_RAW}/menu/UI.sh") ;;[m
[31m-            0) echo "  ${C}Bye from ${BRAND}!${N}"; exit 0 ;;[m
[31m-            *) warn "Invalid option"; sleep 1 ;;[m
[32m+[m[32m            0|exit|quit) echo "  ${C}Bye from ${BRAND}!${N}"; exit 0 ;;[m
[32m+[m[32m            *) warn "Invalid option — choose 0 to 5"; sleep 1 ;;[m
         esac[m
     done[m
 }[m
[31m-[m
 main() {[m
     case "${1:-menu}" in[m
         status) PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}'); banner; show_status ;;[m
