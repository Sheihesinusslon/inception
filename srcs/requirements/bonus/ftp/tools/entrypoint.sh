#!/bin/sh
set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

envsubst '${FTP_PASV_MIN} ${FTP_PASV_MAX} ${FTP_PASV_ADDRESS}' \
    < /etc/vsftpd/vsftpd.conf.template \
    > /etc/vsftpd/vsftpd.conf

if ! id "${FTP_USER}" >/dev/null 2>&1; then
    adduser -D -h /var/www/html -s /sbin/nologin "${FTP_USER}"
fi
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

echo "${FTP_USER}" > /etc/vsftpd/user_list

mkdir -p /var/run/vsftpd/empty

chown -R "${FTP_USER}":nobody /var/www/html
chmod -R g+rwX /var/www/html

exec vsftpd /etc/vsftpd/vsftpd.conf