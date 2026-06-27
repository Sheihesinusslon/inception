FROM alpine:3.23

RUN apk add --no-cache nginx openssl gettext

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
