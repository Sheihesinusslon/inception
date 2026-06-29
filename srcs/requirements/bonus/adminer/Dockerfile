FROM alpine:3.23

RUN apk add --no-cache \
    php83 \
    php83-session \
    php83-mysqli \
    php83-pdo \
    php83-pdo_mysql \
    wget

RUN ln -sf /usr/bin/php83 /usr/bin/php

RUN mkdir -p /var/www \
    && wget -q "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" \
        -O /var/www/index.php

COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8081

ENTRYPOINT ["/entrypoint.sh"]