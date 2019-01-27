provider "external" {
  version = "~> 1.0"
}

data "external" "admin-ws-public-ip" {
  # depends_on = ""
  program = ["bash", "${path.module}/files/admin_ws_ip_gen.sh", "139.178.70.170"]
}

resource "null_resource" "config-admin-ws" {
  connection {
    host     = "${data.external.admin-ws-public-ip.result["content"]}"
    type     = "ssh"
    user     = "${var.admin_ws_admin_username}"
    password = "${var.admin_ws_admin_password}"
  }

  provisioner "local-exec" {
    command = <<EOF
  ${path.module}/files/admin_ws_gen.sh \
  '${var.vcenter_admin_useranme}' \
  '${var.vcenter_admin_password}' \
  '${var.esxi_admin_username}' \
  '${var.esxi_admin_password}' \
  '${var.ova_vcsa}' \
  '${var.ova_f5}'
  EOF
  }

  provisioner "file" {
    source      = "${path.module}/files/govc"
    destination = "/tmp/govc"
  }

  provisioner "file" {
    source      = "${path.module}/files/vcsa.json"
    destination = "/tmp/vcsa.json"
  }

  provisioner "file" {
    source      = "${path.module}/files/f5.json"
    destination = "/tmp/f5.json"
  }

  # provisioner "remote-exec" {
  #   script = "${path.module}/files/admin_ws_tmp.sh"
  # }

  provisioner "file" {
    source      = "${path.module}/files/admin_ws_tmp.sh"
    destination = "/tmp/admin_ws_tmp.sh"
  }

  # provisioner "remote-exec" {
  #   # run bootstrap script on esxi
  #   inline = [
  #     "chmod +x /tmp/govc",
  #     "chmod +x /tmp/admin_ws_tmp.sh",
  #     "/tmp/admin_ws_tmp.sh",
  #   ]
  # }
}
