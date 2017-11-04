#!/bin/bash

mtu=$1

# Create a default swarm bridge with proper MTU
echo "y" | docker network rm ingress <&0
sleep 2
docker network ls
docker network create \
  -d overlay \
  --ingress \
  --opt com.docker.network.driver.mtu=${mtu} \
  ingress


docker node update --label-add mongo.replica=1 $(docker info --format "{{.Swarm.NodeID}}")
