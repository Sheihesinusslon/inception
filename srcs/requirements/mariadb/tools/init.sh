#!/bin/sh
set -e

# First-time initialisation only
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db

    # Start temporarily without networking for secure setup
    mysqld --user=mysql --skip-networking &
    MYSQL_PID=$!

    # Wait until server is ready
    until mysqladmin ping -h localhost --silent 2>/dev/null; do
        sleep 0.2
    done

    DB_PASSWORD=$(cat /run/secrets/db_password)
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    kill "$MYSQL_PID"
    wait "$MYSQL_PID"
fi

# Replace shell → mysqld becomes PID 1
exec mysqld --user=mysql
