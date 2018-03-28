resource "openstack_compute_keypair_v2" "ssh_key" {
  name = "${var.cluster_name}"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}
