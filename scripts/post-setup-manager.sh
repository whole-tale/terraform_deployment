#!/bin/bash

docker_mtu=$(( `cat /sys/class/net/ens4/mtu` - 60 ))

# Create a default swarm bridge with proper MTU
echo "Removing ingress network"
echo "y" | docker network rm ingress <&0
sleep 5

echo "Listing networks"
docker network ls

echo "Creating ingress network"
docker network create \
  -d overlay \
  --ingress \
  --opt com.docker.network.driver.mtu=${docker_mtu} \
  ingress


