#!/bin/sh

domain=$1 
role=$2

sudo umount /usr/local/lib > /dev/null 2>&1 || true
docker stop celery_worker >/dev/null 2>&1
docker rm celery_worker > /dev/null 2>&1 

docker pull wholetale/gwvolman:dev > /dev/null 2>&1

docker run \
    --name celery_worker \
    --label traefik.enable=false \
    -e GIRDER_API_URL=https://girder.${domain}/api/v1 \
    -e HOSTDIR=/host \
    -e TRAEFIK_NETWORK=wt_traefik-net \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /:/host \
    -v /var/cache/davfs2:/var/cache/davfs2 \
    -v /run/mount.davfs:/run/mount.davfs \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --cap-add SYS_PTRACE \
    --network wt_celery \
    -d --entrypoint=/usr/bin/python \
    wholetale/gwvolman:dev \
      -m girder_worker -l info \
      -Q ${role},$(docker info --format "{{.Swarm.NodeID}}") \
      --hostname=$(docker info --format "{{.Swarm.NodeID}}")

sudo mount --bind \
  $(docker inspect --format={{.GraphDriver.Data.MergedDir}} celery_worker)/usr/local/lib \
  /usr/local/lib

docker exec -ti celery_worker chown davfs2:davfs2 /host/run/mount.davfs
docker exec -ti celery_worker chown davfs2:davfs2 /host/var/cache/davfs2
[[ -z $(getent group 100) ]] && sudo groupadd -g 100 wtgroup
[[ -z $(getent passwd 1000) ]] && sudo useradd -g 100 -u 1000 wtuser

sleep 10
