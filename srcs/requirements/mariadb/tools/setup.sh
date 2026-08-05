#!/bin/bash

# Create the MySQL runtime directory and set the correct permissions
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Read secure passwords from the Docker secrets files
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Check if the database already exists; if not, initialize and configure it
if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Create a temporary file with the initial SQL configuration commands
    cat << EOF > /tmp/create_db.sql
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Execute the SQL script in bootstrap mode to configure MariaDB without launching the full server
    mysqld --user=mysql --bootstrap < /tmp/create_db.sql
    rm -f /tmp/create_db.sql
fi

# Start the MariaDB server in the foreground as the container's main process
exec mysqld --user=mysql