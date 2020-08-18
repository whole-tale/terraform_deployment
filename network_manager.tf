resource "openstack_networking_port_v2" "manager_ext_port" {
  network_id         = "${openstack_networking_network_v2.ext_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}",
                        "${openstack_networking_secgroup_v2.wt_manager.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
  }
}

resource "openstack_networking_port_v2" "manager_mgmt_port" {
  network_id         = "${openstack_networking_network_v2.int_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.int_net_subnet.id}"
  }
}

resource "openstack_networking_floatingip_v2" "swarm_manager_ip" {
  pool = "${var.pool}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_manager" {
  depends_on = ["openstack_compute_instance_v2.swarm_manager", "openstack_networking_port_v2.manager_ext_port"]
  floating_ip = "${openstack_networking_floatingip_v2.swarm_manager_ip.address}"
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"
}
