provider "external" {
  version = "~> 1.0"
}

data "external" "admin_ws_public_ip" {
  program = ["bash", "${path.module}/files/gen_admin_ws_ip.sh", "${var.esxi_gw_ip}"]
}

data "template_file" "admin_ws_json" {
  template = "${file("${path.module}/files/admin_ws_json.tpl")}"

  vars = {
    gateway_ip = "${var.esxi_gw_ip}"
  }
}

# build admin_ws json from template
resource "local_file" "admin_ws_json" {
  content  = "${data.template_file.admin_ws_json.rendered}"
  filename = "${path.module}/files/admin_ws_tmp.json"
}

# set up admin workstation
resource "null_resource" "import_admin_ws" {
  # import ova
  provisioner "local-exec" {
    command = "govc import.ova -options=${path.module}/files/admin_ws_tmp.json ${var.ova_admin_ws}"

    environment {
      GOVC_INSECURE      = 1
      GOVC_URL           = "${var.esxi_public_ip}"
      GOVC_USERNAME      = "${var.esxi_admin_username}"
      GOVC_PASSWORD      = "${var.esxi_admin_password}"
      GOVC_DATASTORE     = "${var.esxi_ds_name}"
      GOVC_RESOURCE_POOL = "*/Resources"
    }
  }

  depends_on = ["local_file.admin_ws_json"]
}

data "template_file" "admin_ws_sh" {
  template = "${file("${path.module}/files/admin_ws_sh.tpl")}"

  vars = {
    vcenter_admin_username = "${var.vcenter_admin_username}"
    vcenter_admin_password = "${var.vcenter_admin_password}"
    esxi_admin_username    = "${var.esxi_admin_username}"
    esxi_admin_password    = "${var.esxi_admin_password}"
    esxi_ds_name           = "${var.esxi_ds_name}"
    ova_vcsa               = "${var.ova_vcsa}"
    ova_f5                 = "${var.ova_f5}"
    esxi_host              = "172.16.10.3"
  }
}

# build admin_ws script from template
resource "local_file" "admin_ws_sh" {
  content  = "${data.template_file.admin_ws_sh.rendered}"
  filename = "${path.module}/files/admin_ws_tmp.sh"
}

# import the rest of the ovas from admin workstation
resource "null_resource" "import_the_rest" {
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

  depends_on = ["local_file.admin_ws_sh", "null_resource.import_admin_ws"]
}
