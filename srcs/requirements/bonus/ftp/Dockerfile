FROM alpine:3.23

RUN apk add --no-cache vsftpd gettext

COPY conf/vsftpd.conf.template /etc/vsftpd/vsftpd.conf.template
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 21 21000-21010

ENTRYPOINT ["/entrypoint.sh"]
