resource "openstack_compute_instance_v2" "swarm_worker" {
  count = "${var.num_workers}"
  name = "${format("${var.cluster_name}-%02d", count.index + 1)}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"

  network {
    port = "${element(openstack_networking_port_v2.ext_port.*.id, count.index)}"
  }

  network {
    port = "${element(openstack_networking_port_v2.mgmt_port.*.id, count.index)}"
  }
}

resource "openstack_blockstorage_volume_v2" "worker-docker-vol" {
  count = "${var.num_workers}"
  name = "${format("${var.cluster_name}-%02d-docker-vol", count.index + 1)}"
  description = "Shared volume for Docker image cache"
  size = "${var.docker_volume_size}"
}

resource "openstack_compute_volume_attach_v2" "worker-docker-vol" {
  count = "${var.num_workers}"
  depends_on = ["openstack_compute_instance_v2.swarm_worker", "openstack_blockstorage_volume_v2.worker-docker-vol"]
  instance_id = "${element(openstack_compute_instance_v2.swarm_worker.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.worker-docker-vol.*.id, count.index)}"
}

resource "null_resource" "provision_worker" {
  count = "${var.num_workers}"
  depends_on = ["openstack_networking_floatingip_v2.swarm_worker_ip", "null_resource.provision_manager"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${element(openstack_networking_floatingip_v2.swarm_worker_ip.*.address, count.index)}"
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname ${element(openstack_compute_instance_v2.swarm_worker.*.name, count.index)}"]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/wholetale/",
      "mkdir -p /home/ubuntu/.ssh/",
    ]
  }

  provisioner "file" {
    source = "scripts/fs-init.sh"
    destination = "/home/ubuntu/wholetale/fs-init.sh"
  }

  provisioner "file" {
    source = "scripts/pre-setup-all.sh"
    destination = "/home/ubuntu/wholetale/pre-setup-all.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/wholetale/pre-setup-all.sh",
      "chmod +x /home/ubuntu/wholetale/fs-init.sh",
      "sudo /home/ubuntu/wholetale/fs-init.sh -v -d ${element(openstack_compute_volume_attach_v2.worker-docker-vol.*.device, count.index)} -m /var/lib/docker",
      "/home/ubuntu/wholetale/pre-setup-all.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_join_token.result.worker} ${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
    ]
  }
}

resource "null_resource" "worker_nfs_mounts" {
  depends_on = ["null_resource.provision_fileserver"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${element(openstack_networking_floatingip_v2.swarm_worker_ip.*.address, count.index)}"
  }

  provisioner "file" {
    source = "scripts/nfs-init.sh"
    destination = "/home/ubuntu/wholetale/nfs-init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/wholetale/nfs-init.sh",
      "sudo /home/ubuntu/wholetale/nfs-init.sh  ${openstack_compute_instance_v2.fileserver.access_ip_v4}"
    ]
  }
}
