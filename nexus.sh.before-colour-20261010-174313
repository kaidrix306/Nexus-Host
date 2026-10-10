#!/usr/bin/env bash
# =====================================================================
#  NexusCloud Installer  -  Pterodactyl Panel + Wings
#  Usage:  bash nexus.sh [panel|wings|both|link|status]
#  Rewritten from scratch
# =====================================================================
set -uo pipefail

VERSION="1.0.0"
BRAND="NexusCloud"
LOG="/var/log/nexuscloud-install.log"
CRED_FILE="/root/nexuscloud-credentials.txt"
REPO_RAW="https://raw.githubusercontent.com/kaidrix306/Nexus-Host/master"
PANEL_DIR="/var/www/pterodactyl"
PHP_VER="8.3"
export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------
#  BRIGHT COLOURS ONLY (no dim / grey)
# ---------------------------------------------------------------------
R=$'\e[1;91m'; G=$'\e[1;92m'; Y=$'\e[1;93m'; B=$'\e[1;94m'
M=$'\e[1;95m'; C=$'\e[1;96m'; W=$'\e[1;97m'; N=$'\e[0m'

INNER=55   # inner width of every box (total 57 columns)

# ---------------------------------------------------------------------
#  ASCII UI HELPERS
# ---------------------------------------------------------------------
hline() { printf '%s+%s+%s\n' "${C}" "$(printf '%*s' "$INNER" '' | tr ' ' '-')" "${N}"; }

box() {                       # box "TITLE"
    local t=" $1 " pad l r
    pad=$((INNER - ${#t})); l=$((pad / 2)); r=$((pad - l))
    echo
    hline
    printf '%s|%s%*s%s%s%s%*s%s|%s\n' "$C" "$N" "$l" "" "$Y" "$t" "$N" "$r" "" "$C" "$N"
    hline
}

row() {                       # row "Label" "Value"
    printf '%s|%s %s%-14.14s%s : %s%-36.36s%s %s|%s\n' \
        "$C" "$N" "$Y" "$1" "$C" "$W" "$2" "$N" "$C" "$N"
}

row_c() {                     # row_c "Label" "Text" "Colour"  (pads before colouring)
    printf '%s|%s %s%-14.14s%s : %s%-36.36s%s %s|%s\n' \
        "$C" "$N" "$Y" "$1" "$C" "$3" "$2" "$N" "$C" "$N"
}

banner() {
    clear 2>/dev/null || true
    printf "\033[1;96m"
    cat <<'ART'
███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
ART
    printf "\033[1;95m  ═══════════════════════════════════════════════\033[0m\n"
    printf "\033[1;96m          N E X U S   H O S T\033[0m\n"
    printf "\033[1;93m     NEON SERVER COMMAND CENTER\033[0m\n"
    printf "\033[1;92m       By Kaidrix • NexusCloud Team\033[0m\n"
    printf "\033[1;95m  ═══════════════════════════════════════════════\033[0m\n\n"
}


ok()   { printf '  %s[ OK ]%s %s\n'   "$G" "$N" "$*"; }
warn() { printf '  %s[WARN]%s %s\n'   "$Y" "$N" "$*"; }
info() { printf '  %s[INFO]%s %s\n'   "$B" "$N" "$*"; }
die()  { printf '  %s[FAIL]%s %s\n'   "$R" "$N" "$*"; exit 1; }

spin() {
    local pid=$1 msg=$2 i=0 f='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s[%s]%s %s%s%s   ' "$M" "${f:i%4:1}" "$N" "$W" "$msg" "$N"
        i=$((i + 1)); sleep 0.15
    done
}

# run "message" command [args...]  -> spinner, logs to $LOG, aborts on error
run() {
    local msg=$1 pid rc; shift
    "$@" >>"$LOG" 2>&1 &
    pid=$!
    spin "$pid" "$msg"
    wait "$pid"; rc=$?
    printf '\r\033[K'
    if [ "$rc" -eq 0 ]; then
        ok "$msg"
    else
        printf '  %s[FAIL]%s %s\n' "$R" "$N" "$msg"
        echo "${R}  ---- last log lines ($LOG) ----${N}"
        tail -n 10 "$LOG"
        exit 1
    fi
}

ask() {                       # ask VAR "Prompt" "default"
    local __v=$1 p=$2 d=${3:-} in
    if [ -n "$d" ]; then
        printf '  %s>%s %s%s%s %s[%s]%s: ' "$M" "$N" "$W" "$p" "$N" "$Y" "$d" "$N"
    else
        printf '  %s>%s %s%s%s: ' "$M" "$N" "$W" "$p" "$N"
    fi
    read -r in
    printf -v "$__v" '%s' "${in:-$d}"
}

ask_secret() {                # ask_secret VAR "Prompt"
    local __v=$1 p=$2 in
    printf '  %s>%s %s%s%s: ' "$M" "$N" "$W" "$p" "$N"
    read -rs in; echo
    printf -v "$__v" '%s' "$in"
}

confirm() {
    local a
    while true; do
        printf '  %s?%s %s%s%s %s(y/n)%s: ' "$G" "$N" "$W" "$1" "$N" "$Y" "$N"
        read -r a
        case "$a" in [Yy]*) return 0 ;; [Nn]*) return 1 ;; esac
    done
}

pause() { printf '\n  %sPress ENTER to continue...%s' "$W" "$N"; read -r _; }

rand() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-24}"; }

