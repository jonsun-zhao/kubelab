
variable "vcenter_public_ip" {
  type    = "string"
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

variable "esxi_hostname" {
  type = "string"
}

variable "admin_ws_admin_username" {
  type = "string"
}

variable "admin_ws_admin_password" {
  type = "string"
}

variable "f5_key" {
  type = "string"
}

variable "f5_addr" {
  type = "string"
  default = "172.16.10.4"
}

variable "f5_user" {
  type = "string"
  default = "admin"
}

variable "f5_pass" {
  type = "string"
  default = "gk30npr3m!"
}

variable "esxi_public_ip" {
  type = "string"
}

variable "esxi_gw_ip" {
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

variable "ova_vcsa_web" {
  type = "string"
  default = "https://storage.googleapis.com/gke-on-prem-lab-ovas/current/vcsa-latest.ova"
}

variable "ova_f5_web" {
  type = "string"
  default = "https://storage.googleapis.com/gke-on-prem-lab-ovas/current/f5-latest.ova"
}