#!/bin/sh
set -e

exec netdata -D -p "${NETDATA_PORT:-19999}"