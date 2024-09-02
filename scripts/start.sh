#!/bin/sh
# Start the Docker daemon
dockerd-entrypoint.sh &

# Start the SSH server
/usr/sbin/sshd &

# Join the ZeroTier network
/usr/local/bin/join-zerotier.sh

# Wait indefinitely to keep the container running
tail -f /dev/null
