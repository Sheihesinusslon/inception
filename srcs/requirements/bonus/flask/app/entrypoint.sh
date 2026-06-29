#!/bin/sh
set -e

exec gunicorn \
    --bind "0.0.0.0:${FLASK_PORT:-8080}" \
    --workers 2 \
    app:app