FROM alpine:3.20

RUN apk add --no-cache redis gettext

COPY conf/redis.conf.template /etc/redis/redis.conf.template
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 6379

ENTRYPOINT ["/entrypoint.sh"]
