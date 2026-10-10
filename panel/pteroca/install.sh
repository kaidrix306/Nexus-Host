#!/bin/bash
# NexusCloud shared UI (bright colours, ASCII boxes)
_nx_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
for _nx_p in "$_nx_d/lib" "$_nx_d/../lib" "$_nx_d/../../lib"; do [ -f "$_nx_p/ui.sh" ] && { source "$_nx_p/ui.sh"; break; }; done
type nx_banner >/dev/null 2>&1 || source <(curl -fsSL "https://raw.githubusercontent.com/YOUR_GITHUB_USER/nexuscloud/main/lib/ui.sh")
nx_banner "PANEL > PTEROCA > INSTALL"

GREEN="\e[1;92m"; BLUE="\e[1;94m"; RED="\e[1;91m"; RESET="\e[0m"

set -e

echo -e "${GREEN}===  PteroCA Installer ===${RESET}"

read -p "Enter domain [panel.example.com]: " DOMAIN
DOMAIN=${DOMAIN:-panel.example.com}
set -e
# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive
echo "Updating system..."
apt update -y && apt upgrade -y
echo "Installing required packages..."
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release
echo "Adding PHP repository..."
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
echo "Adding universe repository..."
add-apt-repository -y universe
echo "Updating repositories..."
apt update -y
echo "Installing PHP, MariaDB, Nginx and dependencies..."
apt -y install php8.2 php8.2-{cli,ctype,iconv,mysql,pdo,mbstring,tokenizer,bcmath,xml,intl,fpm,curl,zip} mariadb-server nginx tar unzip git
echo "Installation completed successfully!"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
rm -rf /var/www/pteroca
mkdir -p /var/www/pteroca && cd /var/www/pteroca
git clone https://github.com/PteroCA-Org/panel.git /var/www/pteroca
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
COMPOSER_ALLOW_SUPERUSER=1 composer require pteroca-com/pterodactyl-addon -n
chown -R www-data:www-data /var/www/pteroca/var/ /var/www/pteroca/public/uploads/
chmod -R 775 /var/www/pteroca/var/ /var/www/pteroca/public/uploads/
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pteroca/bin/console pteroca:cron:schedule >> /dev/null 2>&1") | crontab -
DB_NAME=pteroca
DB_USER=pterocauser
DB_PASS=1234
mariadb -e "DROP DATABASE IF EXISTS ${DB_NAME};"
mariadb -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';"
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"
cd /var/www/pteroca
php bin/console pteroca:system:configure-database
php bin/console doctrine:migrations:migrate --no-interaction
mkdir -p /etc/certs/pteroca
cd /etc/certs/pteroca
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem
cat > /etc/nginx/sites-available/pteroca.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate /etc/certs/pteroca/fullchain.pem;
    ssl_certificate_key /etc/certs/pteroca/privkey.pem;

    root /var/www/pteroca/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
EOF
ln -s /etc/nginx/sites-available/pteroca.conf /etc/nginx/sites-enabled/pteroca.conf || true
nginx -t && systemctl restart nginx
sudo chown -R www-data:www-data /var/www/pteroca
sudo chmod -R 755 /var/www/pteroca
cd /var/www/pterodactyl
COMPOSER_ALLOW_SUPERUSER=1 composer require pteroca-com/pterodactyl-addon -n
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:clear
php artisan cache:clear
php artisan queue:restart
chown -R www-data:www-data /var/www/pterodactyl/*
cd /var/www/pteroca
php bin/console pteroca:system:configure