# ---------------------------------------------------------------------
#  VALIDATION
# ---------------------------------------------------------------------
valid_fqdn()  { [[ $1 =~ ^([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$ ]]; }
valid_email() { [[ $1 =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; }
valid_user()  { [[ $1 =~ ^[A-Za-z0-9_.-]{3,30}$ ]]; }

# ---------------------------------------------------------------------
#  PRE-FLIGHT
# ---------------------------------------------------------------------
preflight() {
    [ "$EUID" -eq 0 ] || die "Run as root:  -i  then run again"
    [ -r /etc/os-release ] || die "Cannot detect OS"
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID=$ID; OS_VER=${VERSION_ID%%.*}; OS_CODE=${VERSION_CODENAME:-}
    case "$OS_ID" in
        ubuntu) [ "$OS_VER" -ge 22 ] || die "Ubuntu 22.04+ required (found $VERSION_ID)" ;;
        debian) [ "$OS_VER" -ge 11 ] || die "Debian 11+ required (found $VERSION_ID)" ;;
        *) die "Unsupported OS: $OS_ID (Ubuntu 22.04+/Debian 11+ only)" ;;
    esac
    case "$(uname -m)" in
        x86_64)  ARCH=amd64 ;;
        aarch64) ARCH=arm64 ;;
        *) die "Unsupported CPU architecture: $(uname -m)" ;;
    esac
    local ram; ram=$(free -m | awk '/Mem:/ {print $2}')
    [ "$ram" -ge 1800 ] || warn "Only ${ram}MB RAM - 2GB+ recommended"
    : >>"$LOG"; chmod 600 "$LOG"
    PUBLIC_IP=$(curl -4 -s --max-time 4 https://ipinfo.io/ip 2>/dev/null || true)
    [ -n "$PUBLIC_IP" ] || PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    TZ_NAME=$(timedatectl show --property=Timezone --value 2>/dev/null || echo UTC)
}

dns_check() {                 # dns_check domain
    local resolved
    resolved=$(getent ahostsv4 "$1" 2>/dev/null | awk 'NR==1{print $1}')
    if [ -z "$resolved" ]; then
        warn "$1 does not resolve yet"
    elif [ "$resolved" != "$PUBLIC_IP" ]; then
        warn "$1 -> $resolved but this server is $PUBLIC_IP"
    else
        ok "DNS OK: $1 -> $resolved"; return 0
    fi
    confirm "Continue anyway? (SSL will likely fail)" || exit 0
}

# ---------------------------------------------------------------------
#  SHARED STEPS
# ---------------------------------------------------------------------
s_apt_base() {
    set -e
    apt-get update -q
    apt-get install -y -q curl ca-certificates gnupg lsb-release tar unzip git cron openssl
}

s_install_certbot() { set -e; apt-get install -y -q certbot; }

s_docker() {
    set -e
    if ! command -v docker >/dev/null 2>&1; then
        curl -fsSL https://get.docker.com | CHANNEL=stable bash
    fi
    systemctl enable --now docker
}

