#!/bin/bash

waitforapt(){
  while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
     echo "Waiting for apt lock..."
     sleep 1
  done
}

cat << EOF >> /home/ubuntu/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqtK80wInbOIbvuf3EhANdJxwMJTjm29E0PgxjEishZ0x9Wj+EmL3WvvZf7YFrB3IuJ0bMI7Cjq5ZpSPZ+qEZgTfm4oKZgKJsnnynFibeizH2aN9YgbdIJeIiE0kF6v/fFVQEtIwX5oO3TUMYBP7Mecl+nRibudAX/TK08oZzt4hdOrmbUZ5pmzaCSAfabqDRhi8r5GVVnEHcfGvKv7P+z+O4pySCURF/XozmjlPHv8hl4pqAx9eK6OylB/FH5+2jNIkG5vJMWs1bO4AdmE+mqeefHmn6CH55bNUGFH6Oqc4qGnRapjp5tdiaW4jc8DinLqw1ScEUraH+KjzqrN9mD xarth@shakuras
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4DACR1R4k+Qo3oWDrkaMCox42TLqzSD/+FyzOt7pDkZXqPijOiWZITUUyBhm37EZrZxqr4CYC8KLP0CMkWcPu9gKllNZx78IO8VxVY1BevaTsJRPIMSLEiiReJRMEmaQ0CHfauisWvwNcvMtLlE8xqOSEq98s7bWvkhETcxyZWbFNFOFJKdCWIo35S9c13u/ImUo8uSNd1LvAgLF1zGnWKR1mzjt8ZgD7+M1SoAwNQ/shClwWCwj4z9d5rjYXaWnrOYV93Zn/TGS5jYlzWOzJuFAJaF9KvwqGZFCrBBZhh7XmJkUf+8T9xY96FAhJgvS/2wdcv3oYch1Xm1oYvpW3 willis8@skyuka
EOF

sudo bash -c 'cat << EOF > /etc/fuse.conf
user_allow_other
EOF'


sudo bash -c 'cat << EOF > /etc/sysctl.d/ipv6.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF'

# Disable systemd-resolved
sudo bash -c 'cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=8.8.8.8
FallbackDNS=8.8.4.4
EOF'

sudo systemctl restart systemd-resolved.service
sudo rm /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf


# Configure Docker daemon
docker_mtu=$(( `cat /sys/class/net/ens4/mtu` - 60 ))
eth1_ipv4=`ip -o -4 addr list ens4 | awk '{print $4}' | cut -d/ -f1`

sudo mkdir -p /etc/docker
sudo bash -c "cat << EOF > /etc/docker/daemon.json
{
   \"hosts\": [\"unix:///var/run/docker.sock\", \"tcp://${eth1_ipv4}:237\"],
   \"dns\": [\"8.8.8.8\", \"8.8.4.4\"],
   \"mtu\": ${docker_mtu},
   \"experimental\": true
}
EOF"

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo bash -c "cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
EOF"

# Install required packages
waitforapt
sudo apt-get update -y 
waitforapt
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    davfs2 \
    fuse \
    git \
    gnupg-agent \
    libcurl4-openssl-dev \
    libffi-dev \
    libfuse-dev \
    libjpeg-dev \
    libpython3-dev \
    libssl-dev \
    nfs-common \
    python3 \
    python3-pip \
    software-properties-common \
    wget \
    zlib1g-dev 


# Install Docker
waitforapt
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 

waitforapt
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

waitforapt
sudo apt-get update -y
waitforapt
sudo apt-get install -y docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io
sudo usermod -aG docker ubuntu

sudo docker swarm leave --force || /bin/true
sudo docker network rm docker_gwbridge || /bin/true

# Create a default swarm bridge with proper MTU
sudo docker network create \
  --opt com.docker.network.bridge.name=docker_gwbridge \
  --opt com.docker.network.bridge.enable_icc=false \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  --opt com.docker.network.driver.mtu=${docker_mtu} \
  docker_gwbridge


# Set the maximum journal size
sudo bash -c "cat <<EOF > /etc/systemd/journald.conf
[Journal]
SystemMaxUse=500
EOF"

sudo systemctl restart systemd-journald

# Set the timezone
sudo timedatectl set-timezone America/Chicago
