resource "openstack_compute_instance_v2" "swarm_master" {
  name = "${var.cluster_name}-00"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"

  network {
    port = "${openstack_networking_port_v2.master_ext_port.id}"
  }

  network {
    port = "${openstack_networking_port_v2.master_mgmt_port.id}"
  }
}

resource "openstack_blockstorage_volume_v2" "manager-docker-vol" {
  name = "${var.cluster_name}-00-docker-vol"
  description = "Shared volume for Docker image cache"
  size = "${var.docker_volume_size}"
}

resource "openstack_compute_volume_attach_v2" "manager-docker-vol" {
  depends_on = ["openstack_compute_instance_v2.swarm_manager", "openstack_blockstorage_volume_v2.manager-docker-vol"]
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.manager-docker-vol.id}"
}


/* trick for provisioning after we get a floating ip */

resource "null_resource" "provision_master" {
  depends_on = ["openstack_compute_floatingip_associate_v2.fip_master"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname ${openstack_compute_instance_v2.swarm_master.name}"]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/wholetale/",
      "mkdir -p /home/ubuntu/.ssh/"
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

  provisioner "file" {
    source = "scripts/post-setup-master.sh"
    destination = "/home/ubuntu/wholetale/post-setup-master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/wholetale/pre-setup-all.sh",
      "chmod +x /home/ubuntu/wholetale/fs-init.sh",
      "sudo /home/ubuntu/wholetale/fs-init.sh -v -d ${openstack_compute_volume_attach_v2.manager-docker-vol.device} -m /mnt/docker",
      "/home/ubuntu/wholetale/pre-setup-all.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${openstack_compute_instance_v2.swarm_master.access_ip_v4} --listen-addr ${openstack_compute_instance_v2.swarm_master.access_ip_v4}:2377"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/wholetale/post-setup-master.sh",
      "/home/ubuntu/wholetale/post-setup-master.sh"
    ]
  }
}

data "external" "swarm_join_token" {
  depends_on = ["null_resource.provision_master"]
  program = ["./scripts/get-token.sh"]
  query = {
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }
}