# ---------------------------------------------------------------------
#  PANEL STEPS
# ---------------------------------------------------------------------
s_php_repo() {
    set -e
    if [ "$OS_ID" = ubuntu ]; then
        apt-get install -y -q software-properties-common
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    else
        curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor --yes -o /usr/share/keyrings/sury-php.gpg
        echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${OS_CODE} main" \
            > /etc/apt/sources.list.d/sury-php.list
    fi
    apt-get update -q
}

s_panel_packages() {
    set -e
    apt-get install -y -q "php${PHP_VER}" "php${PHP_VER}"-{cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} \
        mariadb-server nginx redis-server
    systemctl enable --now mariadb redis-server "php${PHP_VER}-fpm" nginx
}

s_composer() {
    set -e
    curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
}

s_panel_download() {
    set -e
    mkdir -p "$PANEL_DIR"; cd "$PANEL_DIR"
    curl -fsSL -o panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzf panel.tar.gz
    rm -f panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
}

s_panel_db() {
    set -e
    mariadb -e "CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;"
}

set_env() {                   # set_env KEY VALUE
    local k=$1 v=$2 f="$PANEL_DIR/.env"
    v=${v//\\/\\\\}; v=${v//&/\\&}; v=${v//|/\\|}
    if grep -q "^${k}=" "$f"; then sed -i "s|^${k}=.*|${k}=${v}|" "$f"
    else echo "${k}=${v}" >>"$f"; fi
}

s_composer_install() {
    set -e
    cd "$PANEL_DIR"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction
}

s_panel_env() {
    set -e
    cd "$PANEL_DIR"
    php artisan key:generate --force
    set_env APP_NAME      "\"${BRAND}\""
    set_env APP_URL       "\"${APP_URL}\""
    set_env APP_TIMEZONE  "$TZ_NAME"
    set_env APP_ENVIRONMENT_ONLY false
    set_env DB_HOST 127.0.0.1;  set_env DB_PORT 3306
    set_env DB_DATABASE panel;  set_env DB_USERNAME pterodactyl
    set_env DB_PASSWORD "$DB_PASS"
    set_env CACHE_DRIVER redis; set_env SESSION_DRIVER redis; set_env QUEUE_CONNECTION redis
    set_env REDIS_HOST 127.0.0.1; set_env REDIS_PORT 6379
    set_env RECAPTCHA_ENABLED false
    set_env PTERODACTYL_TELEMETRY_ENABLED false
    php artisan migrate --seed --force
    php artisan p:user:make --email="$EMAIL" --username="$ADMIN_USER" \
        --name-first=Nexus --name-last=Admin --password="$ADMIN_PASS" --admin=1
    php artisan config:cache
    chown -R www-data:www-data "$PANEL_DIR"
}

s_panel_services() {
    set -e
    echo "* * * * * www-data /usr/bin/php ${PANEL_DIR}/artisan schedule:run >> /dev/null 2>&1" \
        > /etc/cron.d/nexuscloud-panel
    chmod 644 /etc/cron.d/nexuscloud-panel
    cat >/etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php ${PANEL_DIR}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now pteroq.service
}

nginx_php_block() {
    cat <<EOF
    root ${PANEL_DIR}/public;
    index index.php;
    charset utf-8;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
EOF
}

write_nginx() {               # write_nginx http | ssl CERT KEY
    local f=/etc/nginx/sites-available/pterodactyl.conf
    {
        if [ "$1" = ssl ]; then
            cat <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    location /.well-known/acme-challenge/ { root ${PANEL_DIR}/public; }
    location / { return 301 https://\$host\$request_uri; }
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    ssl_certificate ${2};
    ssl_certificate_key ${3};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
$(nginx_php_block)
}
EOF
        else
            cat <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
$(nginx_php_block)
}
EOF
        fi
    } >"$f"
    rm -f /etc/nginx/sites-enabled/default
    ln -sf "$f" /etc/nginx/sites-enabled/pterodactyl.conf
    nginx -t
    systemctl reload nginx
}

