variable "esxi_vm_name" {
  type    = "string"
  default = "esxi1"
}

variable "esxi_vm_cores" {
  description = "number of vcpus"
  type        = "string"
  default     = "4"
}

variable "esxi_vm_memory_size" {
  description = "memory size (MB)"
  type        = "string"
  default     = "32768"
}

variable "esxi_vm_storage_size" {
  description = "storage size (GB)"
  type        = "string"
  default     = "300"
}

variable "esxi_vm_iso" {
  description = "path to the customized esxi iso"
  type        = "string"
}

variable "pw_for_sudo" {
  type = "string"
}
