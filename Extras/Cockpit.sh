#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")
set -e

# ===== Colors =====
R="\e[1;91m"; G="\e[1;92m"; Y="\e[1;93m"; B="\e[1;94m"; C="\e[1;96m"; M="\e[1;95m"; W="\e[0m"
BOLD="${NX_W}"

# ===== Detect Functions =====
svc_status() {
  systemctl is-active --quiet "$1" && echo -e "${G}RUNNING${W}" || echo -e "${R}STOPPED${W}"
}

svc_enabled() {
  systemctl is-enabled --quiet "$1" 2>/dev/null && echo -e "${G}enabled${W}" || echo -e "${R}disabled${W}"
}

detect_port() {
  ss -lntp 2>/dev/null | grep cockpit.socket | awk -F: '{print $NF}' | head -n1
}

pkg_installed() {
  dpkg -s "$1" &>/dev/null
}

count_vms() {
  virsh list --state-running 2>/dev/null | grep -c running || echo "0"
}

count_vms_all() {
  virsh list --all 2>/dev/null | grep -c -E '\s+[0-9]+\s+' || echo "0"
}

COCKPIT_PORT=$(detect_port)
[[ -z "$COCKPIT_PORT" ]] && COCKPIT_PORT="9090"

# ===== UI =====
draw_header() {
    nx_banner "EXTRAS > COCKPIT"
}

draw_status_box() {
echo -e "${Y}+----------- SYSTEM STATUS -----------+${W}"
printf "${Y}|${W}  %-18s : %b\n" "Cockpit Socket"  "$(svc_status cockpit.socket)"
printf "${Y}|${W}  %-18s : %b\n" "Libvirt Daemon"  "$(svc_status libvirtd)"
printf "${Y}|${W}  %-18s : %b\n" "Cockpit Port"    "${C}${COCKPIT_PORT}${W}"
printf "${Y}|${W}  %-18s : "     "Cockpit Files"
if pkg_installed cockpit-files; then echo -e "${G}installed${W}"; else echo -e "${R}not installed${W}"; fi
printf "${Y}|${W}  %-18s : "     "Running VMs"
echo -e "${G}$(count_vms)${W} / ${Y}$(count_vms_all)${W} total"
echo -e "${Y}|${W}  ${Y}Info:${W} cockpit-files adds a file manager"
echo -e "${Y}|${W}  ${Y}      ${W}tab to the Cockpit web console."
echo -e "${Y}+--------------------------------------+${W}"
echo ""
}

draw_menu() {
echo -e "${G}+--------------- MENU ---------------+${W}"
echo -e "${G}|${W}  ${B}i${W}) Install  component"
echo -e "${G}|${W}  ${R}u${W}) Uninstall component"
echo -e "${G}|${W}  ${C}p${W}) Change Cockpit port"
echo -e "${G}|${W}  ${Y}s${W}) Service status (full)"
echo -e "${G}|${W}  ${R}q${W}) Exit"
echo -e "${G}+------------------------------------+${W}"
echo ""
}

draw_install_menu() {
echo ""
echo -e "${G}-- Install Which? --${W}"
echo -e "  ${G}a${W}) All components (cockpit + KVM + files)"
echo -e "  ${Y}b${W}) Back to main menu"
echo ""
}

draw_uninstall_menu() {
echo ""
echo -e "${R}-- Uninstall Which? --${W}"
echo -e "  ${R}a${W}) All components (cockpit + KVM + files)"
echo -e "  ${Y}b${W}) Back to main menu"
echo ""
}

pause(){ read -rp " Press Enter to continue..." || true; }

# ===== Actions =====
install_cockpit() {
echo -e "${G} Installing Cockpit...${W}"
sudo apt update && sudo apt install -y cockpit
sudo systemctl enable --now cockpit.socket
sudo rm -f /etc/cockpit/disallowed-users
sudo systemctl restart cockpit
echo -e "${G}+ Cockpit installed.${W}"
pause
}

install_kvm() {
echo -e "${G} Installing KVM/Libvirt...${W}"
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cockpit-machines
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm $USER
echo -e "${G}+ KVM stack installed.${W}"
pause
}

install_files() {
echo -e "${G} Installing cockpit-files...${W}"
sudo apt update && sudo apt install -y cockpit-files
sudo systemctl restart cockpit
echo -e "${G}+ cockpit-files installed.${W}"
echo -e "${Y}i  Refresh your Cockpit browser tab to see the Files entry.${W}"
pause
}

install_stack() {
echo -e "${G} Installing full stack...${W}"
sudo apt update
sudo apt install -y cockpit qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cockpit-machines cockpit-files
sudo systemctl enable --now cockpit.socket
sudo systemctl enable --now libvirtd
sudo rm -f /etc/cockpit/disallowed-users
sudo usermod -aG libvirt,kvm $USER
sudo systemctl restart cockpit
echo -e "${G}+ Full stack installed.${W}"
echo -e "${Y}i  Refresh Cockpit browser to see Files tab.${W}"
pause
}

