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
  }
}

resource "null_resource" "label_nodes" {
  depends_on = ["null_resource.provision_slave"]

  connection {
    user = "${var.ssh_user_name}"
    private_key = "${file("${var.ssh_key_file}")}"
    host = "${openstack_networking_floatingip_v2.swarm_master_ip.address}"
  }

  provisioner "remote-exec" {
    script = "./scripts/label-nodes.sh"
  }
}

resource "null_resource" "deploy_stack" {
  depends_on = ["null_resource.label_nodes"]

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
    content = "${data.template_file.stack.rendered}"
    destination = "/home/core/wholetale/swarm-compose.yaml"
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
    source = "scripts/mongo.sh"
    destination = "/home/core/wholetale/mongo.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "docker stack deploy --compose-file /home/core/wholetale/swarm-compose.yaml wt"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/core/wholetale/init-mongo.sh
      "/home/core/wholetale/init-mongo.sh ${var.domain} ${var.globus_client_id} ${var.globus_client_secret} ${var.restore_url}"
    ]
  }

#  provisioner "remote-exec" {
#    inline = [
#      "chmod +x /home/core/wholetale/start-worker.sh"
#      "/home/core/wholetale/start-worker.sh ${var.domain}"
#    ]
#  }
}
