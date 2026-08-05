#!/bin/bash
set -e

# Create the PHP runtime directory and switch to the web root
mkdir -p /run/php
cd /var/www/html

# Read secure passwords from Docker secrets files
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Wait until the MariaDB service is fully operational
until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    sleep 2
done


SITE_URL="https://${DOMAIN_NAME}"

# Check if WordPress is not yet installed by looking for the configuration file
if [ ! -f /var/www/html/wp-config.php ]; then

    # Download core WordPress files
    wp core download --allow-root --path=/var/www/html

    # Generate the wp-config.php file using database credentials
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --path=/var/www/html \
        --allow-root

    # Run standard WordPress installation with administrator details
    wp core install \
        --url="${SITE_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --path=/var/www/html \
        --allow-root

    # Create directories and copy custom theme patterns for WordPress
    mkdir -p /var/www/html/wp-content/themes/twentytwentyfive/patterns
    cp /tmp/header.php /var/www/html/wp-content/themes/twentytwentyfive/patterns/header.php

    # Create a regular user account with author permissions
    wp user create \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --path=/var/www/html \
        --allow-root
fi

# Update core site URLs to ensure consistency
wp option update siteurl "${SITE_URL}" --path=/var/www/html --allow-root
wp option update home "${SITE_URL}" --path=/var/www/html --allow-root

# Set correct ownership permissions for the web server
chown -R www-data:www-data /var/www/html

# Start the PHP-FPM service in the foreground as the container's main process
exec php-fpm8.2 -F
