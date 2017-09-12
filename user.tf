resource "openstack_compute_keypair_v2" "ssh_key" {
  name = "SSH keypair for Terraform instances"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}
