resource "openstack_networking_secgroup_v2" "wt_node" {
  name = "WT Node defaults"
  description = "Default set of networking rules for WT Node"
}

resource "openstack_networking_secgroup_rule_v2" "default_ip4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
  security_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
}

resource "openstack_networking_secgroup_rule_v2" "default_ip6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  remote_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
  security_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
}

resource "openstack_networking_secgroup_rule_v2" "default_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
}

resource "openstack_networking_secgroup_rule_v2" "default_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
}

resource "openstack_networking_secgroup_rule_v2" "default_checkmk" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6556
  port_range_max    = 6556
  remote_ip_prefix  = "141.142.227.156/32"
  security_group_id = "${openstack_networking_secgroup_v2.wt_node.id}"
}
