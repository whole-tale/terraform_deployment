#!/bin/bash

# Export homes NFS mount

internal_network=$1
external_network=$2

sudo apt-get update -y
sudo apt-get install nfs-kernel-server

sudo echo "/mnt/homes	$internal_network(rw,async,no_subtree_check,no_root_squash) $external_network(rw,async,no_subtree_check,no_root_squash)"  >> /etc/exports

sudo systemctl restart nfs-kernel-server
