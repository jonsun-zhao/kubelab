module "esxi_packet" {
  source = "./esxi_packet"

  packet_auth_token   = "${var.packet_auth_token}"
  packet_project_id   = "${var.packet_project_id}"
  packet_region       = "${var.packet_region}"
  packet_device_plan  = "${var.packet_device_plan}"
  esxi_hostname       = "${var.esxi_hostname}"
  esxi_admin_username = "${var.esxi_admin_username}"
  esxi_admin_password = "${var.esxi_admin_password}"
}

module "ansible" {
  source = "./ansible"

  nsvm_public_ip                     = "${element(split(".",module.esxi_packet.esxi_public_ip),0)}.${element(split(".",module.esxi_packet.esxi_public_ip),1)}.${element(split(".",module.esxi_packet.esxi_public_ip),2)}.${element(split(".",module.esxi_packet.esxi_public_ip),3) + 1}"
  vcenter_admin_username             = "${var.vcenter_admin_username}"
  vcenter_admin_password             = "${var.vcenter_admin_password}"
  esxi_public_ip                     = "${module.esxi_packet.esxi_public_ip}"
  esxi_gw_ip                         = "${module.esxi_packet.esxi_gw_ip}"
  esxi_admin_username                = "${var.esxi_admin_username}"
  esxi_admin_password                = "${var.esxi_admin_password}"
  esxi_ds_name                       = "${var.esxi_ds_name}"
  esxi_hostname                      = "${var.esxi_hostname}"
  nsvm_admin_username                = "${var.nsvm_admin_username}"
  nsvm_admin_password                = "${var.nsvm_admin_password}"
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
}
