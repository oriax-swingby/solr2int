#!/bin/bash
set -e

/usr/sbin/sshd

exec /entrypoint.sh "$@"
