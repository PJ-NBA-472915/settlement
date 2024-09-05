# Use the Ubuntu 22.04 image as the base
FROM ubuntu:22.04

USER root

# Define build arguments
ARG SSH_PORT=22
ARG SSH_USER=admin
ARG SSH_SUBNET=192.168.1.*

# Set environment variables
ENV SSH_PORT=${SSH_PORT}
ENV SSH_USER=${SSH_USER}
ENV SSH_SUBNET=${SSH_SUBNET}

# Install necessary packages including OpenSSH server, Docker, docker-compose, and ZeroTier
RUN apt-get update && \
  apt-get install -y \
  openssh-server \
  curl \
  nano \
  sudo \
  gnupg \
  lsb-release \
  software-properties-common \
  systemd && \
  # Install Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
  apt-get update && \
  apt-get install -y docker-ce docker-ce-cli containerd.io && \
  # Install docker-compose
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose && \
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose && \
  # Clean up apt cache
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install ZeroTier
RUN curl -s https://install.zerotier.com | bash

# Create an admin user with sudo privileges and add to docker and root groups
RUN adduser --disabled-password --gecos "" ${SSH_USER} && \
  usermod -aG docker ${SSH_USER} && \
  echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
  mkdir -p /home/${SSH_USER}/.ssh && \
  chown ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh

# Configure SSH
RUN mkdir /var/run/sshd && \
  sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config && \
  sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  ssh-keygen -A

# Document the ports being exposed
EXPOSE ${SSH_PORT}
EXPOSE 2375

# Copy the template file into the container
COPY config/sshd/settlement.config.template /tmp/settlement.conf

# Replace placeholders in the template file with environment variables
RUN sed -i "s/{{SSH_PORT}}/${SSH_PORT}/g" /tmp/settlement.conf \
  && sed -i "s/{{SSH_USER}}/${SSH_USER}/g" /tmp/settlement.conf \
  && sed -i "s/{{SSH_SUBNET}}/${SSH_SUBNET}/g" /tmp/settlement.conf

# Copy the start script into the container, set ownership and make it executable
COPY ./scripts/start.sh /usr/local/bin/start.sh

RUN chown root:root /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Start the SSH server and ZeroTier
CMD ["/usr/local/bin/start.sh"]