s_selfsigned() {
    set -e
    mkdir -p /etc/certs/panel
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/C=NA/ST=NA/L=NA/O=${BRAND}/CN=${DOMAIN}" \
        -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem
    write_nginx ssl /etc/certs/panel/fullchain.pem /etc/certs/panel/privkey.pem
}

s_nginx_http() { set -e; write_nginx http; }

s_certbot_panel() {
    set -e
    certbot certonly --webroot -w "${PANEL_DIR}/public" -d "$DOMAIN" \
        --non-interactive --agree-tos -m "$EMAIL"
    write_nginx ssl "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
}

# ---------------------------------------------------------------------
#  PANEL FLOW
# ---------------------------------------------------------------------
panel_collect() {
    box "PANEL SETUP"
    ask DOMAIN "Panel domain (e.g. panel.example.com)"
    until valid_fqdn "$DOMAIN"; do warn "Invalid domain"; ask DOMAIN "Panel domain"; done
    ask EMAIL "Admin email"
    until valid_email "$EMAIL"; do warn "Invalid email"; ask EMAIL "Admin email"; done
    ask ADMIN_USER "Admin username" "admin"
    until valid_user "$ADMIN_USER"; do warn "3-30 chars: letters, numbers . _ -"; ask ADMIN_USER "Admin username" "admin"; done
    while true; do
        ask_secret ADMIN_PASS "Admin password (blank = random)"
        [ -z "$ADMIN_PASS" ] && { ADMIN_PASS=$(rand 20); break; }
        [ "${#ADMIN_PASS}" -ge 8 ] && break
        warn "Minimum 8 characters"
    done
    echo
    echo "  ${W}SSL mode:${N}"
    echo "   ${G}1${N}) Let's Encrypt  ${C}(domain must point here)${N}"
    echo "   ${G}2${N}) Self-signed    ${C}(browser warning)${N}"
    echo "   ${G}3${N}) None / HTTP    ${C}(behind Cloudflare or a proxy)${N}"
    ask SSL_CHOICE "Choose" "1"
    case "$SSL_CHOICE" in 2) SSL_MODE=selfsigned ;; 3) SSL_MODE=none ;; *) SSL_MODE=letsencrypt ;; esac
    [ "$SSL_MODE" = none ] && APP_URL="http://${DOMAIN}" || APP_URL="https://${DOMAIN}"
    DB_PASS=$(rand 24)

    box "REVIEW"
    row "Domain"   "$DOMAIN"
    row "Admin"    "$ADMIN_USER <$EMAIL>"
    row "SSL"      "$SSL_MODE"
    row "PHP"      "$PHP_VER"
    row "Install"  "nginx mariadb redis composer"
    row "Server"   "$PUBLIC_IP"
    hline
    confirm "Start installation?" || exit 0
    [ "$SSL_MODE" = letsencrypt ] && dns_check "$DOMAIN"
}

install_panel() {
    [ -f "$PANEL_DIR/.env" ] && die "Panel already exists in $PANEL_DIR (refusing to overwrite)"
    panel_collect
    box "INSTALLING PANEL"
    run "Base packages"            s_apt_base
    run "PHP repository"           s_php_repo
    run "PHP, MariaDB, NGINX, Redis" s_panel_packages
    run "Composer"                 s_composer
    run "Downloading panel"        s_panel_download
    run "Creating database"        s_panel_db
    run "PHP dependencies"         s_composer_install
    run "Configuring + migrating"  s_panel_env
    run "Queue worker + cron"      s_panel_services
    case "$SSL_MODE" in
        none)       run "NGINX (HTTP)"         s_nginx_http ;;
        selfsigned) run "Self-signed SSL"      s_selfsigned ;;
        letsencrypt)
            run "NGINX (HTTP bootstrap)" s_nginx_http
            run "Installing certbot"     s_install_certbot
            if ! run_soft "Let's Encrypt certificate" s_certbot_panel; then
                warn "Let's Encrypt failed - falling back to self-signed"
                run "Self-signed SSL" s_selfsigned
                SSL_MODE=selfsigned
            fi ;;
    esac
    PANEL_DONE=1
    save_creds
    panel_summary
}

