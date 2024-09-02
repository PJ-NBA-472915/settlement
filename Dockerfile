# Use the Docker-in-Docker image as the base
FROM docker:27.2.0-dind

ARG SSH_PORT=31221
ARG ADMIN_USER=admin

ENV SSH_PORT=${SSH_PORT}
ENV ADMIN_USER=${ADMIN_USER}

# Install necessary packages including OpenSSH server and ZeroTier
RUN apk update && \
  apk add --no-cache openssh curl sudo bash && \
  # Clean up APK cache
  rm -rf /var/cache/apk/*

# Install ZeroTier
RUN curl -s https://install.zerotier.com | bash \
  && curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import \  
  && if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | bash; fi

# Configure SSH
RUN mkdir /var/run/sshd && \
  sed -i 's/#Port 22/Port ${SSH_PORT}/' /etc/ssh/sshd_config && \
  sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  ssh-keygen -A

# Create an ${ADMIN_USER} user with sudo privileges
RUN adduser -D ${ADMIN_USER} && \
  echo '${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  mkdir -p /home/${ADMIN_USER}/.ssh && \
  chown ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}/.ssh

# Expose the SSH port
EXPOSE ${SSH_PORT}

# Create a directory for ZeroTier configuration
RUN mkdir -p /var/lib/zerotier-one

# Add a script to join the ZeroTier network
COPY scripts/join-zerotier.sh /usr/local/bin/join-zerotier.sh
RUN chmod +x /usr/local/bin/join-zerotier.sh

# Start services
COPY scripts/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose the Docker daemon port
EXPOSE 2375

# Start the SSH server and ZeroTier
USER ${ADMIN_USER}
CMD ["/usr/local/bin/start.sh"]
