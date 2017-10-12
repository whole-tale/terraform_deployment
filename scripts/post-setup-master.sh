#!/bin/bash

# Create a default swarm bridge with proper MTU
echo "y" | docker network rm ingress <&0
sleep 2
docker network ls
docker network create \
  -d overlay \
  --ingress \
  --opt com.docker.network.driver.mtu=1454 \
  ingress
