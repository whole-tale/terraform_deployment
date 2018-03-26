resource "openstack_networking_network_v2" "ext_network" {
  name = "${var.cluster_name}-external"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2"  "ext_net_subnet" {
  name       = "${var.cluster_name}-external_subnet"
  network_id = "${openstack_networking_network_v2.ext_network.id}"
  cidr       = "${var.external_subnet}"
  ip_version = 4
  enable_dhcp = "true"
  dns_nameservers = ["8.8.8.8", "8.8.8.4"]
}

resource "openstack_networking_router_v2" "ext_router" {
  name = "${var.cluster_name}_ext_router"
  admin_state_up = "true"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_router_interface_v2" "ext_router_interface" {
  subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
  router_id = "${openstack_networking_router_v2.ext_router.id}"
}

resource "openstack_networking_network_v2" "int_network" {
  name = "${var.cluster_name}-mgmt"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2"  "int_net_subnet" {
  name       = "${var.cluster_name}-internal_subnet"
  network_id = "${openstack_networking_network_v2.int_network.id}"
  cidr       = "${var.internal_subnet}"
  ip_version = 4
  enable_dhcp = "true"
  no_gateway = "true"
  dns_nameservers = ["8.8.8.8", "8.8.8.4"]
}
