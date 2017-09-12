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
  subnet_id = "${openstack_networking_subnet_v2.ext_net_subnet.id}"
  router_id = "${openstack_networking_router_v2.ext_router.id}"
}

resource "openstack_networking_network_v2" "int_network" {
  name = "WT-mgmt"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2"  "int_net_subnet" {
  name       = "WT-internal_subnet"
  network_id = "${openstack_networking_network_v2.int_network.id}"
  cidr       = "192.168.149.0/24"
  ip_version = 4
  enable_dhcp = "true"
  no_gateway = "true"
  dns_nameservers = ["141.142.2.2","141.142.230.144"]
}
