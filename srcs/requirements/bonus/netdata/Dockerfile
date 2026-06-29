FROM alpine:3.23

RUN apk add --no-cache netdata

COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 19999

ENTRYPOINT ["/entrypoint.sh"]