variable "packet_auth_token" {
  description = "packet api key"
}

variable "packet_project_id" {
  description = "packet project hybrid-playground"
  default     = "231a57e1-a348-43ce-9b26-b1238e82dc4c"
}

variable "packet_device_plan" {
  description = "packet machine type"
  default     = "c2.medium.x86"
}

variable "packet_storage_plan" {
  description = "packet storage type"
  default     = "storage_2"
}

variable "esxi_hostname" {
  description = "esxi hostname"
}

variable "esxi_admin_username" {
  description = "esxi admin username"
}

variable "esxi_admin_password" {
  description = "esxi admin password"
}