uninstall_cockpit() {
echo -e "${R} Removing Cockpit...${W}"
sudo systemctl disable --now cockpit.socket || true
sudo apt purge -y cockpit
sudo apt autoremove -y
echo -e "${R}x Cockpit removed.${W}"
pause
}

uninstall_kvm() {
echo -e "${R} Removing KVM/Libvirt...${W}"
sudo systemctl disable --now libvirtd || true
sudo apt purge -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cockpit-machines
sudo apt autoremove -y
echo -e "${R}x KVM stack removed.${W}"
pause
}

uninstall_files() {
echo -e "${R} Removing cockpit-files...${W}"
sudo apt purge -y cockpit-files
sudo apt autoremove -y
sudo systemctl restart cockpit 2>/dev/null || true
echo -e "${R}x cockpit-files removed.${W}"
pause
}

uninstall_stack() {
echo -e "${R} Removing full stack...${W}"
sudo systemctl disable --now cockpit.socket libvirtd || true
sudo apt purge -y cockpit-files cockpit cockpit-machines qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo apt autoremove -y
echo -e "${R}x Full stack removed.${W}"
pause
}

change_port() {
read -rp " New Cockpit port: " NEW_PORT
[[ ! "$NEW_PORT" =~ ^[0-9]+$ ]] && echo -e "${R}Invalid port${W}" && pause && return

sudo mkdir -p /etc/systemd/system/cockpit.socket.d
sudo tee /etc/systemd/system/cockpit.socket.d/listen.conf >/dev/null <<EOF
[Socket]
ListenStream=
ListenStream=$NEW_PORT
EOF

sudo systemctl daemon-reload
sudo systemctl restart cockpit.socket

command -v ufw >/dev/null && sudo ufw allow "$NEW_PORT"/tcp && sudo ufw reload

echo -e "${G}+ Port changed to $NEW_PORT${W}"
pause
}

show_full_status() {
clear
echo -e "${C}+------------------- FULL STATUS -------------------+${W}"
echo ""

echo -e "${Y}-- Services --${W}"
for svc in cockpit.socket libvirtd; do
  printf "  %-20s : %b  (%b)\n" "$svc" "$(svc_status "$svc")" "$(svc_enabled "$svc")"
done

echo ""
echo -e "${Y}-- Packages --${W}"
for pkg in cockpit cockpit-machines cockpit-files qemu-kvm libvirt-daemon-system virt-manager; do
  if pkg_installed "$pkg"; then
    echo -e "  ${G}+${W} $pkg"
  else
    echo -e "  ${R}x${W} $pkg"
  fi
done

echo ""
echo -e "${Y}-- Virtual Machines --${W}"
if command -v virsh &>/dev/null; then
  echo -e "  Running : ${G}$(count_vms)${W}"
  echo -e "  Total   : ${Y}$(count_vms_all)${W}"
  virsh list --all 2>/dev/null | tail -n +3 | grep -v '^$' | while read -r line; do
    echo -e "    ${C}>${W} $line"
  done
else
  echo -e "  ${R}(virsh not available)${W}"
fi

echo ""
echo -e "${C}+----------------------------------------------------+${W}"
pause
}

# ===== Install Sub-Menu =====
install_submenu() {
while true; do
  draw_header
  draw_status_box
  draw_install_menu
  read -rp "Install [a,b]: " choice || break
  case "$choice" in
    a|A) install_stack ;;
    b|B) break ;;
    *) echo -e "${R}x Invalid${W}"; pause ;;
  esac
done
}

# ===== Uninstall Sub-Menu =====
uninstall_submenu() {
while true; do
  draw_header
  draw_status_box
  draw_uninstall_menu
  read -rp "Uninstall [a,b]: " choice || break
  case "$choice" in
    a|A) uninstall_stack ;;
    b|B) break ;;
    *) echo -e "${R}x Invalid${W}"; pause ;;
  esac
done
}

# ===== Main Loop =====
while true; do
  COCKPIT_PORT=$(detect_port)
  [[ -z "$COCKPIT_PORT" ]] && COCKPIT_PORT="9090"

  draw_header
  draw_status_box
  draw_menu

  read -rp "Action [i/u/p/s/q]: " cmd || continue
  case "$cmd" in
    i|I) install_submenu ;;
    u|U) uninstall_submenu ;;
    p|P) change_port ;;
    s|S) show_full_status ;;
    q|Q) echo -e "${B} System under control.${W}"; exit 0 ;;
    *) echo -e "${R}x Invalid${W}"; pause ;;
  esac
done
