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
