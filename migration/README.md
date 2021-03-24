# Migrating from v0.9 to v1.0


## (Staing) Restore from backup

After provisioning, `ssh` to the NFS node. For v1.0, we also 
separate the contents of `homes` and `workspaces`.


```
ssh <nfs>
export BACKUP_DATE=<date of backup>
docker run -it --network wt_mongo -v /mnt/homes:/backup -v /home/ubuntu/rclone/:/conf wholetale/backup bash
rclone --config /conf/rclone.conf ls backup:WT
rclone --config /conf/rclone.conf copy backup:WT/wt-prod-a/20210318/mongodump-${BACKUP_DATE}.tgz /tmp
rclone --config /conf/rclone.conf copy backup:WT/wt-prod-a/20210318/home-${BACKUP_DATE}.tgz /tmp

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

## (Staging) Change admin password

```
$ docker exec -ti $(docker ps --filter=name=wt_girder -q) bash
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
python3 scripts/migrate_v1.0.py <admin_password>
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
    workspace.update(
        {
            "fsPath": f"{workspace_base}/{tale_id[:1]}/{tale_id}",
            "isMapping": True
        }
    )
    Folder().save(workspace)

# Drop DMS cache - also not necessary on stage/prod provided that dms data was copied
for i in Item().find({'dm': {'$exists': True}}):
    i.pop('dm')
    Item().save(i)
```


## Remove `CSP_HOSTS` env var
```
from girder.plugins.wholetale.models.image import Image
images = Image().find()
for img in images:
    envs = img["config"]["environment"]
    new_envs = [env for env in envs if not env.startswith('CSP_HOSTS=')]
    img["config"]["environment"] = new_envs
    Image().save(img)
```
