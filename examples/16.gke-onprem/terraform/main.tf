module "esxi_packet" {
  source = "./esxi_packet"

  packet_auth_token   = "${var.packet_auth_token}"
  packet_project_id   = "${var.packet_project_id}"
  packet_device_plan  = "${var.packet_device_plan}"
  packet_storage_plan = "${var.packet_storage_plan}"
  esxi_hostname       = "${var.esxi_hostname}"
  esxi_admin_username = "${var.esxi_admin_username}"
  esxi_admin_password = "${var.esxi_admin_password}"
}

module "admin_ws" {
  source = "./admin_ws"

  esxi_public_ip = "${module.esxi_packet.esxi_public_ip}"
  esxi_gw_ip     = "${module.esxi_packet.esxi_gw_ip}"

  vcenter_admin_useranme  = "${var.vcenter_admin_useranme}"
  vcenter_admin_password  = "${var.vcenter_admin_password}"
  esxi_admin_username     = "${var.esxi_admin_username}"
  esxi_admin_password     = "${var.esxi_admin_password}"
  admin_ws_admin_username = "${var.admin_ws_admin_username}"
  admin_ws_admin_password = "${var.admin_ws_admin_password}"
  ova_admin_ws            = "${var.ova_admin_ws}"
  ova_vcsa                = "${var.ova_vcsa}"
  ova_f5                  = "${var.ova_f5}"
}
