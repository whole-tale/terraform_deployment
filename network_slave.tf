resource "openstack_networking_port_v2" "ext_port" {
  count              = "${var.num_slaves}"
  network_id         = "${openstack_networking_network_v2.ext_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
  }
}

resource "openstack_networking_port_v2" "mgmt_port" {
  count              = "${var.num_slaves}"
  network_id         = "${openstack_networking_network_v2.int_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.int_net_subnet.id}"
  }
}
