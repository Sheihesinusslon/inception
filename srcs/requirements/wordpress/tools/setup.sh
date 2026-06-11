#!/bin/sh
set -e

mkdir -p /var/www/html
cd /var/www/html

# Only install on first run (volume empty)
if [ ! -f wp-config.php ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    WP_ADMIN_PASS=$(sed -n '1p' /run/secrets/credentials)
    WP_USER_PASS=$(sed -n '2p'  /run/secrets/credentials)

    wp core download --allow-root --locale=en_US

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb:3306

    # Redis object cache constants
    wp config set --allow-root WP_REDIS_HOST redis
    wp config set --allow-root WP_REDIS_PORT 6379 --raw

    # Wait for MariaDB to accept connections before installing
    until wp db check --allow-root 2>/dev/null; do
        sleep 1
    done

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

# Replace shell → php-fpm becomes PID 1
exec php-fpm83 -F