run_soft() {                  # like run, but returns 1 instead of exiting
    local msg=$1 pid rc; shift
    "$@" >>"$LOG" 2>&1 &
    pid=$!; spin "$pid" "$msg"; wait "$pid"; rc=$?
    printf '\r\033[K'
    if [ "$rc" -eq 0 ]; then ok "$msg"; else printf '  %s[FAIL]%s %s\n' "$R" "$N" "$msg"; fi
    return "$rc"
}

save_creds() {
    umask 077
    {
        echo "# ${BRAND} panel credentials - $(date -u +%FT%TZ)"
        echo "URL=${APP_URL}"
        echo "ADMIN_USER=${ADMIN_USER}"
        echo "ADMIN_EMAIL=${EMAIL}"
        echo "ADMIN_PASS=${ADMIN_PASS}"
        echo "DB_USER=pterodactyl"
        echo "DB_PASS=${DB_PASS}"
    } >"$CRED_FILE"
}

panel_summary() {
    box "PANEL READY"
    row "URL"       "$APP_URL"
    row "Username"  "$ADMIN_USER"
    row "Password"  "$ADMIN_PASS"
    row "Email"     "$EMAIL"
    row "DB user"   "pterodactyl"
    row "DB pass"   "$DB_PASS"
    hline
    info "Credentials saved to ${CRED_FILE} (chmod 600)"
    info "Set up mail in Admin > Settings > Mail (none configured)"
    [ "$SSL_MODE" = selfsigned ] && warn "Self-signed cert: browsers will show a warning"
}

# ---------------------------------------------------------------------
#  WINGS
# ---------------------------------------------------------------------
s_wings_binary() {
    set -e
    mkdir -p /etc/pterodactyl
    curl -fsSL -o /usr/local/bin/wings \
        "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}"
    chmod u+x /usr/local/bin/wings
}

s_wings_service() {
    set -e
    cat >/etc/systemd/system/wings.service <<'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable wings
}

