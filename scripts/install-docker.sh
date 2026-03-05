#!/usr/bin/env bash

# Remove old binaries
sudo dnf remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

# Setup repo
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

# Install docker stuff
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable docker daemon
sudo systemctl enable --now docker

# Setup docker without sudo
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker
