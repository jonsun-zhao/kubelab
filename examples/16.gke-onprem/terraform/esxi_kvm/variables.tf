variable "esxi_vm_name" {
  default = "esxi1"
}

variable "esxi_vm_cores" {
  description = "number of vcpus"
  default     = 4
}

variable "esxi_vm_memory_size" {
  description = "memory size (MB)"
  default     = 32768
}

variable "esxi_vm_storage_size" {
  description = "storage size (GB)"
  default     = 300
}

variable "esxi_vm_iso" {
  description = "path to the customized esxi iso"
  default     = "/tmp/custom_esxi.iso"
}
