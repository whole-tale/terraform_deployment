resource "openstack_blockstorage_volume_v2" "fileserver" {
  name = "${var.cluster_name}-nfs-vol"
  description = "Shared volume"
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

resource "openstack_compute_volume_attach_v2" "fileserver" {
  instance_id = "${openstack_compute_instance_v2.fileserver.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.fileserver.id}"
}

resource "null_resource" "provision_fileserver" {
  depends_on = ["openstack_compute_floatingip_associate_v2.fip_fileserver"]
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
      "mkdir -p /home/core/wholetale/"
    ]
  }

  provisioner "file" {
    source = "scripts/nfs-init.sh"
    destination = "/home/core/wholetale/nfs-init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/nfs-init.sh",
      "sudo /home/core/wholetale/nfs-init.sh -v -d /dev/vdb -m /mnt -e /share -c ${openstack_networking_subnet_v2.ext_net_subnet.cidr}"
    ]
  }

}
