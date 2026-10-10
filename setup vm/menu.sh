#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/lib/ui.sh")

# COLORS
R="\e[1;91m"; G="\e[1;92m"; Y="\e[1;93m"; B="\e[1;94m"; C="\e[1;96m"; M="\e[1;95m"; W="\e[1;97m"; N="\e[0m"

# NEW UI STYLE FUNCTIONS
print_box() {
    local text="$1"
    local color="$2"
    local width=50
    local padding=$(( (width - ${#text} - 2) / 2 ))
    
    echo -e "${color}+$(printf '-%.0s' $(seq 1 $((width-2))))+${N}"
    printf "${color}|%*s%s%*s|${N}\n" $padding "" "$text" $((padding - ((${#text} % 2) ? 1 : 0))) ""
    echo -e "${color}+$(printf '-%.0s' $(seq 1 $((width-2))))+${N}"
}

print_header() {
    nx_banner "SETUP VM > MENU"
}

print_option() {
    local num="$1"
    local text="$2"
    local color="$3"
    
    echo -e "  ${color}+--------------------------------------+${N}"
    echo -e "  ${color}|${W}  [$num]  $text$(printf '%*s' $((31 - ${#text} - 6)))${color}|${N}"
    echo -e "  ${color}+--------------------------------------+${N}\n"
}

print_status() {
    local text="$1"
    local color="$2"
    echo -e "\n${color}>> ${text}${N}\n"
}

# MAIN MENU LOOP
while true; do
    print_header
    
    print_option "1" "RDX Tool" "$G"
    print_option "2" "Run vm 1 Kvm" "$Y"
    print_option "3" "Run vm 2 No Kvm" "$B"
    print_option "4" "Run vm 3 ALL SETUP" "$B"
    print_option "5" "Exit" "$R"

    
    echo -e "${M}------------------------------------------------${N}"
    echo -ne "${W}Select Option > ${N}"
    read -p "" op
    
    case $op in
    
    # =========================================================
    # (1) IDX TOOL - ENHANCED
    # =========================================================
    1)
        clear
        print_status " Running IDX Tool Setup..." "$Y"
        echo -e "${M}------------------------------------------------${N}\n"
        
        echo -e "${C} Cleaning up old files...${N}"
        cd
        rm -rf myapp
        rm -rf flutter
        
        cd vm
        
        if [ ! -d ".idx" ]; then
            echo -e "${G} Creating .idx directory...${N}"
            mkdir .idx
            cd .idx
            
            echo -e "${C} Creating dev.nix configuration...${N}"
            cat <<EOF > dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = { };
    };

    previews = {
      enable = false;
    };
  };
}
EOF
            
            echo -e "\n${G}+ IDX Tool setup complete!${N}"
            echo -e "${W}+--------------------------------------+${N}"
            echo -e "${W}| ${G}Status${W}: ${Y}Ready to use${W}                 |${N}"
            echo -e "${W}| ${G}Location${W}: ${Y}~/vps123/.idx${W}              |${N}"
            echo -e "${W}+--------------------------------------+${N}"
        else
            echo -e "${Y}! Directory .idx already exists - skipping.${N}"
        fi
        
        echo -e "\n${M}------------------------------------------------${N}"
        read -p "<- Press Enter..."
        ;;
    
    # =========================================================
    # (2) Run vm1 Kvm - ENHANCED
    # =========================================================
    2)
        clear
        print_status " Starting IDX VM From GitHub Script..." "$B"
        echo -e "${M}------------------------------------------------${N}\n"
        
        echo -e "${C} Fetching script from GitHub...${N}"
        bash <(curl -s https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/setup%20vm/vm-1.sh)
        
        echo -e "\n${M}------------------------------------------------${N}"
        read -p "<- Press Enter..."
        ;;

    # =========================================================
    # (3) Run vm2 No kvm  - ENHANCED
    # =========================================================
    3)
        clear
        print_status " Starting vm 2 From GitHub Script..." "$B"
        echo -e "${M}------------------------------------------------${N}\n"
        
        echo -e "${C} Fetching script from GitHub...${N}"

        bash <(curl -s https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/setup%20vm/vm-2.sh)
        
        echo -e "\n${M}------------------------------------------------${N}"
        read -p "<- Press Enter..."
        ;;

    # =========================================================
    # (4) Run vm3 no+yes setup  - ENHANCED
    # =========================================================
    4)
        clear
        print_status " Starting vm 2 From GitHub Script..." "$B"
        echo -e "${M}------------------------------------------------${N}\n"
        
        echo -e "${C} Fetching script from GitHub...${N}"

        bash <(curl -s https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master/setup%20vm/vm-3.sh)
        
        echo -e "\n${M}------------------------------------------------${N}"
        read -p "<- Press Enter..."
        ;;  
    # =========================================================
    # EXIT - ENHANCED
    # =========================================================
    5)
        clear
        echo -e "\n${C}+------------------------------------------------+${N}"
        echo -e "${C}|${R}                 E X I T I N G                  ${C}|${N}"
        echo -e "${C}+------------------------------------------------+${N}\n"
        echo -e "${Y} Thank you for using the Development Menu!${N}\n"
        exit 0
        ;;
    
    *)
        echo -e "\n${R}x Invalid Option! Please try again.${N}"
        sleep 1
        ;;
    esac
done
