#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")

# ==========================================
#  BASIC PROTECTION
# ==========================================
[[ $EUID -ne 0 ]] && echo "Run as root!" && exit 1

# ==========================================
#  COLORS
# ==========================================
R="\e[1;91m"; G="\e[1;92m"; Y="\e[1;93m"
B="\e[1;94m"; M="\e[1;95m"; C="\e[1;96m"
W="\e[97m"; N="\e[0m"

BR="\e[1;91m"; BG="\e[1;92m"; BY="\e[1;93m"
BM="\e[1;95m"; BC="\e[1;96m"; BW="\e[1;97m"

URL="https://github.com/kaidrix306/Nexus-Host/raw/refs/heads/main/thame/Extension"

trap 'echo -e "\n${R}[!] Force exit detected.${N}"; exit 1' SIGINT

# ==========================================
#  BLUEPRINT LIST
# ==========================================
names=(
"adminauditlogs.blueprint" "huxregister.blueprint"
"loader.blueprint" "lyrdyannounce.blueprint"
"mclogs.blueprint" "mcplugins.blueprint"
"mctools.blueprint" "minecraftplayermanager.blueprint"
"playerlisting.blueprint" "resourcealerts.blueprint"
"resourcemanager.blueprint" "serverbackgrounds.blueprint"
"serversplitter.blueprint" "simplefavicons.blueprint"
"snowflakes.blueprint" "sociallogin.blueprint"
"startupchanger.blueprint" "subdomains.blueprint"
"tawkto.blueprint" "versionchanger.blueprint"
"pteromonaco.blueprint" "urldownloader.blueprint"
"consolelogs.blueprint" "laravellogs.blueprint"
"vanillatweaks.blueprint" "modrinthbrowser.blueprint"
"nopagination.blueprint" "activitypurges.blueprint"
"redirect.blueprint" "simplefooters.blueprint"
"paneladdressoverride.blueprint" "shownodeids.blueprint"
"votifiertester.blueprint" "sidebar.blueprint"
"translations.blueprint" "monacoeditor.blueprint"
"minecraftpluginmanager.blueprint" "subdomainmanager.blueprint"
"serverimporter.blueprint" "pstatistics.blueprint"
"simplefooters.blueprint" "pullfiles.blueprint"
"serverpropsmanager.blueprint" "motdmaker.blueprint"
"servericonimporter.blueprint" "sagaautosuspension.blueprint"
"sagaminecraftmodpackinstaller.blueprint" "blueannoucements.blueprint"
"trashbin.blueprint" "eggchanger.blueprint"
)

# ==========================================
#  CHECK INSTALLATION STATUS
# ==========================================
is_installed() {
    local slug="${1%.blueprint}"
    if [[ -d "/var/www/pterodactyl/storage/extensions/$slug" ]]; then
        return 0 # Installed
    else
        return 1 # Not Installed
    fi
}

# ==========================================
#  RUN FUNCTION
# ==========================================
run_blueprint() {
    local NAME="$1"
    local ACTION="$2"
    cd /var/www/pterodactyl || { echo -e "${R}Pterodactyl directory not found!${N}"; exit 1; }

    if [[ "$ACTION" == "install" ]]; then
        echo -e "\n${G} Installing ${NAME%.blueprint}...${N}"
        wget -q "$URL/$NAME" -O "$NAME"
        if [[ -f "$NAME" ]]; then
            yes | blueprint -i "$NAME"
            rm -f "$NAME"
        else
            echo -e "${R}x Download failed!${N}"
        fi
    else
        echo -e "\n${R} Removing ${NAME%.blueprint}...${N}"
        yes | blueprint -r "${NAME%.blueprint}"
    fi
}

get_title() { echo 'ICAgICAg44CCIOKAjCDigJMgTm9iaXRhLmRldiBDT05UUk9MIEhVQiDigJMg44CCICAgICAg' | base64 -d; }

# ==========================================
#  HEADER
# ==========================================
header() {
    nx_banner "THAME > EXTENSION"
}

# ==========================================
#  MENU (TWO COLUMNS)
# ==========================================
show_menu() {
  header
  echo -e "${BW} SELECT AN OPTION:${N}\n"
  
  local count=0
  for i in "${!names[@]}"; do
      num=$((i+1))
      clean_name="${names[$i]%.blueprint}"
      
      # Status detect karke icon set karna
      if is_installed "$clean_name"; then
          status="${BG}*${N}" # Green dot
      else
          status="${R}*${N}" # Empty circle
      fi
      
      # Two columns format
      printf "  ${BG}%2d${N} %-22s %b   " "$num" "$clean_name" "$status"
      
      ((count++))
      if (( count % 2 == 0 )); then echo ""; fi
  done

  echo -e "\n\n  ${BR} 0 ${N} Exit"
  echo -e "${C} ----------------------------------------------------------${N}"
}

# ==========================================
#  MAIN LOOP
# ==========================================
while true; do
  show_menu
  read -p "  Enter choice: " opt

  if [[ "$opt" == "0" ]]; then
      echo -e "\n${M}  Nexus.dev is sleeping... Bye!${N}"
      exit
  fi

  index=$((opt-1))
  NAME="${names[$index]}"

  if [[ -z "$NAME" ]]; then
      echo -e "\n${R} x Invalid Option${N}"
      sleep 1
      continue
  fi

  clean_name="${NAME%.blueprint}"

  # Sub-menu (Action selection)
  clear
  header
  
  if is_installed "$clean_name"; then
      cur_status="${BG}ALREADY INSTALLED${N}"
  else
      cur_status="${R}NOT INSTALLED${N}"
  fi

  echo -e " ${BW}SELECTED:${N} ${BC}$clean_name${N}"
  echo -e " ${BW}STATUS:${N}   $cur_status"
  echo -e "${C} ----------------------------------------------------------${N}"
  echo -e "  ${BG}[ 1 ]${N} Install"
  echo -e "  ${BR}[ 2 ]${N} Uninstall"
  echo -e "  ${BY}[ 0 ]${N} Back to Menu"
  echo -e "${C} ----------------------------------------------------------${N}"

  read -p "  Action: " action

  case $action in
      1) run_blueprint "$NAME" "install" ;;
      2) run_blueprint "$NAME" "remove" ;;
      0) continue ;;
      *) echo -e "${R}Invalid Choice${N}" ;;
  esac

  echo
  read -p " <- Press Enter to return..."
done
