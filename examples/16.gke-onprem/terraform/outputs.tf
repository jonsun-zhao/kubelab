output "esxi_public_ip" {
  description = "ESXi public IP"
  value       = "${module.esxi_packet.esxi_public_ip}"
}

output "esxi_gw_ip" {
  description = "ESXi Gateway"
  value       = "${module.esxi_packet.esxi_gw_ip}"
}
