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
        --url="https://${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --path=/var/www/html \
        --allow-root

    echo "Criando utilizador normal (autor)..."
    wp user create \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --path=/var/www/html \
        --allow-root

    echo "WordPress instalado e configurado com sucesso!"
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F