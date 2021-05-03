# Migrating from v0.9 to v1.0

Instructions for migrating from v0.9 to v1.0 including
staging deployment instructions.

## (Staging) Restore from backup

For staging only. After provisioning, `ssh` to the NFS node. 


```
ssh <nfs>
docker run -it --network wt_mongo -v /mnt/homes:/backup -v /home/ubuntu/rclone/:/conf wholetale/backup bash
export BACKUP_DATE=<date of backup>
rclone --config /conf/rclone.conf ls backup:WT
rclone --config /conf/rclone.conf copy backup:WT/wt-prod-a/${BACKUP_DATE}/mongodump-${BACKUP_DATE}.tgz /tmp
rclone --config /conf/rclone.conf copy backup:WT/wt-prod-a/${BACKUP_DATE}/home-${BACKUP_DATE}.tgz /tmp

mongo_host="rs1/wt_mongo1:27017,wt_mongo2:27017,wt_mongo3:27017"
mongorestore --drop --host=$mongo_host --gzip --archive=/tmp/mongodump-${BACKUP_DATE}.tgz
cd /backup 
rm -rf *
mkdir homes workspaces
tar xvf /tmp/home-${BACKUP_DATE}.tgz -C homes/
mv homes/5 workspaces/
mv homes/6 workspaces/
chown -R 999:999 .
```

Prod note: For v1.0, contents of `homes` and `workspaces` must be separated.

## (Staging) Change admin password

```
$ docker exec -ti --user girder $(docker ps --filter=name=wt_girder -q) bash
# girder-shell

from girder.models.user import User
admin = User().findOne({"login": "admin"})
User().setPassword(admin, "newpassword")
```

Delete instances:
```
from girder.plugins.wholetale.models.instance import Instance
instances = Instance().find()
for instance in instances:
    Instance().remove(instance)
```

## Run the migration script

```
python3 migrate_v1.0.py <admin_password>
```

## Migrate virtual resources

Via `girder-shell`:
```
from girder.models.model_base import Model
from girder.models.assetstore import Assetstore
from girder.models.file import File
from girder.models.folder import Folder
from girder.models.item import Item
from girder.models.user import User
from girder.plugins.wholetale.models.tale import Tale

old_base = Assetstore().load("596448521801c10001a4c5fb")
Assetstore().remove(old_base)

home_base = "/tmp/data/homes"   
workspace_base = "/tmp/data/workspaces"  

for store in Assetstore().list():
    if store["type"] < 100:
        continue
    for f in File().find({"assetstoreId": store["_id"]}):
        f["assetstoreId"] = None
        f["linkUrl"] = "https://blah.com"
        File().save(f)
    Model.remove(Assetstore(), store)

for home in Folder().find({"name": "Home"}):
    user = User().load(home["parentId"], force=True)
    Folder().clean(home)
    home.update(
        {
            "fsPath": f"{home_base}/{user['login'][:1]}/{user['login']}",
            "isMapping": True
        }
    )
    Folder().save(home)

for workspace in Folder().find({"meta.taleId": {"$exists": True}}):
    Folder().clean(workspace)
    tale_id = str(workspace["meta"]["taleId"])
    tale = Tale().load(tale_id, force=True)
    if not tale:
        Folder().remove(workspace)
        continue
    workspace.update(
        {
            "fsPath": f"{workspace_base}/{tale_id[:1]}/{tale_id}",
            "isMapping": True,
            "access": tale["access"],
            "public": tale["public"],
            "publicFlags": tale.get("publicFlags", []),
        }
    )
    Folder().save(workspace)

# Create versions and runs folders for old tales
from girder.plugins.wholetale.models.tale import Tale
from bson import ObjectId
from girder import events

for tale in list(Tale().find()):  
    event = events.trigger("model.tale.save.created", info=tale)


# Drop DMS cache - also not necessary on stage/prod provided that dms data was copied
for i in Item().find({'dm': {'$exists': True}}):
    i.pop('dm')
    Item().save(i)


# Remove `CSP_HOSTS` env var
from girder.plugins.wholetale.models.image import Image
images = Image().find()
for img in images:
    if "environment" in img["config"]:
      envs = img["config"]["environment"]
      new_envs = [env for env in envs if not env.startswith('CSP_HOSTS=')]
      img["config"]["environment"] = new_envs
      Image().save(img)
```

## Deploying MATLAB and STATA

Build `matlab-install:R2020b` with correct network license.

From node with `matlab-install:R2020b` and `stata-install:16` images:
```
docker login registry.stage.wholetale.org
docker push registry.stage.wholetale.org/matlab-install:R2020b
docker push registry.stage.wholetale.org/stata-install:16
```

On each worker node:
```
for host in <hosts>:
do
  scp -r ~/.docker $host:.
  ssh $host docker pull registry.stage.wholetale.org/stata-install:16;
  ssh $host docker tag registry.stage.wholetale.org/stata-install:16 stata-install:16;
  ssh $host docker pull registry.stage.wholetale.org/matlab-install:R2020b
  ssh $host docker tag registry.stage.wholetale.org/matlab-install:R2020b matlab-install:R2020b
done
```

Copy stata licenses to each worker node:
```
for host in <hosts>:
do
  scp -r licenses/ <node>:.
done
```

Cache base image on each node
```
for host in <hosts>:
do
  docker run \
    --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    wholetale/repo2docker_wholetale:latest \
    jupyter-repo2docker \
      --config="/wholetale/repo2docker_config.py" \
      --target-repo-dir="/home/jovyan/work/" \
done
      --user-id=1000 --user-name=jovyan \
      --no-clean --no-run --image-name base /tmp
```

