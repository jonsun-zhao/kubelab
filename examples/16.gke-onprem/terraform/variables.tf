variable "packet_auth_token" {
  description = "packet api key"
  type        = "string"
}

variable "packet_project_id" {
  description = "packet project id"
  type        = "string"
}

variable "packet_region" {
  description = "packet region for server and storage"
  type        = "string"
  default     = "sjc1"
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

variable "esxi_ds_name" {
  type    = "string"
  default = "datastore1"
}

variable "vcenter_admin_username" {
  type    = "string"
  default = "administrator@gkeonprem.local"
}

variable "vcenter_admin_password" {
  type = "string"
}

variable "nsvm_admin_username" {
  type = "string"
}

variable "nsvm_admin_password" {
  type = "string"
}

variable "ova_nsvm" {
  type = "string"
}

variable "ova_vcsa" {
  type = "string"
}

variable "ova_f5" {
  type = "string"
}

variable "f5_addr" {
  type    = "string"
  default = "172.16.10.4"
}

variable "f5_user" {
  type    = "string"
  default = "admin"
}

variable "f5_pass" {
  type    = "string"
  default = "gk30npr3m!"
}

variable "f5_key" {
  type    = "string"
  default = ""
}

variable "gkeonprem_service_account_key_file" {
  type = "string"
}

variable "gkeonprem_service_account_email" {
  type = "string"
}

variable "gcp_project" {
  type = "string"
}

variable "gcp_compute_zone" {
  type = "string"
}
