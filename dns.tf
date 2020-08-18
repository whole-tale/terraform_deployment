resource "null_resource" "update_dns" {
  depends_on = ["openstack_compute_floatingip_associate_v2.fip_manager"]

  provisioner "local-exec" {
    command = "docker run -v `pwd`/scripts:/scripts jfloff/alpine-python:2.7-slim -p requests -- python scripts/godaddy-update-dns.py -k ${var.godaddy_api_key} -s ${var.godaddy_api_secret} -d ${var.domain} -n ${var.cluster_name} -a ${openstack_networking_floatingip_v2.swarm_manager_ip.address}"
  }

}
