#!/bin/sh
set -e

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out    /etc/nginx/ssl/nginx.crt \
        -subj "/C=ES/ST=Barcelona/L=Barcelona/O=42Barcelona/OU=inception/CN=${DOMAIN_NAME}"
fi

envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

exec nginx -g "daemon off;"
