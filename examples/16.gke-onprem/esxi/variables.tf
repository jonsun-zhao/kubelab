variable "packet_auth_token" {
  description = "packet api key"
}

variable "packet_project_id" {
  description = "packet project hybrid-playground"
  default = "231a57e1-a348-43ce-9b26-b1238e82dc4c"
}

variable "packet_plan_name" {
  description = "packet machine type"
  default = "c2.medium.x86"
}

variable "esxi_hostname" {
  description = "esxi hostname"
}

variable "esxi_admin_username" {
  description = "esxi admin username"
  default = "gkeadmin"
}

variable "esxi_admin_passwordd" {
  description = "esxi admin password"
}
