./rclone --config rclone.conf config
2018/03/10 22:26:52 NOTICE: Config file "/home/core/terraform_deployment/rclone.conf" not found - using defaults
No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
name> backup
Type of storage to configure.
Choose a number from below, or type in your own value
 1 / Amazon Drive
   \ "amazon cloud drive"
 2 / Amazon S3 (also Dreamhost, Ceph, Minio)
   \ "s3"
 3 / Backblaze B2
   \ "b2"
 4 / Box
   \ "box"
 5 / Cache a remote
   \ "cache"
 6 / Dropbox
   \ "dropbox"
 7 / Encrypt/Decrypt a remote
   \ "crypt"
 8 / FTP Connection
   \ "ftp"
 9 / Google Cloud Storage (this is not Google Drive)
   \ "google cloud storage"
10 / Google Drive
   \ "drive"
11 / Hubic
   \ "hubic"
12 / Local Disk
   \ "local"
13 / Microsoft Azure Blob Storage
   \ "azureblob"
14 / Microsoft OneDrive
   \ "onedrive"
15 / Openstack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
   \ "swift"
16 / Pcloud
   \ "pcloud"
17 / QingCloud Object Storage
   \ "qingstor"
18 / SSH/SFTP Connection
   \ "sftp"
19 / Webdav
   \ "webdav"
20 / Yandex Disk
   \ "yandex"
21 / http Connection
   \ "http"
Storage> 4
Box App Client Id - leave blank normally.
client_id>
Box App Client Secret - leave blank normally.
client_secret>
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
y) Yes
n) No
y/n>
y/n> y
If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth
Log in and authorize rclone for access
Waiting for code...
Got code
--------------------
[backup]
client_id =
client_secret =
token = {"access_token":"WqW9pkhSuoR6hy5e3xBxr9eXAjB5xKy6","token_type":"bearer","refresh_token":"Z9WY7nLySeEcpvnmQeA6JgNoyPDdClfLL9bcsMVQYHYpfQUTdS7Glvjk7oR8FChD","expiry":"2018-03-10T23:29:07.770756693Z"}
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y
Current remotes:

Name                 Type
====                 ====
backup               box

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q
