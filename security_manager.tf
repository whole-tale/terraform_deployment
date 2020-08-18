resource "openstack_networking_secgroup_v2" "wt_manager" {
  name = "${var.cluster_name} Master Node"
  description = "HTTP/HTTPS access for main node"
}

resource "openstack_networking_secgroup_rule_v2" "remote_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wt_manager.id}"
}

resource "openstack_networking_secgroup_rule_v2" "remote_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wt_manager.id}"
}
