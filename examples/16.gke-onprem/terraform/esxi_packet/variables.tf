variable "packet_auth_token" {
  description = "packet api key"
}

variable "packet_region" {
  description = "packet server and storage region"
  default     = "sjc1"
}

variable "packet_project_id" {
  description = "packet project hybrid-playground"
}

variable "packet_device_plan" {
  description = "packet machine type"
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
