variable "esxi_public_ip" {
  type = "string"
}

variable "esxi_gw_ip" {
  type = "string"
}

variable "vcenter_admin_username" {
  type    = "string"
  default = "administrator@gkeonprem.local"
}

variable "vcenter_admin_password" {
  type = "string"
}

variable "esxi_admin_username" {
  type = "string"
}

variable "esxi_admin_password" {
  type = "string"
}

variable "esxi_ds_name" {
  type    = "string"
  default = "persistent_ds1"
}

variable "admin_ws_admin_username" {
  type = "string"
}

variable "admin_ws_admin_password" {
  type = "string"
}

variable "ova_admin_ws" {
  type = "string"
}

variable "ova_vcsa" {
  type = "string"
}

variable "ova_f5" {
  type = "string"
}
