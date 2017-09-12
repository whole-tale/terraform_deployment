resource "openstack_compute_instance_v2" "swarm_master" {
  name = "wt-prod-00"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.ssh_key.name}"
  user_data = "${file("config.ign")}"

  network {
    port = "${openstack_networking_port_v2.master_ext_port.0.id}"
  }

  network {
    port = "${openstack_networking_port_v2.master_mgmt_port.0.id}"
  }
}
