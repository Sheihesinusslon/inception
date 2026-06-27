#!/bin/sh
set -e

envsubst '${REDIS_PORT} ${REDIS_MAXMEMORY} ${REDIS_MAXMEMORY_POLICY}' \
    < /etc/redis/redis.conf.template \
    > /etc/redis/redis.conf

exec redis-server /etc/redis/redis.conf