s_certbot_node() {
    set -e
    local pre=() 
    if systemctl is-active --quiet nginx; then
        pre=(--pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx")
    fi
    certbot certonly --standalone -d "$NODE_FQDN" --non-interactive --agree-tos \
        -m "$NODE_EMAIL" "${pre[@]}"
}

install_wings() {
    box "WINGS SETUP"
    echo "  ${W}Node SSL:${N}"
    echo "   ${G}1${N}) Let's Encrypt for the node domain"
    echo "   ${G}2${N}) Skip ${C}(I will provide certificates myself)${N}"
    ask NODE_SSL "Choose" "1"
    NODE_FQDN=""; NODE_EMAIL=""
    if [ "$NODE_SSL" != 2 ]; then
        ask NODE_FQDN "Node domain (e.g. node1.example.com)"
        until valid_fqdn "$NODE_FQDN"; do warn "Invalid domain"; ask NODE_FQDN "Node domain"; done
        ask NODE_EMAIL "Email for Let's Encrypt"
        until valid_email "$NODE_EMAIL"; do warn "Invalid email"; ask NODE_EMAIL "Email"; done
        dns_check "$NODE_FQDN"
    fi
    box "REVIEW"
    row "Docker"  "install if missing"
    row "Wings"   "latest (${ARCH})"
    row "Node SSL" "${NODE_FQDN:-skipped}"
    hline
    confirm "Start installation?" || exit 0

    box "INSTALLING WINGS"
    run "Base packages"   s_apt_base
    run "Docker Engine"   s_docker
    run "Wings binary"    s_wings_binary
    run "Wings service"   s_wings_service
    if [ -n "$NODE_FQDN" ]; then
        run "Installing certbot" s_install_certbot
        run_soft "Node certificate" s_certbot_node \
            || warn "Certificate failed - see $LOG. Port 80 must be free and DNS correct."
    fi
    box "WINGS INSTALLED"
    row "Binary"   "/usr/local/bin/wings"
    row "Config"   "/etc/pterodactyl/config.yml"
    row "Service"  "wings (enabled, not started)"
    [ -n "$NODE_FQDN" ] && [ -d "/etc/letsencrypt/live/$NODE_FQDN" ] && {
        row "Cert"   "/etc/letsencrypt/live/$NODE_FQDN/fullchain.pem"
        row "Key"    "/etc/letsencrypt/live/$NODE_FQDN/privkey.pem"
    }
    hline
    info "Next: create a node in the panel, then run:  bash nexus.sh link"
}

s_wings_configure() {
    set -e
    cd /etc/pterodactyl
    /usr/local/bin/wings configure --panel-url "$LINK_URL" --token "$LINK_TOKEN" --node "$LINK_NODE"
}

link_wings() {
    [ -x /usr/local/bin/wings ] || die "Wings is not installed - run option 2 first"
    box "LINK WINGS TO PANEL"
    info "Panel > Admin > Nodes > (your node) > Configuration"
    info "Copy the three values from the auto-deploy command"
    ask LINK_URL "Panel URL (https://panel.example.com)"
    [[ $LINK_URL =~ ^https?://[A-Za-z0-9.:-]+$ ]] || die "Invalid panel URL"
    ask LINK_NODE "Node ID" "1"
    [[ $LINK_NODE =~ ^[0-9]+$ ]] || die "Node ID must be a number"
    ask_secret LINK_TOKEN "Token (--token value, hidden)"
    [[ $LINK_TOKEN =~ ^[A-Za-z0-9_-]+$ ]] || die "Invalid token"
    run "Writing config.yml"   s_wings_configure
    run "Starting Wings"       systemctl restart wings
    ok "Wings is running - check the node heart icon in the panel"
}

# ---------------------------------------------------------------------
#  STATUS
# ---------------------------------------------------------------------
svc() {
    if ! systemctl list-unit-files "$1.service" 2>/dev/null | grep -q "$1.service"; then
        row_c "$1" "not installed" "$Y"
    elif systemctl is-active --quiet "$1"; then
        row_c "$1" "ACTIVE" "$G"
    else
        row_c "$1" "INACTIVE" "$R"
    fi
}

show_status() {
    box "SYSTEM STATUS"
    row "Host"   "$(hostname)"
    row "IP"     "${PUBLIC_IP:-unknown}"
    row "OS"     "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
    row "RAM"    "$(free -m | awk '/Mem:/ {printf "%d / %d MB", $3, $2}')"
    row "Disk"   "$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    hline
    for s in nginx mariadb redis-server "php${PHP_VER}-fpm" pteroq docker wings; do svc "$s"; done
    hline
    [ -f "$PANEL_DIR/.env" ] && info "Panel: $(grep '^APP_URL=' "$PANEL_DIR/.env" | cut -d= -f2- | tr -d '"')"
    return 0
}

# ---------------------------------------------------------------------
#  MENU
# ---------------------------------------------------------------------
nexus_splash() {
    clear 2>/dev/null || true
    printf '\033[?25l'
    trap 'printf "\033[?25h"; exit 130' INT TERM

    printf '\033[1;96m'
    cat <<'ART'
███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
ART
    printf '\033[0m\n'
    printf '  \033[1;95mN E X U S   H O S T\033[0m\n'
    printf '  \033[1;96mDevelopers:\033[0m \033[1;92mKaidrix\033[0m \033[1;95m•\033[0m \033[1;93mNexusCloud Team\033[0m\n'
    printf '  \033[1;95mBOOTING SYSTEM \033[0m['

    local i
    for ((i=0; i<28; i++)); do
        case $((i % 4)) in
            0) printf '\033[1;96m█\033[0m' ;;
            1) printf '\033[1;95m█\033[0m' ;;
            2) printf '\033[1;93m█\033[0m' ;;
            3) printf '\033[1;92m█\033[0m' ;;
        esac
        sleep 0.035
    done
    printf '] \033[1;92mONLINE\033[0m\n'

    for i in 1 2 3; do
        printf '\033[1;91m  >> NEXUS HOST // SYSTEM READY <<\033[0m\r'
        sleep 0.06
        printf '\033[1;96m  >> NEXUS HOST // SYSTEM READY <<\033[0m\r'
        sleep 0.06
    done

    printf '\033[?25h\n'
    trap - INT TERM
    sleep 0.15
    clear 2>/dev/null || true
}


