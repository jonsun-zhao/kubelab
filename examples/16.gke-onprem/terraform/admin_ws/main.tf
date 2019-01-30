provider "external" {
  version = "~> 1.0"
}

data "external" "admin_ws_public_ip" {
  program = ["bash", "${path.module}/files/gen_admin_ws_ip.sh", "${var.esxi_public_ip}"]
}

# set up admin workstation
resource "null_resource" "import_admin_ws" {
  # generate the vapp property json for admin ws
  provisioner "local-exec" {
    command = "${path.module}/files/gen_json.sh ${var.esxi_gw_ip}"
  }

  # import ova
  provisioner "local-exec" {
    command = "govc import.ova -options=${path.module}/files/admin_ws_tmp.json ${var.ova_admin_ws}"

    environment {
      GOVC_INSECURE      = 1
      GOVC_URL           = "${var.esxi_public_ip}"
      GOVC_USERNAME      = "${var.esxi_admin_username}"
      GOVC_PASSWORD      = "${var.esxi_admin_password}"
      GOVC_DATASTORE     = "persistent_ds1"
      GOVC_RESOURCE_POOL = "*/Resources"
    }
  }
}

resource "null_resource" "import_the_rest" {
  # generate admin-ws configuration script
  provisioner "local-exec" {
    command = <<EOF
${path.module}/files/gen_admin_ws_mod.sh \
'${var.vcenter_admin_useranme}' \
'${var.vcenter_admin_password}' \
'${var.esxi_admin_username}' \
'${var.esxi_admin_password}' \
'${var.ova_vcsa}' \
'${var.ova_f5}'
EOF
  }

  connection {
    host     = "${data.external.admin_ws_public_ip.result["ip"]}"
    type     = "ssh"
    user     = "${var.admin_ws_admin_username}"
    password = "${var.admin_ws_admin_password}"
  }

  # upload supporting files to admin-ws
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

  # run the admin-ws configuration script remotely
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

  depends_on = ["null_resource.import_admin_ws"]
}
