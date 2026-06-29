#!/bin/sh
set -e

# Netdata is zero-config: it serves a live dashboard immediately, with no
# login or first-run wizard. -D runs it in the foreground (PID 1) and
# -p sets the listen port from the environment.
exec netdata -D -p "${NETDATA_PORT:-19999}"