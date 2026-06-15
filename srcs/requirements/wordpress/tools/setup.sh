#!/bin/sh
set -e

mkdir -p /var/www/html
cd /var/www/html

DB_PASSWORD=$(cat /run/secrets/db_password)

# Download core only if not already present
if [ ! -f wp-load.php ]; then
    wp core download --allow-root --locale=en_US
fi

# Create config only if missing (--skip-check: DB may not be up yet)
if [ ! -f wp-config.php ]; then
    wp config create --allow-root --skip-check \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb:3306

    wp config set --allow-root WP_REDIS_HOST redis
    wp config set --allow-root WP_REDIS_PORT 6379 --raw
fi

# Wait for MariaDB to accept connections
until mariadb-admin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
    sleep 1
done

# Install site and users only once
if ! wp core is-installed --allow-root 2>/dev/null; then
    WP_ADMIN_PASS=$(sed -n '1p' /run/secrets/credentials)
    WP_USER_PASS=$(sed -n '2p'  /run/secrets/credentials)

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASS}" \
        --role=author

    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
fi

exec php-fpm83 -F
