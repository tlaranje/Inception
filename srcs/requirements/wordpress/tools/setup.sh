#!/bin/bash
set -e

mkdir -p /run/php
cd /var/www/html

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

echo "Aguardando o MariaDB inicializar..."
until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    sleep 2
done

echo "MariaDB está operacional!"

SITE_PORT="${SITE_PORT:-443}"
SITE_URL="https://${DOMAIN_NAME}"

if [ ! -f /var/www/html/wp-config.php ]; then

    echo "Descarregando o WordPress..."
    wp core download --allow-root --path=/var/www/html

    echo "Criando o wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --path=/var/www/html \
        --allow-root

    echo "Instalando o WordPress..."
    wp core install \
        --url="${SITE_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --path=/var/www/html \
        --allow-root

    mkdir -p /var/www/html/wp-content/themes/twentytwentyfive/patterns
    cp /tmp/header.php /var/www/html/wp-content/themes/twentytwentyfive/patterns/header.php

    echo "Criando utilizador normal (autor)..."
    wp user create \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --path=/var/www/html \
        --allow-root

    echo "Adicionando link de login à página inicial..."
    HOME_ID=$(wp option get page_on_front --path=/var/www/html --allow-root)
    if [ -z "$HOME_ID" ] || [ "$HOME_ID" = "0" ]; then
        HOME_ID=$(wp post list --post_type=post --posts_per_page=1 --field=ID --path=/var/www/html --allow-root)
    fi
    CURRENT_CONTENT=$(wp post get "$HOME_ID" --field=post_content --path=/var/www/html --allow-root)
    wp post update "$HOME_ID" \
        --post_content="${CURRENT_CONTENT}<p><a href=\"${SITE_URL}/wp-login.php\">Login</a></p>" \
        --path=/var/www/html \
        --allow-root

    echo "WordPress instalado e configurado com sucesso!"
fi

echo "Sincronizando siteurl/home com a porta atual (${SITE_PORT})..."
wp option update siteurl "${SITE_URL}" --path=/var/www/html --allow-root
wp option update home "${SITE_URL}" --path=/var/www/html --allow-root

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F