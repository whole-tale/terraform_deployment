#!/bin/bash

device=""
mount_path=""   # assumes /mnt/<name> TODO: Add sanity check
verbose=0

usage() {
      echo "Usage: `basename $0` -d device -m mount_path"
}

while getopts "h?vd:m:e:c:" opt; do
    case "$opt" in
    h|\?)
      usage
      exit 0
      ;;
    v) verbose=1
      ;;
    d) device=$OPTARG
      ;;
    m) mount_path=$OPTARG
      ;;
    esac
done

if [ ! $device ]; then
  echo "You must speficy a device (-d) to mount"
  usage
  exit 1
fi

if [ ! $mount_path ]; then
  echo "You must speficy a mount_path (-m)"
  usage
  exit 1
fi

echo "verbose=$verbose, device=$device, mount_path=$mount_path"


# Check that block device exists
if [ ! -b ${device} ]; then
  echo "${device} is not a block device"
  exit 1
fi

# Create filesystem
if  ! blkid ${device} | grep "ext4" > /dev/null ; then
   if [ $verbose ]; then
      echo "Creating ext4 filesytem on device ${device}"
   fi
   mkfs -t ext4 ${device}
else
   echo "Device ${device} already has fs"
fi

# Create mount point
if [ ! -d ${mount_path} ]; then
   if [ $verbose ]; then
      echo "Creating mount point ${mount_path}"
   fi
   mkdir -p ${mount_path}
fi


# Create systemd mount file
cat << EOF >  /etc/systemd/system/mnt-${mount_path#/mnt/}.mount
[Unit]
Description=Mount $device on $mount_path
After=local-fs.target

[Mount]
What=$device
Where=$mount_path
Type=ext4
Options=noatime

[Install]
WantedBy=multi-user.target
EOF

# Enable mount file
systemctl enable mnt-${mount_path#/mnt/}.mount

# Mount device to specified path
if  ! mount | grep "^${device} " > /dev/null ; then
   if [ $verbose ]; then
      echo "Mounting ${device} to ${mount_path}"
   fi
   systemctl start mnt-${mount_path#/mnt/}.mount
else
   echo "${device} already mounted"
fi
