#!/bin/bash

nfs_host=$1

# Label the manager node as a mongo replica
echo "Labeling master node"
docker node update --label-add mongo.replica=1 --label-add core=1 $(docker node ls -q -f "role=manager")


# Label the storage node
docker node update --label-add storage=1 --label-add core=1 $(docker node ls -q -f "name=$nfs_host")

# Label the first two worker nodes as mongo replicas
echo "Labeling mongo replicas"
i=2
for node in `docker node ls -q -f "role=worker" | head -2`
do
    docker node update --label-add mongo.replica=$i --label-add core=1 $node
    ((i++))
done
