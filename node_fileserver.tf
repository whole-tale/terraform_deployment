resource "openstack_blockstorage_volume_v2" "homes-vol" {
  name = "${var.cluster_name}-homes-vol"
  description = "Shared volume for home directories"
  size = "${var.nfs_volume_size}"
}

resource "openstack_blockstorage_volume_v2" "registry-vol" {
  depends_on = ["openstack_blockstorage_volume_v2.homes-vol"]
  name = "${var.cluster_name}-registry-vol"
  description = "Shared volume for Docker registry"
  size = "${var.nfs_volume_size}"
}

resource "openstack_blockstorage_volume_v2" "dms-vol" {
  depends_on = ["openstack_blockstorage_volume_v2.registry-vol"]
  name = "${var.cluster_name}-dms-vol"
  description = "Shared volume for DMS Private Storage"
  size = "${var.nfs_volume_size}"
}

resource "openstack_compute_instance_v2" "fileserver" {
  name = "${var.cluster_name}-nfs"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"
  user_data = "${file("config.ign")}"

  network {
    port = "${openstack_networking_port_v2.fileserver_ext_port.id}"
  }

  network {
    port = "${openstack_networking_port_v2.fileserver_mgmt_port.id}"
  }
}

resource "openstack_compute_volume_attach_v2" "homes-vol" {
  depends_on = ["openstack_compute_instance_v2.fileserver", "openstack_blockstorage_volume_v2.homes-vol"]
  instance_id = "${openstack_compute_instance_v2.fileserver.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.homes-vol.id}"
}

resource "openstack_compute_volume_attach_v2" "registry-vol" {
  depends_on = ["openstack_compute_instance_v2.fileserver", "openstack_blockstorage_volume_v2.registry-vol"]
  instance_id = "${openstack_compute_instance_v2.fileserver.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.registry-vol.id}"
}

resource "openstack_compute_volume_attach_v2" "dms-vol" {
  depends_on = ["openstack_compute_instance_v2.fileserver", "openstack_blockstorage_volume_v2.dms-vol"]
  instance_id = "${openstack_compute_instance_v2.fileserver.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.dms-vol.id}"
}

output "Registry device" {
  value = "${openstack_compute_volume_attach_v2.registry-vol.device}"
}

output "Home device" {
  value = "${openstack_compute_volume_attach_v2.homes-vol.device}"
}

output "DMS device" {
  value = "${openstack_compute_volume_attach_v2.dms-vol.device}"
}

resource "null_resource" "provision_fileserver" {
  depends_on = ["openstack_compute_floatingip_associate_v2.fip_fileserver", "null_resource.provision_master", "openstack_compute_volume_attach_v2.homes-vol", "openstack_compute_volume_attach_v2.registry-vol", "openstack_compute_volume_attach_v2.dms-vol"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${openstack_networking_floatingip_v2.fileserver_ip.address}"
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname ${openstack_compute_instance_v2.fileserver.name}"]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/core/wholetale/",
      "mkdir -p /home/core/rclone/",
    ]
  }

  provisioner "file" {
    source = "scripts/pre-setup-all.sh"
    destination = "/home/core/wholetale/pre-setup-all.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/pre-setup-all.sh",
      "/home/core/wholetale/pre-setup-all.sh ${var.docker_mtu}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_join_token.result.worker} ${openstack_compute_instance_v2.swarm_master.access_ip_v4}"
    ]
  }

  provisioner "file" {
    source = "scripts/nfs-init.sh"
    destination = "/home/core/wholetale/nfs-init.sh"
  }

  provisioner "file" {
    source = "scripts/init-backup.sh"
    destination = "/home/core/wholetale/init-backup.sh"
  }

  provisioner "file" {
    source = "rclone.conf"
    destination = "/home/core/rclone/rclone.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/nfs-init.sh",
      "chmod +x /home/core/wholetale/init-backup.sh",
      "sudo /home/core/wholetale/nfs-init.sh -v -d ${openstack_compute_volume_attach_v2.registry-vol.device} -m /mnt/registry -e /share -c ${openstack_networking_subnet_v2.ext_net_subnet.cidr}",
      "sudo /home/core/wholetale/nfs-init.sh -v -d ${openstack_compute_volume_attach_v2.homes-vol.device} -m /mnt/homes -e /share -c ${openstack_networking_subnet_v2.ext_net_subnet.cidr}",
      "sudo /home/core/wholetale/nfs-init.sh -v -d ${openstack_compute_volume_attach_v2.dms-vol.device} -m /mnt/dms -e /share -c ${openstack_networking_subnet_v2.ext_net_subnet.cidr}",
      "sudo /home/core/wholetale/init-backup.sh ${var.cluster_name}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "docker pull registry:2.6",
      "sudo mkdir -p /mnt/registry/auth",
      "docker run --rm --entrypoint htpasswd registry:2.6 -Bbn ${var.registry_user} ${var.registry_pass} | sudo tee /mnt/registry/auth/registry.password > /dev/null"
    ]
  }
}
