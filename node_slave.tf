data "external" "swarm_join_token" {
  depends_on = ["null_resource.provision_master"]
  program = ["./scripts/get-token.sh"]
  query = {
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }
}

resource "openstack_compute_instance_v2" "swarm_slave" {
  count = "${var.num_slaves}"
  name = "${format("wt-prod-%02d", count.index + 1)}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"
  user_data = "${file("config.ign")}"

  network {
    port = "${element(openstack_networking_port_v2.ext_port.*.id, count.index)}"
  }

  network {
    port = "${element(openstack_networking_port_v2.mgmt_port.*.id, count.index)}"
  }
}

resource "null_resource" "provision_slave" {
  count = "${var.num_slaves}"
  depends_on = ["openstack_networking_floatingip_v2.swarm_slave_ip"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${element(openstack_networking_floatingip_v2.swarm_slave_ip.*.address, count.index)}"
  }

  provisioner "remote-exec" {
    script = "./scripts/pre-setup-all.sh ${var.docker_mtu}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_join_token.result.worker} ${openstack_compute_instance_v2.swarm_master.access_ip_v4}"
    ]
  }
}


