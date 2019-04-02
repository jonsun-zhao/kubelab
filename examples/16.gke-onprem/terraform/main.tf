module "esxi_packet" {
  source = "./esxi_packet"

  packet_auth_token   = "${var.packet_auth_token}"
  packet_project_id   = "${var.packet_project_id}"
  packet_region       = "${var.packet_region}"
  packet_device_plan  = "${var.packet_device_plan}"
  packet_storage_plan = "${var.packet_storage_plan}"
  packet_facility     = "${var.packet_facility}"
  esxi_hostname       = "${var.esxi_hostname}"
  esxi_ds_name        = "${var.esxi_ds_name}"
  esxi_admin_username = "${var.esxi_admin_username}"
  esxi_admin_password = "${var.esxi_admin_password}"
}

//module "vm_setup" {
//  source = "./vm_setup"
//
//  esxi_public_ip          = "${module.esxi_packet.esxi_public_ip}"
//  esxi_gw_ip              = "${module.esxi_packet.esxi_gw_ip}"
//  esxi_admin_username     = "${var.esxi_admin_username}"
//  esxi_admin_password     = "${var.esxi_admin_password}"
//  admin_ws_admin_username = "${var.admin_ws_admin_username}"
//  admin_ws_admin_password = "${var.admin_ws_admin_password}"
//  ova_admin_ws            = "${var.ova_admin_ws}"
//  ova_vcsa                = "${var.ova_vcsa}"
//  ova_f5                  = "${var.ova_f5}"
//
//}

//module "admin_ws" {
//  source = "./admin_ws"
//
//  esxi_public_ip          = "${module.esxi_packet.esxi_public_ip}"
//  vcenter_public_ip       = "${element(split(".",module.esxi_packet.esxi_public_ip),0)}.${element(split(".",module.esxi_packet.esxi_public_ip),1)}.${element(split(".",module.esxi_packet.esxi_public_ip),2)}.${element(split(".",module.esxi_packet.esxi_public_ip),3) + 1}"
//  vcenter_admin_password  = "${var.vcenter_admin_password}"
//  esxi_admin_username     = "${var.esxi_admin_username}"
//  esxi_admin_password     = "${var.esxi_admin_password}"
//  admin_ws_admin_username = "${var.admin_ws_admin_username}"
//  admin_ws_admin_password = "${var.admin_ws_admin_password}"
//  f5_key                  = "${var.f5_key}"
//  dependency_link         = "${module.vm_setup.dependency_link}"
//
//
//}

module "admin_ws_ansible" {
  source = "./admin_ws_ansible"

  vcenter_public_ip       = "${element(split(".",module.esxi_packet.esxi_public_ip),0)}.${element(split(".",module.esxi_packet.esxi_public_ip),1)}.${element(split(".",module.esxi_packet.esxi_public_ip),2)}.${element(split(".",module.esxi_packet.esxi_public_ip),3) + 1}"
  vcenter_admin_username  = "${var.vcenter_admin_username}"
  vcenter_admin_password  = "${var.vcenter_admin_password}"
  esxi_public_ip          = "${module.esxi_packet.esxi_public_ip}"
  esxi_gw_ip              = "${module.esxi_packet.esxi_gw_ip}"
  esxi_admin_username     = "${var.esxi_admin_username}"
  esxi_admin_password     = "${var.esxi_admin_password}"
  esxi_ds_name            = "${var.esxi_ds_name}"
  esxi_hostname           = "${var.esxi_hostname}"
  admin_ws_admin_username = "${var.admin_ws_admin_username}"
  admin_ws_admin_password = "${var.admin_ws_admin_password}"
  f5_key                  = "${var.f5_key}"
  ova_admin_ws            = "${var.ova_admin_ws}"
  ova_vcsa                = "${var.ova_vcsa}"
  ova_f5                  = "${var.ova_f5}"
}
