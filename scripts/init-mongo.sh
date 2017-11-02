#!/bin/bash


domain=$1
globus_client_id=$2
globus_client_secret=$3
restore_url=$4

container=$(docker ps -qf label=com.docker.swarm.service.name=wt_mongo1)

if [ -z "$container" ]; then
  echo "Couldn't find wt_mongo1, container exiting"
  exit 1;
fi

# Create replica set
echo "Configuring replica set"
docker exec -it $container mongo \
    --eval 'rs.initiate({ _id: "rs1", members: [{ _id: 1, host: "wt_mongo1:27017" }, { _id: 2, host: "wt_mongo2:27017" }, { _id: 3, host: "wt_mongo3:27017" }], settings: { getLastErrorDefaults: { w: "majority", wtimeout: 30000 }}})'


# Import DB
if [ ! -z "$restore_url" ]; then
    echo "Restoring Mongo from backup $restore_url"
    curl -J -o girder_backup.tar.gz $restore_url
    docker cp girder_backup.tar.gz $container:.
    docker exec $container mkdir /restore
    docker exec $container tar -xvf girder_backup.tar.gz -C /restore
    docker exec $container mongorestore --drop /restore
    docker exec $container rm girder_backup.tar.gz
fi


# Update CORS origin
if [ ! -z "$domain" ]; then
   echo "Adding $domain to Girder CORS origin"
   docker exec $container mongo girder --eval 'db.setting.updateOne( { key: "core.cors.allow_origin" }, { $set : { value: "http://localhost:4200, https://dashboard.wholetale.org, http://localhost:8000, https://dashboard-dev.wholetale.org, https://dashboard.'$domain'"}})'
fi

docker exec $container mongo girder --eval 'db.setting.updateOne( { name: "GridFS local" }, { $set : { mongohost: "mongodb://wt_mongo1:27017,wt_mongo2:27017,wt_mongo3:27017"}})'

# Update Globus keys
if [ ! -z "$globus_client_id" ]; then
   echo "Updating Globus client ID and secret"
   docker exec $container mongo girder --eval 'db.setting.updateOne( { key : "oauth.globus_client_id" }, { $set: { value: "'$globus_client_id'"} } )'
   docker exec $container mongo girder --eval 'db.setting.updateOne( { key : "oauth.globus_client_secret" }, { $set: { value: "'$globus_client_secret'"} } )'
   docker exec $container mongo girder --eval 'db.setting.find()'
fi
