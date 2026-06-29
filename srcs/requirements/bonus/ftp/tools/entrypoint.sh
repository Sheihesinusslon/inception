#!/bin/sh
set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# Render the config from the template using values from the environment.
envsubst '${FTP_PASV_MIN} ${FTP_PASV_MAX} ${FTP_PASV_ADDRESS}' \
    < /etc/vsftpd/vsftpd.conf.template \
    > /etc/vsftpd/vsftpd.conf

# Create the FTP user with the shared WordPress volume as its home, if missing.
if ! id "${FTP_USER}" >/dev/null 2>&1; then
    adduser -D -h /var/www/html -s /sbin/nologin "${FTP_USER}"
fi
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

# Only this user may log in over FTP.
echo "${FTP_USER}" > /etc/vsftpd/user_list

# vsftpd needs this directory for privilege separation in chroot mode.
mkdir -p /var/run/vsftpd/empty

# Give the FTP user ownership and the WordPress group (nobody) write access,
# so both FTP uploads and WordPress runtime writes work on the shared volume.
chown -R "${FTP_USER}":nobody /var/www/html
chmod -R g+rwX /var/www/html

exec vsftpd /etc/vsftpd/vsftpd.conf