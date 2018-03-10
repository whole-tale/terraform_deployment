#!/bin/bash

device=""
mount_path=""
export_path=""
cidr_range=""
verbose=0

usage() {
      echo "Usage: `basename $0` -d device -m mount_path -e export_path -c cidr_range"
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
    e) export_path=$OPTARG
      ;;
    c) cidr_range=$OPTARG
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

if [ ! $export_path ]; then
  echo "You must speficy an export_path (-e)"
  usage
  exit 1
fi

if [ ! $cidr_range ]; then
  echo "You must speficy an export CIDR range (-c)"
  usage
  exit 1
fi

echo "verbose=$verbose, device=$device, mount_path=$mount_path, export_path=$export_path, cidr_range=$cidr_range"


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


mount_name=$(echo "$mount_path" | sed 's/^\///g' | sed 's/\//-/g')

# Create systemd mount file
cat << EOF >  /etc/systemd/system/${mount_name}.mount
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


# Mount device to specified path
if  ! mount | grep "^${device} " > /dev/null ; then
   if [ $verbose ]; then
      echo "Mounting ${device} to ${mount_path}"
   fi
   systemctl start ${mount_name}.mount
else
   echo "${device} already mounted"
fi

if  ! grep "^${mount_path}" /etc/exports > /dev/null ; then
   if [ $verbose ]; then
      echo "Creating /etc/exports entry"
   fi
   echo "${mount_path} ${cidr_range}(rw,async,fsid=0,async,no_subtree_check)" >> /etc/exports
else
   echo "Export exists for ${mount_path}"
fi

if [ $verbose ]; then
   echo "Restarting rpc-mountd"
fi
systemctl start rpc-mountd
