#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
CRED_FILE=/run/secrets/credentials
WP_ADMIN_PASSWORD=$(grep WORDPRESS_ADMIN_PASSWORD "$CRED_FILE" | cut -d '=' -f2)
WP_USER_PASSWORD=$(grep WORDPRESS_USER_PASSWORD "$CRED_FILE" | cut -d '=' -f2)

if [ ! -f "/usr/local/bin/wp" ]; then
    curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "[setup_wp] Downloading WordPress core..."
    wp core download --allow-root

    echo "[setup_wp] Waiting for MariaDB to be reachable..."
    until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
        sleep 1
    done

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    chown -R www-data:www-data /var/www/html
    echo "[setup_wp] WordPress installed."
fi

echo "[setup_wp] Starting php-fpm in foreground (PID 1)..."
exec php-fpm8.2 -F
