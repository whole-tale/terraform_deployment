#!/bin/bash

# Setup home NFS mount system unit

nfs_server=$1

# Create systemd mount file
cat << EOF >  /etc/systemd/system/mnt-homes.mount
[Unit]
Description=NFS mount for WT homes
After=network.target

[Mount]
What=$nfs_server:/mnt/homes
Where=/mnt/homes
Type=nfs
Options=_netdev,auto

[Install]
WantedBy=multi-user.target
EOF

# Enable mount file
systemctl enable mnt-homes.mount

# Mount device to specified path
systemctl start mnt-homes.mount
if  ! mount | grep "/mnt/homes" > /dev/null ; then
   if [ $verbose ]; then
      echo "Mounting ${nfs_server} to /mnt/homes}"
   fi
   systemctl start mnt-homes.mount
else
   echo "mnt-homes already mounted"
fi
