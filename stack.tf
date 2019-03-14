data "template_file" "traefik" {
  template = "${file("${path.module}/assets/traefik/traefik.tpl")}"

  vars {
    domain = "${var.domain}"
  }
}

data "template_file" "stack" {
  template = "${file("${path.module}/stacks/core/swarm-compose.tpl")}"

  vars {
    domain = "${var.domain}"
    mtu = "${var.docker_mtu}"
    version = "${var.version}"
    godaddy_api_key = "${var.godaddy_api_key}"
    godaddy_api_secret = "${var.godaddy_api_secret}"
    dataone_url = "${var.dataone_url}"
  }
}

resource "null_resource" "label_nodes" {
  depends_on = ["null_resource.provision_slave", "null_resource.provision_fileserver"]

  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }

  provisioner "file" {
    source = "./scripts/label-nodes.sh"
    destination = "/tmp/label-nodes.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/label-nodes.sh",
      "/tmp/label-nodes.sh ${var.cluster_name}-nfs"
    ]
  }

}

resource "null_resource" "deploy_stack" {
  depends_on = ["null_resource.label_nodes", "null_resource.provision_fileserver"]

  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/core/wholetale/traefik/acme"
    ]
  }

  provisioner "file" {
    source = "assets/traefik/acme/acme.json"
    destination = "/home/core/wholetale/traefik/acme/acme.json"
  }

  provisioner "file" {
    content = "${data.template_file.stack.rendered}"
    destination = "/home/core/wholetale/swarm-compose.yaml"
  }

  provisioner "file" {
    source = "stacks/monitoring/monitoring.yaml"
    destination = "/home/core/wholetale/monitoring.yaml"
  }

  provisioner "file" {
    content      = "${data.template_file.traefik.rendered}"
    destination = "/home/core/wholetale/traefik/traefik.toml"
  }

  provisioner "file" {
    source = "scripts/start-worker.sh"
    destination = "/home/core/wholetale/start-worker.sh"
  }

  provisioner "file" {
    source = "scripts/init-mongo.sh"
    destination = "/home/core/wholetale/init-mongo.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/core/wholetale/traefik/acme/acme.json",
      "docker stack deploy --compose-file /home/core/wholetale/swarm-compose.yaml wt",
      "docker stack deploy --compose-file /home/core/wholetale/monitoring.yaml omd"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/init-mongo.sh",
      "/home/core/wholetale/init-mongo.sh ${var.domain} ${var.globus_client_id} ${var.globus_client_secret}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/start-worker.sh",
      "/home/core/wholetale/start-worker.sh ${var.domain} manager ${var.registry_user} ${var.registry_pass} ${var.version}"
    ]
  }
}


resource "null_resource" "start_worker" {
  count = "${var.num_slaves}"
  depends_on = ["null_resource.deploy_stack"]
  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${element(openstack_networking_floatingip_v2.swarm_slave_ip.*.address, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/core/wholetale/"
    ]
  }

  provisioner "file" {
    source = "scripts/start-worker.sh"
    destination = "/home/core/wholetale/start-worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/start-worker.sh",
      "/home/core/wholetale/start-worker.sh ${var.domain} celery ${var.registry_user} ${var.registry_pass} ${var.version}"
    ]
  }
}