launch_hub_feature() {
    local path="$1"
    local root encoded tmpfile

    root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$root/$path" ]]; then
        bash "$root/$path"
        return
    fi

    encoded="${path// /%20}"
    tmpfile="$(mktemp)"

    if ! curl -fsSL "${REPO_RAW}/${encoded}" -o "$tmpfile"; then
        printf '\033[1;91mCould not download:\033[0m %s\n' "$path"
        rm -f "$tmpfile"
        return 1
    fi

    bash "$tmpfile"
    local result=$?
    rm -f "$tmpfile"
    return "$result"
}

menu() {
    local choice ram disk uptime_text

    while true; do
        banner

        ram="$(free -m 2>/dev/null | awk '/Mem:/ {if ($2>0) printf "%d%%", $3/$2*100}')"
        disk="$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')"
        uptime_text="$(uptime -p 2>/dev/null | sed 's/^up //')"

        printf '\n \033[1;96m╔════════════════════════════╦════════════════════════════╗\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;95m      CORE INSTALLER       \033[0m\033[1;96m║\033[0m \033[1;94m     MANAGERS & EXTRAS     \033[0m\033[1;96m║\033[0m\n'
        printf ' \033[1;96m╠════════════════════════════╬════════════════════════════╣\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[1]\033[0m Install Panel            \033[1;96m║\033[0m \033[1;93m[7]\033[0m Panel Manager           \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[2]\033[0m Install Wings            \033[1;96m║\033[0m \033[1;93m[8]\033[0m Wings Manager           \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[3]\033[0m Panel + Wings            \033[1;96m║\033[0m \033[1;93m[9]\033[0m Toolbox                 \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[4]\033[0m Link Wings to Panel      \033[1;96m║\033[0m \033[1;93m[10]\033[0m Themes & Extensions    \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[5]\033[0m System Status            \033[1;96m║\033[0m \033[1;93m[11]\033[0m VM Manager             \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[6]\033[0m Open Master Hub          \033[1;96m║\033[0m \033[1;93m[12]\033[0m Extras                 \033[1;96m║\033[0m\n'
        printf ' \033[1;96m╠════════════════════════════╩════════════════════════════╣\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;92mRAM:\033[0m %-5s  \033[1;92mDISK:\033[0m %-5s  \033[1;92mUP:\033[0m %-19.19s \033[1;96m║\033[0m\n' \
            "${ram:-N/A}" "${disk:-N/A}" "${uptime_text:-unknown}"
        printf ' \033[1;96m╠════════════════════════════════════════════════════════╣\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;91m[0] Exit\033[0m      \033[1;95mChoose an option from 0 to 12\033[0m             \033[1;96m║\033[0m\n'
        printf ' \033[1;96m╚════════════════════════════════════════════════════════╝\033[0m\n\n'
        printf ' \033[1;95m➜\033[0m \033[1;97mYour choice:\033[0m '
        read -r choice || choice=0

        case "$choice" in
            1) install_panel; pause ;;
            2) install_wings; pause ;;
            3) install_panel; install_wings; pause ;;
            4) link_wings; pause ;;
            5) show_status; pause ;;
            6) launch_hub_feature "menu/UI.sh"; pause ;;
            7) launch_hub_feature "panel/1.sh"; pause ;;
            8) launch_hub_feature "wings/run.sh"; pause ;;
            9) launch_hub_feature "toolbox/run.sh"; pause ;;
            10) launch_hub_feature "thame/run.sh"; pause ;;
            11) launch_hub_feature "setup vm/menu.sh"; pause ;;
            12) launch_hub_feature "Extras/run.sh"; pause ;;
            0|exit|quit)
                printf '\033[1;96mGoodbye from Nexus Host!\033[0m\n'
                exit 0
                ;;
            *)
                printf '\033[1;91mInvalid option. Choose 0–12.\033[0m\n'
                sleep 1
                ;;
        esac
    done
}

main() {
    case "${1:-menu}" in
        status) PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}'); banner; show_status ;;
        panel)  preflight; banner; install_panel ;;
        wings)  preflight; banner; install_wings ;;
        both)   preflight; banner; install_panel; install_wings ;;
        link)   preflight; banner; link_wings ;;
        menu)   nexus_splash; preflight; menu ;;
        *) echo "Usage: $0 [panel|wings|both|link|status]"; exit 1 ;;
    esac
}

main "$@"
