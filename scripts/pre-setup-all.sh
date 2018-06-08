#!/bin/bash

mtu=$1
docker swarm leave --force || /bin/true
docker network rm docker_gwbridge || /bin/true

# Create a default swarm bridge with proper MTU
docker network create \
  --opt com.docker.network.bridge.name=docker_gwbridge \
  --opt com.docker.network.bridge.enable_icc=false \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  --opt com.docker.network.driver.mtu=${mtu} \
  docker_gwbridge


# Set the maximum journal size
sudo cat << EOF > /etc/systemd/journald.conf 
[Journal]
SystemMaxUse=500M
EOF

sudo systemctl reload systemd-journald
sudo systemctl restart systemd-journald
