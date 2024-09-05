#!/bin/sh
# Start the Docker service
service docker start

# Start the SSH server
if [ ! -f /etc/ssh/sshd_config.d/settlement.conf ]; then
  cp /tmp/settlement.conf /etc/ssh/sshd_config.d/settlement.conf
fi

/usr/sbin/sshd

# Start ZeroTier in daemon mode and join the network
zerotier-one -d
zerotier-cli join $ZT_NETWORK_ID

# Wait indefinitely to keep the container running
tail -f /dev/null
