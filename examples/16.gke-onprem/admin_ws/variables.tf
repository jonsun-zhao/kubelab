variable "admin_ws_public_ip" {
  type = "string"
}

variable "vcenter_admin_useranme" {
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

variable "admin_ws_admin_username" {
  type = "string"
}

variable "admin_ws_admin_password" {
  type = "string"
}
