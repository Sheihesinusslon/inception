FROM alpine:3.20

RUN apk add --no-cache mariadb mariadb-client

# Override the distro default (its only active setting is skip-networking)
COPY conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

EXPOSE 3306

ENTRYPOINT ["/init.sh"]
