# Use the Ubuntu 22.04 image as the base
FROM ubuntu:22.04

ARG SSH_PORT=22
ENV SSH_PORT=${SSH_PORT}

# Install necessary packages including OpenSSH server, Docker, and ZeroTier
RUN apt-get update && \
  apt-get install -y \
  openssh-server \
  curl \
  sudo \
  gnupg \
  lsb-release \
  software-properties-common && \
  # Install Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
  apt-get update && \
  apt-get install -y docker-ce docker-ce-cli containerd.io && \
  # Clean up apt cache
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install ZeroTier
RUN curl -s https://install.zerotier.com | bash

# Create an admin user with sudo privileges
RUN adduser --disabled-password --gecos "" admin && \
  echo 'admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  mkdir -p /home/admin/.ssh && \
  chown admin:admin /home/admin/.ssh

# Configure SSH
RUN mkdir /var/run/sshd && \
  sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config && \
  sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  ssh-keygen -A

# Expose the SSH port
EXPOSE ${SSH_PORT}

# Start services
COPY scripts/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose the Docker daemon port
EXPOSE 2375

# Start the SSH server and ZeroTier
CMD ["/usr/local/bin/start.sh"]
