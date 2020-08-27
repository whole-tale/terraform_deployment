#!/bin/bash

CLUSTER_ID=$1

# Create backup service
cat << EOF1 >  /etc/systemd/system/backup.service
[Unit]
Description=Runs nightly backup

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --rm --network wt_mongo -v /mnt/homes:/backup -v /home/ubuntu/rclone/:/conf wholetale/backup backup.sh -c $CLUSTER_ID 2>&1  > /home/ubuntu/wholetale/backup.log

[Install]
WantedBy=multi-user.target
EOF1

systemctl enable backup.service
 
# Create backup timer
cat << EOF2 >  /etc/systemd/system/backup.timer
[Unit]
Description=Run backup.service every day

[Timer]
OnCalendar=daily
EOF2

systemctl start backup.timer
