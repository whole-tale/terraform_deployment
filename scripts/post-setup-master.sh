#!/bin/bash

# Create a default swarm bridge with proper MTU
( yes 1 | docker network rm ingres ) || true
sleep 1  # because docker %#$@%
docker network create \
  -d overlay \
  --ingress \
  --opt com.docker.network.driver.mtu=1454 \
  ingress
