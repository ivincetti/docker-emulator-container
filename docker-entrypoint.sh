#!/bin/sh
set -e

# forward adb port
for ip in $(hostname -I); do
    socat tcp-listen:5555,bind=${ip},fork tcp:127.0.0.1:5555 &
done

exec "$@"
