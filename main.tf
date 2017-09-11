provider "openstack" {
}

resource "openstack_networking_secgroup_v2" "wt_node" {
  name = "WT Node defaults"
  description = "Default set of networking rules for WT Node"
}

resource "openstack_networking_secgroup_v2" "wt_master" {
  name = "WT Master Node"
  description = "HTTP/HTTPS access for main node"
}

resource "openstack_networking_secgroup_rule_v2" "remote_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wt_master.id}"
}

resource "openstack_networking_secgroup_rule_v2" "remote_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.wt_master.id}"
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

resource "openstack_networking_network_v2" "ext_network" {
  name = "WT-external"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2"  "ext_net_subnet" {
  name       = "WT-external_subnet"
  network_id = "${openstack_networking_network_v2.ext_network.id}"
  cidr       = "192.168.99.0/24"
  ip_version = 4
  enable_dhcp = "true"
  dns_nameservers = ["141.142.2.2","141.142.230.144"]
}

resource "openstack_networking_router_v2" "ext_router" {
  name = "WT_ext_router"
  admin_state_up = "true"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_router_interface_v2" "ext_router_interface" {
  router_id = "${openstack_networking_router_v2.ext_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
}

resource "openstack_networking_router_route_v2" "ext_route" {
  depends_on       = ["openstack_networking_router_interface_v2.ext_router_interface"]
  router_id        = "${openstack_networking_router_v2.ext_router.id}"
  destination_cidr = "10.0.1.0/24"
  next_hop         = "192.168.99.254"
}

resource "openstack_networking_network_v2" "int_network" {
  name = "WT-mgmt"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2"  "int_net_subnet" {
  name       = "WT-external_subnet"
  network_id = "${openstack_networking_network_v2.int_network.id}"
  cidr       = "192.168.149.0/24"
  ip_version = 4
  enable_dhcp = "true"
  dns_nameservers = ["141.142.2.2","141.142.230.144"]
}

resource "openstack_compute_keypair_v2" "ssh_key" {
  name = "SSH keypair for Terraform instances"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

resource "openstack_networking_port_v2" "ext_port" {
  count              = "${var.num_slaves + 1}"
  network_id         = "${openstack_networking_network_v2.ext_network.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.wt_node.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
  }
}

resource "openstack_networking_port_v2" "mgmt_port" {
  count              = "${var.num_slaves + 1}"
  network_id         = "${openstack_networking_network_v2.int_network.id}"
  admin_state_up     = "true"
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.int_net_subnet.id}"
  }
}

resource "openstack_compute_instance_v2" "swarm_manager" {
  name = "wt-prod-00"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"
  security_groups = ["${openstack_networking_secgroup_v2.wt_node.name}",
                     "${openstack_networking_secgroup_v2.wt_master.name}"]
  user_data = "${file("config.ign")}"

  network {
    port = "${openstack_networking_port_v2.ext_port.0.id}"
  }

  network {
    port = "${openstack_networking_port_v2.mgmt_port.0.id}"
  }
}

resource "openstack_networking_floatingip_v2" "swarm_manager_ip" {
  depends_on = ["openstack_networking_router_interface_v2.ext_router_interface"]
  pool = "${var.pool}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_master" {
  floating_ip = "${openstack_networking_floatingip_v2.swarm_manager_ip.address}"
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"
}

resource "openstack_compute_instance_v2" "swarm_slave" {
  count = "${var.num_slaves}"
  name = "${format("wt-prod-%02d", count.index + 1)}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"
  security_groups = ["${openstack_networking_secgroup_v2.wt_node.name}",
                     "${openstack_networking_secgroup_v2.wt_master.name}"]
  user_data = "${file("config.ign")}"

  network {
    port = "${element(openstack_networking_port_v2.ext_port.*.id, count.index + 1)}"
  }

  network {
    port = "${element(openstack_networking_port_v2.mgmt_port.*.id, count.index + 1)}"
  }
}
