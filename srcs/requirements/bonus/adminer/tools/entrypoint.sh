#!/bin/sh
set -e

# Serve Adminer with PHP's built-in web server on the configured port.
exec php -S "0.0.0.0:${ADMINER_PORT:-8081}" -t /var/www