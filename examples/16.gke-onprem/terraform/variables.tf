variable "packet_auth_token" {
  description = "packet api key"
  type        = "string"
}

variable "packet_project_id" {
  description = "hybrid-playground"
  type        = "string"
  default     = "231a57e1-a348-43ce-9b26-b1238e82dc4c"
}

variable "packet_device_plan" {
  description = "packet machine type"
  type        = "string"
  default     = "c2.medium.x86"
}

variable "packet_storage_plan" {
  type    = "string"
  default = "storage_1"
}

variable "esxi_hostname" {
  type = "string"
}

variable "esxi_admin_username" {
  type = "string"
}

variable "esxi_admin_password" {
  type = "string"
}

variable "vcenter_admin_username" {
  type    = "string"
  default = "administrator@gkeonprem.local"
}

variable "vcenter_admin_password" {
  type = "string"
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
