resource "openstack_networking_port_v2" "ext_port" {
  count              = "${var.num_workers}"
  network_id         = "${openstack_networking_network_v2.ext_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
  }
}

resource "openstack_networking_port_v2" "mgmt_port" {
  count              = "${var.num_workers}"
  network_id         = "${openstack_networking_network_v2.int_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.int_net_subnet.id}"
  }
}

resource "openstack_networking_floatingip_v2" "swarm_worker_ip" {
  count = "${var.num_workers}"
  pool = "${var.pool}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_worker" {
  count = "${var.num_workers}"
  depends_on = ["openstack_compute_instance_v2.swarm_worker", "openstack_networking_port_v2.ext_port"]
  floating_ip = "${element(openstack_networking_floatingip_v2.swarm_worker_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.swarm_worker.*.id, count.index)}"
}
