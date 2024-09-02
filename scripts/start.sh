#!/bin/sh
# Start the Docker service
service docker start

# Start the SSH server
/usr/sbin/sshd

zerotier-one -d
zerotier-cli join $ZT_NETWORK_ID

# Wait indefinitely to keep the container running
tail -f /dev/null
