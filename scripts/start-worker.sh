#!/bin/sh

domain=$1 
role=$2

docker stop celery_worker >/dev/null 2>&1
docker rm celery_worker > /dev/null 2>&1 

docker pull wholetale/gwvolman:dev > /dev/null 2>&1

docker run --privileged \
    --name celery_worker \
    --label traefik.enable=false \
    -e GIRDER_API_URL=https://girder.${domain}/api/v1 \
    -e HOSTDIR=/host \
    -e TRAEFIK_NETWORK=wt_traefik-net \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /:/host \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --network wt_celery \
    -d --entrypoint=/usr/bin/python \
    wholetale/gwvolman:dev \
      -m girder_worker -l info \
      -Q ${role},$(docker info --format "{{.Swarm.NodeID}}") \
      --hostname=$(docker info --format "{{.Swarm.NodeID}}")

sleep 10
