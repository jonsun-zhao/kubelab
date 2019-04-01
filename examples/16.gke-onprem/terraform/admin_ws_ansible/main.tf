#### CREATE CLUSTER ADD FOR GOVC COMMAND
data "template_file" "inventory_template" {
  template = "${file("${path.module}/files/inventory.yaml.tpl")}"

  vars = {
    vcenter_public_ip         = "${var.vcenter_public_ip}"
    admin_ws_admin_password   = "${var.admin_ws_admin_password}"
    admin_ws_admin_username   = "${var.admin_ws_admin_username}"
    vcenter_username          = "${var.vcenter_admin_username}"
    vcenter_password          = "${var.vcenter_admin_password}"
    esxi_username             = "${var.esxi_admin_username}"
    esxi_password             = "${var.esxi_admin_password}"
    esxi_hostname             = "${var.esxi_hostname}"
    f5_addr                   = "${var.f5_addr}"
    f5_user                   = "${var.f5_user}"
    f5_pass                   = "${var.f5_pass}"
    f5_key                    = "${var.f5_key}"
    esxi_gw_ip                = "${var.esxi_gw_ip}"
    esxi_username             = "${var.esxi_admin_username}"
    esxi_password             = "${var.esxi_admin_password}"
    esxi_public_ip            = "${var.esxi_public_ip}"
    govc_guest_login          = "${var.admin_ws_admin_username}:${var.admin_ws_admin_password}"
    ova_admin_ws              = "${var.ova_admin_ws}"
    ova_vcsa                  = "${var.ova_vcsa_web}"
    ova_f5                    = "${var.ova_f5_web}"
    module_path               = "${path.module}"
  }
}
resource "local_file" "inventory_file" {
  content  = "${data.template_file.inventory_template.rendered}"
  filename = "${path.module}/files/inventory.yaml"
}