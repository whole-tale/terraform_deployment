resource "openstack_compute_instance_v2" "swarm_master" {
  name = "wt-prod-00"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"
  user_data = "${file("config.ign")}"

  network {
    port = "${openstack_networking_port_v2.master_ext_port.id}"
  }

  network {
    port = "${openstack_networking_port_v2.master_mgmt_port.id}"
  }
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
    inline = [
      "mkdir -p /home/core/wholetale/"
    ]
  }

  provisioner "file" {
    source = "scripts/pre-setup-all.sh"
    destination = "/home/core/wholetale/pre-setup-all.sh"
  }

  provisioner "file" {
    source = "scripts/post-setup-master.sh"
    destination = "/home/core/wholetale/post-setup-master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/pre-setup-all.sh",
      "/home/core/wholetale/pre-setup-all.sh ${var.docker_mtu}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${openstack_compute_instance_v2.swarm_master.access_ip_v4} --listen-addr ${openstack_compute_instance_v2.swarm_master.access_ip_v4}:2377"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/post-setup-master.sh",
      "/home/core/wholetale/post-setup-master.sh ${var.docker_mtu}"
    ]
  }
}
