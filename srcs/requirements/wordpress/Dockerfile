FROM alpine:3.20

RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-pdo \
    php83-pdo_mysql \
    php83-phar \
    php83-ctype \
    php83-tokenizer \
    php83-opcache \
    php83-redis \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-gd \
    php83-iconv \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-xmlreader \
    php83-zip \
    php83-json \
    mariadb-client \
    wget

RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -O /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/php.ini /etc/php83/conf.d/99-custom.ini
COPY tools/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 9000

ENTRYPOINT ["/setup.sh"]
