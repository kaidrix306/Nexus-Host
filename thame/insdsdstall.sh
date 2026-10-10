#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")
nx_banner "THAME > INSDSDSTALL"
set -e
set -o pipefail

R="\e[1;91m"; G="\e[1;92m"; Y="\e[1;93m"; B="\e[1;94m"; C="\e[1;96m"; W="\e[1;97m"; N="\e[0m"
PT_DIR="/var/www/pterodactyl"
REPO="BlueprintFramework/framework"

cleanup() { rm -f "$PT_DIR/release.zip"; }
trap cleanup EXIT

if [ "$EUID" -ne 0 ]; then
    echo -e "${R}x Error: Please run as root (sudo bash $0)${N}"
    exit 1
fi

clear
echo -e "${B}+------------------------------------------------------+${N}"
echo -e "${B}|${W}        PTERODACTYL BLUEPRINT AUTO-INSTALLER        ${B}|${N}"
echo -e "${B}+------------------------------------------------------+${N}"
echo
echo -e "${Y}!  This script will automatically install Blueprint on:${N}"
echo -e "${C}   $PT_DIR${N}"
echo
echo -e "Starting in 3 seconds... (Press Ctrl+C to cancel)"
sleep 3

# --- STEP 1/6: CHECK & INSTALL SYSTEM DEPS ---
echo -e "\n${B}[1/6] Checking directory and installing dependencies...${N}"
if [ ! -d "$PT_DIR" ]; then
    echo -e "${R}x Error: Pterodactyl not found at $PT_DIR${N}"
    exit 1
fi
apt update -qq
apt install -y -qq curl wget unzip ca-certificates git gnupg zip jq
echo -e "${G}+ Directory OK, dependencies installed.${N}"

# --- STEP 2/6: NODE.JS + YARN ---
echo -e "\n${B}[2/6] Configuring Node.js environment...${N}"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --batch --yes -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
apt update -qq
dpkg --purge --force-all libnode-dev 2>/dev/null || true
apt install -y -qq -f
apt install -y -qq nodejs
npm install -g yarn
echo -e "${G}+ Node.js & Yarn ready.${N}"

# --- STEP 3/6: VERSION SELECTION ---
echo -e "\n${B}[3/6] Selecting Blueprint version...${N}"
echo -e "${Y}Fetching available releases...${N}"
RELEASES_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases?per_page=30")
VERSIONS=(); URLS=()
while IFS="|" read -r ver url; do
    VERSIONS+=("$ver"); URLS+=("$url")
done < <(echo "$RELEASES_JSON" | jq -r '.[] | select(.draft == false and .prerelease == false) | "\(.tag_name)|\(.assets[] | select(.name | endswith("release.zip")) | .browser_download_url)"' 2>/dev/null)

if [ ${#VERSIONS[@]} -eq 0 ]; then
    echo -e "${R}! No releases detected. Using latest...${N}"
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq -r '.assets[] | select(.name | endswith("release.zip")) | .browser_download_url')
else
    echo -e "\n${C}Available versions:${N}"
    echo -e "${W}  [0] latest (default)${N}"
    for i in "${!VERSIONS[@]}"; do
        printf "  ${W}[%d]${N} ${C}%s${N}\n" $((i+1)) "${VERSIONS[$i]}"
    done
    echo
    read -t 10 -p "$(echo -e "${Y}Enter version number (default: 0): ${N}")" choice
    if [ -z "$choice" ] || [ "$choice" == "0" ]; then
        DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq -r '.assets[] | select(.name | endswith("release.zip")) | .browser_download_url')
    elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#VERSIONS[@]} ] 2>/dev/null; then
        DOWNLOAD_URL="${URLS[$((choice-1))]}"
    else
        echo -e "${R}! Invalid choice. Using latest.${N}"
        DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq -r '.assets[] | select(.name | endswith("release.zip")) | .browser_download_url')
    fi
fi

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${R}x Failed to retrieve download URL. Aborting.${N}"
    exit 1
fi
echo -e "${G}+ Version selected.${N}"

# --- STEP 4/6: DOWNLOAD & EXTRACT ---
echo -e "\n${B}[4/6] Downloading Blueprint Framework...${N}"
cd "$PT_DIR"
wget -q "$DOWNLOAD_URL" -O release.zip
unzip -o -q release.zip
rm -f release.zip
echo -e "${G}+ Files extracted.${N}"

# --- STEP 5/6: CONFIGURATION ---
echo -e "\n${B}[5/6] Generating configuration...${N}"
cat <<EOF > .blueprintrc
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
chmod +x blueprint.sh
chown -R www-data:www-data "$PT_DIR"
echo -e "${G}+ Configuration ready.${N}"

# --- STEP 6/6: INSTALL ---
echo -e "\n${B}[6/6] Running Blueprint installer...${N}"
if [ ! -f blueprint.sh ]; then
    echo -e "${R}x blueprint.sh not found after extraction. Aborting.${N}"
    exit 1
fi
yes | bash blueprint.sh

echo -e "\n${G}------------------------------------------------------${N}"
echo -e "${G}    INSTALLATION COMPLETE!${N}"
echo -e "${W}   Blueprint Framework is now active on your panel.${N}"
echo -e "${G}------------------------------------------------------${N}"
