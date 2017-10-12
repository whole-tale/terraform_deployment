Kacper's random notes
=====================

Converting yaml to ign:

```bash
$ wget https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.3.1/ct-v0.3.1-x86_64-unknown-linux-gnu
$ mv ct-v0.3.1-x86_64-unknown-linux-gnu ct
$ chmod +x ct
$ ./ct -platform openstack-metadata -in-file coreos.yaml -out-file config.ign
```

All the magic that needs to happen
==================================
```bash
$ docker network create --driver overlay -o "com.docker.network.driver.mtu"="1454" traefik-net
$ docker network create --driver overlay -o "com.docker.network.driver.mtu"="1454" mongo
$ docker network create --driver overlay -o "com.docker.network.driver.mtu"="1454" --attachable celery
$ docker node ls
$ docker node update --label-add mongo.replica=1 ekyc8kh9a6e680bsdh3087c67
$ docker node update --label-add mongo.replica=2 uqiwamfpqo41segqz6f8s954z
$ docker node update --label-add mongo.replica=3 dog0pdne1gtig53vwks993vx1

$ ssh $(docker node inspect ekyc8kh9a6e680bsdh3087c67 -f "{{.Status.Addr}}") docker volume create mongodata1
$ ssh $(docker node inspect ekyc8kh9a6e680bsdh3087c67 -f "{{.Status.Addr}}") docker volume create mongoconfig1
$ ssh $(docker node inspect uqiwamfpqo41segqz6f8s954z -f "{{.Status.Addr}}") docker volume create mongodata2
$ ssh $(docker node inspect uqiwamfpqo41segqz6f8s954z -f "{{.Status.Addr}}") docker volume create mongoconfig2
$ ssh $(docker node inspect dog0pdne1gtig53vwks993vx1 -f "{{.Status.Addr}}") docker volume create mongodata3
$ ssh $(docker node inspect dog0pdne1gtig53vwks993vx1 -f "{{.Status.Addr}}") docker volume create mongoconfig3

$ docker service create \
    --replicas 1 --network mongo \
    --mount type=volume,source=mongodata1,target=/data/db \
    --mount type=volume,source=mongoconfig1,target=/data/configdb \
    --constraint 'node.labels.mongo.replica == 1' \
    --name mongo1 mongo:3.2 mongod --replSet rs1

$ docker service create \
    --replicas 1 --network mongo \
    --mount type=volume,source=mongodata2,target=/data/db \
    --mount type=volume,source=mongoconfig2,target=/data/configdb \
    --constraint 'node.labels.mongo.replica == 2' \
    --name mongo2 mongo:3.2 mongod --replSet rs1

$ docker service create \
    --replicas 1 --network mongo \
    --mount type=volume,source=mongodata3,target=/data/db \
    --mount type=volume,source=mongoconfig3,target=/data/configdb \
    --constraint 'node.labels.mongo.replica == 3' \
    --name mongo3 mongo:3.2 mongod --replSet rs1

# Manual db restore if needed ^^^

$ docker service create --name traefik \
    --constraint=node.role==manager \
    --publish 80:80 --publish 443:443 --publish 8080:8080 \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
    --mount type=bind,source=/home/core/traefik,target=/etc/traefik \
    --mount type=bind,source=/home/core/traefik/acme,target=/acme \
    --network traefik-net traefik

$ docker service create \
    --replicas 1 --network celery --name redis --label traefik.enable=false redis

$ docker service create \
    --name girder --label traefik.port=8080 \
    --label traefik.docker.network=traefik-net \
    --label traefik.frontend.passHostHeader=true \
    --label traefik.enable=true \
    --label traefik.frontend.entryPoints=https \
    --network traefik-net --network celery --network mongo \
    wholetale/girder:dev

...
```
