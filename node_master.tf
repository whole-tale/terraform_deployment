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
  depends_on = ["openstack_networking_floatingip_v2.swarm_master_ip"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }

  provisioner "remote-exec" {
    script = "./scripts/pre-setup-all.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${openstack_compute_instance_v2.swarm_master.access_ip_v4} --listen-addr ${openstack_compute_instance_v2.swarm_master.access_ip_v4}:2377"
    ]
  }

  provisioner "remote-exec" {
    script = "./scripts/post-setup-master.sh"
  }
}
