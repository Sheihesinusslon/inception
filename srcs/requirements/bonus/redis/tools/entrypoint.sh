#!/bin/sh
set -e

# Render redis.conf from env every start so REDIS_* settings in .env
# take effect without rebuilding the image.
envsubst '${REDIS_PORT} ${REDIS_MAXMEMORY} ${REDIS_MAXMEMORY_POLICY}' \
    < /etc/redis/redis.conf.template \
    > /etc/redis/redis.conf

exec redis-server /etc/redis/redis.conf
