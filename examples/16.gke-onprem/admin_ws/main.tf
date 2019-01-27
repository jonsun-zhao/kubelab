resource "null_resource" "setup-admin-ws" {
  connection {
    host     = "${var.admin_ws_public_ip}"
    type     = "ssh"
    user     = "${var.admin_ws_admin_username}"
    password = "${var.admin_ws_admin_password}"
  }

  provisioner "local-exec" {
    command = "${path.module}/files/admin_ws_gen.sh '${var.vcenter_admin_useranme}' '${var.vcenter_admin_password}' '${var.esxi_admin_username}' '${var.esxi_admin_password}'"
  }

  provisioner "file" {
    source      = "${path.module}/files/govc"
    destination = "/tmp/govc"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/admin_ws_tmp.sh"
  }

  # provisioner "file" {
  #   source      = "${path.module}/files/admin_ws_tmp.sh"
  #   destination = "/tmp/admin_ws_tmp.sh"
  # }

  # provisioner "remote-exec" {
  #   # run bootstrap script on esxi
  #   inline = [
  #     "chmod +x /tmp/govc",
  #     "chmod +x /tmp/admin_ws_tmp.sh",
  #     "/tmp/admin_ws_tmp.sh",
  #   ]
  # }
}
