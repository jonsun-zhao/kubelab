#### CREATE CLUSTER ADD FOR GOVC COMMAND
data "template_file" "inventory_template" {
  template = "${file("${path.module}/files/inventory.yml.tpl")}"

  vars = {
    nsvm_public_ip                     = "${var.nsvm_public_ip}"
    nsvm_admin_password                = "${var.nsvm_admin_password}"
    nsvm_admin_username                = "${var.nsvm_admin_username}"
    vcenter_username                   = "${var.vcenter_admin_username}"
    vcenter_password                   = "${var.vcenter_admin_password}"
    esxi_username                      = "${var.esxi_admin_username}"
    esxi_password                      = "${var.esxi_admin_password}"
    esxi_hostname                      = "${var.esxi_hostname}"
    f5_addr                            = "${var.f5_addr}"
    f5_user                            = "${var.f5_user}"
    f5_pass                            = "${var.f5_pass}"
    f5_key                             = "${var.f5_key}"
    esxi_gw_ip                         = "${var.esxi_gw_ip}"
    esxi_username                      = "${var.esxi_admin_username}"
    esxi_password                      = "${var.esxi_admin_password}"
    esxi_public_ip                     = "${var.esxi_public_ip}"
    esxi_ds_name                       = "${var.esxi_ds_name}"
    govc_guest_login                   = "${var.nsvm_admin_username}:${var.nsvm_admin_password}"
    ova_f5                             = "${var.ova_f5}"
    f5_pass                            = "${var.f5_pass}"
    f5_key                             = "${var.f5_key}"
    gkeonprem_service_account_key_file = "${var.gkeonprem_service_account_key_file}"
    gkeonprem_service_account_email    = "${var.gkeonprem_service_account_email}"
    gcp_project                        = "${var.gcp_project}"
    gcp_compute_zone                   = "${var.gcp_compute_zone}"
    govc                               = "${var.govc}"
    buildscripts                       = "${var.buildscripts}"
    vcenter_iso                        = "${var.vcenter_iso}"
    gke_op_version                     = "${var.gke_op_version}"
  }
}

resource "local_file" "inventory_file" {
  content  = "${data.template_file.inventory_template.rendered}"
  filename = "${path.module}/files/inventory.yml"
}
