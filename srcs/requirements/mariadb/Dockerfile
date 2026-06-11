FROM alpine:3.20

RUN apk add --no-cache mariadb mariadb-client

COPY conf/50-server.cnf /etc/my.cnf.d/50-server.cnf
COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

EXPOSE 3306

ENTRYPOINT ["/init.sh"]
